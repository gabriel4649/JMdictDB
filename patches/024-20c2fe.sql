\set ON_ERROR_STOP
BEGIN;

\set dbversion  '''20c2fe'''  -- Update version applied by this update.
\set require    23            -- Database must be at this version in
                              --  order to apply this update.

-- Change the means of database version identification.
--   Add function "err".
--   Replace table "dbpatch" with table "db".
--   Add view for displaying "db" with id's in hexidecimal.
-- Instead of using small sequentially increasing integers as a version id,
-- we now use pseudo-random 6-digit hex numbers.  We also mark each version
-- row as active or inactive.  This allows application code to check if a 
-- particular set of features in available in addition to a base level data-
-- base version.

CREATE OR REPLACE FUNCTION err(msg TEXT) RETURNS boolean AS $body$
    BEGIN RAISE '%', msg; END;
    $body$ LANGUAGE plpgsql;

\qecho Checking database version...
-- If db is a post-23 version, there will be no dbpatch table, so create 
-- one so that the following check will fail with a meaningful message
-- rather than obscure one about missing table.  It will be removed when
-- transaction is rolled back.
CREATE TABLE IF NOT EXISTS dbpatch(level INT, dt TIMESTAMP);
SELECT CASE WHEN (:require=(SELECT MAX(level) FROM dbpatch)) THEN NULL 
    ELSE (SELECT err('Database at wrong update level, need version '||:require)) END;

CREATE TABLE db (
    id INT PRIMARY KEY,
    active BOOLEAN DEFAULT TRUE, 
    ts TIMESTAMP DEFAULT NOW());

CREATE OR REPLACE VIEW vdb AS (
    SELECT LPAD(TO_HEX(id),6,'0') AS id, active, ts
    FROM db 
    ORDER BY ts DESC);

INSERT INTO db (SELECT level,False,dt FROM dbpatch);
INSERT INTO db(id) VALUES(x:dbversion::INT);
DROP TABLE dbpatch;

COMMIT;
