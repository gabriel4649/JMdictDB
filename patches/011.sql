-- Descr: Add additional FLD, MISC and POS tags per jwb rev ad64ce221266 2014-05-18.
-- Trans: 10->11

\set ON_ERROR_STOP
BEGIN;

INSERT INTO dbpatch(level) VALUES(11);

INSERT INTO kwfld  VALUES (29, 'mahj',  'mahjong term');
INSERT INTO kwfld  VALUES (30, 'shogi', 'shogi term');
INSERT INTO kwmisc VALUES (84, 'yoji',  'yojijukugo');
INSERT INTO kwpos  VALUES (98, 'unc',   'unclassified');

COMMIT;

