-- Descr: Update for kwsrc types (IS-228).
-- Trans: 15->16

\set ON_ERROR_STOP
BEGIN;

INSERT INTO dbpatch(level) VALUES(16);

-- Defintion should match definition in pg/mktables.sql
CREATE TABLE kwsrct (
    id SMALLINT PRIMARY KEY,
    kw VARCHAR(20) NOT NULL UNIQUE,
    descr VARCHAR(255));

-- Data below should match pg/data/kwsrct.csv
INSERT INTO kwsrct VALUES (1,'jmdict','Words dictionary (http://www.edrdg.org/jmdict/edict_doc.html)');
INSERT INTO kwsrct VALUES (2,'jmnedict','Names dictionary (http://www.csse.monash.edu.au/~jwb/enamdict_doc.html)');
INSERT INTO kwsrct VALUES (3,'examples','Example sentences (http://www.edrdg.org/wiki/index.php/Tanaka_Corpus)');
INSERT INTO kwsrct VALUES (4,'kanjidic','Kanji dictionary (http://www.csse.monash.edu.au/~jwb/kanjidic.html)');

ALTER TABLE kwsrc ADD COLUMN srct SMALLINT REFERENCES kwsrct(id);
UPDATE kwsrc SET srct=1;
UPDATE kwsrc SET srct=2 WHERE kw LIKE 'jmnedict%';
UPDATE kwsrc SET srct=3 WHERE kw LIKE 'examples%';
UPDATE kwsrc SET srct=4 WHERE kw LIKE 'kanjidic%';
ALTER TABLE kwsrc ALTER COLUMN srct SET NOT NULL;

COMMIT;

