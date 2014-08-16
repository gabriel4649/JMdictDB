-- Descr: Fix provisional form of 来る.
-- Trans: 16->17

\set ON_ERROR_STOP
BEGIN;

INSERT INTO dbpatch(level) VALUES(17);

-- Fix erroneous value: provisional form of くる is くれば (was これば).
UPDATE conjo SET euphr='く' WHERE pos=45 AND conj=4;

COMMIT;

