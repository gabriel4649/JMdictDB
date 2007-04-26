-------------------------------------------------------------------------
--  This file is part of JMdictDB. 
--
--  JMdictDB is free software; you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published 
--  by the Free Software Foundation; either version 2 of the License, 
--  or (at your option) any later version.
--
--  JMdictDB is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with JMdictDB; if not, write to the Free Software Foundation,
--  51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
--
--  Copyright (c) 2006,2007 Stuart McGraw 
---------------------------------------------------------------------------

-- $Revision$ $Date$
-- JMdict schema for Postgresql

-- Note: The commented-out ALTER TABLE and CREATE INDEX statement
-- (any comment where the "--" starts in the first column and is
-- followed immediately by text with no intervening space character,
-- is not really a comment.  It is extracted by a tool, put into 
-- a separate file, and execute during the database build phase.
-- It is kept in here in comment form in order to provide a more
-- cohesive view of the schema.

CREATE TABLE kwdial (
    id SMALLINT PRIMARY KEY,
    kw VARCHAR(20) NOT NULL UNIQUE,
    descr VARCHAR(255));

CREATE TABLE kwfreq (
    id SMALLINT PRIMARY KEY,
    kw VARCHAR(20) NOT NULL UNIQUE,
    descr VARCHAR(255));

CREATE TABLE kwfld (
    id SMALLINT PRIMARY KEY,
    kw VARCHAR(20) NOT NULL UNIQUE,
    descr VARCHAR(255));

CREATE TABLE kwkinf (
    id SMALLINT PRIMARY KEY,
    kw VARCHAR(20) NOT NULL,
    descr VARCHAR(255));

CREATE TABLE kwlang (
    id SMALLINT PRIMARY KEY,
    kw VARCHAR(20) NOT NULL UNIQUE,
    descr VARCHAR(255));

CREATE TABLE kwmisc (
    id SMALLINT PRIMARY KEY,
    kw VARCHAR(20) NOT NULL,
    descr VARCHAR(255));

CREATE TABLE kwpos (
    id SMALLINT PRIMARY KEY,
    kw VARCHAR(20) NOT NULL UNIQUE,
    descr VARCHAR(255));

CREATE TABLE kwrinf (
    id SMALLINT PRIMARY KEY,
    kw VARCHAR(20) NOT NULL UNIQUE,
    descr VARCHAR(255));

CREATE TABLE kwsrc (
    id SMALLINT PRIMARY KEY,
    kw VARCHAR(20) NOT NULL UNIQUE,
    descr VARCHAR(255));

CREATE TABLE kwstat (
    id SMALLINT PRIMARY KEY,
    kw VARCHAR(20) NOT NULL UNIQUE,
    descr VARCHAR(255));

CREATE TABLE kwxref (
    id SMALLINT PRIMARY KEY,
    kw VARCHAR(20) NOT NULL UNIQUE,
    descr VARCHAR(255));



CREATE TABLE entr (
    id SERIAL NOT NULL PRIMARY KEY,
    src SMALLINT NOT NULL,
    seq INT NOT NULL,
    stat SMALLINT NOT NULL,
    srcnote VARCHAR(255) NULL,
    notes TEXT);
--CREATE INDEX entr_seq ON entr(seq);
--CREATE INDEX entr_stat ON entr(stat) WHERE stat!=2;
--ALTER TABLE entr ADD CONSTRAINT entr_src_fkey FOREIGN KEY (src) REFERENCES kwsrc(id);
--ALTER TABLE entr ADD CONSTRAINT entr_stat_fkey FOREIGN KEY (stat) REFERENCES kwstat(id);

CREATE SEQUENCE seq 
   INCREMENT 10 MINVALUE 1000000 MAXVALUE 8999999 
   NO CYCLE OWNED BY entr.seq;

CREATE TABLE rdng (
    entr INT NOT NULL,
    rdng SMALLINT NOT NULL,
    txt VARCHAR(2048) NOT NULL,
    PRIMARY KEY(entr,rdng));
--CREATE INDEX rdng_txt ON rdng(txt);
    -- CREATE UNIQUE INDEX rdng_txt1 ON rdng(entr,txt);
--ALTER TABLE rdng ADD CONSTRAINT rdng_entr_fkey FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE;

CREATE TABLE kanj (
    entr INT NOT NULL,
    kanj SMALLINT NOT NULL,
    txt VARCHAR(2048) NOT NULL,
    PRIMARY KEY(entr,kanj));
--CREATE INDEX kanj_txt ON kanj(txt);
  -- CREATE UNIQUE INDEX kanj_txt1 ON kanj(entr,txt);
--ALTER TABLE kanj ADD CONSTRAINT kanj_entr_fkey FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE;

CREATE TABLE sens (
    entr INT NOT NULL,
    sens SMALLINT NOT NULL,
    notes TEXT,
    PRIMARY KEY(entr,sens));
--ALTER TABLE sens ADD CONSTRAINT sens_entr_fkey FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE;

CREATE TABLE gloss (
    entr INT NOT NULL,
    sens SMALLINT NOT NULL,
    gloss SMALLINT NOT NULL,
    lang SMALLINT NOT NULL,
    txt VARCHAR(2048) NOT NULL,
    PRIMARY KEY(entr,sens,gloss));
--CREATE INDEX gloss_txt ON gloss(txt); 
    -- CREATE UNIQUE INDEX gloss_txt1 ON gloss(sens,txt);
--ALTER TABLE gloss ADD CONSTRAINT gloss_entr_fkey FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE gloss ADD CONSTRAINT gloss_lang_fkey FOREIGN KEY (lang) REFERENCES kwlang(id);

CREATE TABLE xref (
    entr INT NOT NULL,
    sens SMALLINT NOT NULL,
    xentr INT NOT NULL,
    xsens SMALLINT NOT NULL,
    typ SMALLINT NOT NULL,
    notes TEXT,
    PRIMARY KEY (entr,sens,xentr,xsens,typ));
--CREATE INDEX xref_xentr ON xref(xentr,xsens);
--ALTER TABLE xref ADD CONSTRAINT xref_entr_fkey FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE xref ADD CONSTRAINT xref_xentr_fkey FOREIGN KEY (xentr,xsens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE xref ADD CONSTRAINT xref_typ_fkey FOREIGN KEY (typ) REFERENCES kwxref(id);


CREATE TABLE hist (
    entr INT NOT NULL,
    hist SMALLINT NOT NULL,
    stat SMALLINT NOT NULL,
    dt TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    who VARCHAR(250),
    diff TEXT,
    notes TEXT,
    PRIMARY KEY(entr,hist));
--CREATE INDEX hist_dt ON hist(dt);
--CREATE INDEX hist_who ON hist(who);
--ALTER TABLE hist ADD CONSTRAINT hist_entr_fkey FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE hist ADD CONSTRAINT hist_stat_fkey FOREIGN KEY (stat) REFERENCES kwstat(id);

CREATE TABLE audio (
    entr INT NOT NULL,
    rdng SMALLINT NOT NULL,
    audio SMALLINT NOT NULL,
    fname VARCHAR(255) NOT NULL,
    strt INT NOT NULL,
    leng INT NOT NULL,
    notes TEXT,
    PRIMARY KEY(entr,rdng,audio));
--CREATE INDEX audio_fname ON audio(fname);
--ALTER TABLE audio ADD CONSTRAINT audio_entr_fkey FOREIGN KEY (entr,rdng) REFERENCES rdng(entr,rdng) ON DELETE CASCADE ON UPDATE CASCADE;

CREATE TABLE editor (
    id SERIAL NOT NULL PRIMARY KEY,
    name VARCHAR(80) NOT NULL,
    email VARCHAR(250),
    notes TEXT);
--CREATE INDEX editor_email ON editor(email);
--CREATE UNIQUE INDEX editor_name ON editor(name);

CREATE TABLE xresolv (
    entr INT NOT NULL,
    sens SMALLINT NOT NULL,
    ord SMALLINT NOT NULL,
    typ SMALLINT NOT NULL,
    rtxt VARCHAR(250),
    ktxt VARCHAR(250),
    tsens SMALLINT,
    notes VARCHAR(250),
    PRIMARY KEY(entr,sens,ord),
    CHECK (rtxt NOTNULL OR ktxt NOTNULL));
--CREATE INDEX xresolv_rdng ON xresolv(rtxt);
--CREATE INDEX xresolv_kanj ON xresolv(ktxt);
--ALTER TABLE xresolv ADD CONSTRAINT xresolv_entr_fkey FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE xresolv ADD CONSTRAINT xresolv_typ_fkey FOREIGN KEY (typ) REFERENCES kwxref(id);

CREATE TABLE freq (
    entr INT NOT NULL,
    rdng SMALLINT NULL,
    kanj SMALLINT NULL,
    kw SMALLINT NOT NULL,
    value INT,
    UNIQUE (entr,rdng,kanj,kw),
    CHECK (rdng NOTNULL OR kanj NOTNULL));
--CREATE UNIQUE INDEX freq_idx1 ON freq(entr,(coalesce(rdng,999)),(coalesce(kanj,999)),kw); 
--ALTER TABLE freq ADD CONSTRAINT freq_entr_fkey FOREIGN KEY (entr,kanj) REFERENCES kanj(entr,kanj) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE freq ADD CONSTRAINT freq_entr_fkey1 FOREIGN KEY (entr,rdng) REFERENCES rdng(entr,rdng) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE freq ADD CONSTRAINT freq_kw_fkey FOREIGN KEY (kw) REFERENCES kwfreq(id);



CREATE TABLE dial (
    entr INT NOT NULL,
    kw SMALLINT NOT NULL,
    PRIMARY KEY (entr,kw));
--ALTER TABLE dial ADD CONSTRAINT dial_entr_fkey FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE dial ADD CONSTRAINT dial_kw_fkey FOREIGN KEY (kw) REFERENCES kwdial(id);

CREATE TABLE fld (
    entr INT NOT NULL,
    sens SMALLINT NOT NULL,
    kw SMALLINT NOT NULL,
    PRIMARY KEY (entr,sens,kw));
--ALTER TABLE fld ADD CONSTRAINT fld_entr_fkey FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE fld ADD CONSTRAINT fld_kw_fkey FOREIGN KEY (kw) REFERENCES kwfld(id);

CREATE TABLE kinf (
    entr INT NOT NULL,
    kanj SMALLINT NOT NULL,
    kw SMALLINT NOT NULL,
    PRIMARY KEY (entr,kanj,kw));
--ALTER TABLE kinf ADD CONSTRAINT kinf_entr_fkey FOREIGN KEY (entr,kanj) REFERENCES kanj(entr,kanj) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE kinf ADD CONSTRAINT kinf_kw_fkey FOREIGN KEY (kw) REFERENCES kwkinf(id);

CREATE TABLE lang (
    entr INT NOT NULL,
    kw SMALLINT NOT NULL,
    PRIMARY KEY (entr,kw));
--ALTER TABLE lang ADD CONSTRAINT lang_entr_fkey FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE lang ADD CONSTRAINT lang_kw_fkey FOREIGN KEY (kw) REFERENCES kwlang(id);

CREATE TABLE misc (
    entr INT NOT NULL,
    sens SMALLINT NOT NULL,
    kw SMALLINT NOT NULL,
    PRIMARY KEY (entr,sens,kw));
--ALTER TABLE misc ADD CONSTRAINT misc_entr_fkey FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE misc ADD CONSTRAINT misc_kw_fkey FOREIGN KEY (kw) REFERENCES kwmisc(id);

CREATE TABLE pos (
    entr INT NOT NULL,
    sens SMALLINT NOT NULL,
    kw SMALLINT  NOT NULL,
    PRIMARY KEY (entr,sens,kw));
--ALTER TABLE pos ADD CONSTRAINT pos_entr_fkey FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE pos ADD CONSTRAINT pos_kw_fkey FOREIGN KEY (kw) REFERENCES kwpos(id);

CREATE TABLE rinf (
    entr INT NOT NULL,
    rdng SMALLINT NOT NULL,
    kw SMALLINT NOT NULL,
    PRIMARY KEY (entr,rdng,kw));
--ALTER TABLE rinf ADD CONSTRAINT rinf_entr_fkey FOREIGN KEY (entr,rdng) REFERENCES rdng(entr,rdng) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE rinf ADD CONSTRAINT rinf_kw_fkey FOREIGN KEY (kw) REFERENCES kwrinf(id);


CREATE TABLE restr (
    entr INT NOT NULL,
    rdng SMALLINT NOT NULL,
    kanj SMALLINT NOT NULL,
    PRIMARY KEY (entr,rdng,kanj));
--ALTER TABLE restr ADD CONSTRAINT restr_entr_fkey FOREIGN KEY (entr,rdng) REFERENCES rdng(entr,rdng) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE restr ADD CONSTRAINT restr_entr_fkey1 FOREIGN KEY (entr,kanj) REFERENCES kanj(entr,kanj) ON DELETE CASCADE ON UPDATE CASCADE;

CREATE TABLE stagr (
    entr INT NOT NULL,
    sens SMALLINT NOT NULL,
    rdng SMALLINT NOT NULL,
    PRIMARY KEY (entr,sens,rdng));
--ALTER TABLE stagr ADD CONSTRAINT stagr_entr_fkey FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE stagr ADD CONSTRAINT stagr_entr_fkey1 FOREIGN KEY (entr,rdng) REFERENCES rdng(entr,rdng) ON DELETE CASCADE ON UPDATE CASCADE;

CREATE TABLE stagk (
    entr INT NOT NULL,
    sens SMALLINT NOT NULL,
    kanj SMALLINT NOT NULL,
    PRIMARY KEY (entr,sens,kanj));
--ALTER TABLE stagk ADD CONSTRAINT stagk_entr_fkey FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE stagk ADD CONSTRAINT stagk_entr_fkey1 FOREIGN KEY (entr,kanj) REFERENCES kanj(entr,kanj) ON DELETE CASCADE ON UPDATE CASCADE;
