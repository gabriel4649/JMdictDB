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
	 FROM (SELECT k.txt FROM rdng k WHERE k.entr=e.id ORDER BY k.ord) AS sk) AS rdng,
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
	(SELECT COUNT(*) FROM rdng k WHERE k.entr=e.id) as nrdng,
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
    LEFT JOIN rdng k ON k.entr=e.id)
    LEFT JOIN kanj j ON j.entr=e.id)
    LEFT JOIN restr r ON k.id=r.rdng AND j.id=r.kanj);

------------------------------------------------------------
-- List all readings that should be marked "re_nokanji" 
-- in jmdict.xml.
------------------------------------------------------------
CREATE VIEW re_nokanji AS (
    SELECT e.id AS id,e.seq AS seq,k.id AS rid,k.txt AS rtxt
    FROM rdng k 
    JOIN entr e ON e.id=k.entr
    WHERE 
	k.id IN (SELECT rk.rdng FROM restr rk)
	AND (SELECT COUNT(*) FROM restr x WHERE x.rdng=k.id)
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
      JOIN rdng r ON r.entr=e.id
      LEFT JOIN (
        SELECT e.id AS eid, r.id AS rid, j.id AS jid, j.txt AS jtxt
          FROM entr e
          JOIN rdng r ON r.entr=e.id
            LEFT JOIN kanj j ON j.entr=r.entr
            LEFT JOIN restr z ON z.rdng=r.id AND z.kanj=j.id
          WHERE z.rdng IS NULL
        ) AS sub ON sub.rid=r.id AND sub.eid=e.id
  );
