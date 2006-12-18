-- Run this file from a shell cd'd to the parent
-- directory of the directory this file is in
-- using a command like:
-- 
--    psql -f pg/load.sql -d postgres [-U username]
--
-- You may need to use additional arguments such
-- as '-U username' depending on exiting defaults.

\c postgres
drop database jb;
\set ON_ERROR_STOP 1
create database jb encoding 'utf8';
\c jb
\i pg/schema.sql
\i pg/loadkw.sql

