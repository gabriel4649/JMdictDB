-- Descr: Add view 'vcopos' used to identify entries that are conjugable.
-- Trans: 11->12

\set ON_ERROR_STOP
BEGIN;

INSERT INTO dbpatch(level) VALUES(12);

CREATE OR REPLACE VIEW vcopos AS (
    SELECT id,kw,descr FROM kwpos p JOIN copos c ON c.pos=p.id);
ALTER VIEW vcopos OWNER TO jmdictdb;
GRANT SELECT ON vcopos TO jmdictdbv;

COMMIT;

