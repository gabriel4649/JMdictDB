-- Schema objects for word conjugations.

-- $Revision$ $Date$
-- Copyright (c) 2006-2013, Stuart McGraw 

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

COMMIT;
