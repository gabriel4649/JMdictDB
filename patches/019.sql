-- Descr: Replace conjugations for 'n', 'adj-na' and 'vs' with note.
-- Trans: 18->19

\set ON_ERROR_STOP
BEGIN;

INSERT INTO dbpatch(level) VALUES(19);

-- Remove all but one conjugation for 'vs' (pos=47), 'n' (pos=17)
--  and 'adj-na' (pos=2).  Attach a note to each of the one remaining
--  conjugations that points to the base word (する or だ).
-- Note: we use Postgresql's \copy command rather than sql INSERTs
--  in some cases so that we can copy-paste the relevant data directly
--  from the pg/data/*.csv file(s) to reduce chances of discrepancies.
-- Caution: be careful not to (possibly inadvertantly) replace tab
--  characters (which may include trailing tabs!) in the csv data with
--  spaces when editing this file.

DELETE FROM conjo_notes WHERE pos IN (2,17,46);
DELETE FROM conjo WHERE pos IN (2,17,46);
INSERT INTO conjo VALUES 
  (2, 1,false,false,1,'だ',NULL,NULL,NULL),
  (17,1,false,false,1,'だ',NULL,NULL,NULL),
  (46,1,false,false,1,'する',NULL,NULL,NULL);

DELETE FROM conotes WHERE id IN (7,8);  -- This allows re-application of patch during development.
\copy conotes FROM stdin DELIMITER E'\t' CSV
7	"'n' and 'adj-na' words when used as predicates are followed by the
 copula <a href=""entr.py?svc=jmdict&sid=&q=2089020.jmdict"">だ</a> which is what is conjugated (<a href=""conj.py?svc=jmdict&sid=&q=2089020.jmdict"">conjugations</a>)."
8	'vs' words are followed by <a href="entr.py?svc=jmdict&sid=&q=1157170.jmdict">する</a> which is what is conjugated (<a href=""conj.py?svc=jmdict&sid=&q=1157170.jmdict"">conjugations</a>).
\.

INSERT INTO conjo_notes VALUES 
  (2, 1,false,false,1,7),
  (17,1,false,false,1,7),
  (46,1,false,false,1,8);

COMMIT;

