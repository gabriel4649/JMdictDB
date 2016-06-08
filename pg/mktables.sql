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
--  Copyright (c) 2006-2014 Stuart McGraw 
---------------------------------------------------------------------------

-- $Revision$ $Date$
-- JMdict schema for Postgresql

\unset ON_ERROR_STOP 
CREATE LANGUAGE 'plpgsql';
\set ON_ERROR_STOP 

-- Update the DB patch number in the INSERT statement below
-- whenever there is a change to the schema or static data. 
-- At the same time create a patch file in the patches/
-- directory to bring a database at the previous patch level
-- to the current one. 
-- We don't support rolling back patches -- to undo a patch
-- create a new one that undoes the previous one.  Thus the
-- current database patch level should be determined by
-- MAX(level) rather than MAX(dt) (although usually they will
-- correspond.) 
CREATE TABLE dbpatch(
    level INT PRIMARY KEY,
    dt TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'utc'));
INSERT INTO dbpatch(level) VALUES(22);


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

CREATE TABLE kwsrct (
    id SMALLINT PRIMARY KEY,
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
    smin BIGINT,		-- Sequence MINVALUE value used when creating seq.
    smax BIGINT,		-- Sequence MAXVALUE value used when creating seq.
    srct SMALLINT NOT NULL REFERENCES kwsrct(id));

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
    DECLARE cur REFCURSOR; seqname VARCHAR; maxseq BIGINT;
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
    id SERIAL PRIMARY KEY,
    src SMALLINT NOT NULL
      REFERENCES kwsrc(id) ON DELETE CASCADE ON UPDATE CASCADE,
    stat SMALLINT NOT NULL
      REFERENCES kwstat(id),
    seq BIGINT NOT NULL CHECK(seq>0),
    dfrm INT
      REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE,
    unap BOOLEAN NOT NULL,
    srcnote VARCHAR(255) NULL,
    notes TEXT);
CREATE INDEX ON entr(seq);
CREATE INDEX ON entr(stat) WHERE stat!=2;
CREATE INDEX ON entr(dfrm) WHERE dfrm IS NOT NULL;
CREATE INDEX ON entr(unap) WHERE unap;
   -- Following temporarily disabled since it is preventing the 
   -- submission of "approved" entries.
-- -- CREATE UNIQUE INDEX entr_active ON entr(src,seq,stat,unap) WHERE stat=2 AND NOT unap;

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
    entr INT NOT NULL REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE,
    rdng SMALLINT NOT NULL CHECK (rdng>0),
      PRIMARY KEY (entr,rdng),
    txt VARCHAR(2048) NOT NULL);
CREATE INDEX ON rdng(txt);
CREATE UNIQUE INDEX ON rdng(entr,txt);
CREATE INDEX ON rdng(txt varchar_pattern_ops); --For fast LIKE 'xxx%'

CREATE TABLE kanj (
    entr INT NOT NULL REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE,
    kanj SMALLINT NOT NULL CHECK (kanj>0),
      PRIMARY KEY (entr,kanj),
    txt VARCHAR(2048) NOT NULL);
CREATE INDEX ON kanj(txt);
CREATE UNIQUE INDEX ON kanj(entr,txt);
CREATE INDEX ON kanj(txt varchar_pattern_ops); --For fast LIKE 'xxx%'

CREATE TABLE sens (
    entr INT NOT NULL REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE,
    sens SMALLINT NOT NULL CHECK (sens>0),
      PRIMARY KEY (entr,sens),
    notes TEXT);

CREATE TABLE gloss (
    entr INT NOT NULL,
    sens SMALLINT NOT NULL,
      FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE,
    gloss SMALLINT NOT NULL CHECK (gloss>0),
      PRIMARY KEY (entr,sens,gloss),
    lang SMALLINT NOT NULL DEFAULT 1
      REFERENCES kwlang(id),
    ginf SMALLINT NOT NULL DEFAULT 1,
    txt VARCHAR(2048) NOT NULL);
CREATE INDEX ON gloss(txt); 
CREATE UNIQUE INDEX ON gloss(entr,sens,lang,txt);
CREATE INDEX ON gloss(lower(txt) varchar_pattern_ops); --For case-insensitive LIKE 'xxx%'
CREATE INDEX ON gloss(lower(txt)); 		    --For case-insensitive '='

CREATE TABLE xref (
    entr INT NOT NULL,
    sens SMALLINT NOT NULL,
      FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE,
    xref SMALLINT NOT NULL CHECK (xref>0),
    typ SMALLINT NOT NULL
      REFERENCES kwxref(id),
    xentr INT NOT NULL CHECK (xentr!=entr),
    xsens SMALLINT NOT NULL,
      FOREIGN KEY (xentr,xsens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE,
    rdng SMALLINT,
      CONSTRAINT xref_rdng_fkey FOREIGN KEY (xentr,rdng) REFERENCES rdng(entr,rdng) ON DELETE CASCADE ON UPDATE CASCADE,
    kanj SMALLINT CHECK (kanj IS NOT NULL OR rdng IS NOT NULL),
      CONSTRAINT xref_kanj_fkey FOREIGN KEY (xentr,kanj) REFERENCES kanj(entr,kanj) ON DELETE CASCADE ON UPDATE CASCADE,
    notes TEXT,
      PRIMARY KEY (entr,sens,xref,xentr,xsens));
CREATE INDEX ON xref(xentr,xsens);
    --## The following index disabled because it is violated by Examples file xrefs.
    --CREATE UNIQUE INDEX xref_entr_unq ON xref(entr,sens,typ,xentr,xsens);

CREATE TABLE hist (
    entr INT NOT NULL
      REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE,
    hist SMALLINT NOT NULL CHECK (hist>0),
    stat SMALLINT NOT NULL
      REFERENCES kwstat(id),
    unap BOOLEAN NOT NULL,
    dt TIMESTAMP NOT NULL DEFAULT NOW(),
    userid VARCHAR(20),
    name VARCHAR(60),
    email VARCHAR(120),
    diff TEXT,
    refs TEXT,
    notes TEXT,
      PRIMARY KEY (entr,hist));
CREATE INDEX ON hist(dt);
CREATE INDEX ON hist(email);
CREATE INDEX ON hist(userid);

CREATE TABLE dial (
    entr INT NOT NULL,
    sens INT NOT NULL,
      FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE,
    ord SMALLINT NOT NULL,
    kw SMALLINT NOT NULL DEFAULT 1
      REFERENCES kwdial(id),
      PRIMARY KEY (entr,sens,kw));

CREATE TABLE fld (
    entr INT NOT NULL,
    sens SMALLINT NOT NULL,
      FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE,
    ord SMALLINT NOT NULL,
    kw SMALLINT NOT NULL
      REFERENCES kwfld(id),
      PRIMARY KEY (entr,sens,kw));

CREATE TABLE freq (
    entr INT NOT NULL,
    rdng SMALLINT NULL,
      FOREIGN KEY (entr,rdng) REFERENCES rdng(entr,rdng) ON DELETE CASCADE ON UPDATE CASCADE,
    kanj SMALLINT NULL,
      FOREIGN KEY (entr,kanj) REFERENCES kanj(entr,kanj) ON DELETE CASCADE ON UPDATE CASCADE,
    kw SMALLINT NOT NULL
      REFERENCES kwfreq(id),
    value INT,
      UNIQUE (entr,rdng,kanj,kw),
      CHECK (rdng NOTNULL OR kanj NOTNULL)) 
    WITH OIDS;
CREATE UNIQUE INDEX ON freq(entr,(coalesce(rdng,999)),(coalesce(kanj,999)),kw); 

CREATE TABLE kinf (
    entr INT NOT NULL,
    kanj SMALLINT NOT NULL,
      FOREIGN KEY (entr,kanj) REFERENCES kanj(entr,kanj) ON DELETE CASCADE ON UPDATE CASCADE,
    ord SMALLINT NOT NULL,
    kw SMALLINT NOT NULL
      REFERENCES kwkinf(id),
      PRIMARY KEY (entr,kanj,kw));

CREATE TABLE lsrc (
    entr INT NOT NULL,
    sens SMALLINT NOT NULL,
      FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE,
    ord SMALLINT NOT NULL,
    lang SMALLINT NOT NULL DEFAULT 1
      REFERENCES kwlang(id),
    txt VARCHAR(250) NOT NULL,
      PRIMARY KEY (entr,sens,lang,txt),
    part BOOLEAN DEFAULT FALSE,
    wasei BOOLEAN DEFAULT FALSE);

CREATE TABLE misc (
    entr INT NOT NULL,
    sens SMALLINT NOT NULL,
      FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE,
    ord SMALLINT NOT NULL,
    kw SMALLINT NOT NULL
      REFERENCES kwmisc(id),
      PRIMARY KEY (entr,sens,kw));

CREATE TABLE pos (
    entr INT NOT NULL,
    sens SMALLINT NOT NULL,
      FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE,
    ord SMALLINT NOT NULL,
    kw SMALLINT  NOT NULL
      REFERENCES kwpos(id),
      PRIMARY KEY (entr,sens,kw));

CREATE TABLE rinf (
    entr INT NOT NULL,
    rdng SMALLINT NOT NULL,
      FOREIGN KEY (entr,rdng) REFERENCES rdng(entr,rdng) ON DELETE CASCADE ON UPDATE CASCADE,
    ord SMALLINT NOT NULL,
    kw SMALLINT NOT NULL
      REFERENCES kwrinf(id),
      PRIMARY KEY (entr,rdng,kw));

CREATE TABLE restr (
    entr INT NOT NULL,
    rdng SMALLINT NOT NULL,
      FOREIGN KEY (entr,rdng) REFERENCES rdng(entr,rdng) ON DELETE CASCADE ON UPDATE CASCADE,
    kanj SMALLINT NOT NULL,
      FOREIGN KEY (entr,kanj) REFERENCES kanj(entr,kanj) ON DELETE CASCADE ON UPDATE CASCADE,
      PRIMARY KEY (entr,rdng,kanj));

CREATE TABLE stagr (
    entr INT NOT NULL,
    sens SMALLINT NOT NULL,
      FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE,
    rdng SMALLINT NOT NULL,
      FOREIGN KEY (entr,rdng) REFERENCES rdng(entr,rdng) ON DELETE CASCADE ON UPDATE CASCADE,
      PRIMARY KEY (entr,sens,rdng));

CREATE TABLE stagk (
    entr INT NOT NULL,
    sens SMALLINT NOT NULL,
      FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE,
    kanj SMALLINT NOT NULL,
      FOREIGN KEY (entr,kanj) REFERENCES kanj(entr,kanj) ON DELETE CASCADE ON UPDATE CASCADE,
      PRIMARY KEY (entr,sens,kanj));

CREATE TABLE grp (
    entr INT NOT NULL REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE,
    kw INT NOT NULL REFERENCES kwgrp(id)  ON DELETE CASCADE ON UPDATE CASCADE,
      PRIMARY KEY (entr,kw),
    ord INT NOT NULL,
    notes VARCHAR(250));
CREATE INDEX grp_kw ON grp(kw);

-------------------------------
-- Tables for audio sound clips
-------------------------------

CREATE TABLE sndvol (	-- Audio media volume (directory, CD, etc)
    id SERIAL PRIMARY KEY,		-- Volume id.
    title VARCHAR(50),			-- Volume title (for display).
    loc VARCHAR(500),			-- Volume location (directory name or CD id).
    type SMALLINT NOT NULL,		-- Volume type, 1:file, 2:cd
    idstr VARCHAR(100),			-- If type==2, this is CD ID string.
    corp INT 				-- Corpus id (in table kwsrc).
      REFERENCES kwsrc(id) ON UPDATE CASCADE ON DELETE CASCADE,
    notes TEXT);			-- Ad hoc notes pertinent to this sound volume.
-- Anticipate this table will generally be too small to benefit from indexes.

CREATE TABLE sndfile (	-- Audio file, track, etc.
    id SERIAL PRIMARY KEY,		-- File id.
    vol INT NOT NULL 			-- Volume id (in table sndvol).
      REFERENCES sndvol(id) ON UPDATE CASCADE ON DELETE CASCADE,
    title VARCHAR(50),			-- File title (for display).
    loc VARCHAR(500),			-- File location in vol (filename or track number).
    type SMALLINT,			-- File type.
    notes TEXT);			-- Ad hoc notes pertinent to this sound file.
CREATE INDEX ON sndfile(vol);

CREATE TABLE snd (	-- Audio sound clip.
    id SERIAL PRIMARY KEY,		-- Sound id.
    file SMALLINT NOT NULL 		-- File id (in table sndfile).
      REFERENCES sndfile(id) ON UPDATE CASCADE ON DELETE CASCADE,
    strt INT NOT NULL DEFAULT(0),	-- Start of clip in file (10ms units).
    leng INT NOT NULL DEFAULT(0),	-- Length of clip in file (10ms units).
    trns TEXT,				-- Transcription of sound clip (typ. japanese).
    notes VARCHAR(255));		-- Ad hoc notes pertinent to this clip.

CREATE TABLE entrsnd (	-- Entry to sound clip map.
    entr INT NOT NULL		-- Entry id.
      REFERENCES entr(id) ON UPDATE CASCADE ON DELETE CASCADE,
    ord SMALLINT NOT NULL,	-- Order in entry.
    snd INT NOT NULL 		-- Sound id.
      REFERENCES snd(id) ON UPDATE CASCADE ON DELETE CASCADE,
      PRIMARY KEY (entr,snd));
CREATE INDEX ON entrsnd(snd);

CREATE TABLE rdngsnd (	-- Reading to sound clip map.
    entr INT NOT NULL,		-- Entry id.
    rdng INT NOT NULL,		-- Reading number.
      FOREIGN KEY(entr,rdng) REFERENCES rdng(entr,rdng) ON UPDATE CASCADE ON DELETE CASCADE,
    ord SMALLINT NOT NULL,	-- Order in reading.
    snd INT NOT NULL 		-- Sound id.
      REFERENCES snd(id) ON UPDATE CASCADE ON DELETE CASCADE,
    PRIMARY KEY (entr,rdng,snd));
CREATE INDEX rdngsnd_snd ON rdngsnd(snd);


-- The following tables are used for resolving textual xrefs to 
-- actual entries and senses when loading data from external files.
-- See file pg/xresolv.sql for a description of the process.

CREATE TABLE xresolv (
    entr INT NOT NULL,		-- Entry xref occurs in.
    sens SMALLINT NOT NULL,	-- Sense number xref occurs in.
      FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE,
    typ SMALLINT NOT NULL 	-- Type of xref (table kwxref).
      REFERENCES kwxref(id),
    ord SMALLINT NOT NULL,	-- Order of xref in sense.
    rtxt VARCHAR(250),		-- Reading text of target given in xref.
    ktxt VARCHAR(250),		-- Kanji text of target given in xref.
    tsens SMALLINT,		-- Target sense number.
    notes VARCHAR(250),		-- Notes.
    prio BOOLEAN DEFAULT FALSE,	-- True if this is a Tanaka corpus exemplar.
    PRIMARY KEY (entr,sens,typ,ord),
    CHECK (rtxt NOTNULL OR ktxt NOTNULL));
CREATE INDEX xresolv_rdng ON xresolv(rtxt);
CREATE INDEX xresolv_kanj ON xresolv(ktxt);

-------------------
--  Kanjidic tables
-------------------

CREATE TABLE kwcinf (
    id SMALLINT PRIMARY KEY,
    kw VARCHAR(50) NOT NULL UNIQUE,
    descr VARCHAR(250));

CREATE TABLE rad (
    num SMALLINT NOT NULL,	-- Radical (bushu) number.
    var SMALLINT NOT NULL,	-- Variant number.
      PRIMARY KEY (num,var),
    rchr CHAR(1),		-- Radical character from unicode blocks CJK radicals
				--   2F00-2FDF and Radicals Supplement 2E80-2EFF.
    chr CHAR(1),		-- Radical character from outside radical blocks.
    strokes SMALLINT,		-- Number of strokes.
    loc	CHAR(1) 		-- Location code.
	CHECK(loc is NULL OR loc IN('O','T','B','R','L','E','V')),
    name VARCHAR(50),		-- Name of radical (japanese).
    examples VARCHAR(20));	-- Characters that include the radical.

CREATE TABLE chr(
    entr INT PRIMARY KEY	-- Defines readings and meanings, but not kanji.
      REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE,
    chr CHAR(1) NOT NULL,	-- Defines kanji.
    bushu SMALLINT,		-- Radical number.
    strokes SMALLINT,
    freq SMALLINT,
    grade SMALLINT,
    jlpt SMALLINT,
    radname VARCHAR(50));
CREATE UNIQUE INDEX ON chr(chr);
-- XX ALTER TABLE chr ADD CONSTRAINT chr_rad_fkey FOREIGN KEY (bushu) REFERENCES rad(num);

CREATE TABLE cinf(
    entr INT NOT NULL
      REFERENCES chr(entr) ON DELETE CASCADE ON UPDATE CASCADE,
    kw SMALLINT NOT NULL
      REFERENCES kwcinf(id) ON DELETE CASCADE ON UPDATE CASCADE,
    value VARCHAR(50) NOT NULL,
    mctype VARCHAR(50) NOT NULL DEFAULT(''),
      PRIMARY KEY (entr,kw,value,mctype));
CREATE INDEX cinf_kw ON cinf(kw);
CREATE INDEX cinf_val ON cinf(value);

CREATE TABLE kresolv(
    entr INT NOT NULL
      REFERENCES entr(id) ON DELETE CASCADE ON UPDATE CASCADE,
    kw SMALLINT NOT NULL,
    value VARCHAR(50) NOT NULL,
      PRIMARY KEY (entr,kw,value));
-- No FK constraint on 'kw' (to kwcinf) because it may have a value of
-- 0, meaning 'ucs', which we don't need or want to be a real cinf item.

---------------------------------------------
--  Verb/adjective/copula conjugation tables
---------------------------------------------

DROP TABLE IF EXISTS conjo_notes, conotes, conjo, conj CASCADE;

-- Notes for conj, conjo items.
CREATE TABLE conotes (
    id INT PRIMARY KEY, 
    txt TEXT NOT NULL);

-- Verb and adjective inflection names.
CREATE TABLE conj (
    id SMALLINT PRIMARY KEY,
    name VARCHAR(50) UNIQUE);             -- Eg, "present", "past", "conditional", provisional", etc.

-- Okurigana used for for each verb inflection type.
CREATE TABLE conjo (
    pos SMALLINT NOT NULL                 -- Part-of-speech id from 'kwpos'.
      REFERENCES kwpos(id) ON UPDATE CASCADE,
    conj SMALLINT NOT NULL                -- Conjugation id from 'conj'.
      REFERENCES conj(id) ON UPDATE CASCADE, 
    neg BOOLEAN NOT NULL DEFAULT FALSE,   -- Negative form.
    fml BOOLEAN NOT NULL DEFAULT FALSE,   -- Formal (aka distal) form.
    onum SMALLINT NOT NULL DEFAULT 1,     -- Okurigana variant id when more than one exists.
      PRIMARY KEY (pos,conj,neg,fml,onum),
    stem SMALLINT DEFAULT 1,              -- Number of chars to remove to get stem. 
    okuri VARCHAR(50) NOT NULL,           -- Okurigana text.
    euphr VARCHAR(50) DEFAULT NULL,       -- Kana for euphonic change in stem (する and 来る).
    euphk VARCHAR(50) DEFAULT NULL,       -- Kanji for change in stem (used only for 為る-＞出来る).
    pos2 SMALLINT DEFAULT NULL            -- Part-of-speech (kwpos id) of word after conjugation.
      REFERENCES kwpos(id) ON UPDATE CASCADE);

-- Notes that apply to a particular conjugation.
CREATE TABLE conjo_notes (
    pos SMALLINT NOT NULL,  ---.
    conj SMALLINT NOT NULL, --  \
    neg BOOLEAN NOT NULL,   --   +--- Primary key of table 'conjo'. 
    fml BOOLEAN NOT NULL,   --  /
    onum SMALLINT NOT NULL, ---'
      FOREIGN KEY (pos,conj,neg,fml,onum) REFERENCES conjo(pos,conj,neg,fml,onum) ON UPDATE CASCADE,
    note SMALLINT NOT NULL
      REFERENCES conotes(id) ON UPDATE CASCADE, 
    PRIMARY KEY (pos,conj,neg,fml,onum,note));



