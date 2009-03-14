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

\unset ON_ERROR_STOP 
CREATE LANGUAGE 'plpgsql';
\set ON_ERROR_STOP 

-- Note: The commented-out ALTER TABLE and CREATE INDEX statements
-- (where the comment's "--" starts in the first column and is
-- followed immediately by text with no intervening space character,
-- are not really comments.  They is extracted by a tool, put into 
-- a separate file, and execute during the database build phase.
-- They are kept in here in comment form in order to provide a more
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

CREATE TABLE kwginf (
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

CREATE TABLE kwstat (
    id SMALLINT PRIMARY KEY,
    kw VARCHAR(20) NOT NULL UNIQUE,
    descr VARCHAR(255));

CREATE TABLE kwxref (
    id SMALLINT PRIMARY KEY,
    kw VARCHAR(20) NOT NULL UNIQUE,
    descr VARCHAR(255));

CREATE TABLE kwgrp (
    id SERIAL PRIMARY KEY,
    kw VARCHAR(20) NOT NULL UNIQUE,
    descr VARCHAR(255));

CREATE TABLE kwsrc (
    id SMALLINT PRIMARY KEY,
    kw VARCHAR(20) NOT NULL UNIQUE,
    descr VARCHAR(255),
    dt DATE,
    notes VARCHAR(255),
    seq VARCHAR(20) NOT NULL,	-- Name of sequence to create for entr.seq default values.
    sinc SMALLINT,		-- Sequence INCREMENT value used when creating seq.
    smin INT,			-- Sequence MINVALUE value used when creating seq.
    smax INT);			-- Sequence MAXVALUE value used when creating seq.

CREATE OR REPLACE FUNCTION kwsrc_updseq() RETURNS trigger AS $kwsrc_updseq$
    -- Create a sequence for entr.seq numbers whenever a new
    -- row is added to table 'kwsrc' (and delete it when row 
    -- is deleted).  This allows every corpus to maintain its
    -- own sequence.  The sequence is *not* made default value
    -- of entr.seq (because there multiple sequences are used
    -- depending on entr.src); the API is responsible for choosing
    -- and using the correct sequence. 

    DECLARE seqnm VARCHAR; newseq VARCHAR := ''; oldseq VARCHAR := '';
	partinc VARCHAR := ''; partmin VARCHAR := ''; partmax VARCHAR := '';
	usedcnt INT;
    BEGIN
	IF TG_OP != 'DELETE' THEN newseq=NEW.seq; END IF;
	IF TG_OP != 'INSERT' THEN oldseq=OLD.seq; END IF;
	IF oldseq != '' THEN
	    -- 'kwsrc' row was deleted or updated.  Drop the deleted sequence
	    -- if not used in any other rows.
	    SELECT INTO usedcnt COUNT(*) FROM kwsrc WHERE seq=oldseq;
	    IF usedcnt = 0 THEN
		EXECUTE 'DROP SEQUENCE IF EXISTS '||oldseq;
		END IF;
	ELSEIF newseq != '' THEN 
	    -- 'kwsrc' row was inserted or updated.  See if sequence 'newseq'
	    -- already exists, and if so, do nothing.  If not, create it.
	    IF NEW.sinc IS NOT NULL THEN
		partinc = ' INCREMENT ' || NEW.sinc;
		END IF;
	    IF NEW.smin IS NOT NULL THEN
		partmin = ' MINVALUE ' || NEW.smin;
		END IF;
	    IF NEW.smax IS NOT NULL THEN
		partmax = ' MAXVALUE ' || NEW.smax;
		END IF;
	    IF NOT EXISTS (SELECT relname FROM pg_class WHERE relname=NEW.seq AND relkind='S') THEN
	        EXECUTE 'CREATE SEQUENCE '||newseq||partinc||partmin||partmax||' NO CYCLE';
		END IF;
	    END IF;
	RETURN NEW;
        END;
    $kwsrc_updseq$ LANGUAGE plpgsql;

CREATE TRIGGER kwsrc_updseq AFTER INSERT OR UPDATE OR DELETE ON kwsrc
    FOR EACH ROW EXECUTE PROCEDURE kwsrc_updseq();

CREATE OR REPLACE FUNCTION syncseq() RETURNS VOID AS $syncseq$
    -- Syncronises all the sequences specified in table 'kwsrc'
    -- (which are used for generation of corpus specific seq numbers.)
    DECLARE cur REFCURSOR; seqname VARCHAR; maxseq INT;
    BEGIN
	-- The following cursor gets the max value of entr.seq for each corpus
	-- for entr.seq values within the range of the associated seq (where
	-- the range is what was given in kwsrc table .smin and .smax values.  
	-- [Don't confuse kwsrc.seq (name of the Postgresq1 sequence that
	-- generates values used for entry seq numbers) with entr.seq (the
	-- entry sequence numbers themselves).]  Since the kwsrc.smin and
	-- .smax values can be changed after the sequence was created, and
	-- doing so may screwup the operation herein, don't do that!  It is 
	-- also possible that multiple kwsrc's can share a common 'seq' value,
	-- but have different 'smin' and 'smax' values -- again, don't do that!
	-- The rather elaborate join below is done to make sure we get a row
	-- for every kwsrc.seq value, even if there are no entries that
	-- reference that kwsrc row. 

	OPEN cur FOR 
	    SELECT ks.sqname, COALESCE(ke.mxseq,ks.smin,1) 
	    FROM 
		(SELECT seq AS sqname, MIN(smin) AS smin
		FROM kwsrc 
		GROUP BY seq) AS ks
	    LEFT JOIN	-- Find the max entr.seq number in use, but ignoring
			-- any that are autside the min/max bounds of the kwsrc's
			-- sequence.
		(SELECT k.seq AS sqname, MAX(e.seq) AS mxseq
		FROM entr e 
		JOIN kwsrc k ON k.id=e.src 
		WHERE e.seq BETWEEN COALESCE(k.smin,1)
		    AND COALESCE(k.smax,9223372036854775807)
		GROUP BY k.seq,k.smin) AS ke 
	    ON ke.sqname=ks.sqname;
	LOOP
	    FETCH cur INTO seqname, maxseq;
	    EXIT WHEN NOT FOUND;
	    EXECUTE 'SELECT setval(''' || seqname || ''', ' || maxseq || ')';
	    END LOOP;
	END;
    $syncseq$ LANGUAGE plpgsql;


CREATE TABLE entr (
    id SERIAL NOT NULL PRIMARY KEY,
    src SMALLINT NOT NULL,
    stat SMALLINT NOT NULL,
    seq INT NOT NULL CHECK(seq>0),
    dfrm INT,
    unap BOOLEAN NOT NULL,
    srcnote VARCHAR(255) NULL,
    notes TEXT);
--CREATE INDEX entr_seq ON entr(seq);
--CREATE INDEX entr_stat ON entr(stat) WHERE stat!=2;
--CREATE INDEX entr_dfrm ON entr(dfrm) WHERE dfrm IS NOT NULL;
--CREATE INDEX entr_unap ON entr(unap) WHERE unap;
--ALTER TABLE entr ADD CONSTRAINT entr_src_fkey FOREIGN KEY (src) REFERENCES kwsrc(id) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE entr ADD CONSTRAINT entr_stat_fkey FOREIGN KEY (stat) REFERENCES kwstat(id);
--ALTER TABLE entr ADD CONSTRAINT entr_dfrm_fkey FOREIGN KEY (dfrm) REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE;

CREATE FUNCTION entr_seqdef() RETURNS trigger AS $entr_seqdef$
    -- This function is used as an "insert" trigger on table 
    -- 'entr'.  It checks the 'seq' field value and if NULL,
    -- provides a default value from one of several sequences,
    -- with the sequence used determined by the value if the
    -- new row's 'src' field.  The name of the sequence to be
    -- used is given in the 'seq' column of table 'kwsrc'.

    DECLARE seqnm VARCHAR;
    BEGIN
        IF NEW.seq IS NOT NULL THEN 
	    RETURN NEW;
	    END IF;
	SELECT seq INTO seqnm FROM kwsrc WHERE id=NEW.src;
        NEW.seq :=  NEXTVAL(seqnm);
        RETURN NEW;
        END;
    $entr_seqdef$ LANGUAGE plpgsql;

CREATE TRIGGER entr_seqdef BEFORE INSERT ON entr
    FOR EACH ROW EXECUTE PROCEDURE entr_seqdef();


CREATE TABLE rdng (
    entr INT NOT NULL,
    rdng SMALLINT NOT NULL CHECK(rdng>0),
    txt VARCHAR(2048) NOT NULL,
    PRIMARY KEY(entr,rdng));
--CREATE INDEX rdng_txt ON rdng(txt);
--CREATE UNIQUE INDEX rdng_txt1 ON rdng(entr,txt);
--CREATE INDEX rdng_txt2 ON rdng(txt varchar_pattern_ops); --For fast LIKE 'xxx%'
--ALTER TABLE rdng ADD CONSTRAINT rdng_entr_fkey FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE;

CREATE TABLE kanj (
    entr INT NOT NULL,
    kanj SMALLINT NOT NULL CHECK(kanj>0),
    txt VARCHAR(2048) NOT NULL,
    PRIMARY KEY(entr,kanj));
--CREATE INDEX kanj_txt ON kanj(txt);
--CREATE UNIQUE INDEX kanj_txt1 ON kanj(entr,txt);
--CREATE INDEX kanj_txt2 ON kanj(txt varchar_pattern_ops); --For fast LIKE 'xxx%'
--ALTER TABLE kanj ADD CONSTRAINT kanj_entr_fkey FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE;

CREATE TABLE sens (
    entr INT NOT NULL,
    sens SMALLINT NOT NULL CHECK(sens>0),
    notes TEXT,
    PRIMARY KEY(entr,sens));
--ALTER TABLE sens ADD CONSTRAINT sens_entr_fkey FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE;

CREATE TABLE gloss (
    entr INT NOT NULL,
    sens SMALLINT NOT NULL,
    gloss SMALLINT NOT NULL CHECK(gloss>0),
    lang SMALLINT NOT NULL DEFAULT 1,
    ginf SMALLINT NOT NULL DEFAULT 1,
    txt VARCHAR(2048) NOT NULL,
    PRIMARY KEY(entr,sens,gloss));
--CREATE INDEX gloss_txt ON gloss(txt); 
--CREATE UNIQUE INDEX gloss_txt1 ON gloss(entr,sens,lang,txt);
--CREATE INDEX gloss_txt2 ON gloss(lower(txt) varchar_pattern_ops); --For case-insensitive LIKE 'xxx%'
--CREATE INDEX gloss_txt3 ON gloss(lower(txt)); 		    --For case-insensitive '='
--ALTER TABLE gloss ADD CONSTRAINT gloss_entr_fkey FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE gloss ADD CONSTRAINT gloss_lang_fkey FOREIGN KEY (lang) REFERENCES kwlang(id);

CREATE TABLE xref (
    entr INT NOT NULL,
    sens SMALLINT NOT NULL,
    xref SMALLINT NOT NULL CHECK(xref>0),
    typ SMALLINT NOT NULL,
    xentr INT NOT NULL CHECK(xentr!=entr),
    xsens SMALLINT NOT NULL,
    rdng SMALLINT,
    kanj SMALLINT CHECK(kanj IS NOT NULL OR rdng IS NOT NULL),
    notes TEXT,
    PRIMARY KEY (entr,sens,xref));
    --## The following index disabled because it is violated by Examples file xrefs.
    --CREATE UNIQUE INDEX xref_entr_unq ON xref(entr,sens,typ,xentr,xsens);
--CREATE INDEX xref_xentr ON xref(xentr,xsens);
--ALTER TABLE xref ADD CONSTRAINT xref_entr_fkey FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE xref ADD CONSTRAINT xref_xentr_fkey FOREIGN KEY (xentr,xsens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE xref ADD CONSTRAINT xref_typ_fkey FOREIGN KEY (typ) REFERENCES kwxref(id);
--ALTER TABLE xref ADD CONSTRAINT xref_rdng_fkey FOREIGN KEY (xentr,rdng) REFERENCES rdng(entr,rdng) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE xref ADD CONSTRAINT xref_kanj_fkey FOREIGN KEY (xentr,kanj) REFERENCES kanj(entr,kanj) ON DELETE CASCADE ON UPDATE CASCADE;

CREATE TABLE hist (
    entr INT NOT NULL,
    hist SMALLINT NOT NULL CHECK(hist>0),
    stat SMALLINT NOT NULL,
    unap BOOLEAN NOT NULL,
    dt TIMESTAMP NOT NULL DEFAULT NOW(),
    userid VARCHAR(20),
    name VARCHAR(60),
    email VARCHAR(120),
    diff TEXT,
    refs TEXT,
    notes TEXT,
    PRIMARY KEY(entr,hist));
--CREATE INDEX hist_dt ON hist(dt);
--CREATE INDEX hist_email ON hist(email);
--CREATE INDEX hist_userid ON hist(userid);
--ALTER TABLE hist ADD CONSTRAINT hist_entr_fkey FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE hist ADD CONSTRAINT hist_stat_fkey FOREIGN KEY (stat) REFERENCES kwstat(id);

CREATE TABLE dial (
    entr INT NOT NULL,
    sens INT NOT NULL,
    ord SMALLINT NOT NULL,
    kw SMALLINT NOT NULL DEFAULT 1,
    PRIMARY KEY (entr,sens,kw));
--ALTER TABLE dial ADD CONSTRAINT dial_entr_fkey FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE dial ADD CONSTRAINT dial_kw_fkey FOREIGN KEY (kw) REFERENCES kwdial(id);

CREATE TABLE fld (
    entr INT NOT NULL,
    sens SMALLINT NOT NULL,
    ord SMALLINT NOT NULL,
    kw SMALLINT NOT NULL,
    PRIMARY KEY (entr,sens,kw));
--ALTER TABLE fld ADD CONSTRAINT fld_entr_fkey FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE fld ADD CONSTRAINT fld_kw_fkey FOREIGN KEY (kw) REFERENCES kwfld(id);

CREATE TABLE freq (
    entr INT NOT NULL,
    rdng SMALLINT NULL,
    kanj SMALLINT NULL,
    kw SMALLINT NOT NULL,
    value INT,
    UNIQUE (entr,rdng,kanj,kw),
    CHECK (rdng NOTNULL OR kanj NOTNULL)) 
      WITH OIDS;
--CREATE UNIQUE INDEX freq_idx1 ON freq(entr,(coalesce(rdng,999)),(coalesce(kanj,999)),kw); 
--ALTER TABLE freq ADD CONSTRAINT freq_entr_fkey FOREIGN KEY (entr,kanj) REFERENCES kanj(entr,kanj) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE freq ADD CONSTRAINT freq_entr_fkey1 FOREIGN KEY (entr,rdng) REFERENCES rdng(entr,rdng) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE freq ADD CONSTRAINT freq_kw_fkey FOREIGN KEY (kw) REFERENCES kwfreq(id);

CREATE TABLE kinf (
    entr INT NOT NULL,
    kanj SMALLINT NOT NULL,
    ord SMALLINT NOT NULL,
    kw SMALLINT NOT NULL,
    PRIMARY KEY (entr,kanj,kw));
--ALTER TABLE kinf ADD CONSTRAINT kinf_entr_fkey FOREIGN KEY (entr,kanj) REFERENCES kanj(entr,kanj) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE kinf ADD CONSTRAINT kinf_kw_fkey FOREIGN KEY (kw) REFERENCES kwkinf(id);

CREATE TABLE lsrc (
    entr INT NOT NULL,
    sens SMALLINT NOT NULL,
    ord SMALLINT NOT NULL,
    lang SMALLINT NOT NULL DEFAULT 1,
    txt VARCHAR(250) NOT NULL,
    part BOOLEAN DEFAULT FALSE,
    wasei BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (entr,sens,lang,txt));
--ALTER TABLE lsrc ADD CONSTRAINT lsrc_entr_fkey FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE lsrc ADD CONSTRAINT lsrc_lang_fkey FOREIGN KEY (lang) REFERENCES kwlang(id);

CREATE TABLE misc (
    entr INT NOT NULL,
    sens SMALLINT NOT NULL,
    ord SMALLINT NOT NULL,
    kw SMALLINT NOT NULL,
    PRIMARY KEY (entr,sens,kw));
--ALTER TABLE misc ADD CONSTRAINT misc_entr_fkey FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE misc ADD CONSTRAINT misc_kw_fkey FOREIGN KEY (kw) REFERENCES kwmisc(id);

CREATE TABLE pos (
    entr INT NOT NULL,
    sens SMALLINT NOT NULL,
    ord SMALLINT NOT NULL,
    kw SMALLINT  NOT NULL,
    PRIMARY KEY (entr,sens,kw));
--ALTER TABLE pos ADD CONSTRAINT pos_entr_fkey FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE pos ADD CONSTRAINT pos_kw_fkey FOREIGN KEY (kw) REFERENCES kwpos(id);

CREATE TABLE rinf (
    entr INT NOT NULL,
    rdng SMALLINT NOT NULL,
    ord SMALLINT NOT NULL,
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

CREATE TABLE grp (
    entr INT NOT NULL,
    kw INT NOT NULL,
    ord INT NOT NULL,
    notes VARCHAR(250),
    PRIMARY KEY (entr,kw));
--ALTER TABLE grp ADD CONSTRAINT grp_entr_fkey FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE grp ADD CONSTRAINT grp_kw_fkey  FOREIGN KEY (kw)  REFERENCES kwgrp(id)  ON DELETE CASCADE ON UPDATE CASCADE;
--CREATE INDEX grp_kw ON grp(kw);

-------------------------------
-- Tables for audio sound clips
-------------------------------

CREATE TABLE sndvol (	-- Audio media volume (directory, CD, etc)
    id SERIAL NOT NULL PRIMARY KEY,	-- Volume id.
    title VARCHAR(50),			-- Volume title (for display).
    loc VARCHAR(500),			-- Volume location (directory name or CD id).
    type SMALLINT NOT NULL,		-- Volume type, 1:file, 2:cd
    idstr VARCHAR(100),			-- If type==2, this is CD ID string.
    corp INT,				-- Corpus id (in table kwsrc).
    notes TEXT);			-- Ad hoc notes pertinent to this sound volume.
-- Anticipate this table will generally be too small to benefit from indexes.
--ALTER TABLE sndvol ADD CONSTRAINT sndvol_corp_fkey FOREIGN KEY(corp) REFERENCES kwsrc(id) ON UPDATE CASCADE ON DELETE CASCADE;

CREATE TABLE sndfile (	-- Audio file, track, etc.
    id SERIAL NOT NULL PRIMARY KEY,	-- File id.
    vol INT NOT NULL,			-- Volume id (in table sndvol).
    title VARCHAR(50),			-- File title (for display).
    loc VARCHAR(500),			-- File location in vol (filename or track number).
    type SMALLINT,			-- File type.
    notes TEXT);			-- Ad hoc notes pertinent to this sound file.
--CREATE INDEX sndfile_vol ON sndfile(vol);
--ALTER TABLE sndfile ADD CONSTRAINT sndfile_vol_fkey FOREIGN KEY(vol) REFERENCES sndvol(id) ON UPDATE CASCADE ON DELETE CASCADE;

CREATE TABLE snd (	-- Audio sound clip.
    id SERIAL NOT NULL PRIMARY KEY,	-- Sound id.
    file SMALLINT NOT NULL,		-- File id (in table sndfile).
    strt INT NOT NULL DEFAULT(0),	-- Start of clip in file (10ms units).
    leng INT NOT NULL DEFAULT(0),	-- Length of clip in file (10ms units).
    trns TEXT,				-- Transcription of sound clip (typ. japanese).
    notes VARCHAR(255));		-- Ad hoc notes pertinent to this clip.
--ALTER TABLE snd ADD CONSTRAINT snd_file_fkey FOREIGN KEY(file) REFERENCES sndfile(id) ON UPDATE CASCADE ON DELETE CASCADE;

CREATE TABLE entrsnd (	-- Entry to sound clip map.
    entr INT NOT NULL,		-- Entry id.
    ord SMALLINT NOT NULL,	-- Order in entry.
    snd INT NOT NULL,		-- Sound id.
    PRIMARY KEY(entr,snd));
--CREATE INDEX entrsnd_snd ON entrsnd(snd);
--ALTER TABLE entrsnd ADD CONSTRAINT entrsnd_entr_fkey FOREIGN KEY(snd) REFERENCES snd(id) ON UPDATE CASCADE ON DELETE CASCADE;
--ALTER TABLE entrsnd ADD CONSTRAINT entrsnd_entr_fkey1 FOREIGN KEY(entr) REFERENCES entr(id) ON UPDATE CASCADE ON DELETE CASCADE;

CREATE TABLE rdngsnd (	-- Reading to sound clip map.
    entr INT NOT NULL,		-- Entry id.
    rdng INT NOT NULL,		-- Reading number.
    ord SMALLINT NOT NULL,	-- Order in reading.
    snd INT NOT NULL,		-- Sound id.
    PRIMARY KEY(entr,rdng,snd));
--CREATE INDEX rdngsnd_snd ON rdngsnd(snd);
--ALTER TABLE rdngsnd ADD CONSTRAINT rdngsnd_entr_fkey FOREIGN KEY(snd) REFERENCES snd(id) ON UPDATE CASCADE ON DELETE CASCADE;
--ALTER TABLE rdngsnd ADD CONSTRAINT rdngsnd_entr_fkey1 FOREIGN KEY(entr,rdng) REFERENCES rdng(entr,rdng) ON UPDATE CASCADE ON DELETE CASCADE;


-- The following tables are used for resolving textual xrefs to 
-- actual entries and senses when loading data from external files.
-- See file pg/xresolv.sql for a description of the process.

CREATE TABLE xresolv (
    entr INT NOT NULL,		-- Entry xref occurs in.
    sens SMALLINT NOT NULL,	-- Sense number xref occurs in.
    typ SMALLINT NOT NULL,	-- Type of xref (table kwxref).
    ord SMALLINT NOT NULL,	-- Order of xref in sense.
    rtxt VARCHAR(250),		-- Reading text of target given in xref.
    ktxt VARCHAR(250),		-- Kanji text of target given in xref.
    tsens SMALLINT,		-- Target sense number.
    notes VARCHAR(250),		-- Notes.
    prio BOOLEAN DEFAULT FALSE,	-- True if this is a Tanaka corpus exemplar.
    PRIMARY KEY(entr,sens,typ,ord),
    CHECK (rtxt NOTNULL OR ktxt NOTNULL));
--CREATE INDEX xresolv_rdng ON xresolv(rtxt);
--CREATE INDEX xresolv_kanj ON xresolv(ktxt);
--ALTER TABLE xresolv ADD CONSTRAINT xresolv_entr_fkey FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE xresolv ADD CONSTRAINT xresolv_typ_fkey FOREIGN KEY (typ) REFERENCES kwxref(id);

-------------------
--  Kanjidic tables
-------------------

CREATE TABLE kwcinf(
    id SMALLINT PRIMARY KEY,
    kw VARCHAR(50) NOT NULL UNIQUE,
    descr VARCHAR(250));

CREATE TABLE rad(
    num SMALLINT NOT NULL,	-- Radical (bushu) number.
    var SMALLINT NOT NULL,	-- Variant number.
    rchr CHAR(1),		-- Radical character from unicode blocks CJK radicals
				--   2F00-2FDF and Radicals Supplement 2E80-2EFF.
    chr CHAR(1),		-- Radical character from outside radical blocks.
    strokes SMALLINT,		-- Number of strokes.
    loc	CHAR(1) 		-- Location code.
	CHECK(loc is NULL OR loc IN('O','T','B','R','L','E','V')),
    name VARCHAR(50),		-- Name of radical (japanese).
    examples VARCHAR(20),	-- Characters that include the radical.
    PRIMARY KEY (num,var));

CREATE TABLE chr(
    entr INT PRIMARY KEY,	-- Defines readings and meanings, but not kanji.
    chr CHAR(1) NOT NULL,	-- Defines kanji.
    bushu SMALLINT,		-- Radical number.
    strokes SMALLINT,
    freq SMALLINT,
    grade SMALLINT,
    jlpt SMALLINT,
    radname VARCHAR(50));
--CREATE UNIQUE INDEX chr_chr ON chr(chr);
--ALTER TABLE chr ADD CONSTRAINT chr_entr_fkey FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE;
-- XX ALTER TABLE chr ADD CONSTRAINT chr_rad_fkey FOREIGN KEY (bushu) REFERENCES rad(num);

CREATE TABLE cinf(
    entr INT NOT NULL,
    kw SMALLINT NOT NULL,
    value VARCHAR(50) NOT NULL,
    mctype VARCHAR(50) NOT NULL DEFAULT(''),
    PRIMARY KEY (entr,kw,value,mctype));
--CREATE INDEX cinf_kw ON cinf(kw);
--CREATE INDEX cinf_val ON cinf(value);
--ALTER TABLE cinf ADD CONSTRAINT chr_entr_fkey FOREIGN KEY (entr) REFERENCES chr(entr) ON DELETE CASCADE ON UPDATE CASCADE;
--ALTER TABLE cinf ADD CONSTRAINT chr_kw_fkey FOREIGN KEY (kw) REFERENCES kwcinf(id) ON DELETE CASCADE ON UPDATE CASCADE;

CREATE TABLE kresolv(
    entr INT NOT NULL,
    kw SMALLINT NOT NULL,
    value VARCHAR(50) NOT NULL,
    PRIMARY KEY(entr,kw,value));
--ALTER TABLE kresolv ADD CONSTRAINT kresolv_entr_fkey FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE;
-- No FK constraint on 'kw' (to kwcinf) because it may have a value of
-- 0, meaning 'ucs', which we don't need or want to be a real cinf item.

