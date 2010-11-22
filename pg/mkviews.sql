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

-------------------------------------------------------------
-- View "is_p" returns each row in table "entr" with an
-- additional boolean column, "p" that if true indicates
-- the entry meets the wwwjdic criteria for a "P" marking: 
-- has a reading or a kanji with a freq tag of "ichi1", 
-- "gai1", "spec1", or "news1" as documented at
--   http://www.csse.monash.edu.au/~jwb/edict_doc.html#IREF05
--
-- See also views pkfreq and prfreq below.
-------------------------------------------------------------
CREATE OR REPLACE VIEW is_p AS (
    SELECT e.*,
	    EXISTS (
		SELECT * FROM freq f
       		WHERE f.entr=e.id AND
		  -- ichi1, gai1, jdd1, spec1
		  ((f.kw IN (1,2,3,4) AND f.value=1)))
	    AS p
    FROM entr e);


-----------------------------------------------------------
-- Summarize each entry (one per row) with readings, kanji, 
-- and sense/gloss.  The rdng and kanj columns contain the
-- entry's single "headword" items (as given by view hdwds)
-- The sense column contain gloss strings in contatented
-- with ';', and grouped into senses concatenated with "/".
-----------------------------------------------------------
CREATE OR REPLACE VIEW esum AS (
    SELECT e.id,e.seq,e.stat,e.src,e.dfrm,e.unap,e.notes,e.srcnote,
	h.rtxt AS rdng,
	h.ktxt AS kanj,
	(SELECT ARRAY_TO_STRING(ARRAY_AGG( ss.gtxt ), ' / ') 
	 FROM 
	    (SELECT 
		(SELECT ARRAY_TO_STRING(ARRAY_AGG(sg.txt), '; ') 
		FROM (
		    SELECT g.txt 
		    FROM gloss g 
		    WHERE g.sens=s.sens AND g.entr=s.entr 
		    ORDER BY g.gloss) AS sg
		ORDER BY entr,sens) AS gtxt
	    FROM sens s WHERE s.entr=e.id ORDER BY s.sens) AS ss) AS gloss,
	(SELECT COUNT(*) FROM sens WHERE sens.entr=e.id) AS nsens,
	(SELECT p FROM is_p WHERE is_p.id=e.id) AS p
    FROM entr e
    JOIN hdwds h on h.id=e.id);
    
-----------------------------------------------------------
-- Provide a pseudo-sens table with an additional column
-- "txt" that contains an aggregation of all the glosses
-- for that sense concatenated into a single string with
-- each gloss delimited with the string "; ".
--
-- DEPRECATED: use vt_sens* in mkviews2 instead.  Note 
--  that that view may need to be used in an outer join
--  unlike this view. 
------------------------------------------------------------
CREATE OR REPLACE VIEW ssum AS (
    SELECT s.entr,s.sens,
       (SELECT ARRAY_TO_STRING(ARRAY_AGG(sg.txt), '; ') 
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
    SELECT e.id, e.seq, e.src, e.stat, 
	    s.sens, 
	    h.rtxt as rdng, 
	    h.ktxt as kanj, 
	    s.gloss,
	   (SELECT COUNT(*) FROM sens WHERE sens.entr=e.id) AS nsens
	FROM entr e
	JOIN hdwds h ON h.id=e.id
        JOIN ssum s ON s.entr=e.id);

---------------------------------------------------------
-- For every entry, give the number of associated reading,
-- kanji, and sense items.
----------------------------------------------------------
CREATE OR REPLACE VIEW item_cnts AS (
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
CREATE OR REPLACE VIEW rk_validity AS (
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
CREATE OR REPLACE VIEW re_nokanji AS (
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
CREATE OR REPLACE VIEW rk_valid AS (
    SELECT r.entr,r.rdng,r.txt as rtxt,k.kanj,k.txt as ktxt
    FROM rdng r
    JOIN kanj k ON k.entr=r.entr
    WHERE NOT EXISTS (
	SELECT * FROM restr z 
	WHERE z.entr=r.entr AND z.kanj=k.kanj AND z.rdng=r.rdng));
	
CREATE OR REPLACE VIEW sr_valid AS (
    SELECT s.entr,s.sens,r.rdng,r.txt as rtxt
    FROM sens s
    JOIN rdng r ON r.entr=s.entr
    WHERE NOT EXISTS (
	SELECT * FROM stagr z 
	WHERE z.entr=s.entr AND z.sens=s.sens AND z.rdng=r.rdng)); 
	
CREATE OR REPLACE VIEW sk_valid AS (
    SELECT s.entr,s.sens,k.kanj,k.txt as ktxt
    FROM sens s
    JOIN kanj k ON k.entr=s.entr
    WHERE NOT EXISTS (
	SELECT * FROM stagk z 
	WHERE z.entr=s.entr AND z.sens=s.sens AND z.kanj=k.kanj)); 

CREATE OR REPLACE VIEW xrefhw AS (
    SELECT r.entr,rm.sens,r.txt as rtxt,k.kanj,k.txt as ktxt
    FROM (
	SELECT entr,sens,MIN(rdng) as rdng FROM sr_valid GROUP BY entr,sens)
	AS rm 
    JOIN rdng r ON r.entr=rm.entr AND r.rdng=rm.rdng 
    LEFT JOIN (
	SELECT entr,sens,MIN(kanj) as kanj FROM sk_valid GROUP BY entr,sens)
	AS km ON km.entr=r.entr AND km.sens=rm.sens
    LEFT JOIN kanj k ON k.entr=km.entr AND k.kanj=km.kanj);

-------------------------------------------------------------
-- View pkfreq returns each row in table "kanj" with an
-- additional boolean column, "p" that if true indicates
-- the kanji meets the wwwjdic criteria for a "P" marking
-- on its containing entry as described above.
--
-- View prfreq returned each row in table "rdng" with an
-- additional boolean column, "p" that if true indicates
-- the reading meets the wwwjdic criteria for a "P" marking
-- on its containing entry as described above.
--
-- See also is_p above.
-------------------------------------------------------------
CREATE OR REPLACE VIEW pkfreq AS (
    SELECT k.*, EXISTS (
        SELECT * FROM freq f
          WHERE f.entr=k.entr AND f.kanj=k.kanj AND
            -- ichi1, gai1, jdd1, spec1
            ((f.kw IN (1,2,3,4) AND f.value=1))) AS p 
    FROM kanj k);
 
CREATE OR REPLACE VIEW prfreq AS (
    SELECT r.*, EXISTS (
        SELECT * FROM freq f
          WHERE f.entr=r.entr AND f.rdng=r.rdng AND
            -- ichi1, gai1, jdd1, spec1
            ((f.kw IN (1,2,3,4) AND f.value=1))) AS p 
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
	INSERT INTO entr(src,stat,seq,dfrm,unap,srcnotes,notes)
	  (SELECT src,seq,3,notes FROM entr WHERE id=entrid);
	SELECT lastval() INTO _p0_;

	INSERT INTO hist(entr,hist,stat,unap,dt,userid,name,email,diff,refs,notes) 
	  (SELECT _p0_,hist,stat,unap,dt,userid,name,email,diff,refs,notes 
	   FROM hist WHERE hist.entr=entrid);

	INSERT INTO kanj(entr,kanj,txt) 
	  (SELECT _p0_,kanj,txt FROM kanj WHERE entr=entrid);
	INSERT INTO kinf(entr,kanj,ord,kw)
	  (SELECT _p0_,kanj,kw FROM kinf WHERE entr=entrid);

	INSERT INTO rdng(entr,rdng,txt) 
	  (SELECT _p0_,rdng,txt FROM rdng WHERE entr=entrid);
	INSERT INTO rinf(entr,rdng,ord,kw)
	  (SELECT _p0_,rdng,kw FROM rinf WHERE entr=entrid);
	INSERT INTO audio(entr,rdng,audio,fname,strt,leng) 
	  (SELECT _p0_,rdng,audio,fname,strt,leng FROM audio a WHERE a.entr=entrid);
	    
	INSERT INTO sens(entr,sens,notes) 
	  (SELECT _p0_,sens,notes FROM sens WHERE entr=entrid);
	INSERT INTO pos(entr,sens,ord,kw) 
	  (SELECT _p0_,sens,kw FROM pos WHERE entr=entrid);
	INSERT INTO misc(entr,sens,ord,kw) 
	  (SELECT _p0_,sens,kw FROM misc WHERE entr=entrid);
	INSERT INTO fld(entr,sens,ord,kw) 
	  (SELECT _p0_,sens,kw FROM fld WHERE entr=entrid);
	INSERT INTO gloss(entr,sens,gloss,lang,ginf,txt,notes) 
	  (SELECT _p0_,sens,gloss,lang,txt,ginf,notes FROM gloss WHERE entr=entrid);
	INSERT INTO dial(entr,sens,ord,kw) 
	  (SELECT _p0_,kw FROM dial WHERE dial.entr=entrid);
	INSERT INTO lsrc(entr,sens,ord,lang,txt,part,wasei) 
	  (SELECT _p0_,kw FROM lsrc WHERE lang.entr=entrid);
	INSERT INTO xref(entr,sens,xref,typ,xentr,xsens,notes) 
	  (SELECT _p0_,sens,xref,typ,xentr,xsens,notes FROM xref WHERE entr=entrid);
	INSERT INTO xref(entr,sens,xref,typ,xentr,xsens,notes) 
	  (SELECT entr,sens,xref,typ,_p0_,xsens,notes FROM xref WHERE xentr=entrid);
	INSERT INTO xresolv(entr,sens,typ,ord,typ,rtxt,ktxt,tsens,notes,prio) 
	  (SELECT _p0_,sens,typ,ord,typ,rtxt,ktxt,tsens,notes,prio FROM xresolv WHERE entr=entrid);

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

CREATE OR REPLACE FUNCTION get_subtree (eid INT) RETURNS SETOF entr AS $$
    -- Return the set of entr rows that reference the row with id
    -- 'eid' via 'dfrm', and all the row that reference those rows
    -- and so on.  This function will terminate even if there are
    -- 'dfrm' cycles.
    BEGIN
	RETURN QUERY
	    WITH RECURSIVE wt(id) AS (
                SELECT id FROM entr WHERE id=eid
                UNION
                SELECT entr.id
                FROM wt, entr WHERE wt.id=entr.dfrm)
	    SELECT entr.*
	    FROM wt
	    JOIN entr ON entr.id=wt.id;
	RETURN;
    END; $$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION get_edroot (eid INT) RETURNS SETOF int AS $$
    -- Starting at entry 'eid', follow the chain of 'dfrm' foreign
    -- keys until a entr row is found that has a NULL 'dfrm' value,
    -- and return that row (which may be the row with id of 'eid').
    -- If there is no row with an id of 'eid', or if there is a cycle
    -- in the dfrm references such that none of entries have a NULL
    -- dfrm, no rows are returned. 
    BEGIN
	RETURN QUERY
	    WITH RECURSIVE wt(id,dfrm) AS (
                SELECT id,dfrm FROM entr WHERE id=eid
                UNION
                SELECT entr.id,entr.dfrm
                FROM wt, entr WHERE wt.dfrm=entr.id)
	    SELECT id FROM wt WHERE dfrm IS NULL;
	RETURN;
    END; $$ LANGUAGE 'plpgsql';

CREATE OR REPLACE VIEW vsnd AS (
    SELECT snd.id, snd.strt, snd.leng, 
	sndfile.loc AS sfile, sndvol.loc AS sdir, 
	sndvol.type=2 AS iscd, sndvol.id AS sdid, snd.trns
    FROM sndvol 
    JOIN sndfile ON sndvol.id = sndfile.vol
    JOIN snd ON sndfile.id = snd.file);

COMMIT;
