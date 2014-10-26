 -- This file was auto-generated at 2014-10-19 20:36:29.1857-06, dbpatch level 21.

 ALTER TABLE public.chr DROP CONSTRAINT IF EXISTS chr_entr_fkey;
 ALTER TABLE public.cinf DROP CONSTRAINT IF EXISTS cinf_entr_fkey;
 ALTER TABLE public.cinf DROP CONSTRAINT IF EXISTS cinf_kw_fkey;
 ALTER TABLE public.conjo DROP CONSTRAINT IF EXISTS conjo_conj_fkey;
 ALTER TABLE public.conjo DROP CONSTRAINT IF EXISTS conjo_pos2_fkey;
 ALTER TABLE public.conjo DROP CONSTRAINT IF EXISTS conjo_pos_fkey;
 ALTER TABLE public.conjo_notes DROP CONSTRAINT IF EXISTS conjo_notes_note_fkey;
 ALTER TABLE public.conjo_notes DROP CONSTRAINT IF EXISTS conjo_notes_pos_fkey;
 ALTER TABLE public.dial DROP CONSTRAINT IF EXISTS dial_entr_fkey;
 ALTER TABLE public.dial DROP CONSTRAINT IF EXISTS dial_kw_fkey;
 ALTER TABLE public.entr DROP CONSTRAINT IF EXISTS entr_dfrm_fkey;
 ALTER TABLE public.entr DROP CONSTRAINT IF EXISTS entr_src_fkey;
 ALTER TABLE public.entr DROP CONSTRAINT IF EXISTS entr_stat_fkey;
 ALTER TABLE public.entrsnd DROP CONSTRAINT IF EXISTS entrsnd_entr_fkey;
 ALTER TABLE public.entrsnd DROP CONSTRAINT IF EXISTS entrsnd_snd_fkey;
 ALTER TABLE public.fld DROP CONSTRAINT IF EXISTS fld_entr_fkey;
 ALTER TABLE public.fld DROP CONSTRAINT IF EXISTS fld_kw_fkey;
 ALTER TABLE public.freq DROP CONSTRAINT IF EXISTS freq_entr_fkey;
 ALTER TABLE public.freq DROP CONSTRAINT IF EXISTS freq_entr_fkey1;
 ALTER TABLE public.freq DROP CONSTRAINT IF EXISTS freq_kw_fkey;
 ALTER TABLE public.gloss DROP CONSTRAINT IF EXISTS gloss_entr_fkey;
 ALTER TABLE public.gloss DROP CONSTRAINT IF EXISTS gloss_lang_fkey;
 ALTER TABLE public.grp DROP CONSTRAINT IF EXISTS grp_entr_fkey;
 ALTER TABLE public.grp DROP CONSTRAINT IF EXISTS grp_kw_fkey;
 ALTER TABLE public.hist DROP CONSTRAINT IF EXISTS hist_entr_fkey;
 ALTER TABLE public.hist DROP CONSTRAINT IF EXISTS hist_stat_fkey;
 ALTER TABLE public.kanj DROP CONSTRAINT IF EXISTS kanj_entr_fkey;
 ALTER TABLE public.kinf DROP CONSTRAINT IF EXISTS kinf_entr_fkey;
 ALTER TABLE public.kinf DROP CONSTRAINT IF EXISTS kinf_kw_fkey;
 ALTER TABLE public.kresolv DROP CONSTRAINT IF EXISTS kresolv_entr_fkey;
 ALTER TABLE public.kwsrc DROP CONSTRAINT IF EXISTS kwsrc_srct_fkey;
 ALTER TABLE public.lsrc DROP CONSTRAINT IF EXISTS lsrc_entr_fkey;
 ALTER TABLE public.lsrc DROP CONSTRAINT IF EXISTS lsrc_lang_fkey;
 ALTER TABLE public.misc DROP CONSTRAINT IF EXISTS misc_entr_fkey;
 ALTER TABLE public.misc DROP CONSTRAINT IF EXISTS misc_kw_fkey;
 ALTER TABLE public.pos DROP CONSTRAINT IF EXISTS pos_entr_fkey;
 ALTER TABLE public.pos DROP CONSTRAINT IF EXISTS pos_kw_fkey;
 ALTER TABLE public.rdng DROP CONSTRAINT IF EXISTS rdng_entr_fkey;
 ALTER TABLE public.rdngsnd DROP CONSTRAINT IF EXISTS rdngsnd_entr_fkey;
 ALTER TABLE public.rdngsnd DROP CONSTRAINT IF EXISTS rdngsnd_snd_fkey;
 ALTER TABLE public.restr DROP CONSTRAINT IF EXISTS restr_entr_fkey;
 ALTER TABLE public.restr DROP CONSTRAINT IF EXISTS restr_entr_fkey1;
 ALTER TABLE public.rinf DROP CONSTRAINT IF EXISTS rinf_entr_fkey;
 ALTER TABLE public.rinf DROP CONSTRAINT IF EXISTS rinf_kw_fkey;
 ALTER TABLE public.sens DROP CONSTRAINT IF EXISTS sens_entr_fkey;
 ALTER TABLE public.snd DROP CONSTRAINT IF EXISTS snd_file_fkey;
 ALTER TABLE public.sndfile DROP CONSTRAINT IF EXISTS sndfile_vol_fkey;
 ALTER TABLE public.sndvol DROP CONSTRAINT IF EXISTS sndvol_corp_fkey;
 ALTER TABLE public.stagk DROP CONSTRAINT IF EXISTS stagk_entr_fkey;
 ALTER TABLE public.stagk DROP CONSTRAINT IF EXISTS stagk_entr_fkey1;
 ALTER TABLE public.stagr DROP CONSTRAINT IF EXISTS stagr_entr_fkey;
 ALTER TABLE public.stagr DROP CONSTRAINT IF EXISTS stagr_entr_fkey1;
 ALTER TABLE public.xref DROP CONSTRAINT IF EXISTS xref_entr_fkey;
 ALTER TABLE public.xref DROP CONSTRAINT IF EXISTS xref_kanj_fkey;
 ALTER TABLE public.xref DROP CONSTRAINT IF EXISTS xref_rdng_fkey;
 ALTER TABLE public.xref DROP CONSTRAINT IF EXISTS xref_typ_fkey;
 ALTER TABLE public.xref DROP CONSTRAINT IF EXISTS xref_xentr_fkey;
 ALTER TABLE public.xresolv DROP CONSTRAINT IF EXISTS xresolv_entr_fkey;
 ALTER TABLE public.xresolv DROP CONSTRAINT IF EXISTS xresolv_typ_fkey;
 ALTER TABLE public.entr DROP CONSTRAINT IF EXISTS entr_seq_check;
 ALTER TABLE public.freq DROP CONSTRAINT IF EXISTS freq_check;
 ALTER TABLE public.gloss DROP CONSTRAINT IF EXISTS gloss_gloss_check;
 ALTER TABLE public.hist DROP CONSTRAINT IF EXISTS hist_hist_check;
 ALTER TABLE public.kanj DROP CONSTRAINT IF EXISTS kanj_kanj_check;
 ALTER TABLE public.rad DROP CONSTRAINT IF EXISTS rad_loc_check;
 ALTER TABLE public.rdng DROP CONSTRAINT IF EXISTS rdng_rdng_check;
 ALTER TABLE public.sens DROP CONSTRAINT IF EXISTS sens_sens_check;
 ALTER TABLE public.xref DROP CONSTRAINT IF EXISTS xref_check;
 ALTER TABLE public.xref DROP CONSTRAINT IF EXISTS xref_check1;
 ALTER TABLE public.xref DROP CONSTRAINT IF EXISTS xref_xref_check;
 ALTER TABLE public.xresolv DROP CONSTRAINT IF EXISTS xresolv_check;
 ALTER TABLE public.chr DROP CONSTRAINT IF EXISTS chr_pkey;
 ALTER TABLE public.cinf DROP CONSTRAINT IF EXISTS cinf_pkey;
 ALTER TABLE public.conj DROP CONSTRAINT IF EXISTS conj_pkey;
 ALTER TABLE public.conjo DROP CONSTRAINT IF EXISTS conjo_pkey;
 ALTER TABLE public.conjo_notes DROP CONSTRAINT IF EXISTS conjo_notes_pkey;
 ALTER TABLE public.conotes DROP CONSTRAINT IF EXISTS conotes_pkey;
 ALTER TABLE public.dbpatch DROP CONSTRAINT IF EXISTS dbpatch_pkey;
 ALTER TABLE public.dial DROP CONSTRAINT IF EXISTS dial_pkey;
 ALTER TABLE public.entr DROP CONSTRAINT IF EXISTS entr_pkey;
 ALTER TABLE public.entrsnd DROP CONSTRAINT IF EXISTS entrsnd_pkey;
 ALTER TABLE public.fld DROP CONSTRAINT IF EXISTS fld_pkey;
 ALTER TABLE public.gloss DROP CONSTRAINT IF EXISTS gloss_pkey;
 ALTER TABLE public.grp DROP CONSTRAINT IF EXISTS grp_pkey;
 ALTER TABLE public.hist DROP CONSTRAINT IF EXISTS hist_pkey;
 ALTER TABLE public.kanj DROP CONSTRAINT IF EXISTS kanj_pkey;
 ALTER TABLE public.kinf DROP CONSTRAINT IF EXISTS kinf_pkey;
 ALTER TABLE public.kresolv DROP CONSTRAINT IF EXISTS kresolv_pkey;
 ALTER TABLE public.kwcinf DROP CONSTRAINT IF EXISTS kwcinf_pkey;
 ALTER TABLE public.kwdial DROP CONSTRAINT IF EXISTS kwdial_pkey;
 ALTER TABLE public.kwfld DROP CONSTRAINT IF EXISTS kwfld_pkey;
 ALTER TABLE public.kwfreq DROP CONSTRAINT IF EXISTS kwfreq_pkey;
 ALTER TABLE public.kwginf DROP CONSTRAINT IF EXISTS kwginf_pkey;
 ALTER TABLE public.kwgrp DROP CONSTRAINT IF EXISTS kwgrp_pkey;
 ALTER TABLE public.kwkinf DROP CONSTRAINT IF EXISTS kwkinf_pkey;
 ALTER TABLE public.kwlang DROP CONSTRAINT IF EXISTS kwlang_pkey;
 ALTER TABLE public.kwmisc DROP CONSTRAINT IF EXISTS kwmisc_pkey;
 ALTER TABLE public.kwpos DROP CONSTRAINT IF EXISTS kwpos_pkey;
 ALTER TABLE public.kwrinf DROP CONSTRAINT IF EXISTS kwrinf_pkey;
 ALTER TABLE public.kwsrc DROP CONSTRAINT IF EXISTS kwsrc_pkey;
 ALTER TABLE public.kwsrct DROP CONSTRAINT IF EXISTS kwsrct_pkey;
 ALTER TABLE public.kwstat DROP CONSTRAINT IF EXISTS kwstat_pkey;
 ALTER TABLE public.kwxref DROP CONSTRAINT IF EXISTS kwxref_pkey;
 ALTER TABLE public.lsrc DROP CONSTRAINT IF EXISTS lsrc_pkey;
 ALTER TABLE public.misc DROP CONSTRAINT IF EXISTS misc_pkey;
 ALTER TABLE public.pos DROP CONSTRAINT IF EXISTS pos_pkey;
 ALTER TABLE public.rad DROP CONSTRAINT IF EXISTS rad_pkey;
 ALTER TABLE public.rdng DROP CONSTRAINT IF EXISTS rdng_pkey;
 ALTER TABLE public.rdngsnd DROP CONSTRAINT IF EXISTS rdngsnd_pkey;
 ALTER TABLE public.restr DROP CONSTRAINT IF EXISTS restr_pkey;
 ALTER TABLE public.rinf DROP CONSTRAINT IF EXISTS rinf_pkey;
 ALTER TABLE public.sens DROP CONSTRAINT IF EXISTS sens_pkey;
 ALTER TABLE public.snd DROP CONSTRAINT IF EXISTS snd_pkey;
 ALTER TABLE public.sndfile DROP CONSTRAINT IF EXISTS sndfile_pkey;
 ALTER TABLE public.sndvol DROP CONSTRAINT IF EXISTS sndvol_pkey;
 ALTER TABLE public.stagk DROP CONSTRAINT IF EXISTS stagk_pkey;
 ALTER TABLE public.stagr DROP CONSTRAINT IF EXISTS stagr_pkey;
 ALTER TABLE public.xref DROP CONSTRAINT IF EXISTS xref_pkey;
 ALTER TABLE public.xresolv DROP CONSTRAINT IF EXISTS xresolv_pkey;
 ALTER TABLE public.conj DROP CONSTRAINT IF EXISTS conj_name_key;
 ALTER TABLE public.freq DROP CONSTRAINT IF EXISTS freq_entr_rdng_kanj_kw_key;
 ALTER TABLE public.kwcinf DROP CONSTRAINT IF EXISTS kwcinf_kw_key;
 ALTER TABLE public.kwdial DROP CONSTRAINT IF EXISTS kwdial_kw_key;
 ALTER TABLE public.kwfld DROP CONSTRAINT IF EXISTS kwfld_kw_key;
 ALTER TABLE public.kwfreq DROP CONSTRAINT IF EXISTS kwfreq_kw_key;
 ALTER TABLE public.kwginf DROP CONSTRAINT IF EXISTS kwginf_kw_key;
 ALTER TABLE public.kwgrp DROP CONSTRAINT IF EXISTS kwgrp_kw_key;
 ALTER TABLE public.kwlang DROP CONSTRAINT IF EXISTS kwlang_kw_key;
 ALTER TABLE public.kwpos DROP CONSTRAINT IF EXISTS kwpos_kw_key;
 ALTER TABLE public.kwrinf DROP CONSTRAINT IF EXISTS kwrinf_kw_key;
 ALTER TABLE public.kwsrc DROP CONSTRAINT IF EXISTS kwsrc_kw_key;
 ALTER TABLE public.kwsrct DROP CONSTRAINT IF EXISTS kwsrct_kw_key;
 ALTER TABLE public.kwstat DROP CONSTRAINT IF EXISTS kwstat_kw_key;
 ALTER TABLE public.kwxref DROP CONSTRAINT IF EXISTS kwxref_kw_key;

 DROP INDEX IF EXISTS public.chr_chr_idx RESTRICT;
 DROP INDEX IF EXISTS public.cinf_kw RESTRICT;
 DROP INDEX IF EXISTS public.cinf_val RESTRICT;
 DROP INDEX IF EXISTS public.conj_name_key RESTRICT;
 DROP INDEX IF EXISTS public.entr_dfrm_idx RESTRICT;
 DROP INDEX IF EXISTS public.entr_seq_idx RESTRICT;
 DROP INDEX IF EXISTS public.entr_stat_idx RESTRICT;
 DROP INDEX IF EXISTS public.entr_unap_idx RESTRICT;
 DROP INDEX IF EXISTS public.entrsnd_snd_idx RESTRICT;
 DROP INDEX IF EXISTS public.freq_entr_coalesce_coalesce1_kw_idx RESTRICT;
 DROP INDEX IF EXISTS public.freq_entr_rdng_kanj_kw_key RESTRICT;
 DROP INDEX IF EXISTS public.gloss_entr_sens_lang_txt_idx RESTRICT;
 DROP INDEX IF EXISTS public.gloss_lower_idx RESTRICT;
 DROP INDEX IF EXISTS public.gloss_lower_idx1 RESTRICT;
 DROP INDEX IF EXISTS public.gloss_txt_idx RESTRICT;
 DROP INDEX IF EXISTS public.grp_kw RESTRICT;
 DROP INDEX IF EXISTS public.hist_dt_idx RESTRICT;
 DROP INDEX IF EXISTS public.hist_email_idx RESTRICT;
 DROP INDEX IF EXISTS public.hist_userid_idx RESTRICT;
 DROP INDEX IF EXISTS public.kanj_entr_txt_idx RESTRICT;
 DROP INDEX IF EXISTS public.kanj_txt_idx RESTRICT;
 DROP INDEX IF EXISTS public.kanj_txt_idx1 RESTRICT;
 DROP INDEX IF EXISTS public.kwcinf_kw_key RESTRICT;
 DROP INDEX IF EXISTS public.kwdial_kw_key RESTRICT;
 DROP INDEX IF EXISTS public.kwfld_kw_key RESTRICT;
 DROP INDEX IF EXISTS public.kwfreq_kw_key RESTRICT;
 DROP INDEX IF EXISTS public.kwginf_kw_key RESTRICT;
 DROP INDEX IF EXISTS public.kwgrp_kw_key RESTRICT;
 DROP INDEX IF EXISTS public.kwlang_kw_key RESTRICT;
 DROP INDEX IF EXISTS public.kwpos_kw_key RESTRICT;
 DROP INDEX IF EXISTS public.kwrinf_kw_key RESTRICT;
 DROP INDEX IF EXISTS public.kwsrc_kw_key RESTRICT;
 DROP INDEX IF EXISTS public.kwsrct_kw_key RESTRICT;
 DROP INDEX IF EXISTS public.kwstat_kw_key RESTRICT;
 DROP INDEX IF EXISTS public.kwxref_kw_key RESTRICT;
 DROP INDEX IF EXISTS public.rdng_entr_txt_idx RESTRICT;
 DROP INDEX IF EXISTS public.rdng_txt_idx RESTRICT;
 DROP INDEX IF EXISTS public.rdng_txt_idx1 RESTRICT;
 DROP INDEX IF EXISTS public.rdngsnd_snd RESTRICT;
 DROP INDEX IF EXISTS public.sndfile_vol_idx RESTRICT;
 DROP INDEX IF EXISTS public.xref_xentr_xsens_idx RESTRICT;
 DROP INDEX IF EXISTS public.xresolv_kanj RESTRICT;
 DROP INDEX IF EXISTS public.xresolv_rdng RESTRICT;
