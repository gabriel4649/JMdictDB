-- Descr: Fix conjugation error for v5s/aff/plain verbs. 
-- Trans: 21->22

-- Fix error in conjugation tables: prior to this fix the plain
-- affirmative causative (alternate) form of v5s verbs was wrong,
-- eg, 話す -> 話さる.  Should be 話さす.

\set ON_ERROR_STOP
BEGIN;

UPDATE conjo SET okuri='さす'
    WHERE pos=39 AND conj=7 AND NOT neg AND not fml AND onum=2;

INSERT INTO dbpatch(level) VALUES(22);

COMMIT;
