-- Descr: Add support for database patch level.
-- Trans: 8->9

\set ON_ERROR_STOP
BEGIN;

CREATE TABLE dbpatch(
    level INT PRIMARY KEY,
    dt TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'utc'));

INSERT INTO dbpatch(level) VALUES(9);
COMMIT;
