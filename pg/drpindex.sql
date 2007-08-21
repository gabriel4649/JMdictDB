-- This file is recreated during the database build process.
-- See Makefile for details.

\set ON_ERROR_STOP 1
DROP INDEX entr_seq;
DROP INDEX entr_stat;
DROP INDEX rdng_txt;
DROP INDEX rdng_txt1;
DROP INDEX rdng_txt2; --For fast LIKE 'xxx%'
DROP INDEX kanj_txt;
DROP INDEX kanj_txt1;
DROP INDEX kanj_txt2; --For fast LIKE 'xxx%'
DROP INDEX gloss_txt; 
DROP INDEX gloss_txt1;
DROP INDEX gloss_txt2; --For case-insensitive LIKE 'xxx%'
DROP INDEX gloss_txt3; 		    --For case-insensitive '='
DROP INDEX xref_xentr;
DROP INDEX hist_dt;
DROP INDEX hist_who;
DROP INDEX audio_fname;
DROP INDEX editor_email;
DROP INDEX editor_name;
DROP INDEX freq_idx1; 
DROP INDEX xresolv_rdng;
DROP INDEX xresolv_kanj;
ALTER TABLE entr DROP CONSTRAINT entr_src_fkey;
ALTER TABLE entr DROP CONSTRAINT entr_stat_fkey;
ALTER TABLE rdng DROP CONSTRAINT rdng_entr_fkey;
ALTER TABLE kanj DROP CONSTRAINT kanj_entr_fkey;
ALTER TABLE sens DROP CONSTRAINT sens_entr_fkey;
ALTER TABLE gloss DROP CONSTRAINT gloss_entr_fkey;
ALTER TABLE gloss DROP CONSTRAINT gloss_lang_fkey;
ALTER TABLE xref DROP CONSTRAINT xref_entr_fkey;
ALTER TABLE xref DROP CONSTRAINT xref_xentr_fkey;
ALTER TABLE xref DROP CONSTRAINT xref_typ_fkey;
ALTER TABLE xref DROP CONSTRAINT xref_rdng_fkey;
ALTER TABLE xref DROP CONSTRAINT xref_kanj_fkey;
ALTER TABLE hist DROP CONSTRAINT hist_entr_fkey;
ALTER TABLE hist DROP CONSTRAINT hist_stat_fkey;
ALTER TABLE audio DROP CONSTRAINT audio_entr_fkey;
ALTER TABLE dial DROP CONSTRAINT dial_entr_fkey;
ALTER TABLE dial DROP CONSTRAINT dial_kw_fkey;
ALTER TABLE fld DROP CONSTRAINT fld_entr_fkey;
ALTER TABLE fld DROP CONSTRAINT fld_kw_fkey;
ALTER TABLE freq DROP CONSTRAINT freq_entr_fkey;
ALTER TABLE freq DROP CONSTRAINT freq_entr_fkey1;
ALTER TABLE freq DROP CONSTRAINT freq_kw_fkey;
ALTER TABLE kinf DROP CONSTRAINT kinf_entr_fkey;
ALTER TABLE kinf DROP CONSTRAINT kinf_kw_fkey;
ALTER TABLE lsrc DROP CONSTRAINT lsrc_entr_fkey;
ALTER TABLE lsrc DROP CONSTRAINT lsrc_lang_fkey;
ALTER TABLE misc DROP CONSTRAINT misc_entr_fkey;
ALTER TABLE misc DROP CONSTRAINT misc_kw_fkey;
ALTER TABLE pos DROP CONSTRAINT pos_entr_fkey;
ALTER TABLE pos DROP CONSTRAINT pos_kw_fkey;
ALTER TABLE rinf DROP CONSTRAINT rinf_entr_fkey;
ALTER TABLE rinf DROP CONSTRAINT rinf_kw_fkey;
ALTER TABLE restr DROP CONSTRAINT restr_entr_fkey;
ALTER TABLE restr DROP CONSTRAINT restr_entr_fkey1;
ALTER TABLE stagr DROP CONSTRAINT stagr_entr_fkey;
ALTER TABLE stagr DROP CONSTRAINT stagr_entr_fkey1;
ALTER TABLE stagk DROP CONSTRAINT stagk_entr_fkey;
ALTER TABLE stagk DROP CONSTRAINT stagk_entr_fkey1;
ALTER TABLE xresolv DROP CONSTRAINT xresolv_entr_fkey;
ALTER TABLE xresolv DROP CONSTRAINT xresolv_typ_fkey;
