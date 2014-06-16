-- Descr: Add POS tag and conjugations for yoi/ii i-adjectives (IS-226).
-- Note: This script does not change the pos tags on any entries; that
--  needs to be done by hand after this script has been applied.
-- Trans: 12->13

\set ON_ERROR_STOP
BEGIN;

INSERT INTO dbpatch(level) VALUES(13);

INSERT INTO kwpos VALUES (99, 'adj-ii','yoi/ii i-adjective');
INSERT INTO copos VALUES (99,1);

INSERT INTO conjo VALUES (99,1, False,False,1, 'い',                NULL,NULL,NULL);
INSERT INTO conjo VALUES (99,1, False,True, 1, 'いです',            NULL,NULL,NULL);
INSERT INTO conjo VALUES (99,1, True, False,1, 'くない',            'よ', NULL,NULL);
INSERT INTO conjo VALUES (99,1, True, True, 1, 'くないです',        'よ', NULL,NULL);
INSERT INTO conjo VALUES (99,1, True, True, 2, 'くありません',      'よ', NULL,NULL);
INSERT INTO conjo VALUES (99,2, False,False,1, 'かった',            'よ', NULL,NULL);
INSERT INTO conjo VALUES (99,2, False,True, 1, 'かったです',        'よ', NULL,NULL);
INSERT INTO conjo VALUES (99,2, True, False,1, 'くなかった',        'よ', NULL,NULL);
INSERT INTO conjo VALUES (99,2, True, True, 1, 'くなかったです',    'よ', NULL,NULL);
INSERT INTO conjo VALUES (99,2, True, True, 2, 'くありませんでした','よ', NULL,NULL);
INSERT INTO conjo VALUES (99,3, False,False,1, 'くて',              'よ', NULL,NULL);
INSERT INTO conjo VALUES (99,3, True, False,1, 'くなくて',          'よ', NULL,NULL);
INSERT INTO conjo VALUES (99,4, False,False,1, 'ければ',            'よ', NULL,NULL);
INSERT INTO conjo VALUES (99,4, True, False,1, 'くなければ',        'よ', NULL,NULL);
INSERT INTO conjo VALUES (99,7, False,False,1, 'くさせる',          'よ', NULL,NULL);
INSERT INTO conjo VALUES (99,9, False,False,1, 'かろう',            'よ', NULL,NULL);
INSERT INTO conjo VALUES (99,9, False,True, 1, 'いでしょう',        NULL,NULL,NULL);
INSERT INTO conjo VALUES (99,11,False,False,1, 'かったら',          'よ', NULL,NULL);
INSERT INTO conjo VALUES (99,11,True, False,1, 'くなかったら',      'よ', NULL,NULL);
INSERT INTO conjo VALUES (99,12,False,False,1, 'かったり',          'よ', NULL,NULL);

COMMIT;
