CREATE TABLE kwaudit (
    id TINYINT PRIMARY KEY ,
    kw VARCHAR(20) NOT NULL UNIQUE ,
    descr VARCHAR(255));

CREATE TABLE kwdial (
    id TINYINT PRIMARY KEY ,
    kw VARCHAR(20) NOT NULL UNIQUE ,
    descr VARCHAR(255));

CREATE TABLE kwfreq (
    id TINYINT PRIMARY KEY ,
    kw VARCHAR(20) NOT NULL UNIQUE ,
    descr VARCHAR(255));

CREATE TABLE kwfld (
    id TINYINT PRIMARY KEY ,
    kw VARCHAR(20) NOT NULL UNIQUE ,
    descr VARCHAR(255));

CREATE TABLE kwkinf (
    id TINYINT PRIMARY KEY ,
    kw VARCHAR(20) NOT NULL ,
    descr VARCHAR(255));

CREATE TABLE kwlang (
    id TINYINT PRIMARY KEY ,
    kw VARCHAR(20) NOT NULL UNIQUE ,
    descr VARCHAR(255));

CREATE TABLE kwmisc (
    id TINYINT PRIMARY KEY ,
    kw VARCHAR(20) NOT NULL ,
    descr VARCHAR(255));

CREATE TABLE kwpos (
    id TINYINT PRIMARY KEY ,
    kw VARCHAR(20) NOT NULL UNIQUE ,
    descr VARCHAR(255));

CREATE TABLE kwrinf (
    id TINYINT PRIMARY KEY ,
    kw VARCHAR(20) NOT NULL UNIQUE ,
    descr VARCHAR(255));

CREATE TABLE kwsrc (
    id TINYINT PRIMARY KEY ,
    kw VARCHAR(20) NOT NULL UNIQUE ,
    descr VARCHAR(255));

CREATE TABLE kwxref (
    id TINYINT PRIMARY KEY ,
    kw VARCHAR(20) NOT NULL UNIQUE ,
    descr VARCHAR(255));




CREATE TABLE entr (
    id INT NOT NULL IDENTITY PRIMARY KEY ,
    src TINYINT NOT NULL references kwsrc (id) ,
    seq INT NOT NULL , 
    note TEXT );
    CREATE INDEX entr_seq ON entr (seq);

CREATE TABLE kana (
    id INT NOT NULL IDENTITY PRIMARY KEY ,
    entr INT NOT NULL REFERENCES entr (id) ON DELETE CASCADE ,
    ord SMALLINT NOT NULL ,
    txt VARCHAR(2048) NOT NULL );
    CREATE INDEX kana_entr ON kana (entr);
    CREATE INDEX kana_txt ON kana (txt);

CREATE TABLE kanj (
    id INT NOT NULL IDENTITY PRIMARY KEY ,
    entr INT NOT NULL REFERENCES entr (id) ON DELETE CASCADE ,
    ord SMALLINT NOT NULL ,
    txt VARCHAR(2048) NOT NULL );
    CREATE INDEX kanj_entr ON kanj (entr);
    CREATE INDEX kanj_txt ON kanj (txt);

CREATE TABLE sens (
    id INT NOT NULL IDENTITY PRIMARY KEY ,
    entr INT NOT NULL REFERENCES entr (id) ON DELETE CASCADE ,
    ord SMALLINT NOT NULL ,
    note TEXT );
    CREATE INDEX sens_entr ON sens (entr);

CREATE TABLE gloss (
    id INT NOT NULL IDENTITY PRIMARY KEY ,
    sens INT NOT NULL REFERENCES sens (id) ON DELETE CASCADE ,
    ord SMALLINT NOT NULL ,
    lang TINYINT NOT NULL REFERENCES kwlang (id) ,
    txt VARCHAR(2048) NOT NULL ,
    note TEXT );
    CREATE INDEX gloss_sens ON gloss (sens);
    CREATE INDEX gloss_txt ON gloss (txt);

CREATE TABLE xref (
    sens INT NOT NULL REFERENCES sens (id) ,
    xref INT NOT NULL REFERENCES sens (id) ,
    typ TINYINT NOT NULL REFERENCES kwxref (id) ,
    note TEXT ,
    PRIMARY KEY ( sens,xref,typ ) );
    CREATE INDEX xref_sens ON xref (sens);
    CREATE INDEX xref_xref ON xref (xref);

CREATE TABLE audit (
    id INT NOT NULL IDENTITY PRIMARY KEY ,
    entr INT NOT NULL REFERENCES entr (id) ON DELETE CASCADE ,
    typ TINYINT NOT NULL REFERENCES kwaudit (id) ,
    dt DATETIME NOT NULL ,
    who VARCHAR(255) ,
    note TEXT );
    CREATE INDEX audit_dt ON audit (dt);
    CREATE INDEX audit_who ON audit (who);

CREATE TABLE kfreq (
    kanj INT NOT NULL REFERENCES kanj (id) ON DELETE CASCADE ,
    kw TINYINT NOT NULL REFERENCES kwfreq (id) ,
    value INT ,
    PRIMARY KEY ( kanj,kw ));

CREATE TABLE rfreq (
    kana INT NOT NULL REFERENCES kana (id) ON DELETE CASCADE ,
    kw TINYINT NOT NULL REFERENCES kwfreq (id) ,
    value INT ,
    PRIMARY KEY ( kana,kw ));

CREATE TABLE dial (
    entr INT NOT NULL REFERENCES entr (id) ON DELETE CASCADE ,
    kw TINYINT NOT NULL REFERENCES kwdial (id) ,
    PRIMARY KEY ( entr,kw ));

CREATE TABLE fld (
    sens INT NOT NULL REFERENCES sens (id) ON DELETE CASCADE ,
    kw TINYINT NOT NULL REFERENCES kwfld (id) ,
    PRIMARY KEY ( sens,kw ));

CREATE TABLE kinf (
    kanj INT NOT NULL REFERENCES kanj (id) ON DELETE CASCADE ,
    kw TINYINT NOT NULL REFERENCES kwkinf (id) ,
    PRIMARY KEY ( kanj,kw ));

CREATE TABLE lang (
    entr INT NOT NULL REFERENCES entr (id) ON DELETE CASCADE ,
    kw TINYINT NOT NULL REFERENCES kwlang (id) ,
    PRIMARY KEY ( entr,kw ));

CREATE TABLE misc (
    sens INT NOT NULL REFERENCES sens (id) ON DELETE CASCADE ,
    kw TINYINT NOT NULL REFERENCES kwmisc (id) ,
    PRIMARY KEY ( sens,kw ));

CREATE TABLE pos (
    sens INT NOT NULL REFERENCES sens (id) ON DELETE CASCADE ,
    kw TINYINT NOT NULL REFERENCES kwpos (id) ,
    PRIMARY KEY ( sens,kw ));

CREATE TABLE rinf (
    kana INT NOT NULL REFERENCES kana (id) ON DELETE CASCADE ,
    kw TINYINT NOT NULL REFERENCES kwrinf (id) ,
    PRIMARY KEY ( kana,kw ));




CREATE TABLE restr (
    kana INT NOT NULL REFERENCES kana (id) ,
    kanj INT NOT NULL REFERENCES kanj (id) ,
    PRIMARY KEY ( kana,kanj ) );
    CREATE INDEX restr_kana ON restr (kana);
    CREATE INDEX restr_kanj ON restr (kanj);

CREATE TABLE stagr (
    sens INT NOT NULL REFERENCES sens (id) ,
    kana INT NOT NULL REFERENCES kana (id) ,
    PRIMARY KEY ( sens,kana ) );
    CREATE INDEX stagr_sens ON stagr (sens);
    CREATE INDEX stagr_kana ON stagr (kana);

CREATE TABLE stagk (
    sens INT NOT NULL REFERENCES sens (id) ,
    kanj INT NOT NULL REFERENCES kanj (id) ,
    PRIMARY KEY ( sens,kanj ) );
    CREATE INDEX stagk_sens ON stagk (sens);
    CREATE INDEX stagk_kanj ON stagk (kanj);
