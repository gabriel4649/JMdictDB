-- Descr: IS-211,IS-212 Add new keywords.
-- Trans: 5->6

-- Patch to running database to apply the changes made in IS-211 and IS-212.

\set ON_ERROR_STOP
BEGIN;
-- Add new keywords described in IS-211 ("hob") and IS-212 (the rest).
INSERT INTO kwdial VALUES(12,'hob','Hokkaidou-ben');
INSERT INTO kwfld  VALUES(11,'archit','architecture term');
INSERT INTO kwfld  VALUES(12,'astron','astronomy, etc. term');
INSERT INTO kwfld  VALUES(13,'baseb','baseball term');
INSERT INTO kwfld  VALUES(14,'biol','biology term');
INSERT INTO kwfld  VALUES(15,'bot','botany term');
INSERT INTO kwfld  VALUES(16,'bus','business term');
INSERT INTO kwfld  VALUES(17,'econ','economics term');
INSERT INTO kwfld  VALUES(18,'eng','engineering term');
INSERT INTO kwfld  VALUES(19,'fin','finance term');
INSERT INTO kwfld  VALUES(20,'geol','geology, etc. term');
INSERT INTO kwfld  VALUES(21,'law','law, etc. term');
INSERT INTO kwfld  VALUES(22,'med','medicine, etc. term');
INSERT INTO kwfld  VALUES(23,'music','music term');
INSERT INTO kwfld  VALUES(24,'Shinto','Shinto term');
INSERT INTO kwfld  VALUES(25,'sports','sports term');
INSERT INTO kwfld  VALUES(26,'sumo','sumo term');
INSERT INTO kwfld  VALUES(27,'zool','zoology term');
INSERT INTO kwpos  VALUES(63,'adj-kari','kari adjective (archaic)');
INSERT INTO kwpos  VALUES(64,'adj-ku','ku adjective (archaic)');
INSERT INTO kwpos  VALUES(65,'adj-shiku','shiku adjective (archaic)');
INSERT INTO kwpos  VALUES(66,'adj-nari','archaic/formal form of na-adjective');
INSERT INTO kwpos  VALUES(67,'n-pr','proper noun');
INSERT INTO kwpos  VALUES(68,'v-unspec','verb unspecified');
INSERT INTO kwpos  VALUES(69,'v4k','Yodan verb with ku ending (archaic)');
INSERT INTO kwpos  VALUES(70,'v4g','Yodan verb with gu ending (archaic)');
INSERT INTO kwpos  VALUES(71,'v4s','Yodan verb with su ending (archaic)');
INSERT INTO kwpos  VALUES(72,'v4t','Yodan verb with tsu ending (archaic)');
INSERT INTO kwpos  VALUES(73,'v4n','Yodan verb with nu ending (archaic)');
INSERT INTO kwpos  VALUES(74,'v4b','Yodan verb with bu ending (archaic)');
INSERT INTO kwpos  VALUES(75,'v4m','Yodan verb with mu ending (archaic)');
INSERT INTO kwpos  VALUES(76,'v2k-k','Nidan verb (upper class) with ku ending (archaic)');
INSERT INTO kwpos  VALUES(77,'v2g-k','Nidan verb (upper class) with gu ending (archaic)');
INSERT INTO kwpos  VALUES(78,'v2t-k','Nidan verb (upper class) with tsu ending (archaic)');
INSERT INTO kwpos  VALUES(79,'v2d-k','Nidan verb (upper class) with dzu ending (archaic)');
INSERT INTO kwpos  VALUES(80,'v2h-k','Nidan verb (upper class) with hu/fu ending (archaic)');
INSERT INTO kwpos  VALUES(81,'v2b-k','Nidan verb (upper class) with bu ending (archaic)');
INSERT INTO kwpos  VALUES(82,'v2m-k','Nidan verb (upper class) with mu ending (archaic)');
INSERT INTO kwpos  VALUES(83,'v2y-k','Nidan verb (upper class) with yu ending (archaic)');
INSERT INTO kwpos  VALUES(84,'v2r-k','Nidan verb (upper class) with ru ending (archaic)');
INSERT INTO kwpos  VALUES(85,'v2k-s','Nidan verb (lower class) with ku ending (archaic)');
INSERT INTO kwpos  VALUES(86,'v2g-s','Nidan verb (lower class) with gu ending (archaic)');
INSERT INTO kwpos  VALUES(87,'v2s-s','Nidan verb (lower class) with su ending (archaic)');
INSERT INTO kwpos  VALUES(88,'v2z-s','Nidan verb (lower class) with zu ending (archaic)');
INSERT INTO kwpos  VALUES(89,'v2t-s','Nidan verb (lower class) with tsu ending (archaic)');
INSERT INTO kwpos  VALUES(90,'v2d-s','Nidan verb (lower class) with dzu ending (archaic)');
INSERT INTO kwpos  VALUES(91,'v2n-s','Nidan verb (lower class) with nu ending (archaic)');
INSERT INTO kwpos  VALUES(92,'v2h-s','Nidan verb (lower class) with hu/fu ending (archaic)');
INSERT INTO kwpos  VALUES(93,'v2b-s','Nidan verb (lower class) with bu ending (archaic)');
INSERT INTO kwpos  VALUES(94,'v2m-s','Nidan verb (lower class) with mu ending (archaic)');
INSERT INTO kwpos  VALUES(95,'v2y-s','Nidan verb (lower class) with yu ending (archaic)');
INSERT INTO kwpos  VALUES(96,'v2r-s','Nidan verb (lower class) with ru ending (archaic)');
INSERT INTO kwpos  VALUES(97,'v2w-s','Nidan verb (lower class) with u ending and we conjugation (archaic)');
INSERT INTO kwmisc VALUES(28,'joc','jocular, humorous term');

-- Correct the descr fields...
UPDATE kwpos SET descr='Yodan verb with `ru'' ending (archaic)' WHERE kw='v4r';
UPDATE kwpos SET descr='Yodan verb with `hu/fu'' ending (archaic)' WHERE kw='v4h';

-- Remove the 'v5z' POS tag...

DELETE FROM kwpos WHERE kw='v5z';

COMMIT;
