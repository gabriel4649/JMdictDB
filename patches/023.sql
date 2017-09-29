-- Descr: Fix conjugation errors for vs-s verbs. 
-- Trans: 22->23

\set ON_ERROR_STOP
BEGIN;

-- The conjugations are in table conjo.
-- Since we change more than a couple values, rather than try to update
-- just those values, it's easiest just to replace the 'vs-s' (pos=47)
-- section of the table.  The table values below are verbatim copy of
-- the values in pg/data/conjo.csv.  We also have to delete and replace
-- the per-conjugation notes in table conjo_notes that refer to any of
-- vs-s conjucations.

DELETE FROM conjo_notes WHERE pos=47;
DELETE FROM conjo WHERE pos=47;

-- From pg/data/conjo.csv...
\copy conjo FROM stdin DELIMITER E'\t' CSV HEADER
pos	conj	neg	fml	onum	stem	okuri	euphr	euphk	pos2
47	1	f	f	1	1	る	す		
47	1	f	t	1	1	ます	し		
47	1	t	f	1	1	ない	さ		
47	1	t	t	1	1	ません	し		
47	2	f	f	1	1	た	し		
47	2	f	t	1	1	ました	し		
47	2	t	f	1	1	なかった	さ		
47	2	t	t	1	1	ませんでした	し		
47	3	f	f	1	1	て	し		
47	3	f	t	1	1	まして	し		
47	3	t	f	1	1	なくて	さ		
47	3	t	f	2	1	ないで	し		
47	3	t	t	1	1	ませんで	し		
47	4	f	f	1	1	れば	す		
47	4	f	t	1	1	ますなら	し		
47	4	f	t	2	1	ますなれば	し		
47	4	t	f	1	1	なければ	さ		
47	4	t	t	1	1	ませんなら	し		
47	4	t	t	2	1	ませんならば	し		
47	5	f	f	1	1	る	しえ		
47	5	f	f	2	1	る	しう		
47	5	f	t	1	1	ます	しえ		
47	5	t	f	1	1	ない	しえ		
47	5	t	t	1	1	ません	しえ		
47	6	f	f	1	1	れる	さ		
47	6	f	t	1	1	れます	さ		
47	6	t	f	1	1	れない	さ		
47	6	t	t	1	1	れません	さ		
47	7	f	f	1	1	せる	さ		
47	7	f	f	2	1	す	さ		
47	7	f	t	1	1	せます	さ		
47	7	f	t	2	1	します	さ		
47	7	t	f	1	1	せない	さ		
47	7	t	f	2	1	さない	さ		
47	7	t	t	1	1	せません	さ		
47	7	t	t	2	1	しません	さ		
47	8	f	f	1	1	せられる	さ		
47	8	f	t	1	1	せられます	さ		
47	8	t	f	1	1	せられない	さ		
47	8	t	t	1	1	せられません	さ		
47	9	f	f	1	1	よう	し		
47	9	f	t	1	1	ましょう	し		
47	9	t	f	1	1	るまい	す		
47	9	t	t	1	1	ますまい	し		
47	10	f	f	1	1	ろ	し		
47	10	f	f	2	1	よ	せ		
47	10	f	t	1	1	なさい	し		
47	10	t	f	1	1	るな	す		
47	10	t	t	1	1	なさるな	し		
47	11	f	f	1	1	たら	し		
47	11	f	t	1	1	ましたら	し		
47	11	t	f	1	1	なかったら	さ		
47	11	t	t	1	1	ませんでしたら	し		
47	12	f	f	1	1	たり	し		
47	12	f	t	1	1	ましたり	し		
47	12	t	f	1	1	なかったり	さ		
47	12	t	t	1	1	ませんでしたり	し		
47	13	f	f	1	1	""	し		
\.

-- From pg/data/conjo_notes.csv...
\copy conjo_notes FROM stdin DELIMITER E'\t' CSV HEADER
pos	conj	neg	fml	onum	note
47	5	f	f	1	1
47	5	f	t	1	1
47	5	t	f	1	1
47	5	t	t	1	1
47	6	f	f	1	1
47	6	f	t	1	1
47	6	t	f	1	1
47	6	t	t	1	1
47	7	f	f	1	1
47	7	f	f	2	1
47	7	f	t	1	1
47	7	f	t	2	1
47	7	t	f	1	1
47	7	t	f	2	1
47	7	t	t	1	1
47	7	t	t	2	1
47	8	f	f	1	1
47	8	f	t	1	1
47	8	t	f	1	1
47	8	t	t	1	1
47	9	t	f	1	5
47	9	t	t	1	5
47	10	f	f	2	1
\.

INSERT INTO dbpatch(level) VALUES(23);

COMMIT;

