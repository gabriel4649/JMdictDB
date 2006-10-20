-- $Revision$ $Date$
-- JMdict schema for Postgresql

CREATE TABLE kwaudit (
    id SMALLINT PRIMARY KEY,
    kw VARCHAR(20) NOT NULL UNIQUE,
    descr VARCHAR(255));

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

CREATE TABLE kwxref (
    id SMALLINT PRIMARY KEY,
    kw VARCHAR(20) NOT NULL UNIQUE,
    descr VARCHAR(255));



CREATE TABLE entr (
    id SERIAL NOT NULL PRIMARY KEY,
    src SMALLINT NOT NULL,
    seq INT NOT NULL, 
    note TEXT,
    FOREIGN KEY (src) REFERENCES kwsrc(id));
  CREATE INDEX entr_seq ON entr(seq);

CREATE TABLE kana (
    id SERIAL NOT NULL PRIMARY KEY,
    entr INT NOT NULL,
    ord SMALLINT NOT NULL,
    txt VARCHAR(2048) NOT NULL,
    FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE);
  CREATE INDEX kana_entr ON kana(entr);
  CREATE INDEX kana_txt ON kana(txt);

CREATE TABLE kanj (
    id SERIAL NOT NULL PRIMARY KEY,
    entr INT NOT NULL,
    ord SMALLINT NOT NULL,
    txt VARCHAR(2048) NOT NULL,
    FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE);
  CREATE INDEX kanj_entr ON kanj(entr);
  CREATE INDEX kanj_txt ON kanj(txt);

CREATE TABLE sens (
    id SERIAL NOT NULL PRIMARY KEY,
    entr INT NOT NULL,
    ord SMALLINT NOT NULL,
    note TEXT,
    FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE);
  CREATE INDEX sens_entr ON sens(entr);

CREATE TABLE gloss (
    id SERIAL NOT NULL PRIMARY KEY,
    sens INT NOT NULL,
    ord SMALLINT NOT NULL,
    lang SMALLINT NOT NULL,
    txt VARCHAR(2048) NOT NULL,
    note TEXT,
    FOREIGN KEY (sens) REFERENCES sens(id) ON DELETE CASCADE,
    FOREIGN KEY (lang) REFERENCES kwlang(id));
  CREATE INDEX gloss_sens ON gloss(sens);
  CREATE INDEX gloss_txt ON gloss(txt);

CREATE TABLE xref (
    sens INT NOT NULL,
    xref INT NOT NULL,
    typ SMALLINT NOT NULL,
    note TEXT,
    PRIMARY KEY (sens,xref,typ),
    FOREIGN KEY (sens) REFERENCES sens(id) ON DELETE CASCADE,
    FOREIGN KEY (xref) REFERENCES sens(id) ON DELETE CASCADE,
    FOREIGN KEY (typ) REFERENCES kwxref(id));
  CREATE INDEX xref_sens ON xref(sens);
  CREATE INDEX xref_xref ON xref(xref);

CREATE TABLE audit (
    id SERIAL NOT NULL PRIMARY KEY,
    entr INT NOT NULL,
    typ SMALLINT NOT NULL,
    dt TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    who VARCHAR(255),
    note TEXT,
    FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE,
    FOREIGN KEY (typ) REFERENCES kwaudit(id) ON DELETE CASCADE);
  CREATE INDEX audit_dt ON audit(dt);
  CREATE INDEX audit_who ON audit(who);



CREATE TABLE kfreq (
    kanj INT NOT NULL,
    kw SMALLINT NOT NULL,
    value INT,
    PRIMARY KEY (kanj,kw),
    FOREIGN KEY (kanj) REFERENCES kanj(id) ON DELETE CASCADE,
    FOREIGN KEY (kw) REFERENCES kwfreq(id));

CREATE TABLE rfreq (
    kana INT NOT NULL,
    kw SMALLINT NOT NULL,
    value INT,
    PRIMARY KEY (kana,kw),
    FOREIGN KEY (kana) REFERENCES kana(id) ON DELETE CASCADE,
    FOREIGN KEY (kw) REFERENCES kwfreq(id));

CREATE TABLE dial (
    entr INT NOT NULL,
    kw SMALLINT NOT NULL,
    PRIMARY KEY (entr,kw),
    FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE,
    FOREIGN KEY (kw) REFERENCES kwdial(id));

CREATE TABLE fld (
    sens INT NOT NULL,
    kw SMALLINT NOT NULL,
    PRIMARY KEY (sens,kw),
    FOREIGN KEY (sens) REFERENCES sens(id) ON DELETE CASCADE,
    FOREIGN KEY (kw) REFERENCES kwfld(id));

CREATE TABLE kinf (
    kanj INT NOT NULL,
    kw SMALLINT NOT NULL,
    PRIMARY KEY (kanj,kw),
    FOREIGN KEY (kanj) REFERENCES kanj(id) ON DELETE CASCADE,
    FOREIGN KEY (kw) REFERENCES kwkinf(id));

CREATE TABLE lang (
    entr INT NOT NULL,
    kw SMALLINT NOT NULL,
    PRIMARY KEY (entr,kw),
    FOREIGN KEY (entr) REFERENCES entr(id) ON DELETE CASCADE,
    FOREIGN KEY (kw) REFERENCES kwlang(id));

CREATE TABLE misc (
    sens INT NOT NULL,
    kw SMALLINT NOT NULL,
    PRIMARY KEY (sens,kw),
    FOREIGN KEY (sens) REFERENCES sens(id) ON DELETE CASCADE,
    FOREIGN KEY (kw) REFERENCES kwmisc(id));

CREATE TABLE pos (
    sens INT NOT NULL,
    kw SMALLINT NOT NULL,
    PRIMARY KEY (sens,kw),
    FOREIGN KEY (sens) REFERENCES sens(id) ON DELETE CASCADE,
    FOREIGN KEY (kw) REFERENCES kwpos(id));

CREATE TABLE rinf (
    kana INT NOT NULL,
    kw SMALLINT NOT NULL,
    PRIMARY KEY (kana,kw),
    FOREIGN KEY (kana) REFERENCES kana(id) ON DELETE CASCADE,
    FOREIGN KEY (kw) REFERENCES kwrinf(id));



CREATE TABLE restr (
    kana INT NOT NULL,
    kanj INT NOT NULL,
    PRIMARY KEY (kana,kanj),
    FOREIGN KEY (kana) REFERENCES kana(id) ON DELETE CASCADE,
    FOREIGN KEY (kanj) REFERENCES kanj(id) ON DELETE CASCADE);
  CREATE INDEX restr_kana ON restr(kana);
  CREATE INDEX restr_kanj ON restr(kanj);

CREATE TABLE stagr (
    sens INT NOT NULL,
    kana INT NOT NULL,
    PRIMARY KEY (sens,kana),
    FOREIGN KEY (sens) REFERENCES sens(id) ON DELETE CASCADE,
    FOREIGN KEY (kana) REFERENCES kana(id) ON DELETE CASCADE);
  CREATE INDEX stagr_sens ON stagr(sens);
  CREATE INDEX stagr_kana ON stagr(kana);

CREATE TABLE stagk (
    sens INT NOT NULL,
    kanj INT NOT NULL,
    PRIMARY KEY (sens,kanj),
    FOREIGN KEY (sens) REFERENCES sens(id) ON DELETE CASCADE,
    FOREIGN KEY (kanj) REFERENCES kanj(id) ON DELETE CASCADE);
  CREATE INDEX stagk_sens ON stagk(sens);
  CREATE INDEX stagk_kanj ON stagk(kanj);

CREATE AGGREGATE accum ( 
    SFUNC = ARRAY_APPEND, 
    BASETYPE = ANYELEMENT, 
    STYPE = ANYARRAY, 
    INITCOND = '{}');

-----------------------------------------------------------
-- Summarize each entry (one per row) with readings, kanji, 
-- and sense/gloss.  Each of those columns values has the
-- text from each child item concatenated into a single
-- string with items delimited by "; "s.  For the sense
-- column, each aggregated gloss string in contatented
-- with the delimiter " / ".
------------------------------------------------------------
CREATE VIEW entr_summary AS (
    SELECT e.id,e.seq,
	(SELECT ARRAY_TO_STRING(ACCUM(sk.txt), '; ') 
	 FROM (SELECT k.txt FROM kana k WHERE k.entr=e.id ORDER BY k.ord) AS sk) AS kana,
	(SELECT ARRAY_TO_STRING(ACCUM(sj.txt), '; ')
	 FROM (SELECT j.txt FROM kanj j WHERE j.entr=e.id ORDER BY j.ord) AS sj) AS kanj,
	(SELECT ARRAY_TO_STRING(ACCUM( ss.gtxt ), ' / ') 
	 FROM 
	    (SELECT 
		(SELECT ARRAY_TO_STRING(ACCUM(sg.txt), '; ') 
		FROM (SELECT txt FROM gloss g WHERE g.sens=s.id ORDER BY g.ord) AS sg
		ORDER BY entr,ord) AS gtxt
	    FROM sens s WHERE s.entr=e.id ORDER BY s.ord) AS ss) AS gloss
    FROM entr e);


---------------------------------------------------------
-- For every entry, give the number of associated reading,
-- kanji, and sense items.
----------------------------------------------------------
CREATE VIEW item_cnts AS (
    SELECT 
	e.id,e.seq,
	(SELECT COUNT(*) FROM kana k WHERE k.entr=e.id) as nkana,
	(SELECT COUNT(*) FROM kanj j WHERE j.entr=e.id) as nkanj,
	(SELECT COUNT(*) FROM sens s WHERE s.entr=e.id) as nsens
    FROM entr e);

------------------------------------------------------------
-- For every entry, give all the combinations of reading and 
-- kanji, and an indicator whether of not that combination
-- is valid ('X' in column 'valid' means invalid).
------------------------------------------------------------
CREATE VIEW rk_validity AS (
    SELECT e.id AS id,e.seq AS seq,
	k.id AS kid,k.txt AS ktxt,j.id AS jid,j.txt AS jtxt,
	CASE WHEN r.kanj IS NOT NULL THEN 'X' END AS valid
    FROM ((entr e
    LEFT JOIN kana k ON k.entr=e.id)
    LEFT JOIN kanj j ON j.entr=e.id)
    LEFT JOIN restr r ON k.id=r.kana AND j.id=r.kanj);

------------------------------------------------------------
-- List all readings that should be marked "re_nokanji" 
-- in jmdict.xml.
------------------------------------------------------------
CREATE VIEW re_nokanji AS (
    SELECT e.id AS id,e.seq AS seq,k.id AS rid,k.txt AS rtxt
    FROM kana k 
    JOIN entr e ON e.id=k.entr
    WHERE 
	k.id IN (SELECT rk.kana FROM restr rk)
	AND (SELECT COUNT(*) FROM restr x WHERE x.kana=k.id)
	  = (SELECT COUNT(*) FROM kanj j WHERE j.entr=e.id));

-------------------------------------------------------------
-- For every reading in every entry, provide only the valid 
-- kanji as determined by restr if applicable, and taking 
-- the jmdict's re_nokanji information into account. 
-------------------------------------------------------------
CREATE VIEW rk_valid AS (
  SELECT e.id, e.seq, r.id AS rid, r.txt AS rtxt, 
	sub.jid AS jid, sub.jtxt AS jtxt
    FROM entr e
      JOIN kana r ON r.entr=e.id
      LEFT JOIN (
        SELECT e.id AS eid, r.id AS rid, j.id AS jid, j.txt AS jtxt
          FROM entr e
          JOIN kana r ON r.entr=e.id
            LEFT JOIN kanj j ON j.entr=r.entr
            LEFT JOIN restr z ON z.kana=r.id AND z.kanj=j.id
          WHERE z.kana IS NULL
        ) AS sub ON sub.rid=r.id AND sub.eid=e.id
  );