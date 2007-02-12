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
    stat SMALLINT NOT NULL,
    notes TEXT);

CREATE SEQUENCE seq 
   INCREMENT 10 MINVALUE 1000000 MAXVALUE 8999999 
   NO CYCLE OWNED BY entr.seq;

CREATE TABLE rdng (
    entr INT NOT NULL,
    rdng SMALLINT NOT NULL,
    txt VARCHAR(2048) NOT NULL,
    PRIMARY KEY(entr,rdng));

CREATE TABLE kanj (
    entr INT NOT NULL,
    kanj SMALLINT NOT NULL,
    txt VARCHAR(2048) NOT NULL,
    PRIMARY KEY(entr,kanj));

CREATE TABLE sens (
    entr INT NOT NULL,
    sens SMALLINT NOT NULL,
    notes TEXT,
    PRIMARY KEY(entr,sens));

CREATE TABLE gloss (
    entr INT NOT NULL,
    sens SMALLINT NOT NULL,
    gloss SMALLINT NOT NULL,
    lang SMALLINT NOT NULL,
    txt VARCHAR(2048) NOT NULL,
    notes TEXT,
    PRIMARY KEY(entr,sens,gloss));

CREATE TABLE xref (
    entr INT NOT NULL,
    sens SMALLINT NOT NULL,
    xentr INT NOT NULL,
    xsens SMALLINT NOT NULL,
    typ SMALLINT NOT NULL,
    notes TEXT,
    PRIMARY KEY (entr,sens,xentr,xsens,typ));

CREATE TABLE hist (
    id SERIAL NOT NULL PRIMARY KEY,
    entr INT NOT NULL,
    stat SMALLINT NOT NULL,
    dt TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    who VARCHAR(250),
    diff TEXT,
    notes TEXT);

CREATE TABLE audio (
    id SERIAL NOT NULL PRIMARY KEY,
    entr INT NOT NULL,
    rdng SMALLINT NOT NULL,
    fname VARCHAR(255) NOT NULL,
    strt INT NOT NULL,
    leng INT NOT NULL);

CREATE TABLE editor (
    id SERIAL NOT NULL PRIMARY KEY,
    name VARCHAR(80) NOT NULL,
    email VARCHAR(250),
    notes TEXT);

CREATE TABLE xresolv (
    entr INT NOT NULL,
    sens SMALLINT NOT NULL,
    typ SMALLINT NOT NULL,
    txt VARCHAR(250) NOT NULL);


CREATE TABLE kfreq (
    entr INT NOT NULL,
    kanj SMALLINT NOT NULL,
    kw SMALLINT NOT NULL,
    value INT,
    PRIMARY KEY (entr,kanj,kw));

CREATE TABLE rfreq (
    entr INT NOT NULL,
    rdng SMALLINT NOT NULL,
    kw SMALLINT NOT NULL,
    value INT,
    PRIMARY KEY (entr,rdng,kw));

CREATE TABLE dial (
    entr INT NOT NULL,
    kw SMALLINT NOT NULL,
    PRIMARY KEY (entr,kw));

CREATE TABLE fld (
    entr INT NOT NULL,
    sens SMALLINT NOT NULL,
    kw SMALLINT NOT NULL,
    PRIMARY KEY (entr,sens,kw));

CREATE TABLE kinf (
    entr INT NOT NULL,
    kanj SMALLINT NOT NULL,
    kw SMALLINT NOT NULL,
    PRIMARY KEY (entr,kanj,kw));

CREATE TABLE lang (
    entr INT NOT NULL,
    kw SMALLINT NOT NULL,
    PRIMARY KEY (entr,kw));

CREATE TABLE misc (
    entr INT NOT NULL,
    sens SMALLINT NOT NULL,
    kw SMALLINT NOT NULL,
    PRIMARY KEY (entr,sens,kw));

CREATE TABLE pos (
    entr INT NOT NULL,
    sens SMALLINT NOT NULL,
    kw SMALLINT  NOT NULL,
    PRIMARY KEY (entr,sens,kw));

CREATE TABLE rinf (
    entr INT NOT NULL,
    rdng SMALLINT NOT NULL,
    kw SMALLINT NOT NULL,
    PRIMARY KEY (entr,rdng,kw));



CREATE TABLE restr (
    entr INT NOT NULL,
    rdng SMALLINT NOT NULL,
    kanj SMALLINT NOT NULL,
    PRIMARY KEY (entr,rdng,kanj));

CREATE TABLE stagr (
    entr INT NOT NULL,
    sens SMALLINT NOT NULL,
    rdng SMALLINT NOT NULL,
    PRIMARY KEY (entr,sens,rdng));

CREATE TABLE stagk (
    entr INT NOT NULL,
    sens SMALLINT NOT NULL,
    kanj SMALLINT NOT NULL,
    PRIMARY KEY (entr,sens,kanj));
