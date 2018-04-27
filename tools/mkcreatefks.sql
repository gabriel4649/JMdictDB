-- Write out a list of SQL commands that will recreate the constaints 
--  and indexes that currently esist in the connected-to database.
--  See: http://blog.hagander.net/archives/131-Automatically-dropping-and-creating-constraints.html

\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only

SET search_path=public;

-- Write the constraints out before the indexes because "unique"
-- constraints will also result in a unique index, and we want to
-- create as a constraint.  The later occuring command to create
-- the corresponding unique index will fail with a "relation
-- 'xxxx_key' already exists" error which can be ignored.

-- FIXME: following is not right because post hgrev-20180418-d83617
-- the db "version" is the set of id# that are active=True, possibly
-- more than one. 
SELECT '-- This file was auto-generated at '||now()||', dbver '
    || (select id order by ts desc limit 1) ||'.' FROM dbx;

SELECT 'ALTER TABLE '||nspname||'.'||relname||' ADD CONSTRAINT '||conname||' '|| pg_get_constraintdef(pg_constraint.oid)||';'
    FROM pg_constraint
    INNER JOIN pg_class ON conrelid=pg_class.oid
    INNER JOIN pg_namespace ON pg_namespace.oid=pg_class.relnamespace
    ORDER BY CASE WHEN contype='f' THEN 0 ELSE 1 END DESC,contype DESC,nspname DESC,relname DESC,conname DESC;

SELECT pg_get_indexdef(pg_index.indexrelid)||';'
    FROM pg_index
    INNER JOIN pg_class ON indexrelid=pg_class.oid
    INNER JOIN pg_namespace ON pg_namespace.oid=pg_class.relnamespace
    WHERE indisprimary=FALSE and indisvalid=TRUE AND nspname NOT LIKE 'pg_%'
    ORDER BY nspname,relname; 



