\set ON_ERROR_STOP 1
\c postgres
drop database jb;
create database jb encoding 'utf8';
\c jb
\i pg/schema.sql
\i pg/loadkw.sql

