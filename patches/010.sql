-- Descr: Add support for word conjugations.
-- Trans: 9->10

\set ON_ERROR_STOP
--BEGIN;  -- Note that because conj.sql and loadconj.sql have
          -- their own BEGIN and COMMIT statements, we can't 
          -- wrap them in our own enclosing transation since 
          -- pg doesn't support nested transactions.  If there 
          -- is an error, you'll need to manually fix things
          -- (delete the conj* tables and reset he patchlevel
          -- number back to 9 before you run this again.)

\encoding utf-8
\cd pg
\i conj.sql
\i loadconj.sql

INSERT INTO dbpatch(level) VALUES(10);
--COMMIT;
