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
--  Copyright (c) 2006-2014 Stuart McGraw 
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
-- "gai1", "news1" or "spec<anything>" as documented at
--   http://www.csse.monash.edu.au/~jwb/edict_doc.html#IREF05
-- (That ref specifies only "spec1" but per IS-149, "spec2" 
-- is also included.)
-- See also views pkfreq and prfreq below.
-------------------------------------------------------------
CREATE OR REPLACE VIEW is_p AS (
    SELECT e.*,
        EXISTS (
            SELECT * FROM freq f
            WHERE f.entr=e.id
              -- ichi1, gai1, news1, or specX
              AND ((f.kw IN (1,2,7) AND f.value=1)
                OR f.kw=4)) AS p
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


--==============================================================
--  The following views were originally in mkviews2.sql
--==============================================================
--
-- This file creates a number of view that summerize a set of 
-- related rows as a single text string in one row.  The all
-- have names starting with "vt_".
--
-- This script requires the server to have the setting
--
--   standard_conforming_strings
--
-- set to "on" (due to the use of Unicode code-point constants.
--
----------------------------------------------------------------

\set ON_ERROR_STOP 
SET standard_conforming_strings = ON;

----------------------------------------------------------------
-- kinf: comma separated list of kinf tags.
-- Key: entr, kanj.

CREATE OR REPLACE VIEW vt_kinf AS (
    SELECT k.entr,k.kanj,
       (SELECT ARRAY_TO_STRING(ARRAY_AGG(k2.txt), ',') 
        FROM (
	    SELECT kw.kw AS txt 
	    FROM kinf k3 
	    JOIN kwkinf kw ON kw.id=k3.kw
	    WHERE k3.entr=k.entr and k3.kanj=k.kanj
	    ORDER BY k3.ord) AS k2
        ) AS kitxt
    FROM 
	(SELECT DISTINCT entr,kanj FROM kanj) as k);

----------------------------------------------------------------
-- rinf: comma separated list of rinf tags.
-- Key: entr, rdng.

CREATE OR REPLACE VIEW vt_rinf AS (
    SELECT r.entr,r.rdng,
       (SELECT ARRAY_TO_STRING(ARRAY_AGG(r2.txt), ',') 
        FROM (
	    SELECT kw.kw AS txt 
	    FROM rinf r3 
	    JOIN kwrinf kw ON kw.id=r3.kw
	    WHERE r3.entr=r.entr and r3.rdng=r.rdng
	    ORDER BY r3.ord) AS r2
        ) AS ritxt
    FROM 
	(SELECT DISTINCT entr,rdng FROM rdng) as r);

----------------------------------------------------------------
-- kanj: kanj texts separated by "; ". 
-- Key: entr

CREATE OR REPLACE VIEW vt_kanj AS (
    SELECT k.entr,
       (SELECT ARRAY_TO_STRING(ARRAY_AGG(k2.txt), '; ') 
        FROM (
	    SELECT k3.txt 
	    FROM kanj k3 
	    WHERE k3.entr=k.entr 
	    ORDER BY k3.kanj) AS k2
        ) AS ktxt
    FROM 
	(SELECT DISTINCT entr FROM kanj) as k);

----------------------------------------------------------------
-- Kanji with kinf. 
-- Key: entr

CREATE OR REPLACE VIEW vt_kanj2 AS (
    SELECT k.entr,
       (SELECT ARRAY_TO_STRING(ARRAY_AGG(k2.txt), '; ') 
        FROM (
	    SELECT k3.txt 
		|| COALESCE('['||i.kitxt||']', '') AS txt
	    FROM kanj k3 
	    LEFT JOIN vt_kinf i ON i.entr=k3.entr AND i.kanj=k3.kanj
	    WHERE k3.entr=k.entr 
	    ORDER BY k3.kanj) AS k2
        ) AS ktxt
    FROM 
	(SELECT DISTINCT entr FROM kanj) as k);

----------------------------------------------------------------
-- Rdng: reading texts separated by "; ". 
-- Key: entr

CREATE OR REPLACE VIEW vt_rdng AS (
    SELECT r.entr,
       (SELECT ARRAY_TO_STRING(ARRAY_AGG(r2.txt), '; ') 
        FROM (
	    SELECT r3.txt 
	    FROM rdng r3 
	    WHERE r3.entr=r.entr 
	    ORDER BY r3.rdng) AS r2
        ) AS rtxt
    FROM 
	(SELECT DISTINCT entr FROM rdng) AS r);

----------------------------------------------------------------
-- Rdng: reading texts with rinf, separated by "; ". 
-- Key: entr

CREATE OR REPLACE VIEW vt_rdng2 AS (
    SELECT r.entr,
       (SELECT ARRAY_TO_STRING(ARRAY_AGG(r2.txt), '; ') 
        FROM (
	    SELECT r3.txt 
		|| COALESCE('['||i.ritxt||']', '') AS txt
	    FROM rdng r3 
	    LEFT JOIN vt_rinf i ON i.entr=r3.entr AND i.rdng=r3.rdng
	    WHERE r3.entr=r.entr 
	    ORDER BY r3.rdng) AS r2
        ) AS rtxt
    FROM 
	(SELECT DISTINCT entr FROM rdng) AS r);

----------------------------------------------------------------
-- Gloss: gloss texts separated with '; '.
-- Key: entr, sens

CREATE OR REPLACE VIEW vt_gloss AS (
    SELECT g.entr,g.sens,
       (SELECT ARRAY_TO_STRING(ARRAY_AGG(g2.txt), '; ') 
        FROM (
	    SELECT g3.txt 
	    FROM gloss g3 
	    WHERE g3.entr=g.entr and g3.sens=g.sens
	    ORDER BY g3.gloss) AS g2
        ) AS gtxt
    FROM 
	(SELECT DISTINCT entr,sens FROM gloss) as g);

----------------------------------------------------------------
-- Gloss: gloss texts prefixed with ginf tags (if not "equ"),
-- separated with '; '.
-- Key: entr, sens

CREATE OR REPLACE VIEW vt_gloss2 AS (
    SELECT g.entr,g.sens, 
        (SELECT ARRAY_TO_STRING(ARRAY_AGG(g2.txt), '; ') 
        FROM (
	    SELECT CASE g3.ginf
		WHEN 1 THEN ''
		ELSE COALESCE('['||kw.kw||'] ','') END || g3.txt AS txt
	    FROM gloss g3 
	    JOIN kwginf kw ON kw.id=g3.ginf
	    WHERE g3.entr=g.entr and g3.sens=g.sens
	    ORDER BY g3.gloss) AS g2
        ) AS gtxt
    FROM 
	(SELECT DISTINCT entr,sens FROM gloss) as g);

----------------------------------------------------------------
-- Pos: comma separated list of pos tags.
-- Key: entr, sens.

CREATE OR REPLACE VIEW vt_pos AS (
    SELECT p.entr,p.sens,
       (SELECT ARRAY_TO_STRING(ARRAY_AGG(p2.txt), ',') 
        FROM (
	    SELECT kw.kw AS txt 
	    FROM pos p3 
	    JOIN kwpos kw ON kw.id=p3.kw
	    WHERE p3.entr=p.entr and p3.sens=p.sens
	    ORDER BY p3.ord) AS p2
        ) AS ptxt
    FROM 
	(SELECT DISTINCT entr,sens FROM pos) as p);

----------------------------------------------------------------
-- Misc: comma separated list of misc tags.
-- Key: entr, sens.

CREATE OR REPLACE VIEW vt_misc AS (
    SELECT m.entr,m.sens,
       (SELECT ARRAY_TO_STRING(ARRAY_AGG(m2.txt), ',') 
        FROM (
	    SELECT kw.kw AS txt 
	    FROM misc m3 
	    JOIN kwmisc kw ON kw.id=m3.kw
	    WHERE m3.entr=m.entr and m3.sens=m.sens
	    ORDER BY m3.ord) AS m2
        ) AS mtxt
    FROM 
	(SELECT DISTINCT entr,sens FROM misc) as m);

----------------------------------------------------------------
-- Sense: Plain (';'-separated gloss strings from vt_gloss),
-- separated by ' / '.
-- Key: entr.

CREATE OR REPLACE VIEW vt_sens AS (
    SELECT s.entr,
       (SELECT ARRAY_TO_STRING(ARRAY_AGG(g2.txt), ' / ') 
        FROM (
	    SELECT g3.gtxt AS txt 
	    FROM vt_gloss g3 
	    WHERE g3.entr=s.entr
	    ORDER BY g3.entr,g3.sens) AS g2
        ) AS stxt
    FROM 
	(SELECT DISTINCT entr FROM sens) as s);

----------------------------------------------------------------
-- Sense: Plain (';'-separated gloss strings from vt_gloss)
-- with sense note, separated by ' / '.
-- Key: entr.

CREATE OR REPLACE VIEW vt_sens2 AS (
    SELECT s.entr,
       (SELECT ARRAY_TO_STRING(ARRAY_AGG(g2.txt), ' / ') 
        FROM (
	    SELECT g3.gtxt AS txt
	    FROM vt_gloss g3 
	    WHERE g3.entr=s.entr
	    ORDER BY g3.entr,g3.sens) AS g2
	    -- U&'\300A' and U&'\300B' are open and close double angle brackets.
        ) || coalesce ((U&' \300A'||s.notes||U&'\300B'), '') AS stxt
    FROM 
	(SELECT DISTINCT entr,notes FROM sens) as s);

----------------------------------------------------------------
-- Sense: ginf-tagged gloss strings (from vt_gloss3) with sense
-- note, separated by ' / '.
-- Key: entr.

CREATE OR REPLACE VIEW vt_sens3 AS (
    SELECT s.entr,
       (SELECT ARRAY_TO_STRING(ARRAY_AGG(g2.txt), ' / ') 
        FROM (
	    SELECT
		COALESCE('['||p.ptxt||']','') || 
		COALESCE('['||m.mtxt||']','') ||
		CASE WHEN p.ptxt IS NULL AND m.mtxt IS NULL THEN ''
		     ELSE ' ' END || 
		g3.gtxt AS txt
	    FROM vt_gloss2 g3 
	    LEFT JOIN vt_pos  p ON p.entr=g3.entr AND p.sens=g3.sens
	    LEFT JOIN vt_misc m ON m.entr=g3.entr AND m.sens=g3.sens
	    WHERE g3.entr=s.entr
	    ORDER BY g3.entr,g3.sens) AS g2
	    -- U&'\300A' and U&'\300B' are open and close double angle brackets.
        ) || coalesce ((U&' \300A'||s.notes||U&'\300B'), '') AS stxt
    FROM 
	(SELECT DISTINCT entr,notes FROM sens) as s);

-----------------------------------------------------------
-- Summarize each entry (one per row) with readings, kanji, 
-- and sense/gloss column.  

CREATE OR REPLACE VIEW vt_entr AS (
    SELECT e.*,
	r.rtxt,
	k.ktxt,
	s.stxt,
	(SELECT COUNT(*) FROM sens WHERE sens.entr=e.id) AS nsens,
	(SELECT p FROM is_p WHERE is_p.id=e.id) AS p
    FROM entr e
    LEFT JOIN vt_rdng r ON r.entr=e.id
    LEFT JOIN vt_kanj k ON k.entr=e.id
    LEFT JOIN vt_sens s ON s.entr=e.id);

-----------------------------------------------------------
-- Summarize each entry (one per row) with readings, kanji, 
-- and sense/gloss columns.  Reading and kanji include inf
-- tags, 

CREATE OR REPLACE VIEW vt_entr3 AS (
    SELECT e.*,
	r.rtxt,
	k.ktxt,
	s.stxt,
	(SELECT COUNT(*) FROM sens WHERE sens.entr=e.id) AS nsens,
	(SELECT p FROM is_p WHERE is_p.id=e.id) AS p
    FROM entr e
    LEFT JOIN vt_rdng2 r ON r.entr=e.id
    LEFT JOIN vt_kanj2 k ON k.entr=e.id
    LEFT JOIN vt_sens3 s ON s.entr=e.id);

--==============================================================
--  The following views were originally in conj.sql
--==============================================================
--
-- Views for word conjugations.

DROP VIEW IF EXISTS vconotes, vinflxt, vinflxt_, vinfl, vconj, vcpos CASCADE;

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

COMMIT;
