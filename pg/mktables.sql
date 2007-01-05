-- $Revision$ $Date$
-- Copyright (c) 2006, Stuart McGraw 
-- JMdict schema for Postgresql

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
    stat SMALLINT NOT NULL DEFAULT 2,
    notes TEXT);

CREATE TABLE rdng (
    id SERIAL NOT NULL PRIMARY KEY,
    entr INT NOT NULL,
    ord SMALLINT NOT NULL,
    txt VARCHAR(2048) NOT NULL);

CREATE TABLE kanj (
    id SERIAL NOT NULL PRIMARY KEY,
    entr INT NOT NULL,
    ord SMALLINT NOT NULL,
    txt VARCHAR(2048) NOT NULL);

CREATE TABLE sens (
    id SERIAL NOT NULL PRIMARY KEY,
    entr INT NOT NULL,
    ord SMALLINT NOT NULL,
    notes TEXT);

CREATE TABLE gloss (
    id SERIAL NOT NULL PRIMARY KEY,
    sens INT NOT NULL,
    ord SMALLINT NOT NULL,
    lang SMALLINT NOT NULL,
    txt VARCHAR(2048) NOT NULL,
    notes TEXT);

CREATE TABLE xref (
    sens INT NOT NULL,
    xref INT NOT NULL,
    typ SMALLINT NOT NULL,
    notes TEXT,
    PRIMARY KEY (sens,xref,typ));

CREATE TABLE hist (
    id SERIAL NOT NULL PRIMARY KEY,
    entr INT NOT NULL,
    stat SMALLINT NOT NULL,
    dt TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    who VARCHAR(250),
    notes TEXT);

CREATE TABLE audio (
    id SERIAL NOT NULL PRIMARY KEY,
    rdng INT NOT NULL,
    fname VARCHAR(255) NOT NULL,
    strt INT NOT NULL,
    leng INT NOT NULL);


CREATE TABLE xresolv (
    sens INT NOT NULL,
    typ SMALLINT NOT NULL,
    txt VARCHAR(250) NOT NULL);
    

CREATE TABLE kfreq (
    kanj INT NOT NULL,
    kw SMALLINT NOT NULL,
    value INT,
    PRIMARY KEY (kanj,kw));

CREATE TABLE rfreq (
    rdng INT NOT NULL,
    kw SMALLINT NOT NULL,
    value INT,
    PRIMARY KEY (rdng,kw));

CREATE TABLE dial (
    entr INT NOT NULL,
    kw SMALLINT NOT NULL,
    PRIMARY KEY (entr,kw));

CREATE TABLE fld (
    sens INT NOT NULL,
    kw SMALLINT NOT NULL,
    PRIMARY KEY (sens,kw));

CREATE TABLE kinf (
    kanj INT NOT NULL,
    kw SMALLINT NOT NULL,
    PRIMARY KEY (kanj,kw));

CREATE TABLE lang (
    entr INT NOT NULL,
    kw SMALLINT NOT NULL,
    PRIMARY KEY (entr,kw));

CREATE TABLE misc (
    sens INT NOT NULL,
    kw SMALLINT NOT NULL,
    PRIMARY KEY (sens,kw));

CREATE TABLE pos (
    sens INT NOT NULL,
    kw SMALLINT NOT NULL,
    PRIMARY KEY (sens,kw));

CREATE TABLE rinf (
    rdng INT NOT NULL,
    kw SMALLINT NOT NULL,
    PRIMARY KEY (rdng,kw));



CREATE TABLE restr (
    rdng INT NOT NULL,
    kanj INT NOT NULL,
    PRIMARY KEY (rdng,kanj));

CREATE TABLE stagr (
    sens INT NOT NULL,
    rdng INT NOT NULL,
    PRIMARY KEY (sens,rdng));

CREATE TABLE stagk (
    sens INT NOT NULL,
    kanj INT NOT NULL,
    PRIMARY KEY (sens,kanj));
