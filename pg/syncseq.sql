-- $Revision$ $Date$
-- Copyright (c) 2007, Stuart McGraw 

SELECT setval('audio_id_seq', (SELECT max(id) FROM audio));
SELECT setval('entr_id_seq',  (SELECT max(id) FROM entr));
SELECT setval('gloss_id_seq', (SELECT max(id) FROM gloss));
SELECT setval('hist_id_seq',  (SELECT max(id) FROM hist));
SELECT setval('kanj_id_seq',  (SELECT max(id) FROM kanj));
SELECT setval('rdng_id_seq',  (SELECT max(id) FROM rdng));
SELECT setval('sens_id_seq',  (SELECT max(id) FROM sens));
SELECT setval('seq', (SELECT MAX(seq) FROM entr WHERE seq<9000000));

