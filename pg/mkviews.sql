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
	(SELECT ARRAY_TO_STRING(ACCUM(sr.txt), '; ') 
	 FROM (SELECT r.txt FROM rdng r WHERE r.entr=e.id ORDER BY r.ord) AS sr) AS rdng,
	(SELECT ARRAY_TO_STRING(ACCUM(sk.txt), '; ')
	 FROM (SELECT k.txt FROM kanj k WHERE k.entr=e.id ORDER BY k.ord) AS sk) AS kanj,
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
	(SELECT COUNT(*) FROM rdng r WHERE r.entr=e.id) as nrdng,
	(SELECT COUNT(*) FROM kanj k WHERE k.entr=e.id) as nkanj,
	(SELECT COUNT(*) FROM sens s WHERE s.entr=e.id) as nsens
    FROM entr e);

------------------------------------------------------------
-- For every entry, give all the combinations of reading and 
-- kanji, and an indicator whether of not that combination
-- is valid ('X' in column 'valid' means invalid).
------------------------------------------------------------
CREATE VIEW rk_validity AS (
    SELECT e.id AS id,e.seq AS seq,
	r.id AS rid,r.txt AS rtxt,k.id AS kid,k.txt AS ktxt,
	CASE WHEN z.kanj IS NOT NULL THEN 'X' END AS valid
    FROM ((entr e
    LEFT JOIN rdng r ON r.entr=e.id)
    LEFT JOIN kanj k ON k.entr=e.id)
    LEFT JOIN restr z ON r.id=z.rdng AND k.id=z.kanj);

------------------------------------------------------------
-- List all readings that should be marked "re_nokanji" 
-- in jmdict.xml.
------------------------------------------------------------
CREATE VIEW re_nokanji AS (
    SELECT e.id AS id,e.seq AS seq,r.id AS rid,r.txt AS rtxt
    FROM rdng r 
    JOIN entr e ON e.id=r.entr
    WHERE 
	r.id IN (SELECT z.rdng FROM restr z)
	AND (SELECT COUNT(*) FROM restr x WHERE x.rdng=r.id)
	  = (SELECT COUNT(*) FROM kanj k WHERE k.entr=e.id));

-------------------------------------------------------------
-- For every reading in every entry, provide only the valid 
-- kanji as determined by restr if applicable, and taking 
-- the jmdict's re_nokanji information into account. 
-------------------------------------------------------------
CREATE VIEW rk_valid AS (
  SELECT e.id, e.seq, r.id AS rid, r.txt AS rtxt, 
	sub.kid AS kid, sub.ktxt AS ktxt
    FROM entr e
      JOIN rdng r ON r.entr=e.id
      LEFT JOIN (
        SELECT e.id AS eid, r.id AS rid, k.id AS kid, k.txt AS ktxt
          FROM entr e
          JOIN rdng r ON r.entr=e.id
            LEFT JOIN kanj k ON k.entr=r.entr
            LEFT JOIN restr z ON z.rdng=r.id AND z.kanj=k.id
          WHERE z.rdng IS NULL
        ) AS sub ON sub.rid=r.id AND sub.eid=e.id);

-------------------------------------------------------------
-- For each sense, provide it's entry id and seq, and a brief
-- text summary which is the kanji aggregate if there are any
-- kanji entries, of the readings aggregte otherwise.
-- This view is primarily used to provide an xref summary.
-------------------------------------------------------------
CREATE VIEW sref AS (
  SELECT s.id AS sid,e.id AS id,e.seq, 
      COALESCE (NULLIF (	
        (SELECT ARRAY_TO_STRING(ACCUM(sk.txt), '; ')
         FROM (SELECT k.txt FROM kanj k WHERE k.entr=e.id ORDER BY k.ord) AS sk), ''),
 	(SELECT ARRAY_TO_STRING(ACCUM(sr.txt), '; ') 
	 FROM (SELECT r.txt FROM rdng r WHERE r.entr=e.id ORDER BY r.ord) AS sr)) AS txt
  FROM sens s  
    JOIN entr e ON e.id=s.entr);

