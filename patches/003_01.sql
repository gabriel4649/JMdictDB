-- This patch will change the type of column entr.seq 
-- from INT to BIGINT in order to support new synthetic
-- Tatoeba sequence numbers. See IS-192 for more details.
 
\set ON_ERROR_STOP 
BEGIN;

ALTER TABLE entr ADD COLUMN seq2 BIGINT;
UPDATE entr SET seq2=seq;
ALTER TABLE entr DROP COLUMN seq CASCADE;
ALTER TABLE entr RENAME seq2 TO seq;

-- Recreate the views dropped as a result of dropping the 
-- "seq" column above with CASCADE.

CREATE OR REPLACE VIEW hdwds AS (
    SELECT e.*,r.txt AS rtxt,k.txt AS ktxt
    FROM entr e
    LEFT JOIN rdng r ON r.entr=e.id
    LEFT JOIN kanj k ON k.entr=e.id
    WHERE (r.rdng=1 OR r.rdng IS NULL)
      AND (k.kanj=1 OR k.kanj IS NULL));

CREATE VIEW is_p AS (
    SELECT e.*,
	    EXISTS (
		SELECT * FROM freq f
       		WHERE f.entr=e.id AND
		  -- ichi1, gai1, jdd1, spec1
		  ((f.kw IN (1,2,3,4) AND f.value=1)))
	    AS p
    FROM entr e);

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

CREATE VIEW item_cnts AS (
    SELECT 
	e.id,e.seq,
	(SELECT COUNT(*) FROM rdng r WHERE r.entr=e.id) as nrdng,
	(SELECT COUNT(*) FROM kanj k WHERE k.entr=e.id) as nkanj,
	(SELECT COUNT(*) FROM sens s WHERE s.entr=e.id) as nsens
    FROM entr e);

CREATE VIEW rk_validity AS (
    SELECT e.id AS id,e.seq AS seq,
	r.rdng AS rdng,r.txt AS rtxt,k.kanj AS kanj,k.txt AS ktxt,
	CASE WHEN z.kanj IS NOT NULL THEN 'X' END AS valid
    FROM ((entr e
    LEFT JOIN rdng r ON r.entr=e.id)
    LEFT JOIN kanj k ON k.entr=e.id)
    LEFT JOIN restr z ON z.entr=e.id AND r.rdng=z.rdng AND k.kanj=z.kanj);

CREATE VIEW re_nokanji AS (
    SELECT e.id,e.seq,r.rdng,r.txt
    FROM entr e 
    JOIN rdng r ON r.entr=e.id 
    JOIN restr z ON z.entr=r.entr AND z.rdng=r.rdng
    GROUP BY e.id,e.seq,r.rdng,r.txt
    HAVING COUNT(z.kanj)=(SELECT COUNT(*) FROM kanj k WHERE k.entr=e.id));

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

-- Following function also requires update due to datatype change...

CREATE OR REPLACE FUNCTION syncseq() RETURNS VOID AS $syncseq$
    -- Syncronises all the sequences specified in table 'kwsrc'
    -- (which are used for generation of corpus specific seq numbers.)
    DECLARE cur REFCURSOR; seqname VARCHAR; maxseq BIGINT;
    BEGIN
	-- The following cursor gets the max value of entr.seq for each corpus
	-- for entr.seq values within the range of the associated seq (where
	-- the range is what was given in kwsrc table .smin and .smax values.  
	-- [Don't confuse kwsrc.seq (name of the Postgresq1 sequence that
	-- generates values used for entry seq numbers) with entr.seq (the
	-- entry sequence numbers themselves).]  Since the kwsrc.smin and
	-- .smax values can be changed after the sequence was created, and
	-- doing so may screwup the operation herein, don't do that!  It is 
	-- also possible that multiple kwsrc's can share a common 'seq' value,
	-- but have different 'smin' and 'smax' values -- again, don't do that!
	-- The rather elaborate join below is done to make sure we get a row
	-- for every kwsrc.seq value, even if there are no entries that
	-- reference that kwsrc row. 

	OPEN cur FOR 
	    SELECT ks.sqname, COALESCE(ke.mxseq,ks.smin,1) 
	    FROM 
		(SELECT seq AS sqname, MIN(smin) AS smin
		FROM kwsrc 
		GROUP BY seq) AS ks
	    LEFT JOIN	-- Find the max entr.seq number in use, but ignoring
			-- any that are autside the min/max bounds of the kwsrc's
			-- sequence.
		(SELECT k.seq AS sqname, MAX(e.seq) AS mxseq
		FROM entr e 
		JOIN kwsrc k ON k.id=e.src 
		WHERE e.seq BETWEEN COALESCE(k.smin,1)
		    AND COALESCE(k.smax,9223372036854775807)
		GROUP BY k.seq,k.smin) AS ke 
	    ON ke.sqname=ks.sqname;
	LOOP
	    FETCH cur INTO seqname, maxseq;
	    EXIT WHEN NOT FOUND;
	    EXECUTE 'SELECT setval(''' || seqname || ''', ' || maxseq || ')';
	    END LOOP;
	END;
    $syncseq$ LANGUAGE plpgsql;

COMMIT;
