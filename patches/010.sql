-- Descr: Add support for word conjugations.
-- Trans: 9->10

\set ON_ERROR_STOP

BEGIN;
INSERT INTO dbpatch(level) VALUES(10);

-- From pg/conj.sql...

-- Schema objects for word conjugations.

\set ON_ERROR_STOP 
BEGIN;

DROP TABLE IF EXISTS copos_notes, conjo_notes, conj_notes, conotes, conjo, conj, copos CASCADE;
DROP VIEW IF EXISTS vinfl, vconj CASCADE;

-- Parts-of-speech that are conjugatable. 
CREATE TABLE copos (
    pos INT PRIMARY KEY                   -- Part-of-speech id from 'kwpos'.
      REFERENCES kwpos(id) ON UPDATE CASCADE, 
    stem SMALLINT NOT NULL DEFAULT 1);    -- Number of characters to remove from dict form to get stem.
ALTER TABLE copos OWNER TO jmdictdb;

-- Notes for conj, conjo and copos items.
CREATE TABLE conotes (
    id INT PRIMARY KEY, 
    txt TEXT NOT NULL);
ALTER TABLE conotes OWNER TO jmdictdb;

-- Verb and adjective inflection names.
CREATE TABLE conj (
    id SMALLINT PRIMARY KEY,
    name VARCHAR(50) UNIQUE);             -- Eg, "present", "past", "conditional", provisional", etc.
ALTER TABLE conj OWNER TO jmdictdb;

-- Okurigana used for for each verb inflection type.
CREATE TABLE conjo (
    pos SMALLINT NOT NULL                 -- Part-of-speech id from 'kwpos'.
      REFERENCES kwpos(id) ON UPDATE CASCADE,
    conj SMALLINT NOT NULL                -- Conjugation id from 'conj'.
      REFERENCES conj(id) ON UPDATE CASCADE, 
    neg BOOLEAN NOT NULL DEFAULT FALSE,   -- Negative form.
    fml BOOLEAN NOT NULL DEFAULT FALSE,   -- Formal (aka distal) form.
    onum SMALLINT NOT NULL DEFAULT 1,     -- Okurigana variant id when more than one exists.
    okuri VARCHAR(50) NOT NULL,           -- Okurigana text.
    euphr VARCHAR(50) DEFAULT NULL,       -- Kana for euphonic change in stem (する and 来る).
    euphk VARCHAR(50) DEFAULT NULL,       -- Kanji for change in stem (used only for 為る-＞出来る).
    pos2 SMALLINT DEFAULT NULL            -- Part-of-speech (kwpos id) of word after conjugation.
      REFERENCES kwpos(id) ON UPDATE CASCADE,
    PRIMARY KEY (pos,conj,neg,fml,onum));
ALTER TABLE conjo OWNER TO jmdictdb;

-- Notes assignment tables.
CREATE TABLE copos_notes (
    pos SMALLINT NOT NULL
      REFERENCES copos(pos) ON UPDATE CASCADE, 
    note SMALLINT NOT NULL
      REFERENCES conotes(id) ON UPDATE CASCADE, 
    PRIMARY KEY (pos,note));
ALTER TABLE copos_notes OWNER TO jmdictdb;

CREATE TABLE conj_notes (
    conj SMALLINT NOT NULL
      REFERENCES conj(id) ON UPDATE CASCADE, 
    note SMALLINT NOT NULL
      REFERENCES conotes(id) ON UPDATE CASCADE, 
    PRIMARY KEY (conj,note));
ALTER TABLE conj_notes OWNER TO jmdictdb;

CREATE TABLE conjo_notes (
    pos SMALLINT NOT NULL,  ---.
    conj SMALLINT NOT NULL, --  \
    neg BOOLEAN NOT NULL,   --   +--- Primary key of table 'conjo'. 
    fml BOOLEAN NOT NULL,   --  /
    onum SMALLINT NOT NULL, ---'
      FOREIGN KEY (pos,conj,neg,fml,onum) REFERENCES conjo(pos,conj,neg,fml,onum) ON UPDATE CASCADE,
    note SMALLINT NOT NULL
      REFERENCES conotes(id) ON UPDATE CASCADE, 
    PRIMARY KEY (pos,conj,neg,fml,onum,note));
ALTER TABLE conjo_notes OWNER TO jmdictdb;

--------------------------------------------------------------------------------------------------
----    VIEWS    ---------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

CREATE OR REPLACE VIEW vconj AS (
    SELECT conjo.pos, kwpos.kw AS ptxt, conj.id AS conj, conj.name AS ctxt, conjo.neg, conjo.fml
    FROM conj
    INNER JOIN conjo ON conj.id=conjo.conj
    INNER JOIN kwpos ON kwpos.id=conjo.pos
    ORDER BY conjo.pos, conjo.conj, conjo.neg, conjo.fml);
ALTER VIEW vconj OWNER TO jmdictdb;

CREATE OR REPLACE VIEW vinfl AS (
    SELECT u.id, seq, src, unap, pos, ptxt, knum, ktxt, rnum, rtxt, conj, ctxt, neg, fml, 
        CASE WHEN neg THEN 'neg' ELSE 'aff' END || '-' ||
          CASE WHEN fml THEN 'polite' ELSE 'plain' END AS t, onum,
        COALESCE(euphk, LEFT(ktxt,LENGTH(ktxt)-stem)) || okuri AS kitxt,
        COALESCE(euphr, LEFT(rtxt,LENGTH(rtxt)-stem)) || okuri AS ritxt,
        (SELECT array_agg (note ORDER BY note) FROM conjo_notes n 
            WHERE u.pos=n.pos AND u.conj=n.conj AND u.neg=n.neg
                AND u.fml=n.fml AND u.onum=n.onum) AS notes
    FROM (
        SELECT DISTINCT entr.id, seq, src, unap, kanj.txt AS ktxt, rdng.txt AS rtxt,
                        pos.kw AS pos, kwpos.kw AS ptxt, conj.id AS conj, conj.name AS ctxt,
                        onum, okuri, neg, fml,
			kanj.kanj AS knum, rdng.rdng AS rnum, stem, euphr, euphk
	FROM entr
	JOIN sens ON entr.id=sens.entr
	JOIN pos ON pos.entr=sens.entr AND pos.sens=sens.sens
	JOIN kwpos ON kwpos.id=pos.kw
	JOIN conjo ON conjo.pos=pos.kw
	JOIN conj ON conj.id=conjo.conj
	JOIN copos ON copos.pos=conjo.pos
	LEFT JOIN kanj ON entr.id=kanj.entr
	LEFT JOIN rdng ON entr.id=rdng.entr
	WHERE conjo.okuri IS NOT NULL
	AND NOT EXISTS (SELECT 1 FROM stagr WHERE stagr.entr=entr.id AND stagr.sens=sens.sens AND stagr.rdng=rdng.rdng)
	AND NOT EXISTS (SELECT 1 FROM stagk WHERE stagk.entr=entr.id AND stagk.sens=sens.sens AND stagk.kanj=kanj.kanj)
	AND NOT EXISTS (SELECT 1 FROM restr WHERE restr.entr=entr.id AND restr.rdng=rdng.rdng AND restr.kanj=kanj.kanj)
        ) AS u)
    ORDER BY u.id,pos,knum,rnum,conj,neg,fml,onum;
ALTER VIEW vinfl OWNER TO jmdictdb;

-- Example:
--      SELECT * FROM vinfl
--      WHERE seq=.......
--      ORDER BY seq,knum,rnum,pos,conjid,t,onum; 

-- The following view combines, for each conjugation row, multiple okurigana
-- and multiple notes into a single string so that each conjugation will have
-- only one row.  Note that the string inside the string_agg() function below
-- contains an embedded newline.  This file needs to be saved with Unix-style
-- ('\n') newlines (rather than Windows style ('\r\n') in order to prevent
-- the '\r' characters from appearing in the view results.

CREATE OR REPLACE VIEW vinflxt_ AS (
    SELECT id, seq, src, unap, pos, ptxt, knum, ktxt, rnum, rtxt, conj, ctxt, t, string_agg ( 
      COALESCE (kitxt,'') || (CASE WHEN kitxt IS NOT NULL THEN '【' ELSE '' END) ||
      COALESCE (ritxt,'') || (CASE WHEN kitxt IS NOT NULL THEN '】' ELSE '' END) ||
      (CASE WHEN notes IS NOT NULL THEN ' [' ELSE '' END) ||
      COALESCE (ARRAY_TO_STRING (notes, ','), '') ||
      (CASE WHEN notes IS NOT NULL THEN ']' ELSE '' END), ',
' ORDER BY onum) AS word
    FROM vinfl
    GROUP BY id, seq, src, unap, pos, ptxt, knum, ktxt, rnum, rtxt, conj, ctxt, t
    ORDER BY id, pos, ptxt, knum, rnum, conj);
ALTER VIEW vinflxt_ OWNER TO jmdictdb;

CREATE OR REPLACE VIEW vinflxt AS (
    SELECT id, seq, src, unap, pos, ptxt, knum, ktxt, rnum, rtxt, conj, ctxt,
	MIN (CASE t WHEN 'aff-plain'  THEN word END) AS w0,
	MIN (CASE t WHEN 'aff-polite' THEN word END) AS w1,
	MIN (CASE t WHEN 'neg-plain'  THEN word END) AS w2,
	MIN (CASE t WHEN 'neg-polite' THEN word END) AS w3
        FROM vinflxt_
        GROUP BY id, seq, src, unap, pos, ptxt, knum, ktxt, rnum, rtxt, conj, ctxt
	ORDER BY id, pos, knum, rnum, conj);
ALTER VIEW vinflxt OWNER TO jmdictdb;

CREATE OR REPLACE VIEW vconotes AS (
    SELECT DISTINCT k.id AS pos, k.kw AS ptxt, m.*
        FROM kwpos k
        JOIN conjo c ON c.pos=k.id
        JOIN conjo_notes n ON n.pos=c.pos
        JOIN conotes m ON m.id=n.note
        ORDER BY m.id);
ALTER VIEW vconotes OWNER TO jmdictdb;

-- From pg/data/copos.csv...
\copy copos FROM stdin DELIMITER E'\t' CSV HEADER
pos	stem
1	1
2	0
17	0
28	1
30	1
31	1
32	1
33	1
34	1
35	1
36	1
37	1
38	2
39	1
40	1
41	1
42	1
45	1
46	0
47	1
48	1
\.

-- From pg/data/conj.csv...
\copy conj FROM stdin DELIMITER E'\t' CSV HEADER
id	name	formname
1	Non-past
2	Past (~ta)
3	Conjunctive (~te)
4	Provisional (~eba)
5	Potential
6	Passive
7	Causative
8	Causative-Passive 
9	Volitional
10	Imperative
11	Conditional (~tara)
12	Alternative (~tari)
13	Continuative (~i)
\.

-- From pg/data/conjo.csv...
\copy conjo FROM stdin DELIMITER E'\t' CSV HEADER
pos	conj	neg	fml	onum	okuri	euphr	euphk	pos2
1	1	False	False	1	い			
1	1	False	True	1	いです			
1	1	True	False	1	くない			
1	1	True	True	1	くないです			
1	1	True	True	2	くありません			
1	2	False	False	1	かった			
1	2	False	True	1	かったです			
1	2	True	False	1	くなかった			
1	2	True	True	1	くなかったです			
1	2	True	True	2	くありませんでした			
1	3	False	False	1	くて			
1	3	True	False	1	くなくて			
1	4	False	False	1	ければ			
1	4	True	False	1	くなければ			
1	7	False	False	1	くさせる			
1	9	False	False	1	かろう			
1	9	False	True	1	いでしょう			
1	11	False	False	1	かったら			
1	11	True	False	1	くなかったら			
1	12	False	False	1	かったり			
2	1	False	False	1	だ			
2	1	False	True	1	です			
2	1	True	False	1	ではない			
2	1	True	True	1	ではありません			
2	1	True	True	2	ではないです			
2	2	False	False	1	だった			
2	2	False	True	1	でした			
2	2	True	False	1	ではなかった			
2	2	True	True	1	ではありませんでした			
2	3	False	False	1	で			
2	3	False	True	1	でありまして			
2	3	True	False	1	ではなくて			
2	4	False	False	1	なら			
2	4	False	False	2	ならば			
2	4	False	False	3	であれば			
2	9	False	False	1	だろう			
2	9	False	True	1	でしょう			
2	10	False	False	1	であれ			
2	11	False	False	1	だったら			
2	11	False	True	1	でしたら			
2	11	True	False	1	ではなかったら			
2	11	True	True	1	ではありませんでしたら			
2	12	False	False	1	だったり			
17	1	False	False	1	だ			
17	1	False	True	1	です			
17	1	True	False	1	ではない			
17	1	True	True	1	ではありません			
17	1	True	True	2	ではないです			
17	2	False	False	1	だった			
17	2	False	True	1	でした			
17	2	True	False	1	ではなかった			
17	2	True	True	1	ではありませんでした			
17	3	False	False	1	で			
17	3	False	True	1	でありまして			
17	3	True	False	1	ではなくて			
17	4	False	False	1	なら			
17	4	False	False	2	ならば			
17	4	False	False	3	であれば			
17	9	False	False	1	だろう			
17	9	False	True	1	でしょう			
17	10	False	False	1	であれ			
17	11	False	False	1	だったら			
17	11	False	True	1	でしたら			
17	11	True	False	1	ではなかったら			
17	11	True	True	1	ではありませんでしたら			
17	12	False	False	1	だったり			
28	1	False	False	1	る			
28	1	False	True	1	ます			
28	1	True	False	1	ない			
28	1	True	True	1	ました			
28	2	False	False	1	た			
28	2	False	True	1	ました			
28	2	True	False	1	なかった			
28	2	True	True	1	ませんでした			
28	3	False	False	1	て			
28	3	False	True	1	まして			
28	3	True	False	1	なくて			
28	3	True	False	2	ないで			
28	3	True	True	1	ませんで			
28	4	False	False	1	れば			
28	4	False	True	1	ますなら			
28	4	False	True	2	ますならば			
28	4	True	False	1	なければ			
28	4	True	True	1	ませんなら			
28	4	True	True	2	ませんならば			
28	5	False	False	1	られる			
28	5	False	False	2	れる			
28	5	False	True	1	られます			
28	5	False	True	2	れます			
28	5	True	False	1	られない			
28	5	True	False	2	れない			
28	5	True	True	1	られません			
28	5	True	True	2	れません			
28	6	False	False	1	られる			
28	6	False	True	1	られます			
28	6	True	False	1	られない			
28	6	True	True	1	られません			
28	7	False	False	1	させる			
28	7	False	False	2	さす			
28	7	False	True	1	させます			
28	7	False	True	2	さします			
28	7	True	False	1	させない			
28	7	True	False	2	ささない			
28	7	True	True	1	させません			
28	7	True	True	2	さしません			
28	8	False	False	1	させられる			
28	8	False	True	1	させられます			
28	8	True	False	1	させられない			
28	8	True	True	1	させられません			
28	9	False	False	1	よう			
28	9	False	True	1	ましょう			
28	9	True	False	1	まい			
28	9	True	True	1	ますまい			
28	10	False	False	1	ろ			
28	10	False	True	1	なさい			
28	10	True	False	1	るな			
28	10	True	True	1	なさるな			
28	11	False	False	1	たら			
28	11	False	True	1	ましたら			
28	11	True	False	1	なかったら			
28	11	True	True	1	ませんでしたら			
28	12	False	False	1	たり			
28	12	False	True	1	ましたり			
28	12	True	False	1	なかったり			
28	12	True	True	1	ませんでしたり			
28	13	False	False	1	""			
30	1	False	False	1	る			
30	1	False	True	1	います			
30	1	True	False	1	らない			
30	1	True	True	1	いません			
30	2	False	False	1	った			
30	2	False	True	1	いました			
30	2	True	False	1	らなかった			
30	2	True	True	1	いませんでした			
30	3	False	False	1	って			
30	3	False	True	1	いまして			
30	3	True	False	1	らなくて			
30	3	True	False	2	らないで			
30	3	True	True	1	いませんで			
30	4	False	False	1	れば			
30	4	False	True	1	いますなら			
30	4	False	True	2	いますならば			
30	4	True	False	1	らなければ			
30	4	True	True	1	いませんなら			
30	4	True	True	2	いませんならば			
30	5	False	False	1	れる			
30	5	False	True	1	れます			
30	5	True	False	1	れない			
30	5	True	True	1	れません			
30	6	False	False	1	られる			
30	6	False	True	1	られます			
30	6	True	False	1	られない			
30	6	True	True	1	られません			
30	7	False	False	1	らせる			
30	7	False	False	2	らす			
30	7	False	True	1	らせます			
30	7	False	True	2	らします			
30	7	True	False	1	らせない			
30	7	True	False	2	らさない			
30	7	True	True	1	らせません			
30	7	True	True	2	らしません			
30	8	False	False	1	らせられる			
30	8	False	False	2	らされる			
30	8	False	True	1	らせられます			
30	8	False	True	2	らされます			
30	8	True	False	1	らせられない			
30	8	True	False	2	らされない			
30	8	True	True	1	らせられません			
30	8	True	True	2	らされません			
30	9	False	False	1	ろう			
30	9	False	True	1	いましょう			
30	9	True	False	1	るまい			
30	9	True	True	1	いませんまい			
30	10	False	False	1	い			
30	10	False	True	1	いなさい			
30	10	True	False	1	るな			
30	10	True	True	1	いなさるな			
30	11	False	False	1	ったら			
30	11	False	True	1	いましたら			
30	11	True	False	1	らなかったら			
30	11	True	True	1	いませんでしたら			
30	12	False	False	1	ったり			
30	12	False	True	1	いましたり			
30	12	True	False	1	らなかったり			
30	12	True	True	1	いませんでしたり			
30	13	False	False	1	い			
31	1	False	False	1	ぶ			
31	1	False	True	1	びます			
31	1	True	False	1	ばない			
31	1	True	True	1	びません			
31	2	False	False	1	んだ			
31	2	False	True	1	びました			
31	2	True	False	1	ばなかった			
31	2	True	True	1	びませんでした			
31	3	False	False	1	んで			
31	3	False	True	1	びまして			
31	3	True	False	1	ばなくて			
31	3	True	False	2	ばないで			
31	3	True	True	1	びませんで			
31	4	False	False	1	べば			
31	4	False	True	1	びますなら			
31	4	False	True	2	びますならば			
31	4	True	False	1	ばなければ			
31	4	True	True	1	びませんなら			
31	4	True	True	2	びませんならば			
31	5	False	False	1	べる			
31	5	False	True	1	べます			
31	5	True	False	1	べない			
31	5	True	True	1	べません			
31	6	False	False	1	ばれる			
31	6	False	True	1	ばれます			
31	6	True	False	1	ばれない			
31	6	True	True	1	ばれません			
31	7	False	False	1	ばせる			
31	7	False	False	2	ばす			
31	7	False	True	1	ばせます			
31	7	False	True	2	ばします			
31	7	True	False	1	ばせない			
31	7	True	False	2	ばさない			
31	7	True	True	1	ばせません			
31	7	True	True	2	ばしません			
31	8	False	False	1	ばせられる			
31	8	False	False	2	ばされる			
31	8	False	True	1	ばせられます			
31	8	False	True	2	ばされます			
31	8	True	False	1	ばせられない			
31	8	True	False	2	ばされない			
31	8	True	True	1	ばせられません			
31	8	True	True	2	ばされません			
31	9	False	False	1	ぼう			
31	9	False	True	1	びましょう			
31	9	True	False	1	ぶまい			
31	9	True	True	1	びませんまい			
31	10	False	False	1	べ			
31	10	False	True	1	びなさい			
31	10	True	False	1	ぶな			
31	10	True	True	1	びなさるな			
31	11	False	False	1	んだら			
31	11	False	True	1	びましたら			
31	11	True	False	1	ばなかったら			
31	11	True	True	1	びませんでしたら			
31	12	False	False	1	んだり			
31	12	False	True	1	びましたり			
31	12	True	False	1	ばなかったり			
31	12	True	True	1	びませんでしたり			
31	13	False	False	1	び			
32	1	False	False	1	ぐ			
32	1	False	True	1	ぎます			
32	1	True	False	1	がない			
32	1	True	True	1	ぎません			
32	2	False	False	1	いだ			
32	2	False	True	1	ぎました			
32	2	True	False	1	がなかった			
32	2	True	True	1	ぎませんでした			
32	3	False	False	1	いで			
32	3	False	True	1	ぎまして			
32	3	True	False	1	がなくて			
32	3	True	False	2	がないで			
32	3	True	True	1	ぎませんで			
32	4	False	False	1	げば			
32	4	False	True	1	ぎますなら			
32	4	False	True	2	ぎますならば			
32	4	True	False	1	がなければ			
32	4	True	True	1	ぎませんなら			
32	4	True	True	2	ぎませんならば			
32	5	False	False	1	げる			
32	5	False	True	1	げます			
32	5	True	False	1	げない			
32	5	True	True	1	げません			
32	6	False	False	1	がれる			
32	6	False	True	1	がれます			
32	6	True	False	1	がれない			
32	6	True	True	1	がれません			
32	7	False	False	1	がせる			
32	7	False	False	2	がす			
32	7	False	True	1	がせます			
32	7	False	True	2	がします			
32	7	True	False	1	がせない			
32	7	True	False	2	がさない			
32	7	True	True	1	がせません			
32	7	True	True	2	がしません			
32	8	False	False	1	がせられる			
32	8	False	False	2	がされる			
32	8	False	True	1	がせられます			
32	8	False	True	2	がされます			
32	8	True	False	1	がせられない			
32	8	True	False	2	がされない			
32	8	True	True	1	がせられません			
32	8	True	True	2	がされません			
32	9	False	False	1	ごう			
32	9	False	True	1	ぎましょう			
32	9	True	False	1	ぐまい			
32	9	True	True	1	ぎませんまい			
32	10	False	False	1	げ			
32	10	False	True	1	ぎなさい			
32	10	True	False	1	ぐな			
32	10	True	True	1	ぎなさるな			
32	11	False	False	1	いだら			
32	11	False	True	1	ぎましたら			
32	11	True	False	1	がなかったら			
32	11	True	True	1	ぎませんでしたら			
32	12	False	False	1	いだり			
32	12	False	True	1	ぎましたり			
32	12	True	False	1	がなかったり			
32	12	True	True	1	ぎませんでしたり			
32	13	False	False	1	ぎ			
33	1	False	False	1	く			
33	1	False	True	1	きます			
33	1	True	False	1	かない			
33	1	True	True	1	きません			
33	2	False	False	1	いた			
33	2	False	True	1	きました			
33	2	True	False	1	かなかった			
33	2	True	True	1	きませんでした			
33	3	False	False	1	いて			
33	3	False	True	1	きまして			
33	3	True	False	1	かなくて			
33	3	True	False	2	かないで			
33	3	True	True	1	きませんで			
33	4	False	False	1	けば			
33	4	False	True	1	きますなら			
33	4	False	True	2	きますならば			
33	4	True	False	1	かなければ			
33	4	True	True	1	きませんなら			
33	4	True	True	2	きませんならば			
33	5	False	False	1	ける			
33	5	False	True	1	けます			
33	5	True	False	1	けない			
33	5	True	True	1	けません			
33	6	False	False	1	かれる			
33	6	False	True	1	かれます			
33	6	True	False	1	かれない			
33	6	True	True	1	かれません			
33	7	False	False	1	かせる			
33	7	False	False	2	かす			
33	7	False	True	1	かせます			
33	7	False	True	2	かします			
33	7	True	False	1	かせない			
33	7	True	False	2	かさない			
33	7	True	True	1	かせません			
33	7	True	True	2	かしません			
33	8	False	False	1	かせられる			
33	8	False	False	2	かされる			
33	8	False	True	1	かせられます			
33	8	False	True	2	かされます			
33	8	True	False	1	かせられない			
33	8	True	False	2	かされない			
33	8	True	True	1	かせられません			
33	8	True	True	2	かされません			
33	9	False	False	1	こう			
33	9	False	True	1	きましょう			
33	9	True	False	1	くまい			
33	9	True	True	1	きませんまい			
33	10	False	False	1	け			
33	10	False	True	1	きなさい			
33	10	True	False	1	くな			
33	10	True	True	1	きなさるな			
33	11	False	False	1	いたら			
33	11	False	True	1	きましたら			
33	11	True	False	1	かなかったら			
33	11	True	True	1	きませんでしたら			
33	12	False	False	1	いたり			
33	12	False	True	1	きましたり			
33	12	True	False	1	かなかったり			
33	12	True	True	1	きませんでしたり			
33	13	False	False	1	き			
34	1	False	False	1	く			
34	1	False	True	1	きます			
34	1	True	False	1	かない			
34	1	True	True	1	きません			
34	2	False	False	1	った			
34	2	False	True	1	きました			
34	2	True	False	1	かなかった			
34	2	True	True	1	きませんでした			
34	3	False	False	1	って			
34	3	False	True	1	きまして			
34	3	True	False	1	かなくて			
34	3	True	False	2	かないで			
34	3	True	True	1	きませんで			
34	4	False	False	1	けば			
34	4	False	True	1	きますなら			
34	4	False	True	2	きますならば			
34	4	True	False	1	かなければ			
34	4	True	True	1	きませんなら			
34	4	True	True	2	きませんならば			
34	5	False	False	1	ける			
34	5	False	True	1	けます			
34	5	True	False	1	けない			
34	5	True	True	1	けません			
34	6	False	False	1	かれる			
34	6	False	True	1	かれます			
34	6	True	False	1	かれない			
34	6	True	True	1	かれません			
34	7	False	False	1	かせる			
34	7	False	False	2	かす			
34	7	False	True	1	かせます			
34	7	False	True	2	かします			
34	7	True	False	1	かせない			
34	7	True	False	2	かさない			
34	7	True	True	1	かせません			
34	7	True	True	2	かしません			
34	8	False	False	1	かせられる			
34	8	False	False	2	かされる			
34	8	False	True	1	かせられます			
34	8	False	True	2	かされます			
34	8	True	False	1	かせられない			
34	8	True	False	2	かされない			
34	8	True	True	1	かせられません			
34	8	True	True	2	かされません			
34	9	False	False	1	こう			
34	9	False	True	1	きましょう			
34	9	True	False	1	くまい			
34	9	True	True	1	きませんまい			
34	10	False	False	1	け			
34	10	False	True	1	きなさい			
34	10	True	False	1	くな			
34	10	True	True	1	きなさるな			
34	11	False	False	1	ったら			
34	11	False	True	1	きましたら			
34	11	True	False	1	かなかったら			
34	11	True	True	1	きませんでしたら			
34	12	False	False	1	ったり			
34	12	False	True	1	きましたり			
34	12	True	False	1	かなかったり			
34	12	True	True	1	きませんでしたり			
34	13	False	False	1	き			
35	1	False	False	1	む			
35	1	False	True	1	みます			
35	1	True	False	1	まない			
35	1	True	True	1	みません			
35	2	False	False	1	んだ			
35	2	False	True	1	みました			
35	2	True	False	1	まなかった			
35	2	True	True	1	みませんでした			
35	3	False	False	1	んで			
35	3	False	True	1	みまして			
35	3	True	False	1	まなくて			
35	3	True	False	2	まないで			
35	3	True	True	1	みませんで			
35	4	False	False	1	めば			
35	4	False	True	1	みますなら			
35	4	False	True	2	みますならば			
35	4	True	False	1	まなければ			
35	4	True	True	1	みませんなら			
35	4	True	True	2	みませんならば			
35	5	False	False	1	める			
35	5	False	True	1	めます			
35	5	True	False	1	めない			
35	5	True	True	1	めません			
35	6	False	False	1	まれる			
35	6	False	True	1	まれます			
35	6	True	False	1	まれない			
35	6	True	True	1	まれません			
35	7	False	False	1	ませる			
35	7	False	False	2	ます			
35	7	False	True	1	ませます			
35	7	False	True	2	まします			
35	7	True	False	1	ませない			
35	7	True	False	2	まさない			
35	7	True	True	1	ませません			
35	7	True	True	2	ましません			
35	8	False	False	1	ませられる			
35	8	False	False	2	まされる			
35	8	False	True	1	ませられます			
35	8	False	True	2	まされます			
35	8	True	False	1	ませられない			
35	8	True	False	2	まされない			
35	8	True	True	1	ませられません			
35	8	True	True	2	まされません			
35	9	False	False	1	もう			
35	9	False	True	1	みましょう			
35	9	True	False	1	むまい			
35	9	True	True	1	みませんまい			
35	10	False	False	1	め			
35	10	False	True	1	みなさい			
35	10	True	False	1	むな			
35	10	True	True	1	みなさるな			
35	11	False	False	1	んだら			
35	11	False	True	1	みましたら			
35	11	True	False	1	まなかったら			
35	11	True	True	1	みませんでしたら			
35	12	False	False	1	んだり			
35	12	False	True	1	みましたり			
35	12	True	False	1	まなかったり			
35	12	True	True	1	みませんでしたり			
35	13	False	False	1	み			
36	1	False	False	1	ぬ			
36	1	False	True	1	にます			
36	1	True	False	1	なない			
36	1	True	True	1	にません			
36	2	False	False	1	んだ			
36	2	False	True	1	にました			
36	2	True	False	1	ななかった			
36	2	True	True	1	にませんでした			
36	3	False	False	1	んで			
36	3	False	True	1	にまして			
36	3	True	False	1	ななくて			
36	3	True	False	2	なないで			
36	3	True	True	1	にませんで			
36	4	False	False	1	ねば			
36	4	False	True	1	にますなら			
36	4	False	True	2	にますならば			
36	4	True	False	1	ななければ			
36	4	True	True	1	にませんなら			
36	4	True	True	2	にませんならば			
36	5	False	False	1	ねる			
36	5	False	True	1	ねます			
36	5	True	False	1	ねない			
36	5	True	True	1	ねません			
36	6	False	False	1	なれる			
36	6	False	True	1	なれます			
36	6	True	False	1	なれない			
36	6	True	True	1	なれません			
36	7	False	False	1	なせる			
36	7	False	False	2	なす			
36	7	False	True	1	なせます			
36	7	False	True	2	なします			
36	7	True	False	1	なせない			
36	7	True	False	2	なさない			
36	7	True	True	1	なせません			
36	7	True	True	2	なしません			
36	8	False	False	1	なせられる			
36	8	False	False	2	なされる			
36	8	False	True	1	なせられます			
36	8	False	True	2	なされます			
36	8	True	False	1	なせられない			
36	8	True	False	2	なされない			
36	8	True	True	1	なせられません			
36	8	True	True	2	なされません			
36	9	False	False	1	のう			
36	9	False	True	1	にましょう			
36	9	True	False	1	ぬまい			
36	9	True	True	1	にませんまい			
36	10	False	False	1	ね			
36	10	False	True	1	になさい			
36	10	True	False	1	ぬな			
36	10	True	True	1	になさるな			
36	11	False	False	1	んだら			
36	11	False	True	1	にましたら			
36	11	True	False	1	ななかったら			
36	11	True	True	1	にませんでしたら			
36	12	False	False	1	んだり			
36	12	False	True	1	にましたり			
36	12	True	False	1	ななかったり			
36	12	True	True	1	にませんでしたり			
36	13	False	False	1	に			
37	1	False	False	1	る			
37	1	False	True	1	ります			
37	1	True	False	1	らない			
37	1	True	True	1	りません			
37	2	False	False	1	った			
37	2	False	True	1	りました			
37	2	True	False	1	らなかった			
37	2	True	True	1	りませんでした			
37	3	False	False	1	って			
37	3	False	True	1	りまして			
37	3	True	False	1	らなくて			
37	3	True	False	2	らないで			
37	3	True	True	1	りませんで			
37	4	False	False	1	れば			
37	4	False	True	1	りますなら			
37	4	False	True	2	りますならば			
37	4	True	False	1	らなければ			
37	4	True	True	1	りませんなら			
37	4	True	True	2	りませんならば			
37	5	False	False	1	れる			
37	5	False	True	1	れます			
37	5	True	False	1	れない			
37	5	True	True	1	れません			
37	6	False	False	1	られる			
37	6	False	True	1	られます			
37	6	True	False	1	られない			
37	6	True	True	1	られません			
37	7	False	False	1	らせる			
37	7	False	False	2	らす			
37	7	False	True	1	らせます			
37	7	False	True	2	らします			
37	7	True	False	1	らせない			
37	7	True	False	2	らさない			
37	7	True	True	1	らせません			
37	7	True	True	2	らしません			
37	8	False	False	1	らせられる			
37	8	False	False	2	らされる			
37	8	False	True	1	らせられます			
37	8	False	True	2	らされます			
37	8	True	False	1	らせられない			
37	8	True	False	2	らされない			
37	8	True	True	1	らせられません			
37	8	True	True	2	らされません			
37	9	False	False	1	ろう			
37	9	False	True	1	りましょう			
37	9	True	False	1	るまい			
37	9	True	True	1	りませんまい			
37	10	False	False	1	れ			
37	10	False	True	1	りなさい			
37	10	True	False	1	るな			
37	10	True	True	1	りなさるな			
37	11	False	False	1	ったら			
37	11	False	True	1	りましたら			
37	11	True	False	1	らなかったら			
37	11	True	True	1	りませんでしたら			
37	12	False	False	1	ったり			
37	12	False	True	1	りましたり			
37	12	True	False	1	らなかったり			
37	12	True	True	1	りませんでしたり			
37	13	False	False	1	り			
38	1	False	False	1	ある			
38	1	False	True	1	あります			
38	1	True	False	1	ない			
38	1	True	True	1	ありません			
38	2	False	False	1	あった			
38	2	False	True	1	ありました			
38	2	True	False	1	なかった			
38	2	True	True	1	ありませんでした			
38	3	False	False	1	あって			
38	3	False	True	1	ありまして			
38	3	True	False	1	なくて			
38	3	True	False	2	ないで			
38	3	True	True	1	ありませんで			
38	4	False	False	1	あれば			
38	4	False	True	1	ありますなら			
38	4	False	True	2	ありますならば			
38	4	True	False	1	なければ			
38	4	True	True	1	ありませんなら			
38	4	True	True	2	ありませんならば			
38	5	False	False	1	あれる			
38	5	False	True	1	あれます			
38	5	True	False	1	あれない			
38	5	True	True	1	あれません			
38	6	False	False	1	あられる			
38	6	False	True	1	あられます			
38	6	True	False	1	あられない			
38	6	True	True	1	あられません			
38	7	False	False	1	あらせる			
38	7	False	False	2	あらす			
38	7	False	True	1	あらせます			
38	7	False	True	2	あらします			
38	7	True	False	1	あらせない			
38	7	True	False	2	あらさない			
38	7	True	True	1	あらせません			
38	7	True	True	2	あらしません			
38	8	False	False	1	あらせられる			
38	8	False	False	2	あらされる			
38	8	False	True	1	あらせられます			
38	8	False	True	2	あらされます			
38	8	True	False	1	あらせられない			
38	8	True	False	2	あらされない			
38	8	True	True	1	あらせられません			
38	8	True	True	2	あらされません			
38	9	False	False	1	あろう			
38	9	False	True	1	ありましょう			
38	9	True	False	1	あるまい			
38	9	True	True	1	ありませんまい			
38	10	False	False	1	あれ			
38	10	False	True	1	ありなさい			
38	10	True	False	1	あるな			
38	10	True	True	1	ありなさるな			
38	11	False	False	1	あったら			
38	11	False	True	1	ありましたら			
38	11	True	False	1	なかったら			
38	11	True	True	1	ありませんでしたら			
38	12	False	False	1	あったり			
38	12	False	True	1	ありましたり			
38	12	True	False	1	なかったり			
38	12	True	True	1	ありませんでしたり			
38	13	False	False	1	あり			
39	1	False	False	1	す			
39	1	False	True	1	します			
39	1	True	False	1	さない			
39	1	True	True	1	しません			
39	2	False	False	1	した			
39	2	False	True	1	しました			
39	2	True	False	1	さなかった			
39	2	True	True	1	しませんでした			
39	3	False	False	1	して			
39	3	False	True	1	しまして			
39	3	True	False	1	さなくて			
39	3	True	False	2	さないで			
39	3	True	True	1	しませんで			
39	4	False	False	1	せば			
39	4	False	True	1	しますなら			
39	4	False	True	2	しますならば			
39	4	True	False	1	さなければ			
39	4	True	True	1	しませんなら			
39	4	True	True	2	しませんならば			
39	5	False	False	1	せる			
39	5	False	True	1	せます			
39	5	True	False	1	せない			
39	5	True	True	1	せません			
39	6	False	False	1	される			
39	6	False	True	1	されます			
39	6	True	False	1	されない			
39	6	True	True	1	されません			
39	7	False	False	1	させる			
39	7	False	False	2	さる			
39	7	False	True	1	させます			
39	7	False	True	2	さします			
39	7	True	False	1	させない			
39	7	True	False	2	ささない			
39	7	True	True	1	させません			
39	7	True	True	2	さしません			
39	8	False	False	1	させられる			
39	8	False	True	1	させられます			
39	8	True	False	1	させられない			
39	8	True	True	1	させられません			
39	9	False	False	1	そう			
39	9	False	True	1	しましょう			
39	9	True	False	1	すまい			
39	9	True	True	1	しませんまい			
39	10	False	False	1	せ			
39	10	False	True	1	しなさい			
39	10	True	False	1	すな			
39	10	True	True	1	しなさるな			
39	11	False	False	1	したら			
39	11	False	True	1	しましたら			
39	11	True	False	1	さなかったら			
39	11	True	True	1	しませんでしたら			
39	12	False	False	1	したり			
39	12	False	True	1	しましたり			
39	12	True	False	1	さなかったり			
39	12	True	True	1	しませんでしたり			
39	13	False	False	1	し			
40	1	False	False	1	つ			
40	1	False	True	1	ちます			
40	1	True	False	1	たない			
40	1	True	True	1	ちません			
40	2	False	False	1	った			
40	2	False	True	1	ちました			
40	2	True	False	1	たなかった			
40	2	True	True	1	ちませんでした			
40	3	False	False	1	って			
40	3	False	True	1	ちまして			
40	3	True	False	1	たなくて			
40	3	True	False	2	たないで			
40	3	True	True	1	ちませんで			
40	4	False	False	1	てば			
40	4	False	True	1	ちますなら			
40	4	False	True	2	ちますならば			
40	4	True	False	1	たなければ			
40	4	True	True	1	ちませんなら			
40	4	True	True	2	ちませんならば			
40	5	False	False	1	てる			
40	5	False	True	1	てます			
40	5	True	False	1	てない			
40	5	True	True	1	てません			
40	6	False	False	1	たれる			
40	6	False	True	1	たれます			
40	6	True	False	1	たれない			
40	6	True	True	1	たれません			
40	7	False	False	1	たせる			
40	7	False	False	2	たす			
40	7	False	True	1	たせます			
40	7	False	True	2	たします			
40	7	True	False	1	たせない			
40	7	True	False	2	たさない			
40	7	True	True	1	たせません			
40	7	True	True	2	たしません			
40	8	False	False	1	たせられる			
40	8	False	False	2	たされる			
40	8	False	True	1	たせられます			
40	8	False	True	2	たされます			
40	8	True	False	1	たせられない			
40	8	True	False	2	たされない			
40	8	True	True	1	たせられません			
40	8	True	True	2	たされません			
40	9	False	False	1	とう			
40	9	False	True	1	ちましょう			
40	9	True	False	1	つまい			
40	9	True	True	1	ちませんまい			
40	10	False	False	1	て			
40	10	False	True	1	ちなさい			
40	10	True	False	1	つな			
40	10	True	True	1	ちなさるな			
40	11	False	False	1	ったら			
40	11	False	True	1	ちまったら			
40	11	True	False	1	たなかったら			
40	11	True	True	1	ちませんでしたら			
40	12	False	False	1	ったり			
40	12	False	True	1	ちましたり			
40	12	True	False	1	たなかったり			
40	12	True	True	1	ちませんでしたり			
40	13	False	False	1	ち			
41	1	False	False	1	う			
41	1	False	True	1	います			
41	1	True	False	1	わない			
41	1	True	True	1	いません			
41	2	False	False	1	った			
41	2	False	True	1	いました			
41	2	True	False	1	わなかった			
41	2	True	True	1	いませんでした			
41	3	False	False	1	って			
41	3	False	True	1	いまして			
41	3	True	False	1	わなくて			
41	3	True	False	2	わないで			
41	3	True	True	1	いませんで			
41	4	False	False	1	えば			
41	4	False	True	1	いますなら			
41	4	False	True	2	いますならば			
41	4	True	False	1	わなければ			
41	4	True	True	1	いませんなら			
41	4	True	True	2	いませんならば			
41	5	False	False	1	える			
41	5	False	True	1	えます			
41	5	True	False	1	えない			
41	5	True	True	1	えません			
41	6	False	False	1	われる			
41	6	False	True	1	われます			
41	6	True	False	1	われない			
41	6	True	True	1	われません			
41	7	False	False	1	わせる			
41	7	False	False	2	わす			
41	7	False	True	1	わせます			
41	7	False	True	2	わします			
41	7	True	False	1	わせない			
41	7	True	False	2	わさない			
41	7	True	True	1	わせません			
41	7	True	True	2	わしません			
41	8	False	False	1	わせられる			
41	8	False	False	2	わされる			
41	8	False	True	1	わせられます			
41	8	False	True	2	わされます			
41	8	True	False	1	わせられない			
41	8	True	False	2	わされない			
41	8	True	True	1	わせられません			
41	8	True	True	2	わされません			
41	9	False	False	1	おう			
41	9	False	True	1	いましょう			
41	9	True	False	1	うまい			
41	9	True	True	1	いませんまい			
41	10	False	False	1	え			
41	10	False	True	1	いなさい			
41	10	True	False	1	うな			
41	10	True	True	1	いなさるな			
41	11	False	False	1	ったら			
41	11	False	True	1	いましたら			
41	11	True	False	1	わかったら			
41	11	True	True	1	いませんでしたら			
41	12	False	False	1	ったり			
41	12	False	True	1	いましたり			
41	12	True	False	1	わなかったり			
41	12	True	True	1	いませんでしたり			
41	13	False	False	1	い			
42	1	False	False	1	う			
42	1	False	True	1	います			
42	1	True	False	1	わない			
42	1	True	True	1	いません			
42	2	False	False	1	うた			
42	2	False	True	1	いました			
42	2	True	False	1	わなかった			
42	2	True	True	1	いませんでした			
42	3	False	False	1	うて			
42	3	False	True	1	いまして			
42	3	True	False	1	わなくて			
42	3	True	False	2	わないで			
42	3	True	True	1	いませんで			
42	4	False	False	1	えば			
42	4	False	True	1	いますなら			
42	4	False	True	2	いますならば			
42	4	True	False	1	わなければ			
42	4	True	True	1	いませんなら			
42	4	True	True	2	いませんならば			
42	5	False	False	1	える			
42	5	False	True	1	えます			
42	5	True	False	1	えない			
42	5	True	True	1	えません			
42	6	False	False	1	われる			
42	6	False	True	1	われます			
42	6	True	False	1	われない			
42	6	True	True	1	われません			
42	7	False	False	1	わせる			
42	7	False	False	2	わす			
42	7	False	True	1	わせます			
42	7	False	True	2	わします			
42	7	True	False	1	わせない			
42	7	True	False	2	わさない			
42	7	True	True	1	わせません			
42	7	True	True	2	わしません			
42	8	False	False	1	わせられる			
42	8	False	False	2	わされる			
42	8	False	True	1	わせられます			
42	8	False	True	2	わされます			
42	8	True	False	1	わせられない			
42	8	True	False	2	わされない			
42	8	True	True	1	わせられません			
42	8	True	True	2	わされません			
42	9	False	False	1	おう			
42	9	False	True	1	いましょう			
42	9	True	False	1	うまい			
42	9	True	True	1	いませんまい			
42	10	False	False	1	え			
42	10	False	True	1	いなさい			
42	10	True	False	1	うな			
42	10	True	True	1	いなさるな			
42	11	False	False	1	うたら			
42	11	False	True	1	いましたら			
42	11	True	False	1	わなかったら			
42	11	True	True	1	いませんでしたら			
42	12	False	False	1	うたり			
42	12	False	True	1	いましたり			
42	12	True	False	1	わなかったり			
42	12	True	True	1	いませんでしたり			
42	13	False	False	1	い			
45	1	False	False	1	る	く		
45	1	False	True	1	ます	き		
45	1	True	False	1	ない	こ		
45	1	True	True	1	ません	き		
45	2	False	False	1	た	き		
45	2	False	True	1	ました	き		
45	2	True	False	1	なかった	こ		
45	2	True	True	1	ませんでした	き		
45	3	False	False	1	て	き		
45	3	False	True	1	まして	き		
45	3	True	False	1	なくて	こ		
45	3	True	False	2	ないで	こ		
45	3	True	True	1	ませんで	き		
45	4	False	False	1	れば	こ		
45	4	False	True	1	ますなら	き		
45	4	False	True	2	ますならば	き		
45	4	True	False	1	なければ	こ		
45	4	True	True	1	ませんなら	き		
45	4	True	True	2	ませんならば	き		
45	5	False	False	1	られる	こ		
45	5	False	False	2	れる	こ		
45	5	False	True	1	られます	こ		
45	5	False	True	2	れます	こ		
45	5	True	False	1	られない	こ		
45	5	True	False	2	れない	こ		
45	5	True	True	1	られません	こ		
45	5	True	True	2	れません	こ		
45	6	False	False	1	られる	こ		
45	6	False	True	1	られます	こ		
45	6	True	False	1	られない	こ		
45	6	True	True	1	られません	こ		
45	7	False	False	1	させる	こ		
45	7	False	False	2	さす	こ		
45	7	False	True	1	させます	こ		
45	7	False	True	2	さします	こ		
45	7	True	False	1	させない	こ		
45	7	True	False	2	ささない	こ		
45	7	True	True	1	させません	こ		
45	7	True	True	2	さしません	こ		
45	8	False	False	1	させられる	こ		
45	8	False	True	1	させられます	こ		
45	8	True	False	1	させられない	こ		
45	8	True	True	1	させられません	こ		
45	9	False	False	1	よう	こ		
45	9	False	True	1	ましょう	き		
45	9	True	False	1	まい	こ		
45	9	True	True	1	ますまい	き		
45	10	False	False	1	い	こ		
45	10	False	True	1	なさい	こ		
45	10	True	False	1	るな	く		
45	10	True	True	1	なさるな	こ		
45	11	False	False	1	たら	き		
45	11	False	True	1	ましたら	き		
45	11	True	False	1	なかったら	こ		
45	11	True	True	1	ませんでしたら	き		
45	12	False	False	1	たり	き		
45	12	False	True	1	ましたり	き		
45	12	True	False	1	なかったり	こ		
45	12	True	True	1	ませんでしたり	き		
45	13	False	False	1	""	き		
46	1	False	False	1	する			
46	1	False	True	1	します			
46	1	True	False	1	しない			
46	1	True	True	1	しません			
46	2	False	False	1	した			
46	2	False	True	1	しました			
46	2	True	False	1	しなかった			
46	2	True	True	1	しませんでした			
46	3	False	False	1	して			
46	3	False	True	1	しまして			
46	3	True	False	1	しなくて			
46	3	True	False	2	しないで			
46	3	True	True	1	しませんで			
46	4	False	False	1	すれば			
46	4	False	True	1	しますなら			
46	4	False	True	2	しますなれば			
46	4	True	False	1	しなければ			
46	4	True	True	1	しませんなら			
46	4	True	True	2	しませんならば			
46	5	False	False	1	のことができる			
46	5	False	True	1	のことができます			
46	5	True	False	1	のことができない			
46	5	True	True	1	のことができません			
46	6	False	False	1	されない			
46	6	False	True	1	されます			
46	6	True	False	1	されない			
46	6	True	True	1	されません			
46	7	False	False	1	させる			
46	7	False	False	2	さす			
46	7	False	True	1	させます			
46	7	False	True	2	さします			
46	7	True	False	1	させない			
46	7	True	False	2	ささない			
46	7	True	True	1	させません			
46	7	True	True	2	さしません			
46	8	False	False	1	させられる			
46	8	False	True	1	させられます			
46	8	True	False	1	させられない			
46	8	True	True	1	させられません			
46	9	False	False	1	しよう			
46	9	False	True	1	しましょう			
46	9	True	False	1	するまい			
46	9	True	True	1	しますまい			
46	10	False	False	1	しろ			
46	10	False	False	2	せよ			
46	10	False	True	1	しなさい			
46	10	True	False	1	するな			
46	10	True	True	1	しなさるな			
46	11	False	False	1	したら			
46	11	False	True	1	しましたら			
46	11	True	False	1	しなかったら			
46	11	True	True	1	しませんでしたら			
46	12	False	False	1	したり			
46	12	False	True	1	しましたり			
46	12	True	False	1	しなかったり			
46	12	True	True	1	しませんでしたり			
46	13	False	False	1	し			
47	1	False	False	1	る	す		
47	1	False	True	1	ます	し		
47	1	True	False	1	ない	し		
47	1	True	True	1	ません	し		
47	2	False	False	1	た	し		
47	2	False	True	1	ました	し		
47	2	True	False	1	なかった	し		
47	2	True	True	1	ませんでした	し		
47	3	False	False	1	て	し		
47	3	False	True	1	まして	し		
47	3	True	False	1	なくて	し		
47	3	True	False	2	ないで	し		
47	3	True	True	1	ませんで	し		
47	4	False	False	1	れば	す		
47	4	False	True	1	ますなら	し		
47	4	False	True	2	ますなれば	し		
47	4	True	False	1	なければ	し		
47	4	True	True	1	ませんなら	し		
47	4	True	True	2	ませんならば	し		
47	5	False	False	1	る	でき	出来	
47	5	False	True	1	ます	でき	出来	
47	5	True	False	1	ない	でき	出来	
47	5	True	True	1	ません	でき	出来	
47	6	False	False	1	れる	さ		
47	6	False	True	1	れます	さ		
47	6	True	False	1	れない	さ		
47	6	True	True	1	れません	さ		
47	7	False	False	1	せる	さ		
47	7	False	False	2	す	さ		
47	7	False	True	1	せます	さ		
47	7	False	True	2	します	さ		
47	7	True	False	1	せない	さ		
47	7	True	False	2	さない	さ		
47	7	True	True	1	せません	さ		
47	7	True	True	2	しません	さ		
47	8	False	False	1	せられる	さ		
47	8	False	True	1	せられます	さ		
47	8	True	False	1	せられない	さ		
47	8	True	True	1	せられません	さ		
47	9	False	False	1	よう	し		
47	9	False	True	1	ましょう	し		
47	9	True	False	1	るまい	す		
47	9	True	True	1	ますまい	し		
47	10	False	False	1	ろ	し		
47	10	False	False	2	よ	せ		
47	10	False	True	1	なさい	し		
47	10	True	False	1	るな	す		
47	10	True	True	1	なさるな	し		
47	11	False	False	1	たら	し		
47	11	False	True	1	ましたら	し		
47	11	True	False	1	なかったら	し		
47	11	True	True	1	ませんでしたら	し		
47	12	False	False	1	たり	し		
47	12	False	True	1	ましたり	し		
47	12	True	False	1	なかったり	し		
47	12	True	True	1	ませんでしたり	し		
47	13	False	False	1	""	し		
48	1	False	False	1	る	す		
48	1	False	True	1	ます	し		
48	1	True	False	1	ない	し		
48	1	True	True	1	ません	し		
48	2	False	False	1	た	し		
48	2	False	True	1	ました	し		
48	2	True	False	1	なかった	し		
48	2	True	True	1	ませんでした	し		
48	3	False	False	1	て	し		
48	3	False	True	1	まして	し		
48	3	True	False	1	なくて	し		
48	3	True	False	2	ないで	し		
48	3	True	True	1	ませんで	し		
48	4	False	False	1	れば	す		
48	4	False	True	1	ますなら	し		
48	4	False	True	2	ますなれば	し		
48	4	True	False	1	なければ	し		
48	4	True	True	1	ませんなら	し		
48	4	True	True	2	ませんならば	し		
48	5	False	False	1	る	でき	出来	
48	5	False	True	1	ます	でき	出来	
48	5	True	False	1	ない	でき	出来	
48	5	True	True	1	ません	でき	出来	
48	6	False	False	1	れる	さ		
48	6	False	True	1	れます	さ		
48	6	True	False	1	れない	さ		
48	6	True	True	1	れません	さ		
48	7	False	False	1	せる	さ		
48	7	False	False	2	す	さ		
48	7	False	True	1	せます	さ		
48	7	False	True	2	します	さ		
48	7	True	False	1	せない	さ		
48	7	True	False	2	さない	さ		
48	7	True	True	1	せません	さ		
48	7	True	True	2	しません	さ		
48	8	False	False	1	せられる	さ		
48	8	False	True	1	せられます	さ		
48	8	True	False	1	せられない	さ		
48	8	True	True	1	せられません	さ		
48	9	False	False	1	よう	し		
48	9	False	True	1	ましょう	し		
48	9	True	False	1	るまい	す		
48	9	True	True	1	ますまい	し		
48	10	False	False	1	ろ	し		
48	10	False	False	2	よ	せ		
48	10	False	True	1	なさい	し		
48	10	True	False	1	るな	す		
48	10	True	True	1	なさるな	し		
48	11	False	False	1	たら	し		
48	11	False	True	1	ましたら	し		
48	11	True	False	1	なかったら	し		
48	11	True	True	1	ませんでしたら	し		
48	12	False	False	1	たり	し		
48	12	False	True	1	ましたり	し		
48	12	True	False	1	なかったり	し		
48	12	True	True	1	ませんでしたり	し		
48	13	False	False	1	""	し		
\.

-- From pg/data/conotes.csv...
\copy conotes FROM stdin DELIMITER E'\t' CSV HEADER
id	note
1	"Irregular conjugation.  Note that this not the same as the definition of ""irregular verb""
 commonly found in textbooks (typically する and 来る).  It denotes okurigana that is different
 than other words of the same class.  Thus the past tense of 行く (行った) is an irregular
 conjugation because other く (v5k) verbs use いた as the okurigana for this conjugation. 
 します is not an irregular conjugation because we take する to behave as
 a v1 verb and the okurigana is the same as other v1 verbs despite the sound change of the
 stem (す) part of the verb to し."
2	The なければ nakereba form used for the negative form can be colloquially contracted to なきゃ nakya or なくちゃ nakucha. Thus 行かなければ ikanakereba can become 行かなきゃ ikanakya.
3	na-adjectives and nouns are usually used with the なら nara conditional, instead of with であれば de areba. なら is a contracted and more common form of ならば.
4	では is often contracted to じゃ in colloquial speech.
5	The (first) non-abbreviated form is obtained by applying sequentially the causative, then passive conjugations.
6	The -まい negative form is literary and rather rare. 
7	The ら is sometimes dropped from -られる, etc. in the potential form in conversational Japanese, but it is not regarded as grammatically correct. 
\.

-- From pg/data/conjo_notes.csv...
\copy conjo_notes FROM stdin DELIMITER E'\t' CSV HEADER
pos	conj	neg	fml	onum	note
2	1	True	False	1	4
2	1	True	True	1	4
2	1	True	True	2	4
2	2	True	False	1	4
2	2	True	True	1	4
2	3	True	False	1	4
2	4	False	False	1	3
2	11	True	False	1	4
2	11	True	True	1	4
17	1	True	False	1	4
17	1	True	True	1	4
17	1	True	True	2	4
17	2	True	False	1	4
17	2	True	True	1	4
17	3	True	False	1	4
17	4	False	False	1	3
17	11	True	False	1	4
17	11	True	True	1	4
28	4	True	False	1	2
28	5	False	False	2	7
28	5	False	True	2	7
28	5	True	False	2	7
28	5	True	True	2	7
28	9	True	False	1	6
28	9	True	True	1	6
30	1	False	True	1	1
30	1	True	True	1	1
30	2	False	True	1	1
30	2	True	True	1	1
30	3	False	True	1	1
30	3	True	True	1	1
30	4	False	True	1	1
30	4	False	True	2	1
30	4	True	False	1	2
30	4	True	True	1	1
30	4	True	True	2	1
30	9	False	True	1	1
30	9	True	False	1	6
30	9	True	True	1	6
30	10	False	False	1	1
30	10	False	True	1	1
30	10	True	True	1	1
30	11	False	True	1	1
30	11	True	True	1	1
30	12	False	True	1	1
30	13	False	False	1	1
31	4	True	False	1	2
31	9	True	False	1	6
31	9	True	True	1	6
32	4	True	False	1	2
32	9	True	False	1	6
32	9	True	True	1	6
33	4	True	False	1	2
33	9	True	False	1	6
33	9	True	True	1	6
34	2	False	False	1	1
34	3	False	False	1	1
34	4	True	False	1	2
34	9	True	False	1	6
34	9	True	True	1	6
34	11	False	False	1	1
34	12	False	False	1	1
35	4	True	False	1	2
35	9	True	False	1	6
35	9	True	True	1	6
36	4	True	False	1	2
36	9	True	False	1	6
36	9	True	True	1	6
37	4	True	False	1	2
37	9	True	False	1	6
37	9	True	True	1	6
38	1	True	False	1	1
38	2	True	False	1	1
38	3	True	False	1	1
38	3	True	False	2	1
38	4	True	False	1	2
38	9	True	False	1	6
38	9	True	True	1	6
38	11	True	False	1	1
38	12	True	False	1	1
39	4	True	False	1	2
39	9	True	False	1	6
39	9	True	True	1	6
40	4	True	False	1	2
40	9	True	False	1	6
40	9	True	True	1	6
41	4	True	False	1	2
41	9	True	False	1	6
41	9	True	True	1	6
42	2	False	False	1	1
42	3	False	False	1	1
42	4	True	False	1	2
42	9	True	False	1	6
42	9	True	True	1	6
42	11	False	False	1	1
42	12	False	False	1	1
45	4	True	False	1	2
45	5	False	False	2	7
45	5	False	True	2	7
45	5	True	False	2	7
45	5	True	True	2	7
45	9	True	False	1	6
45	9	True	True	1	6
45	10	False	False	1	1
46	4	True	False	1	2
46	5	False	False	1	1
46	5	False	True	1	1
46	5	True	False	1	1
46	5	True	True	1	1
46	6	False	False	1	1
46	6	False	True	1	1
46	6	True	False	1	1
46	6	True	True	1	1
46	7	False	False	1	1
46	7	False	False	2	1
46	7	False	True	1	1
46	7	False	True	2	1
46	7	True	False	1	1
46	7	True	False	2	1
46	7	True	True	1	1
46	7	True	True	2	1
46	8	False	False	1	1
46	8	False	True	1	1
46	8	True	False	1	1
46	8	True	True	1	1
46	9	True	False	1	6
46	9	True	True	1	6
46	10	False	False	2	1
47	4	True	False	1	2
47	5	False	False	1	1
47	5	False	True	1	1
47	5	True	False	1	1
47	5	True	True	1	1
47	6	False	False	1	1
47	6	False	True	1	1
47	6	True	False	1	1
47	6	True	True	1	1
47	7	False	False	1	1
47	7	False	False	2	1
47	7	False	True	1	1
47	7	False	True	2	1
47	7	True	False	1	1
47	7	True	False	2	1
47	7	True	True	1	1
47	7	True	True	2	1
47	8	False	False	1	1
47	8	False	True	1	1
47	8	True	False	1	1
47	8	True	True	1	1
47	9	True	False	1	6
47	9	True	True	1	6
47	10	False	False	2	1
48	4	True	False	1	2
48	5	False	False	1	1
48	5	False	True	1	1
48	5	True	False	1	1
48	5	True	True	1	1
48	6	False	False	1	1
48	6	False	True	1	1
48	6	True	False	1	1
48	6	True	True	1	1
48	7	False	False	1	1
48	7	False	False	2	1
48	7	False	True	1	1
48	7	False	True	2	1
48	7	True	False	1	1
48	7	True	False	2	1
48	7	True	True	1	1
48	7	True	True	2	1
48	8	False	False	1	1
48	8	False	True	1	1
48	8	True	False	1	1
48	8	True	True	1	1
48	9	True	False	1	6
48	9	True	True	1	6
48	10	False	False	2	1
\.

COMMIT;
