-------------------------------------------------------------------------
--  This file is part of JMdictDB.  
--  JMdictDB is free software; you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation; either version 2 of the License, or
--  (at your option) any later version.
--   JMdictDB is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--  You should have received a copy of the GNU General Public License
--  along with Foobar; if not, write to the Free Software Foundation, Inc.,
--  51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
--
--  Copyright (c) 2006,2007 Stuart McGraw 
---------------------------------------------------------------------------

\unset ON_ERROR_STOP 
CREATE LANGUAGE 'plpgsql';
\set ON_ERROR_STOP 

CREATE AGGREGATE accum ( 
    SFUNC = ARRAY_APPEND, 
    BASETYPE = ANYELEMENT, 
    STYPE = ANYARRAY, 
    INITCOND = '{}');

-----------------------------------------------------------
-- Summarize each entry (one per row) with readings, kanji, 
-- and sense/gloss.  Each of those columns values has the
-- text from each child item concatenated into a single
-- string with items delimited by "; "s.  For the sense
-- column, each aggregated gloss string in contatented
-- with the delimiter " / ".
------------------------------------------------------------
CREATE VIEW esum AS (
    SELECT e.id,e.seq,
	(SELECT ARRAY_TO_STRING(ACCUM(sr.txt), '; ') 
	 FROM (SELECT r.txt FROM rdng r WHERE r.entr=e.id ORDER BY r.rdng) AS sr) AS rdng,
	(SELECT ARRAY_TO_STRING(ACCUM(sk.txt), '; ')
	 FROM (SELECT k.txt FROM kanj k WHERE k.entr=e.id ORDER BY k.kanj) AS sk) AS kanj,
	(SELECT ARRAY_TO_STRING(ACCUM( ss.gtxt ), ' / ') 
	 FROM 
	    (SELECT 
		(SELECT ARRAY_TO_STRING(ACCUM(sg.txt), '; ') 
		FROM (SELECT g.txt FROM gloss g WHERE g.sens=s.sens AND g.entr=s.entr ORDER BY g.gloss) AS sg
		ORDER BY entr,sens) AS gtxt
	    FROM sens s WHERE s.entr=e.id ORDER BY s.sens) AS ss) AS gloss,
	(SELECT COUNT(*) FROM sens WHERE sens.entr=e.id) AS nsens
    FROM entr e);

---------------------------------------------------------
-- For every entry, give the number of associated reading,
-- kanji, and sense items.
----------------------------------------------------------
CREATE VIEW item_cnts AS (
    SELECT 
	e.id,e.seq,
	(SELECT COUNT(*) FROM rdng r WHERE r.entr=e.id) as nrdng,
	(SELECT COUNT(*) FROM kanj k WHERE k.entr=e.id) as nkanj,
	(SELECT COUNT(*) FROM sens s WHERE s.entr=e.id) as nsens
    FROM entr e);

------------------------------------------------------------
-- For every entry, give all the combinations of reading and 
-- kanji, and an indicator whether of not that combination
-- is valid ('X' in column 'valid' means invalid).
------------------------------------------------------------
CREATE VIEW rk_validity AS (
    SELECT e.id AS id,e.seq AS seq,
	r.rdng AS rdng,r.txt AS rtxt,k.kanj AS kanj,k.txt AS ktxt,
	CASE WHEN z.kanj IS NOT NULL THEN 'X' END AS valid
    FROM ((entr e
    LEFT JOIN rdng r ON r.entr=e.id)
    LEFT JOIN kanj k ON k.entr=e.id)
    LEFT JOIN restr z ON z.entr=e.id AND r.rdng=z.rdng AND k.kanj=z.kanj);

------------------------------------------------------------
-- List all readings that should be marked "re_nokanji" 
-- in jmdict.xml.
------------------------------------------------------------
CREATE VIEW re_nokanji AS (
    SELECT e.id,e.seq,r.rdng,r.txt
    FROM entr e 
    JOIN rdng r ON r.entr=e.id 
    JOIN restr z ON z.entr=r.entr AND z.rdng=r.rdng
    GROUP BY e.id,e.seq,r.rdng,r.txt
    HAVING COUNT(z.kanj)=(SELECT COUNT(*) FROM kanj k WHERE k.entr=e.id));

-------------------------------------------------------------
-- For every reading in every entry, provide only the valid 
-- kanji as determined by restr if applicable, and taking 
-- the jmdict's re_nokanji information into account. 
-------------------------------------------------------------
CREATE VIEW rk_valid AS (
  SELECT e.id, e.seq, r.rdng, r.txt AS rtxt, sub.kanj, sub.ktxt
    FROM entr e
      JOIN rdng r ON r.entr=e.id
      LEFT JOIN (
        SELECT e.id AS eid, r.rdng, k.kanj, k.txt AS ktxt
          FROM entr e
          JOIN rdng r ON r.entr=e.id
            LEFT JOIN kanj k ON k.entr=r.entr
            LEFT JOIN restr z ON z.entr=e.id AND z.rdng=r.rdng AND z.kanj=k.kanj
          WHERE z.rdng IS NULL
        ) AS sub ON sub.rdng=r.rdng AND sub.eid=e.id);

-------------------------------------------------------------
-- For each xref, provide a summary of the entry containing
-- the sense that the "xsens" column points to.  xsumr is the
-- same except that the summary is for the entry pointed to 
-- by column "sens" (the reverse direction).  
-------------------------------------------------------------
-- CREATE VIEW xsum AS (
--     SELECT x.entr,x.sens,x.xentr,x.xsens,x.typ,x.notes,e.seq,e.kanj,e.rdng,e.nsens
-- 	FROM xref x
-- 	JOIN esum e ON e.id=x.xentr
-- 	ORDER BY x.entr,x.sens,x.typ,x.xentr,x.xsens);

-- CREATE VIEW xsumr AS (
--     SELECT x.entr,x.sens,x.xentr,x.xsens,x.typ,x.notes,e.seq,e.kanj,e.rdng,e.nsens
-- 	FROM xref x
-- 	JOIN esum e ON e.id=x.entr
-- 	ORDER BY x.entr,x.sens,x.typ,x.xentr,x.xsens);

CREATE VIEW xrefesum AS (
    SELECT DISTINCT z.entr AS id,e.id AS eid,e.seq,e.rdng,e.kanj,e.nsens 
        FROM esum e
	JOIN 
	    (SELECT s.entr,x.xentr
		FROM sens s 
	        JOIN xref x ON x.entr=s.entr AND x.sens=s.sens
	    UNION 
	    SELECT s.entr,x.entr
		FROM sens s
		JOIN xref x ON x.xentr=s.entr AND x.xsens=s.sens) 
	  AS z ON z.xentr=e.id);

-------------------------------------------------------------
-- Provide a view of table "kanj" with additional column
-- that is <logical true> if the kanji would be marked as
-- "P" in edict.  According to 
--    http://www.csse.monash.edu.au/~jwb/edict_doc.html#IREF05
-- the "P" kanji are those tagged with "ichi1", "gai1",
-- "jdd1", "spec1", or "news1" (= "nf01"-"nf24") in JMdict.
--
-- View prdng is identical except it is on  table "rdng"
-- instead of table "kanj".
-------------------------------------------------------------
CREATE VIEW pkanj AS (
    SELECT k.*, exists (
        SELECT * FROM kfreq f
          WHERE f.entr=k.entr AND f.kanj=k.kanj AND
            -- ichi1, gai1, jdd1, spec1
            ((f.kw IN (1,2,3,4) AND f.value=1) 
            -- news1
            OR (f.kw=5 AND f.value<=24))) AS p 
    FROM kanj k);
 
CREATE VIEW prdng AS (
    SELECT r.*, exists (
        SELECT * FROM rfreq f
          WHERE f.entr=r.entr AND f.rdng=r.rdng AND
            -- ichi1, gai1, jdd1, spec1
            ((f.kw IN (1,2,3,4) AND f.value=1) 
            -- news1
            OR (f.kw=5 AND f.value<=24))) AS p 
    FROM rdng r);

-------------------------------------------------------------
-- This function will replicate an entry by duplicating it's
-- row in table entr and all child rows recursively (although
-- this function is not recursive.)
-------------------------------------------------------------
CREATE OR REPLACE FUNCTION dupentr(entrid int) RETURNS INT AS $$
    DECLARE
	_p0_ INT; _p1_ INT; rec RECORD; REC2 record; rc INT;
    BEGIN
	INSERT INTO entr(src,seq,stat,notes) 
	  (SELECT src,seq,3,notes FROM entr WHERE id=entrid);
	SELECT lastval() INTO _p0_;

	INSERT INTO dial(entr,kw) 
	  (SELECT _p0_,kw FROM dial WHERE dial.entr=entrid);
	INSERT INTO lang(entr,kw) 
	  (SELECT _p0_,kw FROM lang WHERE lang.entr=entrid);
	INSERT INTO hist(entr,stat,dt,who,diff,notes) 
	  (SELECT _p0_,stat,dt,who,diff,notes FROM hist WHERE hist.entr=entrid);

	FOR rec IN (SELECT * FROM kanj WHERE entr=entrid) LOOP
	    INSERT INTO kanj(entr,kanj,txt) VALUES(_p0_,rec.kanj,rec.txt);
	    SELECT lastval() INTO _p1_;
	    INSERT INTO kinf(entr,kanj,kw) 
	      (SELECT _p0_,_p1_,kw FROM kinf i WHERE i.entr=rec.entr AND i.kanj=rec.kanj);
	    INSERT INTO kfreq(entr,kanj,kw,value) 
	      (SELECT _p0_,_p1_,kw,value FROM kfreq f WHERE f.entr=rec.entr AND f.kanj=rec.kanj);
	    END LOOP;
	FOR rec IN (SELECT * FROM rdng WHERE entr=entrid) LOOP
	    INSERT INTO rdng(entr,rdng,txt) VALUES(_p0_,rec.rdng,rec.txt);
	    SELECT lastval() INTO _p1_;
	    INSERT INTO rinf(entr,rdng,kw) 
	      (SELECT _p0_,_p1_,kw FROM rinf i WHERE i.entr=rec.entr AND i.rdng=rec.rdng);
	    INSERT INTO rfreq(entr,rdng,kw,value) 
	      (SELECT _p0_,_p1_,kw,value FROM rfreq f WHERE f.entr=rec.entr AND f.rdng=rec.rdng);
	    INSERT INTO audio(entr,rdng,fname,strt,leng) 
	      (SELECT _p0_,_p1_,fname,strt,leng FROM audio a WHERE a.entr=rec.entr AND a.rdng=rec.rdng);
	    END LOOP;
	FOR rec IN (SELECT * FROM sens WHERE entr=entrid) LOOP
	    INSERT INTO sens(entr,sens,notes) VALUES(_p0_,rec.sens,rec.notes);
	    SELECT lastval() INTO _p1_;

	    INSERT INTO pos(entr,sens,kw) 
	      (SELECT _p0_,_p1_,kw FROM pos p WHERE p.entr=rec.entr AND p.sens=rec.sens);
	    INSERT INTO misc(entr,sens,kw) 
	      (SELECT _p0_,_p1_,kw FROM misc m WHERE m.entr=rec.entr AND m.sens=rec.sens);
	    INSERT INTO fld(entr,sens,kw) 
	      (SELECT _p0_,_p1_,kw FROM fld f WHERE f.entr=rec.entr AND f.sens=rec.sens);
	    INSERT INTO gloss(entr,sens,ord,lang,txt,notes) 
	      (SELECT _p0_,_p1_,ord,lang,txt,notes FROM gloss g WHERE g.entr=rec.entr AND g.sens=rec.sens);
	    INSERT INTO xref(entr,sens,xentr,xsens,typ,notes) 
	      (SELECT _p0_,_p1_,xref,typ,notes FROM xref x WHERE x.entr=rec.entr AND x.sens=rec.sens);
	    INSERT INTO xref(entr,sens,xentr,xsens,typ,notes) 
	      (SELECT sens,_p0_,_p1_,typ,notes FROM xref x WHERE x.xentr=rec.entr AND x.xsens=rec.sens);
	    END LOOP;

	INSERT INTO restr(entr,rdng,kanj)
	  (SELECT _p0_,rdng,kanj FROM restr z WHERE z.entr=entrid);

	INSERT INTO stagr(entr,sens,rdng)
	  (SELECT _p0_,sens,rdng FROM stagr z WHERE z.entr=entrid);

	INSERT INTO stagk(entr,sens,kanj)
	  (SELECT _p0_,sens,kanj FROM stagk z WHERE z.entr=entrid);

	RETURN _p0_;
	END;
    $$ LANGUAGE plpgsql;

-------------------------------------------------------------
-- This function will delete an entry by deleting all related
-- rows in child tables other than hist, and setting the entr
-- row's status to "deleted, pending approval".  
-------------------------------------------------------------
CREATE OR REPLACE FUNCTION delentr(entrid int) RETURNS void AS $$
    BEGIN
	-- We don't delete the entr row or history rows but
	-- we delete everything else.
	-- Because fk's use "on delete cascade" options we 
	-- need only delete the top-level children to get 
	-- rid of everything.
	UPDATE entr SET stat=5 WHERE entr=entrid;
	DELETE FROM dial WHERE entr=entrid;
	DELETE FROM lang WHERE entr=entrid;
	DELETE FROM kanj WHERE entr=entrid;
	DELETE FROM rdng WHERE entr=entrid;
	DELETE FROM sens WHERE entr=entrid;
	UPDATE entr SET stat=5 WHERE entr=entrid;
	END;
    $$ LANGUAGE plpgsql;


