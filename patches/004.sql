-- Descr: Fix view vt_misc.
-- Trans: 3->4

-- Previously, this view was erroneously getting keyword text
-- from kwpos rather than kwmisc.

\set ON_ERROR_STOP
BEGIN;

CREATE OR REPLACE VIEW vt_misc AS (
    SELECT m.entr,m.sens,
       (SELECT ARRAY_TO_STRING(ARRAY_AGG(m2.txt), ',') 
        FROM (
	    SELECT kw.kw AS txt 
	        FROM misc m3 
		    JOIN kwmisc kw ON kw.id=m3.kw
		        WHERE m3.entr=m.entr and m3.sens=m.sens
			    ORDER BY m3.ord) AS m2
        ) AS mtxt
    FROM 
    (SELECT DISTINCT entr,sens FROM misc) as m);

COMMIT;
