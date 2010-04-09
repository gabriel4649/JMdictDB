-- Run this file from a shell cd'd to the parent
-- directory of the directory this file is in
-- using a command like:
-- 
--    psql -f pg/load.sql -d postgres [-U username]
--
-- You may need to use additional arguments such
-- as '-U username' depending on exiting defaults.

\i mktables.sql
\i loadkw.sql
\i mkviews.sql
\i mkviews2.sql
\i mkperms.sql

