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
CREATE VIEW is_p AS (
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
-- and sense/gloss.  Each of those columns values has the
-- text from each child item concatenated into a single
-- string with items delimited by "; "s.  For the sense
-- column, each aggregated gloss string in contatented
-- with the delimiter " / ".
------------------------------------------------------------
CREATE OR REPLACE VIEW esum AS (
    SELECT e.id,e.seq,e.stat,e.src,e.dfrm,e.unap,e.notes,e.srcnote,h.rtxt AS rdng,h.ktxt AS kanj,
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
	(SELECT COUNT(*) FROM sens WHERE sens.entr=e.id) AS nsens,
	(SELECT p FROM is_p WHERE is_p.id=e.id) AS p
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
CREATE VIEW pkfreq AS (
    SELECT k.*, EXISTS (
        SELECT * FROM freq f
          WHERE f.entr=k.entr AND f.kanj=k.kanj AND
            -- ichi1, gai1, jdd1, spec1
            ((f.kw IN (1,2,3,4) AND f.value=1))) AS p 
    FROM kanj k);
 
CREATE VIEW prfreq AS (
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

-------------------------------------------------------------
-- Following two functions deal with finding the edit set
-- (i.e. entries linked to an entry through entr.dfrm, either
-- directly or indirectly).  They are not intended for
-- external use but are used interally by the 'find_*' 
-- functions that follow below.
-------------------------------------------------------------
CREATE OR REPLACE FUNCTION children (tblname TEXT) RETURNS VOID AS $$
    DECLARE
	level INT := 0; rowcount INT;
    BEGIN
	LOOP
	    EXECUTE 'INSERT INTO '||tblname||'(id,root,dfrm,lvl) (
	        SELECT e.id,t.root,e.dfrm,t.lvl+1 FROM entr e JOIN '||tblname||' t ON e.dfrm=t.id WHERE t.lvl='||level||')';
	    GET DIAGNOSTICS rowcount = ROW_COUNT;
	    --raise notice 'rowcount=%, level=%', rowcount, level;
	    EXIT WHEN rowcount = 0;
	    IF level>=99 THEN RAISE EXCEPTION 'Iteration limit exceeded'; END IF;
	    level := level + 1;
	    END LOOP;
	RETURN;
    END; $$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION childrentbl (eid INT,tblname TEXT) RETURNS TEXT AS $$
    -- Create a temporary table named 'tblname' populated with
    -- information about entry 'eid' and all it's children (i.e.
    -- entries linked by directly or recursively though column
    -- 'dfrm').  Each row represents an entry and has the following
    -- attributes:
    --
    --    id:   Id number of entry.
    --    root: Id number of entry at tree root, i.e. 'eid'.
    --    dfrm: 'dfrm' value of entry.
    --    lvl:  Distance (in number 'dfrm' links) of entry from root.

    DECLARE
	tbl TEXT;
    BEGIN
	IF tblname IS NULL THEN tbl:='_tmpchld'; ELSE tbl:=tblname; END IF;
	EXECUTE 'DROP TABLE IF EXISTS '||tbl;
	EXECUTE 'CREATE TEMPORARY TABLE '||tbl||'(id INT, root INT, dfrm INT, lvl INT)';
	EXECUTE 'INSERT INTO '||tbl||'(id,root,dfrm,lvl) '||
		 '(SELECT id,id,dfrm,0 FROM entr WHERE id='||eid||')';
	PERFORM children (tbl);
	RETURN tbl;
    END; $$ LANGUAGE 'plpgsql';

CREATE TYPE editset AS (id INT, root INT, dfrm INT, lvl INT);
  -- A type matching the tmptbl structure above, useful as a return 
  -- type for functions that return tmptbl rows.

-------------------------------------------------------------
-- The following functions (with names prefixed with "find_")
-- are used for getting information about the "edit set" for
-- a given entry.  An "edit set" is a set of entries (or
-- alternately rows in table 'entr') that are linked (possibly
-- recursively) though attribute 'dfrm'.  The 'dfrm' attribute
-- organizes the rows in the set as a tree, rooted at the given
-- entry.
-------------------------------------------------------------

CREATE OR REPLACE FUNCTION find_edit_set (eid INT) RETURNS SETOF editset AS $$
    -- Return the full edit set that contains 'eid'.  
    -- Each row in the edit set identifies a row in table 'entr' that
    -- is linked (directly or indirectly) to other rows in the set via
    -- the .dfrm attribute, and organised as a tree.  The returned rows
    -- are of type "editset" defined above as:
    --    id INT,   -- Id number of entry.
    --    root INT, -- Id number of entry at tree root.
    --    dfrm INT, -- 'dfrm' value of entry.  Will be NULL for the root row.
    --    lvl INT); -- Distance (in number 'dfrm' links) of entry from root.

    DECLARE rootentr entr%ROWTYPE; tmptbl TEXT := '_tmpchld'; r editset%ROWTYPE; 
    BEGIN
	rootentr := find_edit_root (eid);
	IF rootentr.id IS NOT NULL THEN
	    PERFORM childrentbl (rootentr.id, tmptbl);
	    -- Following doesn't work...
	    --EXECUTE 'RETURN QUERY SELECT id,root,dfrm,lvl FROM '||tmptbl;
	    -- So use an explicit loop instead...
	    FOR r IN EXECUTE 'SELECT id,root,dfrm,lvl FROM '||tmptbl LOOP
		RETURN NEXT r;
		END LOOP;
	    EXECUTE 'DROP TABLE '||tmptbl;
	    END IF;
	RETURN;
    END; $$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION find_edit_leaves (eid INT) RETURNS SETOF entr AS $$
    -- Starting at entry 'eid', find and return the set of entries
    -- linked (recursively) to entry 'eid' though foreign key 'dfrm'
    -- that have no other entries referencing them.  That is, viewing
    -- the set of entr rows linked by 'dfrm' as a tree rooted at 'eid',
    -- thr entr rows returned by this function are the "leaf" nodes
    -- of the tree.

    DECLARE r RECORD; tmptbl TEXT := '_tmpchld';
    BEGIN
	PERFORM childrentbl (eid, tmptbl);
	FOR r IN EXECUTE 
		'SELECT e.* FROM entr e JOIN '||tmptbl||' x ON x.id=e.id '|| 
		'WHERE NOT EXISTS (SELECT * FROM entr e2 WHERE e2.dfrm=x.id)' LOOP
	    RETURN NEXT r;
	    END LOOP;
	EXECUTE 'DROP TABLE '||tmptbl;
	RETURN;
    END; $$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION find_edit_root (eid INT) RETURNS entr AS $$
    -- Starting at entry 'eid', follow the chain of 'dfrm' foreign
    -- keys until a entr row is found that has a NULL 'dfrm' value,
    -- and return that row (which may be the row with id of 'eid').
    -- If there is no row with an id of 'eid', a NULL row (one with
    -- every attribute set to NULL) is returned. 

    DECLARE r entr%ROWTYPE; dfrm INT := eid;
    BEGIN
        LOOP
            SELECT INTO r e.* FROM entr e WHERE e.id=dfrm;
            EXIT WHEN NOT FOUND OR r.dfrm IS NULL;
	    dfrm := r.dfrm;
            END LOOP;
        RETURN r;
    END; $$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION find_chain_head (eid INT) RETURNS entr AS $$
    -- Starting at entry 'eid', follow the chain of 'dfrm' foreign
    -- keys until either:
    --   1. -- An entry is found with a NULL dfrm key.
    --   2. -- An entry is found that has more than one 'dfrm' entry
    --         referencing it.
    -- Returns the entr row of the entry immediately preceeding the
    -- found entry above.  If there is no such preceeding row, we
    -- return a row with every attribute set to NULL.

    DECLARE r entr%ROWTYPE; p entr%ROWTYPE;
    BEGIN
        r.id := -1;
        r.dfrm := eid;
        LOOP
            SELECT INTO r e.* FROM entr e 
              WHERE e.id=r.dfrm AND NOT EXISTS 
                (SELECT * FROM entr e2 WHERE e2.dfrm=e.id AND e2.id!=r.id);
            EXIT WHEN NOT FOUND OR r.dfrm IS NULL;
	    p := r;
            END LOOP;
        RETURN p;
    END; $$ LANGUAGE 'plpgsql';

CREATE OR REPLACE VIEW vsnd AS (
    SELECT snd.id, snd.strt, snd.leng, 
	sndfile.loc AS sfile, sndvol.loc AS sdir, 
	sndvol.type=2 AS iscd, sndvol.id AS sdid, snd.trns
    FROM sndvol 
    JOIN sndfile ON sndvol.id = sndfile.vol
    JOIN snd ON sndfile.id = snd.file);

COMMIT;
