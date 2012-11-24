-- Descr: WARNING alters jbsess database! Change "sessions" table.
-- Trans: 0->1

\set ON_ERROR_STOP
\c jmsess 
BEGIN;

DELETE FROM sessions;
ALTER TABLE sessions ALTER COLUMN ts DROP DEFAULT;
ALTER TABLE sessions ALTER COLUMN ts TYPE TIMESTAMP 
  USING TIMESTAMP 'epoch' AT TIME ZONE 'utc' + ts * '1 second'::INTERVAL;
ALTER TABLE sessions ALTER COLUMN ts SET DEFAULT
  CURRENT_TIMESTAMP AT TIME ZONE 'UTC';

COMMIT;
