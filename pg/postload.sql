-- 
--    psql -f postload.sql [-d jmdict] [-U username]
--
-- You may need to use additional arguments such
-- as '-U username' depending on exiting defaults.

\set ON_ERROR_STOP 1
\c jmdict
\i mkperms.sql
\i mkindex.sql
\i mkfk.sql
\i mkviews.sql
\i xresolv.sql
vacuum analyze