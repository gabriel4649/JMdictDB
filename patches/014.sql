-- Descr: Add MISC tag 'work'.
-- Trans: 13->14

\set ON_ERROR_STOP
BEGIN;

INSERT INTO dbpatch(level) VALUES(14);

INSERT INTO kwmisc VALUES (192, 'work', 'work of art, literature, music, etc. name');

COMMIT;
