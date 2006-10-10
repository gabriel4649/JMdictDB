-- $Revision$ $Date$
-- JMdict schema for Mysql

SET SQL_WARNINGS = 1;

CREATE TABLE kwaudit (
    id TINYINT UNSIGNED PRIMARY KEY,
    kw VARCHAR(20) NOT NULL UNIQUE,
    descr VARCHAR(255));

CREATE TABLE kwdial (
    id TINYINT UNSIGNED PRIMARY KEY,
    kw VARCHAR(20) NOT NULL UNIQUE,
    descr VARCHAR(255));

CREATE TABLE kwfreq (
    id TINYINT UNSIGNED PRIMARY KEY,
    kw VARCHAR(20) NOT NULL UNIQUE,
    descr VARCHAR(255));

CREATE TABLE kwfld (
    id TINYINT UNSIGNED PRIMARY KEY,
    kw VARCHAR(20) NOT NULL UNIQUE,
    descr VARCHAR(255));

CREATE TABLE kwkinf (
    id TINYINT UNSIGNED PRIMARY KEY,
    kw VARCHAR(20) NOT NULL,
    descr VARCHAR(255));

CREATE TABLE kwlang (
    id TINYINT UNSIGNED PRIMARY KEY,
    kw VARCHAR(20) NOT NULL UNIQUE,
    descr VARCHAR(255));

CREATE TABLE kwmisc (
    id TINYINT UNSIGNED PRIMARY KEY,
    kw VARCHAR(20) NOT NULL,
    descr VARCHAR(255));

CREATE TABLE kwpos (
    id TINYINT UNSIGNED PRIMARY KEY,
    kw VARCHAR(20) NOT NULL UNIQUE,
    descr VARCHAR(255));

CREATE TABLE kwrinf (
    id TINYINT UNSIGNED PRIMARY KEY,
    kw VARCHAR(20) NOT NULL UNIQUE,
    descr VARCHAR(255));

CREATE TABLE kwsrc (
    id TINYINT UNSIGNED PRIMARY KEY,
    kw VARCHAR(20) NOT NULL UNIQUE,
    descr VARCHAR(255));

CREATE TABLE kwxref (
    id TINYINT UNSIGNED PRIMARY KEY,
    kw VARCHAR(20) NOT NULL UNIQUE,
    descr VARCHAR(255));



CREATE TABLE entr (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE PRIMARY KEY,
    src TINYINT UNSIGNED NOT NULL,
    seq INT UNSIGNED NOT NULL, 
    note TEXT,
    FOREIGN KEY (src) REFERENCES kwsrc(id));
  CREATE INDEX entr_seq ON entr(seq);

CREATE TABLE kana (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE PRIMARY KEY,
    entr INT UNSIGNED NOT NULL,
    ord MEDIUMINT NOT NULL,
    txt VARCHAR(2048) NOT NULL,
    FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE);
  CREATE INDEX kana_entr ON kana(entr);
  CREATE INDEX kana_txt ON kana(txt(250));

CREATE TABLE kanj (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE PRIMARY KEY,
    entr INT UNSIGNED NOT NULL,
    ord MEDIUMINT NOT NULL,
    txt VARCHAR(2048) NOT NULL,
    FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE);
  CREATE INDEX kanj_entr ON kanj(entr);
  CREATE INDEX kanj_txt ON kanj(txt(250));

CREATE TABLE sens (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE PRIMARY KEY,
    entr INT UNSIGNED NOT NULL,
    ord MEDIUMINT NOT NULL,
    note TEXT,
    FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE);
  CREATE INDEX sens_entr ON sens(entr);

CREATE TABLE gloss (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE PRIMARY KEY,
    sens INT UNSIGNED NOT NULL,
    ord MEDIUMINT NOT NULL,
    lang TINYINT UNSIGNED NOT NULL,
    txt VARCHAR(2048) NOT NULL,
    note TEXT,
    FOREIGN KEY (sens) REFERENCES sens(id) ON DELETE CASCADE,
    FOREIGN KEY (lang) REFERENCES kwlang(id));
  CREATE INDEX gloss_sens ON gloss(sens);
  CREATE INDEX gloss_txt ON gloss(txt(250));

CREATE TABLE xref (
    sens INT UNSIGNED NOT NULL REFERENCES sens(id),
    xref INT UNSIGNED NOT NULL REFERENCES sens(id),
    typ TINYINT UNSIGNED NOT NULL,
    note TEXT,
    PRIMARY KEY (sens,xref,typ),
    FOREIGN KEY (sens) REFERENCES sens(id) ON DELETE CASCADE,
    FOREIGN KEY (xref) REFERENCES sens(id) ON DELETE CASCADE,
    FOREIGN KEY (typ) REFERENCES kwxref(id));
  CREATE INDEX xref_sens ON xref(sens);
  CREATE INDEX xref_xref ON xref(xref);

CREATE TABLE audit (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE PRIMARY KEY,
    entr INT UNSIGNED NOT NULL,
    typ TINYINT UNSIGNED NOT NULL,
    dt DATETIME NOT NULL,
    who VARCHAR(255),
    note TEXT,
    FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE,
    FOREIGN KEY (typ) REFERENCES kwaudit(id) ON DELETE CASCADE);
  CREATE INDEX audit_dt ON audit(dt);
  CREATE INDEX audit_who ON audit(who);



CREATE TABLE kfreq (
    kanj INT UNSIGNED NOT NULL,
    kw TINYINT UNSIGNED NOT NULL,
    value INT UNSIGNED,
    PRIMARY KEY (kanj,kw),
    FOREIGN KEY (kanj) REFERENCES kanj(id) ON DELETE CASCADE,
    FOREIGN KEY (kw) REFERENCES kwfreq(id));

CREATE TABLE rfreq (
    kana INT UNSIGNED NOT NULL,
    kw TINYINT UNSIGNED NOT NULL,
    value INT UNSIGNED,
    PRIMARY KEY (kana,kw),
    FOREIGN KEY (kana) REFERENCES kana(id) ON DELETE CASCADE,
    FOREIGN KEY (kw) REFERENCES kwfreq(id));

CREATE TABLE dial (
    entr INT UNSIGNED NOT NULL,
    kw TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (entr,kw),
    FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE,
    FOREIGN KEY (kw) REFERENCES kwdial(id));

CREATE TABLE fld (
    sens INT UNSIGNED NOT NULL,
    kw TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (sens,kw),
    FOREIGN KEY (sens) REFERENCES sens(id) ON DELETE CASCADE,
    FOREIGN KEY (kw) REFERENCES kwfld(id));

CREATE TABLE kinf (
    kanj INT UNSIGNED NOT NULL,
    kw TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (kanj,kw),
    FOREIGN KEY (kanj) REFERENCES kanj(id) ON DELETE CASCADE,
    FOREIGN KEY (kw) REFERENCES kwkinf(id));

CREATE TABLE lang (
    entr INT UNSIGNED NOT NULL,
    kw TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (entr,kw),
    FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE,
    FOREIGN KEY (kw) REFERENCES kwlang(id));

CREATE TABLE misc (
    sens INT UNSIGNED NOT NULL,
    kw TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (sens,kw),
    FOREIGN KEY (sens) REFERENCES sens(id) ON DELETE CASCADE,
    FOREIGN KEY (kw) REFERENCES kwmisc(id));

CREATE TABLE pos (
    sens INT UNSIGNED NOT NULL,
    kw TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (sens,kw),
    FOREIGN KEY (sens) REFERENCES sens(id) ON DELETE CASCADE,
    FOREIGN KEY (kw) REFERENCES kwpos(id));

CREATE TABLE rinf (
    kana INT UNSIGNED NOT NULL,
    kw TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (kana,kw),
    FOREIGN KEY (kana) REFERENCES kana(id) ON DELETE CASCADE,
    FOREIGN KEY (kw) REFERENCES kwrinf(id));



CREATE TABLE restr (
    kana INT UNSIGNED NOT NULL,
    kanj INT UNSIGNED NOT NULL,
    PRIMARY KEY (kana,kanj),
    FOREIGN KEY (kana) REFERENCES kana(id) ON DELETE CASCADE,
    FOREIGN KEY (kanj) REFERENCES kanj(id) ON DELETE CASCADE);
  CREATE INDEX restr_kana ON restr(kana);
  CREATE INDEX restr_kanj ON restr(kanj);

CREATE TABLE stagr (
    sens INT UNSIGNED NOT NULL,
    kana INT UNSIGNED NOT NULL,
    PRIMARY KEY (sens,kana),
    FOREIGN KEY (sens) REFERENCES sens(id) ON DELETE CASCADE,
    FOREIGN KEY (kana) REFERENCES kana(id) ON DELETE CASCADE);
  CREATE INDEX stagr_sens ON stagr(sens);
  CREATE INDEX stagr_kana ON stagr(kana);

CREATE TABLE stagk (
    sens INT UNSIGNED NOT NULL,
    kanj INT UNSIGNED NOT NULL,
    PRIMARY KEY (sens,kanj),
    FOREIGN KEY (sens) REFERENCES sens(id) ON DELETE CASCADE,
    FOREIGN KEY (kanj) REFERENCES kanj(id) ON DELETE CASCADE);
  CREATE INDEX stagk_sens ON stagk(sens);
  CREATE INDEX stagk_kanj ON stagk(kanj);

-----------------------------------------------------------
-- Summarize each entry (one per row) with readings, kanji, 
-- and sense/gloss.  Each of those columns values has the
-- text from each child item concatenated into a single
-- string with items delimited by "; "s.  For the sense
-- column, all gloss strings in all sense are contatented
-- with the delimiter "; " for performance reasons (c.f.
-- the Postgresql entr_summary view).
------------------------------------------------------------
CREATE VIEW entr_summary AS (
    SELECT e.id,e.seq,
        (SELECT GROUP_CONCAT(k.txt ORDER BY ord SEPARATOR '; ')
         FROM kana k WHERE k.entr=e.id) AS kana,
        (SELECT GROUP_CONCAT(j.txt ORDER BY ord SEPARATOR '; ')
         FROM kanj j WHERE j.entr=e.id) AS kanj,
        (SELECT group_concat(g.txt ORDER BY s.ord,g.ord SEPARATOR '; ')
         FROM sens s JOIN gloss g ON g.sens=s.id
         WHERE s.entr=e.id) AS gloss
    FROM entr e);
