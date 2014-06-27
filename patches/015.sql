-- Descr: Add new kanjidic2 CINF tags. (IS-230).
-- Trans: 14->15

\set ON_ERROR_STOP
BEGIN;

INSERT INTO dbpatch(level) VALUES(15);

\copy kwcinf FROM stdin DELIMITER E'\t' CSV
36	halpern_kkd	"""Kodansha Kanji Dictionary"", (2nd Ed. of the NJECD) edited by Jack Halpern."
37	halpern_kkld_2ed	"""Kanji Learners Dictionary"" (Kodansha), 2nd edition (2013) edited by Jack Halpern."
38	heisig6	"""Remembering The Kanji, Sixth Ed."" by  James Heisig."
\.

COMMIT;

