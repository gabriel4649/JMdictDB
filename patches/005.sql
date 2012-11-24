-- Descr: IS-201 Fix view is_p.
-- Trans: 4->5

-- See doc/issues/000201.txt for details.

\set ON_ERROR_STOP
BEGIN;

CREATE OR REPLACE VIEW is_p AS (
    SELECT e.*,
        EXISTS (
            SELECT * FROM freq f
            WHERE f.entr=e.id
              -- ichi1, gai1, news1, or specX
              AND ((f.kw IN (1,2,7) AND f.value=1)
                OR f.kw=4)) AS p
    FROM entr e);

COMMIT;
