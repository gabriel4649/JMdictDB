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
CREATE VIEW entr_summary AS (
    SELECT e.id,e.seq,
	(SELECT ARRAY_TO_STRING(ACCUM(sr.txt), '; ') 
	 FROM (SELECT r.txt FROM rdng r WHERE r.entr=e.id ORDER BY r.ord) AS sr) AS rdng,
	(SELECT ARRAY_TO_STRING(ACCUM(sk.txt), '; ')
	 FROM (SELECT k.txt FROM kanj k WHERE k.entr=e.id ORDER BY k.ord) AS sk) AS kanj,
	(SELECT ARRAY_TO_STRING(ACCUM( ss.gtxt ), ' / ') 
	 FROM 
	    (SELECT 
		(SELECT ARRAY_TO_STRING(ACCUM(sg.txt), '; ') 
		FROM (SELECT txt FROM gloss g WHERE g.sens=s.id ORDER BY g.ord) AS sg
		ORDER BY entr,ord) AS gtxt
	    FROM sens s WHERE s.entr=e.id ORDER BY s.ord) AS ss) AS gloss
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
	r.id AS rid,r.txt AS rtxt,k.id AS kid,k.txt AS ktxt,
	CASE WHEN z.kanj IS NOT NULL THEN 'X' END AS valid
    FROM ((entr e
    LEFT JOIN rdng r ON r.entr=e.id)
    LEFT JOIN kanj k ON k.entr=e.id)
    LEFT JOIN restr z ON r.id=z.rdng AND k.id=z.kanj);

------------------------------------------------------------
-- List all readings that should be marked "re_nokanji" 
-- in jmdict.xml.
------------------------------------------------------------
CREATE VIEW re_nokanji AS (
    SELECT e.id AS id,e.seq AS seq,r.id AS rid,r.txt AS rtxt
    FROM rdng r 
    JOIN entr e ON e.id=r.entr
    WHERE 
	r.id IN (SELECT z.rdng FROM restr z)
	AND (SELECT COUNT(*) FROM restr x WHERE x.rdng=r.id)
	  = (SELECT COUNT(*) FROM kanj k WHERE k.entr=e.id));

-------------------------------------------------------------
-- For every reading in every entry, provide only the valid 
-- kanji as determined by restr if applicable, and taking 
-- the jmdict's re_nokanji information into account. 
-------------------------------------------------------------
CREATE VIEW rk_valid AS (
  SELECT e.id, e.seq, r.id AS rid, r.txt AS rtxt, 
	sub.kid AS kid, sub.ktxt AS ktxt
    FROM entr e
      JOIN rdng r ON r.entr=e.id
      LEFT JOIN (
        SELECT e.id AS eid, r.id AS rid, k.id AS kid, k.txt AS ktxt
          FROM entr e
          JOIN rdng r ON r.entr=e.id
            LEFT JOIN kanj k ON k.entr=r.entr
            LEFT JOIN restr z ON z.rdng=r.id AND z.kanj=k.id
          WHERE z.rdng IS NULL
        ) AS sub ON sub.rid=r.id AND sub.eid=e.id);

-------------------------------------------------------------
-- For each xref, provide a summary of the entry that the
-- xref.xref column points to.  xsumr is the same except  
-- that the summary is for the entry pointed to by xref.sens 
-- (the reverse direction).  The columns xref and sens are
-- excluded from the select lists of xsum and xsumr respectively,
-- because we want only one row per entry, not one per sense.
-- This is a temporary hack that mimics the jmdict xml file's
-- sense->entry cross reference semantics.
-------------------------------------------------------------
CREATE VIEW xsum AS (
  SELECT DISTINCT x.sens,x.typ,x.notes,e.id AS eid,e.seq,e.kanj,e.rdng
    FROM xref x
    JOIN sens s ON s.id=x.xref
    JOIN entr_summary e ON e.id=s.entr);

CREATE VIEW xsumr AS (
  SELECT DISTINCT x.xref,x.typ,x.notes,e.id AS eid,e.seq,e.kanj,e.rdng
    FROM xref x
    JOIN sens s ON s.id=x.sens
    JOIN entr_summary e ON e.id=s.entr);

-------------------------------------------------------------
-- Provide a view of table "kanj" with additional column
-- that is <logical true> if the kanji would be marked as
-- "P" in edict.  According to 
--    http://www.csse.monash.edu.au/~jwb/edict_doc.html#IREF05
-- the "P" kanji are those tagged with "ichi1", "gai1",
-- "jdd1", "spec1", or "news1" (= "nf01"-"nf24") in JMdict.
-------------------------------------------------------------
CREATE VIEW pkanj AS (
    SELECT k.*, exists (
        SELECT * FROM kfreq f
          WHERE f.kanj=k.id AND
          -- ichi1, gai1, jdd1, spec1
          ((f.kw IN (1,2,3,4) AND f.value=1) 
          -- news1
          OR (f.kw=5 AND f.value<=24))) AS p 
    FROM kanj k);

-------------------------------------------------------------
-- Provide a view of table "rdng" with additional column
-- that is <logical true> if the reading would be marked as
-- "P" in edict.  According to 
--    http://www.csse.monash.edu.au/~jwb/edict_doc.html#IREF05
-- the "P" readings are those tagged with "ichi1", "gai1",
-- "jdd1", "spec1", or "news1" (= "nf01"-"nf24") in JMdict.
-------------------------------------------------------------
CREATE VIEW prdng AS (
    SELECT r.*, exists (
        SELECT * FROM rfreq f
          WHERE f.rdng=r.id AND
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
	    INSERT INTO kanj(entr,ord,txt) VALUES(_p0_,rec.ord,rec.txt);
	    SELECT lastval() INTO _p1_;
	    INSERT INTO kinf(kanj,kw) 
	      (SELECT _p1_,kw FROM kinf WHERE kinf.kanj=rec.id);
	    INSERT INTO kfreq(kanj,kw,value) 
	      (SELECT _p1_,kw,value FROM kfreq WHERE kfreq.kanj=rec.id);
	    END LOOP;
	FOR rec IN (SELECT * FROM rdng WHERE entr=entrid) LOOP
	    INSERT INTO rdng(entr,ord,txt) VALUES(_p0_,rec.ord,rec.txt);
	    SELECT lastval() INTO _p1_;
	    INSERT INTO rinf(rdng,kw) 
	      (SELECT _p1_,kw FROM rinf WHERE rinf.rdng=rec.id);
	    INSERT INTO rfreq(rdng,kw,value) 
	      (SELECT _p1_,kw,value FROM rfreq WHERE rfreq.rdng=rec.id);
	    INSERT INTO audio(rdng,fname,strt,leng) 
	      (SELECT _p1_,fname,strt,leng FROM audio WHERE audio.rdng=rec.id);
	    END LOOP;
	FOR rec IN (SELECT * FROM sens WHERE entr=entrid) LOOP
	    INSERT INTO sens(entr,ord,notes) VALUES(_p0_,rec.ord,rec.notes);
	    SELECT lastval() INTO _p1_;

	    INSERT INTO pos(sens,kw) 
	      (SELECT _p1_,kw FROM pos WHERE pos.sens=rec.id);
	    INSERT INTO misc(sens,kw) 
	      (SELECT _p1_,kw FROM misc WHERE misc.sens=rec.id);
	    INSERT INTO fld(sens,kw) 
	      (SELECT _p1_,kw FROM fld WHERE fld.sens=rec.id);
	    INSERT INTO gloss(sens,ord,lang,txt,notes) 
	      (SELECT _p1_,ord,lang,txt,notes FROM gloss WHERE sens=rec.id);
	    INSERT INTO xref(sens,xref,typ,notes) 
	      (SELECT _p1_,xref,typ,notes FROM xref WHERE xref.sens=rec.id);
	    INSERT INTO xref(sens,xref,typ,notes) 
	      (SELECT sens,_p1_,typ,notes FROM xref WHERE xref.xref=rec.id);
	    END LOOP;

	-- Duplicate the restrictions.  To match up the old and new rdng
	-- kanj, and sens rows, we rely on the "ord" column which means the 
	-- rdng, kanj, and sens ord columns must be unique (have a unique 
	-- index) within an entry.

	INSERT INTO restr(rdng,kanj)
	  (SELECT rn.id,kn.id FROM restr z 
	      JOIN rdng ro ON z.rdng=ro.id 
	      JOIN rdng rn ON rn.ord=ro.ord
	      JOIN kanj ko ON ko.id=z.kanj
	      JOIN kanj kn ON kn.ord=ko.ord
	      WHERE ro.entr=entrid AND rn.entr=_p0_ AND kn.entr=_p0_);

	INSERT INTO stagr(sens,rdng)
	  (SELECT sn.id,rn.id FROM stagr z 
	      JOIN sens so ON z.sens=so.id 
	      JOIN sens sn ON sn.ord=so.ord
	      JOIN rdng ro ON ro.id=z.rdng
	      JOIN rdng rn ON rn.ord=ro.ord
	      WHERE so.entr=entrid AND sn.entr=_p0_ AND rn.entr=_p0_);

	INSERT INTO stagk(sens,kanj)
	  (SELECT sn.id,kn.id FROM stagk z 
	      JOIN sens so ON z.sens=so.id 
	      JOIN sens sn ON sn.ord=so.ord
	      JOIN kanj ko ON ko.id=z.kanj
	      JOIN kanj kn ON kn.ord=ko.ord
	      WHERE so.entr=entrid AND sn.entr=_p0_ AND kn.entr=_p0_);

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


