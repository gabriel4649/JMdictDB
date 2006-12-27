-- 
--    psql -f postload.sql [-d jmdict] [-U username]
--
-- You may need to use additional arguments such
-- as '-U username' depending on exiting defaults.

\set ON_ERROR_STOP 1
\c jmdict
\i mkindex.sql
\i mkfk.sql
\i mkviews.sql
\i xresolv.sql
\i mkperms.sql
vacuum analyze