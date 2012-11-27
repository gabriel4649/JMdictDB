-- Descr: IS-197 (Exp. sense IDs): Add 'ord' column to table 'sens'.
-- Trans: 9->1001

\set ON_ERROR_STOP
BEGIN;

ALTER TABLE sens ADD COLUMN ord SMALLINT;
UPDATE sens SET ord=sens;
ALTER TABLE sens ALTER COLUMN ord SET NOT NULL;

INSERT INTO dbpatch(level) VALUES(1001);
COMMIT;

