-- Descr: Add support for word conjugations.
-- Trans: 9->10

\set ON_ERROR_STOP
BEGIN;

\i pg/loadconj.sql

INSERT INTO dbpatch(level) VALUES(10);
COMMIT;
