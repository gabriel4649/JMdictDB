-- Patch for IS-184.
\set ON_ERROR_STOP 
BEGIN;

CREATE OR REPLACE FUNCTION get_subtree (eid INT) RETURNS SETOF entr AS $$
    -- Return the set of entr rows that reference the row with id
    -- 'eid' via 'dfrm', and all the row that reference those rows
    -- and...recursively.  Currently, if there is a cycle in the 
    -- dfrm references, this function will fail to terminate.
    -- FIXME: Detect cycles and abort.  
    BEGIN
	RETURN QUERY
	    WITH RECURSIVE wt(id) AS (
                SELECT id FROM entr WHERE id=eid
                UNION
                SELECT entr.id
                FROM wt, entr WHERE wt.id=entr.dfrm)
	    SELECT entr.*
	    FROM wt
	    JOIN entr ON entr.id=wt.id;
	RETURN;
    END; $$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION get_edroot (eid INT) RETURNS SETOF int AS $$
    -- Starting at entry 'eid', follow the chain of 'dfrm' foreign
    -- keys until a entr row is found that has a NULL 'dfrm' value,
    -- and return that row (which may be the row with id of 'eid').
    -- If there is no row with an id of 'eid', a NULL row (one with
    -- every attribute set to NULL) is returned. 
    BEGIN
	RETURN QUERY
	    WITH RECURSIVE wt(id,dfrm) AS (
                SELECT id,dfrm FROM entr WHERE id=eid
                UNION
                SELECT entr.id,entr.dfrm
                FROM wt, entr WHERE wt.dfrm=entr.id)
	    SELECT id FROM wt WHERE dfrm IS NULL;
	RETURN;
    END; $$ LANGUAGE 'plpgsql';

DROP FUNCTION find_chain_head(INT);
DROP FUNCTION find_edit_root(INT);
DROP FUNCTION find_edit_leaves(INT);
DROP FUNCTION find_edit_set(INT);
DROP TYPE editset;
DROP FUNCTION childrentbl(INT,TEXT);
DROP FUNCTION children(TEXT);

COMMIT;
