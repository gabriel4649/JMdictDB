-- Descr: Revamp conjugation implementation. 
-- Trans: 19->20

\set ON_ERROR_STOP
BEGIN;

INSERT INTO dbpatch(level) VALUES(20);

DROP TABLE IF EXISTS copos_notes, copos CASCADE;  -- dbpl 19 tables no longer used.

-------------------------------------------------------------------------------------------
--  The following DDL is a verbatim copy of pg/conj.sql (sans some comments).
--  The changes we are making are substantial enough that it is easier to drop,
--  recreate and reload all the conjugation objects, than to try to update them
--  in place.
-------------------------------------------------------------------------------------------

\qecho NOTE: "view does not exist" messages may occur here and are not a problem. 
DROP VIEW IF EXISTS vconotes, vinflxt, vinflxt_, vinfl, vconj, vcpos CASCADE;
DROP TABLE IF EXISTS conjo_notes, conj_notes, conotes, conjo, conj CASCADE;

-- Notes for conj, conjo items.
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
      PRIMARY KEY (pos,conj,neg,fml,onum),
    stem SMALLINT DEFAULT 1,              -- Number of chars to remove to get stem. 
    okuri VARCHAR(50) NOT NULL,           -- Okurigana text.
    euphr VARCHAR(50) DEFAULT NULL,       -- Kana for euphonic change in stem (する and 来る).
    euphk VARCHAR(50) DEFAULT NULL,       -- Kanji for change in stem (used only for 為る-＞出来る).
    pos2 SMALLINT DEFAULT NULL            -- Part-of-speech (kwpos id) of word after conjugation.
      REFERENCES kwpos(id) ON UPDATE CASCADE);
ALTER TABLE conjo OWNER TO jmdictdb;

-- Notes that apply to a particular conjugation.
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
        CASE WHEN ktxt ~ '[^あ-ん].$'  -- True if final verb is kanji, false if it is hiragana
                                      --  (see IS-226, 2014-08-26).
            THEN COALESCE((LEFT(ktxt,LENGTH(ktxt)-stem-1)||euphk), LEFT(ktxt,LENGTH(ktxt)-stem))
            ELSE COALESCE((LEFT(ktxt,LENGTH(ktxt)-stem-1)||euphr), LEFT(ktxt,LENGTH(ktxt)-stem)) END
            || okuri AS kitxt,
        COALESCE((LEFT(rtxt,LENGTH(rtxt)-stem-1)||euphr), LEFT(rtxt,LENGTH(rtxt)-stem)) || okuri AS ritxt,
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
	LEFT JOIN kanj ON entr.id=kanj.entr
	LEFT JOIN rdng ON entr.id=rdng.entr
	WHERE conjo.okuri IS NOT NULL
	AND NOT EXISTS (SELECT 1 FROM stagr WHERE stagr.entr=entr.id AND stagr.sens=sens.sens AND stagr.rdng=rdng.rdng)
	AND NOT EXISTS (SELECT 1 FROM stagk WHERE stagk.entr=entr.id AND stagk.sens=sens.sens AND stagk.kanj=kanj.kanj)
	AND NOT EXISTS (SELECT 1 FROM restr WHERE restr.entr=entr.id AND restr.rdng=rdng.rdng AND restr.kanj=kanj.kanj)
        ) AS u)
    ORDER BY u.id,pos,knum,rnum,conj,neg,fml,onum;

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

CREATE OR REPLACE VIEW vinflxt AS (
    SELECT id, seq, src, unap, pos, ptxt, knum, ktxt, rnum, rtxt, conj, ctxt,
	MIN (CASE t WHEN 'aff-plain'  THEN word END) AS w0,
	MIN (CASE t WHEN 'aff-polite' THEN word END) AS w1,
	MIN (CASE t WHEN 'neg-plain'  THEN word END) AS w2,
	MIN (CASE t WHEN 'neg-polite' THEN word END) AS w3
        FROM vinflxt_
        GROUP BY id, seq, src, unap, pos, ptxt, knum, ktxt, rnum, rtxt, conj, ctxt
	ORDER BY id, pos, knum, rnum, conj);

CREATE OR REPLACE VIEW vconotes AS (
    SELECT DISTINCT k.id AS pos, k.kw AS ptxt, m.*
        FROM kwpos k
        JOIN conjo c ON c.pos=k.id
        JOIN conjo_notes n ON n.pos=c.pos
        JOIN conotes m ON m.id=n.note
        ORDER BY m.id);

-- See IS-226 (2014-06-12).  This view is used to present a pseudo-keyword
--  table that is loaded into the jdb.Kwds instance and provides a list
--  of conjugatable pos's in the same format as the kwpos table.
CREATE OR REPLACE VIEW vcopos AS (
    SELECT id,kw,descr FROM kwpos p JOIN (SELECT DISTINCT pos FROM conjo) AS c ON c.pos=p.id);
GRANT SELECT ON vcopos TO jmdictdbv;

-------------------------------------------------------------------------------------------
--  The following DML are a verbatim copies of conjugation data in pg/data/*.csv
--  at the time this patch file was generated.
-------------------------------------------------------------------------------------------

\copy conj FROM STDIN DELIMITER E'\t' CSV HEADER
id	name
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

\copy conjo FROM STDIN DELIMITER E'\t' CSV HEADER
pos	conj	neg	fml	onum	stem	okuri	euphr	euphk	pos2
1	1	f	f	1	1	い			
1	1	f	t	1	1	いです			
1	1	t	f	1	1	くない			
1	1	t	t	1	1	くないです			
1	1	t	t	2	1	くありません			
1	2	f	f	1	1	かった			
1	2	f	t	1	1	かったです			
1	2	t	f	1	1	くなかった			
1	2	t	t	1	1	くなかったです			
1	2	t	t	2	1	くありませんでした			
1	3	f	f	1	1	くて			
1	3	t	f	1	1	くなくて			
1	4	f	f	1	1	ければ			
1	4	t	f	1	1	くなければ			
1	7	f	f	1	1	くさせる			
1	9	f	f	1	1	かろう			
1	9	f	t	1	1	いでしょう			
1	11	f	f	1	1	かったら			
1	11	t	f	1	1	くなかったら			
1	12	f	f	1	1	かったり			
2	1	f	f	1	0	だ			
7	1	f	f	1	1	い			
7	1	f	t	1	1	いです			
7	1	t	f	1	1	くない	よ		
7	1	t	t	1	1	くないです	よ		
7	1	t	t	2	1	くありません	よ		
7	2	f	f	1	1	かった	よ		
7	2	f	t	1	1	かったです	よ		
7	2	t	f	1	1	くなかった	よ		
7	2	t	t	1	1	くなかったです	よ		
7	2	t	t	2	1	くありませんでした	よ		
7	3	f	f	1	1	くて	よ		
7	3	t	f	1	1	くなくて	よ		
7	4	f	f	1	1	ければ	よ		
7	4	t	f	1	1	くなければ	よ		
7	7	f	f	1	1	くさせる	よ		
7	9	f	f	1	1	かろう	よ		
7	9	f	t	1	1	いでしょう			
7	11	f	f	1	1	かったら	よ		
7	11	t	f	1	1	くなかったら	よ		
7	12	f	f	1	1	かったり	よ		
15	1	f	f	1	1	だ			
15	1	f	t	1	1	です			
15	1	t	f	1	1	ではない			
15	1	t	t	1	1	ではありません			
15	1	t	t	2	1	ではないです			
15	2	f	f	1	1	だった			
15	2	f	t	1	1	でした			
15	2	t	f	1	1	ではなかった			
15	2	t	t	1	1	ではありませんでした			
15	3	f	f	1	1	で			
15	3	f	t	1	1	でありまして			
15	3	t	f	1	1	ではなくて			
15	4	f	f	1	1	なら			
15	4	f	f	2	1	ならば			
15	4	f	f	3	1	であれば			
15	9	f	f	1	1	だろう			
15	9	f	t	1	1	でしょう			
15	10	f	f	1	1	であれ			
15	11	f	f	1	1	だったら			
15	11	f	t	1	1	でしたら			
15	11	t	f	1	1	ではなかったら			
15	11	t	t	1	1	ではありませんでしたら			
15	12	f	f	1	1	だったり			
17	1	f	f	1	0	だ			
28	1	f	f	1	1	る			
28	1	f	t	1	1	ます			
28	1	t	f	1	1	ない			
28	1	t	t	1	1	ました			
28	2	f	f	1	1	た			
28	2	f	t	1	1	ました			
28	2	t	f	1	1	なかった			
28	2	t	t	1	1	ませんでした			
28	3	f	f	1	1	て			
28	3	f	t	1	1	まして			
28	3	t	f	1	1	なくて			
28	3	t	f	2	1	ないで			
28	3	t	t	1	1	ませんで			
28	4	f	f	1	1	れば			
28	4	f	t	1	1	ますなら			
28	4	f	t	2	1	ますならば			
28	4	t	f	1	1	なければ			
28	4	t	t	1	1	ませんなら			
28	4	t	t	2	1	ませんならば			
28	5	f	f	1	1	られる			
28	5	f	f	2	1	れる			
28	5	f	t	1	1	られます			
28	5	f	t	2	1	れます			
28	5	t	f	1	1	られない			
28	5	t	f	2	1	れない			
28	5	t	t	1	1	られません			
28	5	t	t	2	1	れません			
28	6	f	f	1	1	られる			
28	6	f	t	1	1	られます			
28	6	t	f	1	1	られない			
28	6	t	t	1	1	られません			
28	7	f	f	1	1	させる			
28	7	f	f	2	1	さす			
28	7	f	t	1	1	させます			
28	7	f	t	2	1	さします			
28	7	t	f	1	1	させない			
28	7	t	f	2	1	ささない			
28	7	t	t	1	1	させません			
28	7	t	t	2	1	さしません			
28	8	f	f	1	1	させられる			
28	8	f	t	1	1	させられます			
28	8	t	f	1	1	させられない			
28	8	t	t	1	1	させられません			
28	9	f	f	1	1	よう			
28	9	f	t	1	1	ましょう			
28	9	t	f	1	1	まい			
28	9	t	t	1	1	ますまい			
28	10	f	f	1	1	ろ			
28	10	f	t	1	1	なさい			
28	10	t	f	1	1	るな			
28	10	t	t	1	1	なさるな			
28	11	f	f	1	1	たら			
28	11	f	t	1	1	ましたら			
28	11	t	f	1	1	なかったら			
28	11	t	t	1	1	ませんでしたら			
28	12	f	f	1	1	たり			
28	12	f	t	1	1	ましたり			
28	12	t	f	1	1	なかったり			
28	12	t	t	1	1	ませんでしたり			
28	13	f	f	1	1	""			
29	1	f	f	1	1	る			
29	1	f	t	1	1	ます			
29	1	t	f	1	1	ない			
29	1	t	t	1	1	ました			
29	2	f	f	1	1	た			
29	2	f	t	1	1	ました			
29	2	t	f	1	1	なかった			
29	2	t	t	1	1	ませんでした			
29	3	f	f	1	1	て			
29	3	f	t	1	1	まして			
29	3	t	f	1	1	なくて			
29	3	t	f	2	1	ないで			
29	3	t	t	1	1	ませんで			
29	4	f	f	1	1	れば			
29	4	f	t	1	1	ますなら			
29	4	f	t	2	1	ますならば			
29	4	t	f	1	1	なければ			
29	4	t	t	1	1	ませんなら			
29	4	t	t	2	1	ませんならば			
29	5	f	f	1	1	られる			
29	5	f	f	2	1	れる			
29	5	f	t	1	1	られます			
29	5	f	t	2	1	れます			
29	5	t	f	1	1	られない			
29	5	t	f	2	1	れない			
29	5	t	t	1	1	られません			
29	5	t	t	2	1	れません			
29	6	f	f	1	1	られる			
29	6	f	t	1	1	られます			
29	6	t	f	1	1	られない			
29	6	t	t	1	1	られません			
29	7	f	f	1	1	させる			
29	7	f	f	2	1	さす			
29	7	f	t	1	1	させます			
29	7	f	t	2	1	さします			
29	7	t	f	1	1	させない			
29	7	t	f	2	1	ささない			
29	7	t	t	1	1	させません			
29	7	t	t	2	1	さしません			
29	8	f	f	1	1	させられる			
29	8	f	t	1	1	させられます			
29	8	t	f	1	1	させられない			
29	8	t	t	1	1	させられません			
29	9	f	f	1	1	よう			
29	9	f	t	1	1	ましょう			
29	9	t	f	1	1	まい			
29	9	t	t	1	1	ますまい			
29	10	f	f	1	1	""			
29	10	f	t	1	1	なさい			
29	10	t	f	1	1	るな			
29	10	t	t	1	1	なさるな			
29	11	f	f	1	1	たら			
29	11	f	t	1	1	ましたら			
29	11	t	f	1	1	なかったら			
29	11	t	t	1	1	ませんでしたら			
29	12	f	f	1	1	たり			
29	12	f	t	1	1	ましたり			
29	12	t	f	1	1	なかったり			
29	12	t	t	1	1	ませんでしたり			
29	13	f	f	1	1	""			
30	1	f	f	1	1	る			
30	1	f	t	1	1	います			
30	1	t	f	1	1	らない			
30	1	t	t	1	1	いません			
30	2	f	f	1	1	った			
30	2	f	t	1	1	いました			
30	2	t	f	1	1	らなかった			
30	2	t	t	1	1	いませんでした			
30	3	f	f	1	1	って			
30	3	f	t	1	1	いまして			
30	3	t	f	1	1	らなくて			
30	3	t	f	2	1	らないで			
30	3	t	t	1	1	いませんで			
30	4	f	f	1	1	れば			
30	4	f	t	1	1	いますなら			
30	4	f	t	2	1	いますならば			
30	4	t	f	1	1	らなければ			
30	4	t	t	1	1	いませんなら			
30	4	t	t	2	1	いませんならば			
30	5	f	f	1	1	れる			
30	5	f	t	1	1	れます			
30	5	t	f	1	1	れない			
30	5	t	t	1	1	れません			
30	6	f	f	1	1	られる			
30	6	f	t	1	1	られます			
30	6	t	f	1	1	られない			
30	6	t	t	1	1	られません			
30	7	f	f	1	1	らせる			
30	7	f	f	2	1	らす			
30	7	f	t	1	1	らせます			
30	7	f	t	2	1	らします			
30	7	t	f	1	1	らせない			
30	7	t	f	2	1	らさない			
30	7	t	t	1	1	らせません			
30	7	t	t	2	1	らしません			
30	8	f	f	1	1	らせられる			
30	8	f	f	2	1	らされる			
30	8	f	t	1	1	らせられます			
30	8	f	t	2	1	らされます			
30	8	t	f	1	1	らせられない			
30	8	t	f	2	1	らされない			
30	8	t	t	1	1	らせられません			
30	8	t	t	2	1	らされません			
30	9	f	f	1	1	ろう			
30	9	f	t	1	1	いましょう			
30	9	t	f	1	1	るまい			
30	9	t	t	1	1	いませんまい			
30	10	f	f	1	1	い			
30	10	f	t	1	1	いなさい			
30	10	t	f	1	1	るな			
30	10	t	t	1	1	いなさるな			
30	11	f	f	1	1	ったら			
30	11	f	t	1	1	いましたら			
30	11	t	f	1	1	らなかったら			
30	11	t	t	1	1	いませんでしたら			
30	12	f	f	1	1	ったり			
30	12	f	t	1	1	いましたり			
30	12	t	f	1	1	らなかったり			
30	12	t	t	1	1	いませんでしたり			
30	13	f	f	1	1	い			
31	1	f	f	1	1	ぶ			
31	1	f	t	1	1	びます			
31	1	t	f	1	1	ばない			
31	1	t	t	1	1	びません			
31	2	f	f	1	1	んだ			
31	2	f	t	1	1	びました			
31	2	t	f	1	1	ばなかった			
31	2	t	t	1	1	びませんでした			
31	3	f	f	1	1	んで			
31	3	f	t	1	1	びまして			
31	3	t	f	1	1	ばなくて			
31	3	t	f	2	1	ばないで			
31	3	t	t	1	1	びませんで			
31	4	f	f	1	1	べば			
31	4	f	t	1	1	びますなら			
31	4	f	t	2	1	びますならば			
31	4	t	f	1	1	ばなければ			
31	4	t	t	1	1	びませんなら			
31	4	t	t	2	1	びませんならば			
31	5	f	f	1	1	べる			
31	5	f	t	1	1	べます			
31	5	t	f	1	1	べない			
31	5	t	t	1	1	べません			
31	6	f	f	1	1	ばれる			
31	6	f	t	1	1	ばれます			
31	6	t	f	1	1	ばれない			
31	6	t	t	1	1	ばれません			
31	7	f	f	1	1	ばせる			
31	7	f	f	2	1	ばす			
31	7	f	t	1	1	ばせます			
31	7	f	t	2	1	ばします			
31	7	t	f	1	1	ばせない			
31	7	t	f	2	1	ばさない			
31	7	t	t	1	1	ばせません			
31	7	t	t	2	1	ばしません			
31	8	f	f	1	1	ばせられる			
31	8	f	f	2	1	ばされる			
31	8	f	t	1	1	ばせられます			
31	8	f	t	2	1	ばされます			
31	8	t	f	1	1	ばせられない			
31	8	t	f	2	1	ばされない			
31	8	t	t	1	1	ばせられません			
31	8	t	t	2	1	ばされません			
31	9	f	f	1	1	ぼう			
31	9	f	t	1	1	びましょう			
31	9	t	f	1	1	ぶまい			
31	9	t	t	1	1	びませんまい			
31	10	f	f	1	1	べ			
31	10	f	t	1	1	びなさい			
31	10	t	f	1	1	ぶな			
31	10	t	t	1	1	びなさるな			
31	11	f	f	1	1	んだら			
31	11	f	t	1	1	びましたら			
31	11	t	f	1	1	ばなかったら			
31	11	t	t	1	1	びませんでしたら			
31	12	f	f	1	1	んだり			
31	12	f	t	1	1	びましたり			
31	12	t	f	1	1	ばなかったり			
31	12	t	t	1	1	びませんでしたり			
31	13	f	f	1	1	び			
32	1	f	f	1	1	ぐ			
32	1	f	t	1	1	ぎます			
32	1	t	f	1	1	がない			
32	1	t	t	1	1	ぎません			
32	2	f	f	1	1	いだ			
32	2	f	t	1	1	ぎました			
32	2	t	f	1	1	がなかった			
32	2	t	t	1	1	ぎませんでした			
32	3	f	f	1	1	いで			
32	3	f	t	1	1	ぎまして			
32	3	t	f	1	1	がなくて			
32	3	t	f	2	1	がないで			
32	3	t	t	1	1	ぎませんで			
32	4	f	f	1	1	げば			
32	4	f	t	1	1	ぎますなら			
32	4	f	t	2	1	ぎますならば			
32	4	t	f	1	1	がなければ			
32	4	t	t	1	1	ぎませんなら			
32	4	t	t	2	1	ぎませんならば			
32	5	f	f	1	1	げる			
32	5	f	t	1	1	げます			
32	5	t	f	1	1	げない			
32	5	t	t	1	1	げません			
32	6	f	f	1	1	がれる			
32	6	f	t	1	1	がれます			
32	6	t	f	1	1	がれない			
32	6	t	t	1	1	がれません			
32	7	f	f	1	1	がせる			
32	7	f	f	2	1	がす			
32	7	f	t	1	1	がせます			
32	7	f	t	2	1	がします			
32	7	t	f	1	1	がせない			
32	7	t	f	2	1	がさない			
32	7	t	t	1	1	がせません			
32	7	t	t	2	1	がしません			
32	8	f	f	1	1	がせられる			
32	8	f	f	2	1	がされる			
32	8	f	t	1	1	がせられます			
32	8	f	t	2	1	がされます			
32	8	t	f	1	1	がせられない			
32	8	t	f	2	1	がされない			
32	8	t	t	1	1	がせられません			
32	8	t	t	2	1	がされません			
32	9	f	f	1	1	ごう			
32	9	f	t	1	1	ぎましょう			
32	9	t	f	1	1	ぐまい			
32	9	t	t	1	1	ぎませんまい			
32	10	f	f	1	1	げ			
32	10	f	t	1	1	ぎなさい			
32	10	t	f	1	1	ぐな			
32	10	t	t	1	1	ぎなさるな			
32	11	f	f	1	1	いだら			
32	11	f	t	1	1	ぎましたら			
32	11	t	f	1	1	がなかったら			
32	11	t	t	1	1	ぎませんでしたら			
32	12	f	f	1	1	いだり			
32	12	f	t	1	1	ぎましたり			
32	12	t	f	1	1	がなかったり			
32	12	t	t	1	1	ぎませんでしたり			
32	13	f	f	1	1	ぎ			
33	1	f	f	1	1	く			
33	1	f	t	1	1	きます			
33	1	t	f	1	1	かない			
33	1	t	t	1	1	きません			
33	2	f	f	1	1	いた			
33	2	f	t	1	1	きました			
33	2	t	f	1	1	かなかった			
33	2	t	t	1	1	きませんでした			
33	3	f	f	1	1	いて			
33	3	f	t	1	1	きまして			
33	3	t	f	1	1	かなくて			
33	3	t	f	2	1	かないで			
33	3	t	t	1	1	きませんで			
33	4	f	f	1	1	けば			
33	4	f	t	1	1	きますなら			
33	4	f	t	2	1	きますならば			
33	4	t	f	1	1	かなければ			
33	4	t	t	1	1	きませんなら			
33	4	t	t	2	1	きませんならば			
33	5	f	f	1	1	ける			
33	5	f	t	1	1	けます			
33	5	t	f	1	1	けない			
33	5	t	t	1	1	けません			
33	6	f	f	1	1	かれる			
33	6	f	t	1	1	かれます			
33	6	t	f	1	1	かれない			
33	6	t	t	1	1	かれません			
33	7	f	f	1	1	かせる			
33	7	f	f	2	1	かす			
33	7	f	t	1	1	かせます			
33	7	f	t	2	1	かします			
33	7	t	f	1	1	かせない			
33	7	t	f	2	1	かさない			
33	7	t	t	1	1	かせません			
33	7	t	t	2	1	かしません			
33	8	f	f	1	1	かせられる			
33	8	f	f	2	1	かされる			
33	8	f	t	1	1	かせられます			
33	8	f	t	2	1	かされます			
33	8	t	f	1	1	かせられない			
33	8	t	f	2	1	かされない			
33	8	t	t	1	1	かせられません			
33	8	t	t	2	1	かされません			
33	9	f	f	1	1	こう			
33	9	f	t	1	1	きましょう			
33	9	t	f	1	1	くまい			
33	9	t	t	1	1	きませんまい			
33	10	f	f	1	1	け			
33	10	f	t	1	1	きなさい			
33	10	t	f	1	1	くな			
33	10	t	t	1	1	きなさるな			
33	11	f	f	1	1	いたら			
33	11	f	t	1	1	きましたら			
33	11	t	f	1	1	かなかったら			
33	11	t	t	1	1	きませんでしたら			
33	12	f	f	1	1	いたり			
33	12	f	t	1	1	きましたり			
33	12	t	f	1	1	かなかったり			
33	12	t	t	1	1	きませんでしたり			
33	13	f	f	1	1	き			
34	1	f	f	1	1	く			
34	1	f	t	1	1	きます			
34	1	t	f	1	1	かない			
34	1	t	t	1	1	きません			
34	2	f	f	1	1	った			
34	2	f	t	1	1	きました			
34	2	t	f	1	1	かなかった			
34	2	t	t	1	1	きませんでした			
34	3	f	f	1	1	って			
34	3	f	t	1	1	きまして			
34	3	t	f	1	1	かなくて			
34	3	t	f	2	1	かないで			
34	3	t	t	1	1	きませんで			
34	4	f	f	1	1	けば			
34	4	f	t	1	1	きますなら			
34	4	f	t	2	1	きますならば			
34	4	t	f	1	1	かなければ			
34	4	t	t	1	1	きませんなら			
34	4	t	t	2	1	きませんならば			
34	5	f	f	1	1	ける			
34	5	f	t	1	1	けます			
34	5	t	f	1	1	けない			
34	5	t	t	1	1	けません			
34	6	f	f	1	1	かれる			
34	6	f	t	1	1	かれます			
34	6	t	f	1	1	かれない			
34	6	t	t	1	1	かれません			
34	7	f	f	1	1	かせる			
34	7	f	f	2	1	かす			
34	7	f	t	1	1	かせます			
34	7	f	t	2	1	かします			
34	7	t	f	1	1	かせない			
34	7	t	f	2	1	かさない			
34	7	t	t	1	1	かせません			
34	7	t	t	2	1	かしません			
34	8	f	f	1	1	かせられる			
34	8	f	f	2	1	かされる			
34	8	f	t	1	1	かせられます			
34	8	f	t	2	1	かされます			
34	8	t	f	1	1	かせられない			
34	8	t	f	2	1	かされない			
34	8	t	t	1	1	かせられません			
34	8	t	t	2	1	かされません			
34	9	f	f	1	1	こう			
34	9	f	t	1	1	きましょう			
34	9	t	f	1	1	くまい			
34	9	t	t	1	1	きませんまい			
34	10	f	f	1	1	け			
34	10	f	t	1	1	きなさい			
34	10	t	f	1	1	くな			
34	10	t	t	1	1	きなさるな			
34	11	f	f	1	1	ったら			
34	11	f	t	1	1	きましたら			
34	11	t	f	1	1	かなかったら			
34	11	t	t	1	1	きませんでしたら			
34	12	f	f	1	1	ったり			
34	12	f	t	1	1	きましたり			
34	12	t	f	1	1	かなかったり			
34	12	t	t	1	1	きませんでしたり			
34	13	f	f	1	1	き			
35	1	f	f	1	1	む			
35	1	f	t	1	1	みます			
35	1	t	f	1	1	まない			
35	1	t	t	1	1	みません			
35	2	f	f	1	1	んだ			
35	2	f	t	1	1	みました			
35	2	t	f	1	1	まなかった			
35	2	t	t	1	1	みませんでした			
35	3	f	f	1	1	んで			
35	3	f	t	1	1	みまして			
35	3	t	f	1	1	まなくて			
35	3	t	f	2	1	まないで			
35	3	t	t	1	1	みませんで			
35	4	f	f	1	1	めば			
35	4	f	t	1	1	みますなら			
35	4	f	t	2	1	みますならば			
35	4	t	f	1	1	まなければ			
35	4	t	t	1	1	みませんなら			
35	4	t	t	2	1	みませんならば			
35	5	f	f	1	1	める			
35	5	f	t	1	1	めます			
35	5	t	f	1	1	めない			
35	5	t	t	1	1	めません			
35	6	f	f	1	1	まれる			
35	6	f	t	1	1	まれます			
35	6	t	f	1	1	まれない			
35	6	t	t	1	1	まれません			
35	7	f	f	1	1	ませる			
35	7	f	f	2	1	ます			
35	7	f	t	1	1	ませます			
35	7	f	t	2	1	まします			
35	7	t	f	1	1	ませない			
35	7	t	f	2	1	まさない			
35	7	t	t	1	1	ませません			
35	7	t	t	2	1	ましません			
35	8	f	f	1	1	ませられる			
35	8	f	f	2	1	まされる			
35	8	f	t	1	1	ませられます			
35	8	f	t	2	1	まされます			
35	8	t	f	1	1	ませられない			
35	8	t	f	2	1	まされない			
35	8	t	t	1	1	ませられません			
35	8	t	t	2	1	まされません			
35	9	f	f	1	1	もう			
35	9	f	t	1	1	みましょう			
35	9	t	f	1	1	むまい			
35	9	t	t	1	1	みませんまい			
35	10	f	f	1	1	め			
35	10	f	t	1	1	みなさい			
35	10	t	f	1	1	むな			
35	10	t	t	1	1	みなさるな			
35	11	f	f	1	1	んだら			
35	11	f	t	1	1	みましたら			
35	11	t	f	1	1	まなかったら			
35	11	t	t	1	1	みませんでしたら			
35	12	f	f	1	1	んだり			
35	12	f	t	1	1	みましたり			
35	12	t	f	1	1	まなかったり			
35	12	t	t	1	1	みませんでしたり			
35	13	f	f	1	1	み			
36	1	f	f	1	1	ぬ			
36	1	f	t	1	1	にます			
36	1	t	f	1	1	なない			
36	1	t	t	1	1	にません			
36	2	f	f	1	1	んだ			
36	2	f	t	1	1	にました			
36	2	t	f	1	1	ななかった			
36	2	t	t	1	1	にませんでした			
36	3	f	f	1	1	んで			
36	3	f	t	1	1	にまして			
36	3	t	f	1	1	ななくて			
36	3	t	f	2	1	なないで			
36	3	t	t	1	1	にませんで			
36	4	f	f	1	1	ねば			
36	4	f	t	1	1	にますなら			
36	4	f	t	2	1	にますならば			
36	4	t	f	1	1	ななければ			
36	4	t	t	1	1	にませんなら			
36	4	t	t	2	1	にませんならば			
36	5	f	f	1	1	ねる			
36	5	f	t	1	1	ねます			
36	5	t	f	1	1	ねない			
36	5	t	t	1	1	ねません			
36	6	f	f	1	1	なれる			
36	6	f	t	1	1	なれます			
36	6	t	f	1	1	なれない			
36	6	t	t	1	1	なれません			
36	7	f	f	1	1	なせる			
36	7	f	f	2	1	なす			
36	7	f	t	1	1	なせます			
36	7	f	t	2	1	なします			
36	7	t	f	1	1	なせない			
36	7	t	f	2	1	なさない			
36	7	t	t	1	1	なせません			
36	7	t	t	2	1	なしません			
36	8	f	f	1	1	なせられる			
36	8	f	f	2	1	なされる			
36	8	f	t	1	1	なせられます			
36	8	f	t	2	1	なされます			
36	8	t	f	1	1	なせられない			
36	8	t	f	2	1	なされない			
36	8	t	t	1	1	なせられません			
36	8	t	t	2	1	なされません			
36	9	f	f	1	1	のう			
36	9	f	t	1	1	にましょう			
36	9	t	f	1	1	ぬまい			
36	9	t	t	1	1	にませんまい			
36	10	f	f	1	1	ね			
36	10	f	t	1	1	になさい			
36	10	t	f	1	1	ぬな			
36	10	t	t	1	1	になさるな			
36	11	f	f	1	1	んだら			
36	11	f	t	1	1	にましたら			
36	11	t	f	1	1	ななかったら			
36	11	t	t	1	1	にませんでしたら			
36	12	f	f	1	1	んだり			
36	12	f	t	1	1	にましたり			
36	12	t	f	1	1	ななかったり			
36	12	t	t	1	1	にませんでしたり			
36	13	f	f	1	1	に			
37	1	f	f	1	1	る			
37	1	f	t	1	1	ります			
37	1	t	f	1	1	らない			
37	1	t	t	1	1	りません			
37	2	f	f	1	1	った			
37	2	f	t	1	1	りました			
37	2	t	f	1	1	らなかった			
37	2	t	t	1	1	りませんでした			
37	3	f	f	1	1	って			
37	3	f	t	1	1	りまして			
37	3	t	f	1	1	らなくて			
37	3	t	f	2	1	らないで			
37	3	t	t	1	1	りませんで			
37	4	f	f	1	1	れば			
37	4	f	t	1	1	りますなら			
37	4	f	t	2	1	りますならば			
37	4	t	f	1	1	らなければ			
37	4	t	t	1	1	りませんなら			
37	4	t	t	2	1	りませんならば			
37	5	f	f	1	1	れる			
37	5	f	t	1	1	れます			
37	5	t	f	1	1	れない			
37	5	t	t	1	1	れません			
37	6	f	f	1	1	られる			
37	6	f	t	1	1	られます			
37	6	t	f	1	1	られない			
37	6	t	t	1	1	られません			
37	7	f	f	1	1	らせる			
37	7	f	f	2	1	らす			
37	7	f	t	1	1	らせます			
37	7	f	t	2	1	らします			
37	7	t	f	1	1	らせない			
37	7	t	f	2	1	らさない			
37	7	t	t	1	1	らせません			
37	7	t	t	2	1	らしません			
37	8	f	f	1	1	らせられる			
37	8	f	f	2	1	らされる			
37	8	f	t	1	1	らせられます			
37	8	f	t	2	1	らされます			
37	8	t	f	1	1	らせられない			
37	8	t	f	2	1	らされない			
37	8	t	t	1	1	らせられません			
37	8	t	t	2	1	らされません			
37	9	f	f	1	1	ろう			
37	9	f	t	1	1	りましょう			
37	9	t	f	1	1	るまい			
37	9	t	t	1	1	りませんまい			
37	10	f	f	1	1	れ			
37	10	f	t	1	1	りなさい			
37	10	t	f	1	1	るな			
37	10	t	t	1	1	りなさるな			
37	11	f	f	1	1	ったら			
37	11	f	t	1	1	りましたら			
37	11	t	f	1	1	らなかったら			
37	11	t	t	1	1	りませんでしたら			
37	12	f	f	1	1	ったり			
37	12	f	t	1	1	りましたり			
37	12	t	f	1	1	らなかったり			
37	12	t	t	1	1	りませんでしたり			
37	13	f	f	1	1	り			
38	1	f	f	1	1	る			
38	1	f	t	1	1	ります			
38	1	t	f	1	2	ない			
38	1	t	t	1	1	りません			
38	2	f	f	1	1	った			
38	2	f	t	1	1	りました			
38	2	t	f	1	2	なかった			
38	2	t	t	1	1	りませんでした			
38	3	f	f	1	1	って			
38	3	f	t	1	1	りまして			
38	3	t	f	1	2	なくて			
38	3	t	f	2	2	ないで			
38	3	t	t	1	1	りませんで			
38	4	f	f	1	1	れば			
38	4	f	t	1	1	りますなら			
38	4	f	t	2	1	りますならば			
38	4	t	f	1	2	なければ			
38	4	t	t	1	1	りませんなら			
38	4	t	t	2	1	りませんならば			
38	5	f	f	1	1	れる			
38	5	f	t	1	1	れます			
38	5	t	f	1	1	れない			
38	5	t	t	1	1	れません			
38	6	f	f	1	1	られる			
38	6	f	t	1	1	られます			
38	6	t	f	1	1	られない			
38	6	t	t	1	1	られません			
38	7	f	f	1	1	らせる			
38	7	f	f	2	1	らす			
38	7	f	t	1	1	らせます			
38	7	f	t	2	1	らします			
38	7	t	f	1	1	らせない			
38	7	t	f	2	1	らさない			
38	7	t	t	1	1	らせません			
38	7	t	t	2	1	らしません			
38	8	f	f	1	1	らせられる			
38	8	f	f	2	1	らされる			
38	8	f	t	1	1	らせられます			
38	8	f	t	2	1	らされます			
38	8	t	f	1	1	らせられない			
38	8	t	f	2	1	らされない			
38	8	t	t	1	1	らせられません			
38	8	t	t	2	1	らされません			
38	9	f	f	1	1	ろう			
38	9	f	t	1	1	りましょう			
38	9	t	f	1	1	るまい			
38	9	t	t	1	1	りませんまい			
38	10	f	f	1	1	れ			
38	10	f	t	1	1	りなさい			
38	10	t	f	1	1	るな			
38	10	t	t	1	1	りなさるな			
38	11	f	f	1	1	ったら			
38	11	f	t	1	1	りましたら			
38	11	t	f	1	2	なかったら			
38	11	t	t	1	1	りませんでしたら			
38	12	f	f	1	1	ったり			
38	12	f	t	1	1	りましたり			
38	12	t	f	1	2	なかったり			
38	12	t	t	1	1	りませんでしたり			
38	13	f	f	1	1	り			
39	1	f	f	1	1	す			
39	1	f	t	1	1	します			
39	1	t	f	1	1	さない			
39	1	t	t	1	1	しません			
39	2	f	f	1	1	した			
39	2	f	t	1	1	しました			
39	2	t	f	1	1	さなかった			
39	2	t	t	1	1	しませんでした			
39	3	f	f	1	1	して			
39	3	f	t	1	1	しまして			
39	3	t	f	1	1	さなくて			
39	3	t	f	2	1	さないで			
39	3	t	t	1	1	しませんで			
39	4	f	f	1	1	せば			
39	4	f	t	1	1	しますなら			
39	4	f	t	2	1	しますならば			
39	4	t	f	1	1	さなければ			
39	4	t	t	1	1	しませんなら			
39	4	t	t	2	1	しませんならば			
39	5	f	f	1	1	せる			
39	5	f	t	1	1	せます			
39	5	t	f	1	1	せない			
39	5	t	t	1	1	せません			
39	6	f	f	1	1	される			
39	6	f	t	1	1	されます			
39	6	t	f	1	1	されない			
39	6	t	t	1	1	されません			
39	7	f	f	1	1	させる			
39	7	f	f	2	1	さる			
39	7	f	t	1	1	させます			
39	7	f	t	2	1	さします			
39	7	t	f	1	1	させない			
39	7	t	f	2	1	ささない			
39	7	t	t	1	1	させません			
39	7	t	t	2	1	さしません			
39	8	f	f	1	1	させられる			
39	8	f	t	1	1	させられます			
39	8	t	f	1	1	させられない			
39	8	t	t	1	1	させられません			
39	9	f	f	1	1	そう			
39	9	f	t	1	1	しましょう			
39	9	t	f	1	1	すまい			
39	9	t	t	1	1	しませんまい			
39	10	f	f	1	1	せ			
39	10	f	t	1	1	しなさい			
39	10	t	f	1	1	すな			
39	10	t	t	1	1	しなさるな			
39	11	f	f	1	1	したら			
39	11	f	t	1	1	しましたら			
39	11	t	f	1	1	さなかったら			
39	11	t	t	1	1	しませんでしたら			
39	12	f	f	1	1	したり			
39	12	f	t	1	1	しましたり			
39	12	t	f	1	1	さなかったり			
39	12	t	t	1	1	しませんでしたり			
39	13	f	f	1	1	し			
40	1	f	f	1	1	つ			
40	1	f	t	1	1	ちます			
40	1	t	f	1	1	たない			
40	1	t	t	1	1	ちません			
40	2	f	f	1	1	った			
40	2	f	t	1	1	ちました			
40	2	t	f	1	1	たなかった			
40	2	t	t	1	1	ちませんでした			
40	3	f	f	1	1	って			
40	3	f	t	1	1	ちまして			
40	3	t	f	1	1	たなくて			
40	3	t	f	2	1	たないで			
40	3	t	t	1	1	ちませんで			
40	4	f	f	1	1	てば			
40	4	f	t	1	1	ちますなら			
40	4	f	t	2	1	ちますならば			
40	4	t	f	1	1	たなければ			
40	4	t	t	1	1	ちませんなら			
40	4	t	t	2	1	ちませんならば			
40	5	f	f	1	1	てる			
40	5	f	t	1	1	てます			
40	5	t	f	1	1	てない			
40	5	t	t	1	1	てません			
40	6	f	f	1	1	たれる			
40	6	f	t	1	1	たれます			
40	6	t	f	1	1	たれない			
40	6	t	t	1	1	たれません			
40	7	f	f	1	1	たせる			
40	7	f	f	2	1	たす			
40	7	f	t	1	1	たせます			
40	7	f	t	2	1	たします			
40	7	t	f	1	1	たせない			
40	7	t	f	2	1	たさない			
40	7	t	t	1	1	たせません			
40	7	t	t	2	1	たしません			
40	8	f	f	1	1	たせられる			
40	8	f	f	2	1	たされる			
40	8	f	t	1	1	たせられます			
40	8	f	t	2	1	たされます			
40	8	t	f	1	1	たせられない			
40	8	t	f	2	1	たされない			
40	8	t	t	1	1	たせられません			
40	8	t	t	2	1	たされません			
40	9	f	f	1	1	とう			
40	9	f	t	1	1	ちましょう			
40	9	t	f	1	1	つまい			
40	9	t	t	1	1	ちませんまい			
40	10	f	f	1	1	て			
40	10	f	t	1	1	ちなさい			
40	10	t	f	1	1	つな			
40	10	t	t	1	1	ちなさるな			
40	11	f	f	1	1	ったら			
40	11	f	t	1	1	ちまったら			
40	11	t	f	1	1	たなかったら			
40	11	t	t	1	1	ちませんでしたら			
40	12	f	f	1	1	ったり			
40	12	f	t	1	1	ちましたり			
40	12	t	f	1	1	たなかったり			
40	12	t	t	1	1	ちませんでしたり			
40	13	f	f	1	1	ち			
41	1	f	f	1	1	う			
41	1	f	t	1	1	います			
41	1	t	f	1	1	わない			
41	1	t	t	1	1	いません			
41	2	f	f	1	1	った			
41	2	f	t	1	1	いました			
41	2	t	f	1	1	わなかった			
41	2	t	t	1	1	いませんでした			
41	3	f	f	1	1	って			
41	3	f	t	1	1	いまして			
41	3	t	f	1	1	わなくて			
41	3	t	f	2	1	わないで			
41	3	t	t	1	1	いませんで			
41	4	f	f	1	1	えば			
41	4	f	t	1	1	いますなら			
41	4	f	t	2	1	いますならば			
41	4	t	f	1	1	わなければ			
41	4	t	t	1	1	いませんなら			
41	4	t	t	2	1	いませんならば			
41	5	f	f	1	1	える			
41	5	f	t	1	1	えます			
41	5	t	f	1	1	えない			
41	5	t	t	1	1	えません			
41	6	f	f	1	1	われる			
41	6	f	t	1	1	われます			
41	6	t	f	1	1	われない			
41	6	t	t	1	1	われません			
41	7	f	f	1	1	わせる			
41	7	f	f	2	1	わす			
41	7	f	t	1	1	わせます			
41	7	f	t	2	1	わします			
41	7	t	f	1	1	わせない			
41	7	t	f	2	1	わさない			
41	7	t	t	1	1	わせません			
41	7	t	t	2	1	わしません			
41	8	f	f	1	1	わせられる			
41	8	f	f	2	1	わされる			
41	8	f	t	1	1	わせられます			
41	8	f	t	2	1	わされます			
41	8	t	f	1	1	わせられない			
41	8	t	f	2	1	わされない			
41	8	t	t	1	1	わせられません			
41	8	t	t	2	1	わされません			
41	9	f	f	1	1	おう			
41	9	f	t	1	1	いましょう			
41	9	t	f	1	1	うまい			
41	9	t	t	1	1	いませんまい			
41	10	f	f	1	1	え			
41	10	f	t	1	1	いなさい			
41	10	t	f	1	1	うな			
41	10	t	t	1	1	いなさるな			
41	11	f	f	1	1	ったら			
41	11	f	t	1	1	いましたら			
41	11	t	f	1	1	わかったら			
41	11	t	t	1	1	いませんでしたら			
41	12	f	f	1	1	ったり			
41	12	f	t	1	1	いましたり			
41	12	t	f	1	1	わなかったり			
41	12	t	t	1	1	いませんでしたり			
41	13	f	f	1	1	い			
42	1	f	f	1	1	う			
42	1	f	t	1	1	います			
42	1	t	f	1	1	わない			
42	1	t	t	1	1	いません			
42	2	f	f	1	1	うた			
42	2	f	t	1	1	いました			
42	2	t	f	1	1	わなかった			
42	2	t	t	1	1	いませんでした			
42	3	f	f	1	1	うて			
42	3	f	t	1	1	いまして			
42	3	t	f	1	1	わなくて			
42	3	t	f	2	1	わないで			
42	3	t	t	1	1	いませんで			
42	4	f	f	1	1	えば			
42	4	f	t	1	1	いますなら			
42	4	f	t	2	1	いますならば			
42	4	t	f	1	1	わなければ			
42	4	t	t	1	1	いませんなら			
42	4	t	t	2	1	いませんならば			
42	5	f	f	1	1	える			
42	5	f	t	1	1	えます			
42	5	t	f	1	1	えない			
42	5	t	t	1	1	えません			
42	6	f	f	1	1	われる			
42	6	f	t	1	1	われます			
42	6	t	f	1	1	われない			
42	6	t	t	1	1	われません			
42	7	f	f	1	1	わせる			
42	7	f	f	2	1	わす			
42	7	f	t	1	1	わせます			
42	7	f	t	2	1	わします			
42	7	t	f	1	1	わせない			
42	7	t	f	2	1	わさない			
42	7	t	t	1	1	わせません			
42	7	t	t	2	1	わしません			
42	8	f	f	1	1	わせられる			
42	8	f	f	2	1	わされる			
42	8	f	t	1	1	わせられます			
42	8	f	t	2	1	わされます			
42	8	t	f	1	1	わせられない			
42	8	t	f	2	1	わされない			
42	8	t	t	1	1	わせられません			
42	8	t	t	2	1	わされません			
42	9	f	f	1	1	おう			
42	9	f	t	1	1	いましょう			
42	9	t	f	1	1	うまい			
42	9	t	t	1	1	いませんまい			
42	10	f	f	1	1	え			
42	10	f	t	1	1	いなさい			
42	10	t	f	1	1	うな			
42	10	t	t	1	1	いなさるな			
42	11	f	f	1	1	うたら			
42	11	f	t	1	1	いましたら			
42	11	t	f	1	1	わなかったら			
42	11	t	t	1	1	いませんでしたら			
42	12	f	f	1	1	うたり			
42	12	f	t	1	1	いましたり			
42	12	t	f	1	1	わなかったり			
42	12	t	t	1	1	いませんでしたり			
42	13	f	f	1	1	い			
45	1	f	f	1	1	る	く		
45	1	f	t	1	1	ます	き		
45	1	t	f	1	1	ない	こ		
45	1	t	t	1	1	ません	き		
45	2	f	f	1	1	た	き		
45	2	f	t	1	1	ました	き		
45	2	t	f	1	1	なかった	こ		
45	2	t	t	1	1	ませんでした	き		
45	3	f	f	1	1	て	き		
45	3	f	t	1	1	まして	き		
45	3	t	f	1	1	なくて	こ		
45	3	t	f	2	1	ないで	こ		
45	3	t	t	1	1	ませんで	き		
45	4	f	f	1	1	れば	く		
45	4	f	t	1	1	ますなら	く		
45	4	f	t	2	1	ますならば	く		
45	4	t	f	1	1	なければ	く		
45	4	t	t	1	1	ませんなら	く		
45	4	t	t	2	1	ませんならば	く		
45	5	f	f	1	1	られる	こ		
45	5	f	f	2	1	れる	こ		
45	5	f	t	1	1	られます	こ		
45	5	f	t	2	1	れます	こ		
45	5	t	f	1	1	られない	こ		
45	5	t	f	2	1	れない	こ		
45	5	t	t	1	1	られません	こ		
45	5	t	t	2	1	れません	こ		
45	6	f	f	1	1	られる	こ		
45	6	f	t	1	1	られます	こ		
45	6	t	f	1	1	られない	こ		
45	6	t	t	1	1	られません	こ		
45	7	f	f	1	1	させる	こ		
45	7	f	f	2	1	さす	こ		
45	7	f	t	1	1	させます	こ		
45	7	f	t	2	1	さします	こ		
45	7	t	f	1	1	させない	こ		
45	7	t	f	2	1	ささない	こ		
45	7	t	t	1	1	させません	こ		
45	7	t	t	2	1	さしません	こ		
45	8	f	f	1	1	させられる	こ		
45	8	f	t	1	1	させられます	こ		
45	8	t	f	1	1	させられない	こ		
45	8	t	t	1	1	させられません	こ		
45	9	f	f	1	1	よう	こ		
45	9	f	t	1	1	ましょう	き		
45	9	t	f	1	1	まい	こ		
45	9	t	t	1	1	ますまい	き		
45	10	f	f	1	1	い	こ		
45	10	f	t	1	1	なさい	こ		
45	10	t	f	1	1	るな	く		
45	10	t	t	1	1	なさるな	こ		
45	11	f	f	1	1	たら	き		
45	11	f	t	1	1	ましたら	き		
45	11	t	f	1	1	なかったら	こ		
45	11	t	t	1	1	ませんでしたら	き		
45	12	f	f	1	1	たり	き		
45	12	f	t	1	1	ましたり	き		
45	12	t	f	1	1	なかったり	こ		
45	12	t	t	1	1	ませんでしたり	き		
45	13	f	f	1	1	""	き		
46	1	f	f	1	0	する			
47	1	f	f	1	1	る	す		
47	1	f	t	1	1	ます	し		
47	1	t	f	1	1	ない	し		
47	1	t	t	1	1	ません	し		
47	2	f	f	1	1	た	し		
47	2	f	t	1	1	ました	し		
47	2	t	f	1	1	なかった	し		
47	2	t	t	1	1	ませんでした	し		
47	3	f	f	1	1	て	し		
47	3	f	t	1	1	まして	し		
47	3	t	f	1	1	なくて	し		
47	3	t	f	2	1	ないで	し		
47	3	t	t	1	1	ませんで	し		
47	4	f	f	1	1	れば	す		
47	4	f	t	1	1	ますなら	し		
47	4	f	t	2	1	ますなれば	し		
47	4	t	f	1	1	なければ	し		
47	4	t	t	1	1	ませんなら	し		
47	4	t	t	2	1	ませんならば	し		
47	5	f	f	1	1	る	でき	出来	
47	5	f	t	1	1	ます	でき	出来	
47	5	t	f	1	1	ない	でき	出来	
47	5	t	t	1	1	ません	でき	出来	
47	6	f	f	1	1	れる	さ		
47	6	f	t	1	1	れます	さ		
47	6	t	f	1	1	れない	さ		
47	6	t	t	1	1	れません	さ		
47	7	f	f	1	1	せる	さ		
47	7	f	f	2	1	す	さ		
47	7	f	t	1	1	せます	さ		
47	7	f	t	2	1	します	さ		
47	7	t	f	1	1	せない	さ		
47	7	t	f	2	1	さない	さ		
47	7	t	t	1	1	せません	さ		
47	7	t	t	2	1	しません	さ		
47	8	f	f	1	1	せられる	さ		
47	8	f	t	1	1	せられます	さ		
47	8	t	f	1	1	せられない	さ		
47	8	t	t	1	1	せられません	さ		
47	9	f	f	1	1	よう	し		
47	9	f	t	1	1	ましょう	し		
47	9	t	f	1	1	るまい	す		
47	9	t	t	1	1	ますまい	し		
47	10	f	f	1	1	ろ	し		
47	10	f	f	2	1	よ	せ		
47	10	f	t	1	1	なさい	し		
47	10	t	f	1	1	るな	す		
47	10	t	t	1	1	なさるな	し		
47	11	f	f	1	1	たら	し		
47	11	f	t	1	1	ましたら	し		
47	11	t	f	1	1	なかったら	し		
47	11	t	t	1	1	ませんでしたら	し		
47	12	f	f	1	1	たり	し		
47	12	f	t	1	1	ましたり	し		
47	12	t	f	1	1	なかったり	し		
47	12	t	t	1	1	ませんでしたり	し		
47	13	f	f	1	1	""	し		
48	1	f	f	1	1	る	す		
48	1	f	t	1	1	ます	し		
48	1	t	f	1	1	ない	し		
48	1	t	t	1	1	ません	し		
48	2	f	f	1	1	た	し		
48	2	f	t	1	1	ました	し		
48	2	t	f	1	1	なかった	し		
48	2	t	t	1	1	ませんでした	し		
48	3	f	f	1	1	て	し		
48	3	f	t	1	1	まして	し		
48	3	t	f	1	1	なくて	し		
48	3	t	f	2	1	ないで	し		
48	3	t	t	1	1	ませんで	し		
48	4	f	f	1	1	れば	す		
48	4	f	t	1	1	ますなら	し		
48	4	f	t	2	1	ますなれば	し		
48	4	t	f	1	1	なければ	し		
48	4	t	t	1	1	ませんなら	し		
48	4	t	t	2	1	ませんならば	し		
48	5	f	f	1	1	る	でき	出来	
48	5	f	t	1	1	ます	でき	出来	
48	5	t	f	1	1	ない	でき	出来	
48	5	t	t	1	1	ません	でき	出来	
48	6	f	f	1	1	れる	さ		
48	6	f	t	1	1	れます	さ		
48	6	t	f	1	1	れない	さ		
48	6	t	t	1	1	れません	さ		
48	7	f	f	1	1	せる	さ		
48	7	f	f	2	1	す	さ		
48	7	f	t	1	1	せます	さ		
48	7	f	t	2	1	します	さ		
48	7	t	f	1	1	せない	さ		
48	7	t	f	2	1	さない	さ		
48	7	t	t	1	1	せません	さ		
48	7	t	t	2	1	しません	さ		
48	8	f	f	1	1	せられる	さ		
48	8	f	t	1	1	せられます	さ		
48	8	t	f	1	1	せられない	さ		
48	8	t	t	1	1	せられません	さ		
48	9	f	f	1	1	よう	し		
48	9	f	t	1	1	ましょう	し		
48	9	t	f	1	1	るまい	す		
48	9	t	t	1	1	ますまい	し		
48	10	f	f	1	1	ろ	し		
48	10	f	f	2	1	よ	せ		
48	10	f	t	1	1	なさい	し		
48	10	t	f	1	1	るな	す		
48	10	t	t	1	1	なさるな	し		
48	11	f	f	1	1	たら	し		
48	11	f	t	1	1	ましたら	し		
48	11	t	f	1	1	なかったら	し		
48	11	t	t	1	1	ませんでしたら	し		
48	12	f	f	1	1	たり	し		
48	12	f	t	1	1	ましたり	し		
48	12	t	f	1	1	なかったり	し		
48	12	t	t	1	1	ませんでしたり	し		
48	13	f	f	1	1	""	し		
\.

\copy conotes FROM STDIN DELIMITER E'\t' CSV HEADER
id	note
1	"Irregular conjugation.  Note that this not the same as the definition
 of ""irregular verb"" commonly found in textbooks (typically する and
 来る).  It denotes okurigana that is different than other words of
 the same class.  Thus the past tense of 行く (行った) is an irregular
 conjugation because other く (v5k) verbs use いた as the okurigana for
 this conjugation.  します is not an irregular conjugation because if
 we take する to behave as a v1 verb the okurigana is the same as other
 v1 verbs despite the sound change of the stem (す) part of the verb
 to し."
2	na-adjectives and nouns are usually used with the なら nara conditional, instead of with であれば de areba. なら is a contracted and more common form of ならば.
3	では is often contracted to じゃ in colloquial speech.
4	The (first) non-abbreviated form is obtained by applying sequentially the causative, then passive conjugations.
5	The -まい negative form is literary and rather rare.
6	The ら is sometimes dropped from -られる, etc. in the potential form in conversational Japanese, but it is not regarded as grammatically correct.
7	"'n' and 'adj-na' words when used as predicates are followed by the
 copula <a href=""entr.py?svc=jmdict&sid=&q=2089020.jmdict"">だ</a> which is what is conjugated (<a href=""conj.py?svc=jmdict&sid=&q=2089020.jmdict"">conjugations</a>)."
8	'vs' words are followed by <a href="entr.py?svc=jmdict&sid=&q=1157170.jmdict">する</a> which is what is conjugated (<a href=""conj.py?svc=jmdict&sid=&q=1157170.jmdict"">conjugations</a>).
\.

\copy conjo_notes FROM STDIN DELIMITER E'\t' CSV HEADER
pos	conj	neg	fml	onum	note
2	1	f	f	1	7
15	1	t	f	1	3
15	1	t	t	1	3
15	1	t	t	2	3
15	2	t	f	1	3
15	2	t	t	1	3
15	3	t	f	1	3
15	4	f	f	1	2
15	11	t	f	1	3
15	11	t	t	1	3
17	1	f	f	1	7
28	5	f	f	2	6
28	5	f	t	2	6
28	5	t	f	2	6
28	5	t	t	2	6
28	9	t	f	1	5
28	9	t	t	1	5
29	5	f	f	2	6
29	5	f	t	2	6
29	5	t	f	2	6
29	5	t	t	2	6
29	9	t	f	1	5
29	9	t	t	1	5
29	10	f	f	1	1
30	1	f	t	1	1
30	1	t	t	1	1
30	2	f	t	1	1
30	2	t	t	1	1
30	3	f	t	1	1
30	3	t	t	1	1
30	4	f	t	1	1
30	4	f	t	2	1
30	4	t	t	1	1
30	4	t	t	2	1
30	9	f	t	1	1
30	9	t	f	1	5
30	9	t	t	1	5
30	10	f	f	1	1
30	10	f	t	1	1
30	10	t	t	1	1
30	11	f	t	1	1
30	11	t	t	1	1
30	12	f	t	1	1
30	13	f	f	1	1
31	9	t	f	1	5
31	9	t	t	1	5
32	9	t	f	1	5
32	9	t	t	1	5
33	9	t	f	1	5
33	9	t	t	1	5
34	2	f	f	1	1
34	3	f	f	1	1
34	9	t	f	1	5
34	9	t	t	1	5
34	11	f	f	1	1
34	12	f	f	1	1
35	9	t	f	1	5
35	9	t	t	1	5
36	9	t	f	1	5
36	9	t	t	1	5
37	9	t	f	1	5
37	9	t	t	1	5
38	1	t	f	1	1
38	2	t	f	1	1
38	3	t	f	1	1
38	3	t	f	2	1
38	9	t	f	1	5
38	9	t	t	1	5
38	11	t	f	1	1
38	12	t	f	1	1
39	9	t	f	1	5
39	9	t	t	1	5
40	9	t	f	1	5
40	9	t	t	1	5
41	9	t	f	1	5
41	9	t	t	1	5
42	2	f	f	1	1
42	3	f	f	1	1
42	9	t	f	1	5
42	9	t	t	1	5
42	11	f	f	1	1
42	12	f	f	1	1
45	5	f	f	2	6
45	5	f	t	2	6
45	5	t	f	2	6
45	5	t	t	2	6
45	9	t	f	1	5
45	9	t	t	1	5
45	10	f	f	1	1
46	1	f	f	1	8
47	5	f	f	1	1
47	5	f	t	1	1
47	5	t	f	1	1
47	5	t	t	1	1
47	6	f	f	1	1
47	6	f	t	1	1
47	6	t	f	1	1
47	6	t	t	1	1
47	7	f	f	1	1
47	7	f	f	2	1
47	7	f	t	1	1
47	7	f	t	2	1
47	7	t	f	1	1
47	7	t	f	2	1
47	7	t	t	1	1
47	7	t	t	2	1
47	8	f	f	1	1
47	8	f	t	1	1
47	8	t	f	1	1
47	8	t	t	1	1
47	9	t	f	1	5
47	9	t	t	1	5
47	10	f	f	2	1
48	5	f	f	1	1
48	5	f	t	1	1
48	5	t	f	1	1
48	5	t	t	1	1
48	6	f	f	1	1
48	6	f	t	1	1
48	6	t	f	1	1
48	6	t	t	1	1
48	7	f	f	1	1
48	7	f	f	2	1
48	7	f	t	1	1
48	7	f	t	2	1
48	7	t	f	1	1
48	7	t	f	2	1
48	7	t	t	1	1
48	7	t	t	2	1
48	8	f	f	1	1
48	8	f	t	1	1
48	8	t	f	1	1
48	8	t	t	1	1
48	9	t	f	1	5
48	9	t	t	1	5
48	10	f	f	2	1
\.


COMMIT;

