-- Descr: Change keywords of new PoSs per Edict list discussion.
-- Trans: 17->18

\set ON_ERROR_STOP
BEGIN;

INSERT INTO dbpatch(level) VALUES(18);

-- Update PoS keywords to conform to outcome of Edict list discussion,
-- subject: "Additional PoSs", 2014-08-06.
UPDATE kwpos SET kw='adj-ix' WHERE kw='adj-ii';
UPDATE kwpos SET kw='v1-s' WHERE kw='v1k-i';
UPDATE kwpos SET kw='cop-da' WHERE kw='cop';

COMMIT;

