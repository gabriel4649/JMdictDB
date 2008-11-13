-- This file is recreated during the database build process.
-- See pg/Makefile for details.

\set ON_ERROR_STOP 1
CREATE INDEX entr_seq ON entr(seq);
CREATE INDEX entr_stat ON entr(stat) WHERE stat!=2;
CREATE INDEX entr_dfrm ON entr(dfrm) WHERE dfrm IS NOT NULL;
CREATE INDEX entr_unap ON entr(unap) WHERE unap;
CREATE INDEX rdng_txt ON rdng(txt);
CREATE UNIQUE INDEX rdng_txt1 ON rdng(entr,txt);
CREATE INDEX rdng_txt2 ON rdng(txt varchar_pattern_ops); --For fast LIKE 'xxx%'
CREATE INDEX kanj_txt ON kanj(txt);
CREATE UNIQUE INDEX kanj_txt1 ON kanj(entr,txt);
CREATE INDEX kanj_txt2 ON kanj(txt varchar_pattern_ops); --For fast LIKE 'xxx%'
CREATE INDEX gloss_txt ON gloss(txt);
CREATE UNIQUE INDEX gloss_txt1 ON gloss(entr,sens,lang,txt);
CREATE INDEX gloss_txt2 ON gloss(lower(txt) varchar_pattern_ops); --For case-insensitive LIKE 'xxx%'
CREATE INDEX gloss_txt3 ON gloss(lower(txt)); 		    --For case-insensitive '='
CREATE INDEX xref_xentr ON xref(xentr,xsens);
CREATE INDEX hist_dt ON hist(dt);
CREATE INDEX hist_email ON hist(email);
CREATE INDEX hist_userid ON hist(userid);
CREATE UNIQUE INDEX freq_idx1 ON freq(entr,(coalesce(rdng,999)),(coalesce(kanj,999)),kw);
CREATE INDEX sndfile_vol ON sndfile(vol);
CREATE INDEX entrsnd_snd ON entrsnd(snd);
CREATE INDEX rdngsnd_snd ON rdngsnd(snd);
CREATE INDEX xresolv_rdng ON xresolv(rtxt);
CREATE INDEX xresolv_kanj ON xresolv(ktxt);
CREATE UNIQUE INDEX chr_chr ON chr(chr);
CREATE INDEX cinf_kw ON cinf(kw);
CREATE INDEX cinf_val ON cinf(value);
ALTER TABLE entr ADD CONSTRAINT entr_src_fkey FOREIGN KEY (src) REFERENCES kwsrc(id);
ALTER TABLE entr ADD CONSTRAINT entr_stat_fkey FOREIGN KEY (stat) REFERENCES kwstat(id);
ALTER TABLE entr ADD CONSTRAINT entr_dfrm_fkey FOREIGN KEY (dfrm) REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE rdng ADD CONSTRAINT rdng_entr_fkey FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE kanj ADD CONSTRAINT kanj_entr_fkey FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE sens ADD CONSTRAINT sens_entr_fkey FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE gloss ADD CONSTRAINT gloss_entr_fkey FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE gloss ADD CONSTRAINT gloss_lang_fkey FOREIGN KEY (lang) REFERENCES kwlang(id);
ALTER TABLE xref ADD CONSTRAINT xref_entr_fkey FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE xref ADD CONSTRAINT xref_xentr_fkey FOREIGN KEY (xentr,xsens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE xref ADD CONSTRAINT xref_typ_fkey FOREIGN KEY (typ) REFERENCES kwxref(id);
ALTER TABLE xref ADD CONSTRAINT xref_rdng_fkey FOREIGN KEY (xentr,rdng) REFERENCES rdng(entr,rdng) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE xref ADD CONSTRAINT xref_kanj_fkey FOREIGN KEY (xentr,kanj) REFERENCES kanj(entr,kanj) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE hist ADD CONSTRAINT hist_entr_fkey FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE hist ADD CONSTRAINT hist_stat_fkey FOREIGN KEY (stat) REFERENCES kwstat(id);
ALTER TABLE dial ADD CONSTRAINT dial_entr_fkey FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE dial ADD CONSTRAINT dial_kw_fkey FOREIGN KEY (kw) REFERENCES kwdial(id);
ALTER TABLE fld ADD CONSTRAINT fld_entr_fkey FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE fld ADD CONSTRAINT fld_kw_fkey FOREIGN KEY (kw) REFERENCES kwfld(id);
ALTER TABLE freq ADD CONSTRAINT freq_entr_fkey FOREIGN KEY (entr,kanj) REFERENCES kanj(entr,kanj) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE freq ADD CONSTRAINT freq_entr_fkey1 FOREIGN KEY (entr,rdng) REFERENCES rdng(entr,rdng) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE freq ADD CONSTRAINT freq_kw_fkey FOREIGN KEY (kw) REFERENCES kwfreq(id);
ALTER TABLE kinf ADD CONSTRAINT kinf_entr_fkey FOREIGN KEY (entr,kanj) REFERENCES kanj(entr,kanj) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE kinf ADD CONSTRAINT kinf_kw_fkey FOREIGN KEY (kw) REFERENCES kwkinf(id);
ALTER TABLE lsrc ADD CONSTRAINT lsrc_entr_fkey FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE lsrc ADD CONSTRAINT lsrc_lang_fkey FOREIGN KEY (lang) REFERENCES kwlang(id);
ALTER TABLE misc ADD CONSTRAINT misc_entr_fkey FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE misc ADD CONSTRAINT misc_kw_fkey FOREIGN KEY (kw) REFERENCES kwmisc(id);
ALTER TABLE pos ADD CONSTRAINT pos_entr_fkey FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE pos ADD CONSTRAINT pos_kw_fkey FOREIGN KEY (kw) REFERENCES kwpos(id);
ALTER TABLE rinf ADD CONSTRAINT rinf_entr_fkey FOREIGN KEY (entr,rdng) REFERENCES rdng(entr,rdng) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE rinf ADD CONSTRAINT rinf_kw_fkey FOREIGN KEY (kw) REFERENCES kwrinf(id);
ALTER TABLE restr ADD CONSTRAINT restr_entr_fkey FOREIGN KEY (entr,rdng) REFERENCES rdng(entr,rdng) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE restr ADD CONSTRAINT restr_entr_fkey1 FOREIGN KEY (entr,kanj) REFERENCES kanj(entr,kanj) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE stagr ADD CONSTRAINT stagr_entr_fkey FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE stagr ADD CONSTRAINT stagr_entr_fkey1 FOREIGN KEY (entr,rdng) REFERENCES rdng(entr,rdng) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE stagk ADD CONSTRAINT stagk_entr_fkey FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE stagk ADD CONSTRAINT stagk_entr_fkey1 FOREIGN KEY (entr,kanj) REFERENCES kanj(entr,kanj) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE sndvol ADD CONSTRAINT sndvol_corp_fkey FOREIGN KEY(corp) REFERENCES kwsrc(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE sndfile ADD CONSTRAINT sndfile_vol_fkey FOREIGN KEY(vol) REFERENCES sndvol(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE snd ADD CONSTRAINT snd_file_fkey FOREIGN KEY(file) REFERENCES sndfile(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE entrsnd ADD CONSTRAINT entrsnd_entr_fkey FOREIGN KEY(snd) REFERENCES snd(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE entrsnd ADD CONSTRAINT entrsnd_entr_fkey1 FOREIGN KEY(entr) REFERENCES entr(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE rdngsnd ADD CONSTRAINT rdngsnd_entr_fkey FOREIGN KEY(snd) REFERENCES snd(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE rdngsnd ADD CONSTRAINT rdngsnd_entr_fkey1 FOREIGN KEY(entr,rdng) REFERENCES rdng(entr,rdng) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE xresolv ADD CONSTRAINT xresolv_entr_fkey FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE xresolv ADD CONSTRAINT xresolv_typ_fkey FOREIGN KEY (typ) REFERENCES kwxref(id);
ALTER TABLE chr ADD CONSTRAINT chr_entr_fkey FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE cinf ADD CONSTRAINT chr_entr_fkey FOREIGN KEY (entr) REFERENCES chr(entr) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE cinf ADD CONSTRAINT chr_kw_fkey FOREIGN KEY (kw) REFERENCES kwcinf(id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE kresolv ADD CONSTRAINT kresolv_entr_fkey FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE;
