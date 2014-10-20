-- Descr: Rename FKs and indices to match implicit rules. 
-- Trans: 20->21

-- Rename constraints and indexes that were created with explicit
-- names in databases of patchlevel 20 and earlier, to the names
-- assigned by Postgresql implicitly as is done in post-patchlevel
-- 20 databases.

\set ON_ERROR_STOP
BEGIN;

INSERT INTO dbpatch(level) VALUES(21);

ALTER TABLE cinf RENAME CONSTRAINT chr_entr_fkey TO cinf_entr_fkey;
ALTER TABLE cinf RENAME CONSTRAINT chr_kw_fkey TO cinf_kw_fkey;
ALTER TABLE entrsnd RENAME CONSTRAINT entrsnd_entr_fkey TO entrsnd_snd_fkey;
ALTER TABLE entrsnd RENAME CONSTRAINT entrsnd_entr_fkey1 TO entrsnd_entr_fkey;
ALTER TABLE freq RENAME CONSTRAINT freq_entr_fkey TO freq_entr_fkey_tmp;
ALTER TABLE freq RENAME CONSTRAINT freq_entr_fkey1 TO freq_entr_fkey;
ALTER TABLE freq RENAME CONSTRAINT freq_entr_fkey_tmp TO freq_entr_fkey1;
ALTER TABLE rdngsnd RENAME CONSTRAINT rdngsnd_entr_fkey TO rdngsnd_snd_fkey;
ALTER TABLE rdngsnd RENAME CONSTRAINT rdngsnd_entr_fkey1 TO rdngsnd_entr_fkey;

ALTER INDEX chr_chr RENAME TO chr_chr_idx;
ALTER INDEX entr_dfrm RENAME TO entr_dfrm_idx;
ALTER INDEX entr_seq RENAME TO entr_seq_idx;
ALTER INDEX entr_stat RENAME TO entr_stat_idx;
ALTER INDEX entr_unap RENAME TO entr_unap_idx;
ALTER INDEX entrsnd_snd RENAME TO entrsnd_snd_idx;
ALTER INDEX freq_idx1 RENAME TO freq_entr_coalesce_coalesce1_kw_idx;
ALTER INDEX gloss_txt RENAME TO gloss_txt_idx;
ALTER INDEX gloss_txt1 RENAME TO gloss_entr_sens_lang_txt_idx;
ALTER INDEX gloss_txt2 RENAME TO gloss_lower_idx;
ALTER INDEX gloss_txt3 RENAME TO gloss_lower_idx1;
ALTER INDEX hist_dt RENAME TO hist_dt_idx;
ALTER INDEX hist_email RENAME TO hist_email_idx;
ALTER INDEX hist_userid RENAME TO hist_userid_idx;
ALTER INDEX kanj_txt RENAME TO kanj_txt_idx;
ALTER INDEX kanj_txt1 RENAME TO kanj_entr_txt_idx;
ALTER INDEX kanj_txt2 RENAME TO kanj_txt_idx1;
ALTER INDEX rdng_txt RENAME TO rdng_txt_idx;
ALTER INDEX rdng_txt1 RENAME TO rdng_entr_txt_idx;
ALTER INDEX rdng_txt2 RENAME TO rdng_txt_idx1;
ALTER INDEX sndfile_vol RENAME TO sndfile_vol_idx;
ALTER INDEX xref_xentr RENAME TO xref_xentr_xsens_idx;

COMMIT;

