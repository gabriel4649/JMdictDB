-- Descr: IS-192 Change entr.seq from int to bigint.
-- Trans: 2->3
--
-- IMPORTANT: run patchdb.py from the top (jmdictdb) directory.
--
-- This patch will change the type of column entr.seq 
-- from INT to BIGINT in order to support new synthetic
-- Tatoeba sequence numbers. See IS-192 for more details.

\set ON_ERROR_STOP 
BEGIN;

-- mkviews.sql
DROP VIEW IF EXISTS hdwds CASCADE;
DROP VIEW IF EXISTS is_p CASCADE;
DROP VIEW IF EXISTS esum CASCADE;
DROP VIEW IF EXISTS ssum CASCADE;
DROP VIEW IF EXISTS essum CASCADE;
DROP VIEW IF EXISTS item_cnts CASCADE;
DROP VIEW IF EXISTS rk_validity CASCADE;
DROP VIEW IF EXISTS re_nokanji CASCADE;
DROP VIEW IF EXISTS rk_valid CASCADE;
DROP VIEW IF EXISTS sr_valid CASCADE;
DROP VIEW IF EXISTS sk_valid CASCADE;
DROP VIEW IF EXISTS xrefhw CASCADE;
DROP VIEW IF EXISTS pkfreq CASCADE;
DROP VIEW IF EXISTS prfreq CASCADE;
DROP FUNCTION IF EXISTS dupentr(INT);
DROP FUNCTION IF EXISTS delentr(INT);
DROP FUNCTION IF EXISTS get_subtree (INT);
DROP FUNCTION IF EXISTS get_edroot (INT);
DROP VIEW IF EXISTS vsnd CASCADE;

-- mkviews2.sql
DROP VIEW IF EXISTS vt_kinf CASCADE;
DROP VIEW IF EXISTS vt_rinf CASCADE;
DROP VIEW IF EXISTS vt_kanj CASCADE;
DROP VIEW IF EXISTS vt_kanj2 CASCADE;
DROP VIEW IF EXISTS vt_rdng CASCADE;
DROP VIEW IF EXISTS vt_rdng2 CASCADE;
DROP VIEW IF EXISTS vt_gloss CASCADE;
DROP VIEW IF EXISTS vt_gloss2 CASCADE;
DROP VIEW IF EXISTS vt_pos CASCADE;
DROP VIEW IF EXISTS vt_misc CASCADE;
DROP VIEW IF EXISTS vt_sens CASCADE;
DROP VIEW IF EXISTS vt_sens2 CASCADE;
DROP VIEW IF EXISTS vt_sens3 CASCADE;
DROP VIEW IF EXISTS vt_entr CASCADE;
DROP VIEW IF EXISTS vt_entr3 CASCADE;

ALTER TABLE entr ALTER COLUMN seq TYPE BIGINT;
ALTER TABLE kwsrc ALTER COLUMN smin TYPE BIGINT;
ALTER TABLE kwsrc ALTER COLUMN smax TYPE BIGINT;

-- Following is copy/paste from pg/mktables.sql.
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

\i pg/mkviews.sql
\i pg/mkviews.sql

COMMIT;

-- Now run mkviews.sql and mkviews2.sql to recreate all the
-- views dropped above.
