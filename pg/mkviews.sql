-------------------------------------------------------------------------
--  This file is part of JMdictDB. 
--
--  JMdictDB is free software; you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published 
--  by the Free Software Foundation; either version 2 of the License, 
--  or (at your option) any later version.
--
--  JMdictDB is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with JMdictDB; if not, write to the Free Software Foundation,
--  51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
--
--  Copyright (c) 2006,2007 Stuart McGraw 
---------------------------------------------------------------------------

\set ON_ERROR_STOP 
BEGIN;

CREATE AGGREGATE accum ( 
    SFUNC = ARRAY_APPEND, 
    BASETYPE = ANYELEMENT, 
    STYPE = ANYARRAY, 
    INITCOND = '{}');

-------------------------------------------------------------
-- The first kanji and reading in an entry are significant
-- because jmdict xml and some other apps use them as 
-- entry "headwords" that identify the entry.  (Unfortunately
-- they are not necessarily unique, especially for reading-
-- only words.)
-- This view provide's the first reading and (if there is 
-- one) first kanji for each entry.
-------------------------------------------------------------
CREATE OR REPLACE VIEW hdwds AS (
    SELECT e.*,r.txt AS rtxt,k.txt AS ktxt
    FROM entr e
    LEFT JOIN rdng r ON r.entr=e.id
    LEFT JOIN kanj k ON k.entr=e.id
    WHERE (r.rdng=1 OR r.rdng IS NULL)
      AND (k.kanj=1 OR k.kanj IS NULL));

-----------------------------------------------------------
-- Summarize each entry (one per row) with readings, kanji, 
-- and sense/gloss.  Each of those columns values has the
-- text from each child item concatenated into a single
-- string with items delimited by "; "s.  For the sense
-- column, each aggregated gloss string in contatented
-- with the delimiter " / ".
------------------------------------------------------------
CREATE OR REPLACE VIEW esum AS (
    SELECT e.id,e.seq,e.src,e.stat,e.notes,e.srcnote,h.rtxt AS rdng,h.ktxt AS kanj,
	(SELECT ARRAY_TO_STRING(ACCUM( ss.gtxt ), ' / ') 
	 FROM 
	    (SELECT 
		(SELECT ARRAY_TO_STRING(ACCUM(sg.txt), '; ') 
		FROM (
		    SELECT g.txt 
		    FROM gloss g 
		    WHERE g.sens=s.sens AND g.entr=s.entr 
		    ORDER BY g.gloss) AS sg
		ORDER BY entr,sens) AS gtxt
	    FROM sens s WHERE s.entr=e.id ORDER BY s.sens) AS ss) AS gloss,
	(SELECT COUNT(*) FROM sens WHERE sens.entr=e.id) AS nsens
    FROM entr e
    JOIN hdwds h on h.id=e.id);
    
-----------------------------------------------------------
-- Provide a pseudo-sens table with an additional column
-- "txt" that contains an aggregation of all the glosses
-- for that sense concatenated into a single string with
-- each gloss delimited with the string "; ".
------------------------------------------------------------
CREATE OR REPLACE VIEW ssum AS (
    SELECT s.entr,s.sens,
       (SELECT ARRAY_TO_STRING(ACCUM(sg.txt), '; ') 
        FROM (
	    SELECT g.txt 
	    FROM gloss g 
	    WHERE g.sens=s.sens AND g.entr=s.entr 
	    ORDER BY g.gloss) AS sg
        ORDER BY entr,sens) AS gloss,
        s.notes
    FROM sens s);

-----------------------------------------------------------
-- Provide a pseudo-sens table with additional columns
-- "txt" (contains an aggregation of all the glosses
-- for that sense concatenated into a single string with
-- each gloss delimited with the string "; "), "rdng"
-- (similarly has concatenated readings of the entry
-- to which this sense belongs), "kanj" (similarly has
-- concatenated readings of the entry to which this sense
-- belongs).
------------------------------------------------------------

CREATE OR REPLACE VIEW essum AS (
    SELECT e.id, e.seq, e.src, e.stat, s.sens, h.rtxt as rdng, h.ktxt as kanj, s.gloss,
	   (SELECT COUNT(*) FROM sens WHERE sens.entr=e.id) AS nsens
	FROM entr e
	JOIN hdwds h ON h.id=e.id
        JOIN ssum s ON s.entr=e.id);

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
CREATE VIEW pkfreq AS (
    SELECT k.*, exists (
        SELECT * FROM freq f
          WHERE f.entr=k.entr AND f.kanj=k.kanj AND
            -- ichi1, gai1, jdd1, spec1
            ((f.kw IN (1,2,3,4) AND f.value=1) 
            -- news1
            OR (f.kw=5 AND f.value<=24))) AS p 
    FROM kanj k);
 
CREATE VIEW prdng AS (
    SELECT r.*, exists (
        SELECT * FROM freq f
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
	_p0_ INT;
    BEGIN
	INSERT INTO entr(src,seq,stat,notes) 
	  (SELECT src,seq,3,notes FROM entr WHERE id=entrid);
	SELECT lastval() INTO _p0_;

	INSERT INTO hist(entr,hist,stat,dt,who,diff,notes) 
	  (SELECT _p0_,hist,stat,dt,who,diff,notes FROM hist WHERE hist.entr=entrid);

	INSERT INTO kanj(entr,kanj,txt) 
	  (SELECT _p0_,kanj,txt FROM kanj WHERE entr=entrid);
	INSERT INTO kinf(entr,kanj,kw)
	  (SELECT _p0_,kanj,kw FROM kinf WHERE entr=entrid);

	INSERT INTO rdng(entr,rdng,txt) 
	  (SELECT _p0_,rdng,txt FROM rdng WHERE entr=entrid);
	INSERT INTO rinf(entr,rdng,kw)
	  (SELECT _p0_,rdng,kw FROM rinf WHERE entr=entrid);
	INSERT INTO audio(entr,rdng,audio,fname,strt,leng) 
	  (SELECT _p0_,rdng,audio,fname,strt,leng FROM audio a WHERE a.entr=entrid);
	    
	INSERT INTO sens(entr,sens,notes) 
	  (SELECT _p0_,sens,notes FROM sens WHERE entr=entrid);
	INSERT INTO pos(entr,sens,kw) 
	  (SELECT _p0_,sens,kw FROM pos WHERE entr=entrid);
	INSERT INTO misc(entr,sens,kw) 
	  (SELECT _p0_,sens,kw FROM misc WHERE entr=entrid);
	INSERT INTO fld(entr,sens,kw) 
	  (SELECT _p0_,sens,kw FROM fld WHERE entr=entrid);
	INSERT INTO gloss(entr,sens,gloss,lang,ginf,txt,notes) 
	  (SELECT _p0_,sens,gloss,lang,txt,ginf,notes FROM gloss WHERE entr=entrid);
	INSERT INTO dial(entr,sens,kw) 
	  (SELECT _p0_,kw FROM dial WHERE dial.entr=entrid);
	INSERT INTO lsrc(entr,sens,lang,txt,part,wasei) 
	  (SELECT _p0_,kw FROM lsrc WHERE lang.entr=entrid);
	INSERT INTO xref(entr,sens,xref,typ,xentr,xsens,notes) 
	  (SELECT _p0_,sens,xref,typ,xentr,xsens,notes FROM xref WHERE entr=entrid);
	INSERT INTO xref(entr,sens,xref,typ,xentr,xsens,notes) 
	  (SELECT entr,sens,xref,typ,_p0_,xsens,notes FROM xref WHERE xentr=entrid);

	INSERT INTO freq(entr,kanj,kw,value) 
	  (SELECT _p0_,rdng,kanj,kw,value FROM freq WHERE entr=entrid);
	INSERT INTO restr(entr,rdng,kanj)
	  (SELECT _p0_,rdng,kanj FROM restr WHERE entr=entrid);
	INSERT INTO stagr(entr,sens,rdng)
	  (SELECT _p0_,sens,rdng FROM stagr WHERE entr=entrid);
	INSERT INTO stagk(entr,sens,kanj)
	  (SELECT _p0_,sens,kanj FROM stagk WHERE entr=entrid);

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
	DELETE FROM kanj WHERE entr=entrid;
	DELETE FROM rdng WHERE entr=entrid;
	DELETE FROM sens WHERE entr=entrid;
	UPDATE entr SET stat=5 WHERE entr=entrid;
	END;
    $$ LANGUAGE plpgsql;

COMMIT;
