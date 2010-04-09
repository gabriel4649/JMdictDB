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
--  Copyright (c) 2010 Stuart McGraw 
---------------------------------------------------------------------------
--
-- This file creates a number of view that summerize a set of 
-- related rows as a single text string in one row.  The all
-- have names starting with "vt_".
--
-- This script requires the server to have the setting
--
--   standard_conforming_strings
--
-- set to "on" (due to the use of Unicode code-point constants.
--
---------------------------------------------------------------------------

\set ON_ERROR_STOP 
SET standard_conforming_strings = ON;
BEGIN;

----------------------------------------------------------------
-- kinf: comma separated list of kinf tags.
-- Key: entr, kanj.

CREATE OR REPLACE VIEW vt_kinf AS (
    SELECT k.entr,k.kanj,
       (SELECT ARRAY_TO_STRING(ARRAY_AGG(k2.txt), ',') 
        FROM (
	    SELECT kw.kw AS txt 
	    FROM kinf k3 
	    JOIN kwkinf kw ON kw.id=k3.kw
	    WHERE k3.entr=k.entr and k3.kanj=k.kanj
	    ORDER BY k3.ord) AS k2
        ) AS kitxt
    FROM 
	(SELECT DISTINCT entr,kanj FROM kanj) as k);

----------------------------------------------------------------
-- rinf: comma separated list of rinf tags.
-- Key: entr, rdng.

CREATE OR REPLACE VIEW vt_rinf AS (
    SELECT r.entr,r.rdng,
       (SELECT ARRAY_TO_STRING(ARRAY_AGG(r2.txt), ',') 
        FROM (
	    SELECT kw.kw AS txt 
	    FROM rinf r3 
	    JOIN kwrinf kw ON kw.id=r3.kw
	    WHERE r3.entr=r.entr and r3.rdng=r.rdng
	    ORDER BY r3.ord) AS r2
        ) AS ritxt
    FROM 
	(SELECT DISTINCT entr,rdng FROM rdng) as r);

----------------------------------------------------------------
-- kanj: kanj texts separated by "; ". 
-- Key: entr

CREATE OR REPLACE VIEW vt_kanj AS (
    SELECT k.entr,
       (SELECT ARRAY_TO_STRING(ARRAY_AGG(k2.txt), '; ') 
        FROM (
	    SELECT k3.txt 
	    FROM kanj k3 
	    WHERE k3.entr=k.entr 
	    ORDER BY k3.kanj) AS k2
        ) AS ktxt
    FROM 
	(SELECT DISTINCT entr FROM kanj) as k);

----------------------------------------------------------------
-- Kanji with kinf. 
-- Key: entr

CREATE OR REPLACE VIEW vt_kanj2 AS (
    SELECT k.entr,
       (SELECT ARRAY_TO_STRING(ARRAY_AGG(k2.txt), '; ') 
        FROM (
	    SELECT k3.txt 
		|| COALESCE('['||i.kitxt||']', '') AS txt
	    FROM kanj k3 
	    LEFT JOIN vt_kinf i ON i.entr=k3.entr AND i.kanj=k3.kanj
	    WHERE k3.entr=k.entr 
	    ORDER BY k3.kanj) AS k2
        ) AS ktxt
    FROM 
	(SELECT DISTINCT entr FROM kanj) as k);

----------------------------------------------------------------
-- Rdng: reading texts separated by "; ". 
-- Key: entr

CREATE OR REPLACE VIEW vt_rdng AS (
    SELECT r.entr,
       (SELECT ARRAY_TO_STRING(ARRAY_AGG(r2.txt), '; ') 
        FROM (
	    SELECT r3.txt 
	    FROM rdng r3 
	    WHERE r3.entr=r.entr 
	    ORDER BY r3.rdng) AS r2
        ) AS rtxt
    FROM 
	(SELECT DISTINCT entr FROM rdng) AS r);

----------------------------------------------------------------
-- Rdng: reading texts with rinf, separated by "; ". 
-- Key: entr

CREATE OR REPLACE VIEW vt_rdng2 AS (
    SELECT r.entr,
       (SELECT ARRAY_TO_STRING(ARRAY_AGG(r2.txt), '; ') 
        FROM (
	    SELECT r3.txt 
		|| COALESCE('['||i.ritxt||']', '') AS txt
	    FROM rdng r3 
	    LEFT JOIN vt_rinf i ON i.entr=r3.entr AND i.rdng=r3.rdng
	    WHERE r3.entr=r.entr 
	    ORDER BY r3.rdng) AS r2
        ) AS rtxt
    FROM 
	(SELECT DISTINCT entr FROM rdng) AS r);

----------------------------------------------------------------
-- Gloss: gloss texts separated with '; '.
-- Key: entr, sens

CREATE OR REPLACE VIEW vt_gloss AS (
    SELECT g.entr,g.sens,
       (SELECT ARRAY_TO_STRING(ARRAY_AGG(g2.txt), '; ') 
        FROM (
	    SELECT g3.txt 
	    FROM gloss g3 
	    WHERE g3.entr=g.entr and g3.sens=g.sens
	    ORDER BY g3.gloss) AS g2
        ) AS gtxt
    FROM 
	(SELECT DISTINCT entr,sens FROM gloss) as g);

----------------------------------------------------------------
-- Gloss: gloss texts prefixed with ginf tags (if not "equ"),
-- separated with '; '.
-- Key: entr, sens

CREATE OR REPLACE VIEW vt_gloss2 AS (
    SELECT g.entr,g.sens, 
        (SELECT ARRAY_TO_STRING(ARRAY_AGG(g2.txt), '; ') 
        FROM (
	    SELECT CASE g3.ginf
		WHEN 1 THEN ''
		ELSE COALESCE('['||kw.kw||'] ','') END || g3.txt AS txt
	    FROM gloss g3 
	    JOIN kwginf kw ON kw.id=g3.ginf
	    WHERE g3.entr=g.entr and g3.sens=g.sens
	    ORDER BY g3.gloss) AS g2
        ) AS gtxt
    FROM 
	(SELECT DISTINCT entr,sens FROM gloss) as g);

----------------------------------------------------------------
-- Pos: comma separated list of pos tags.
-- Key: entr, sens.

CREATE OR REPLACE VIEW vt_pos AS (
    SELECT p.entr,p.sens,
       (SELECT ARRAY_TO_STRING(ARRAY_AGG(p2.txt), ',') 
        FROM (
	    SELECT kw.kw AS txt 
	    FROM pos p3 
	    JOIN kwpos kw ON kw.id=p3.kw
	    WHERE p3.entr=p.entr and p3.sens=p.sens
	    ORDER BY p3.ord) AS p2
        ) AS ptxt
    FROM 
	(SELECT DISTINCT entr,sens FROM pos) as p);

----------------------------------------------------------------
-- Misc: comma separated list of misc tags.
-- Key: entr, sens.

CREATE OR REPLACE VIEW vt_misc AS (
    SELECT m.entr,m.sens,
       (SELECT ARRAY_TO_STRING(ARRAY_AGG(m2.txt), ',') 
        FROM (
	    SELECT kw.kw AS txt 
	    FROM misc m3 
	    JOIN kwpos kw ON kw.id=m3.kw
	    WHERE m3.entr=m.entr and m3.sens=m.sens
	    ORDER BY m3.ord) AS m2
        ) AS mtxt
    FROM 
	(SELECT DISTINCT entr,sens FROM misc) as m);

----------------------------------------------------------------
-- Sense: Plain (';'-separated gloss strings from vt_gloss),
-- separated by ' / '.
-- Key: entr.

CREATE OR REPLACE VIEW vt_sens AS (
    SELECT s.entr,
       (SELECT ARRAY_TO_STRING(ARRAY_AGG(g2.txt), ' / ') 
        FROM (
	    SELECT g3.gtxt AS txt 
	    FROM vt_gloss g3 
	    WHERE g3.entr=s.entr
	    ORDER BY g3.entr,g3.sens) AS g2
        ) AS stxt
    FROM 
	(SELECT DISTINCT entr FROM sens) as s);

----------------------------------------------------------------
-- Sense: Plain (';'-separated gloss strings from vt_gloss)
-- with sense note, separated by ' / '.
-- Key: entr.

CREATE OR REPLACE VIEW vt_sens2 AS (
    SELECT s.entr,
       (SELECT ARRAY_TO_STRING(ARRAY_AGG(g2.txt), ' / ') 
        FROM (
	    SELECT g3.gtxt AS txt
	    FROM vt_gloss g3 
	    WHERE g3.entr=s.entr
	    ORDER BY g3.entr,g3.sens) AS g2
	    -- U&'\300A' and U&'\300B' are open and close double angle brackets.
        ) || coalesce ((U&' \300A'||s.notes||U&'\300B'), '') AS stxt
    FROM 
	(SELECT DISTINCT entr,notes FROM sens) as s);

----------------------------------------------------------------
-- Sense: ginf-tagged gloss strings (from vt_gloss3) with sense
-- note, separated by ' / '.
-- Key: entr.

CREATE OR REPLACE VIEW vt_sens3 AS (
    SELECT s.entr,
       (SELECT ARRAY_TO_STRING(ARRAY_AGG(g2.txt), ' / ') 
        FROM (
	    SELECT
		COALESCE('['||p.ptxt||']','') || 
		COALESCE('['||m.mtxt||']','') ||
		CASE WHEN p.ptxt IS NULL AND m.mtxt IS NULL THEN ''
		     ELSE ' ' END || 
		g3.gtxt AS txt
	    FROM vt_gloss2 g3 
	    LEFT JOIN vt_pos  p ON p.entr=g3.entr AND p.sens=g3.sens
	    LEFT JOIN vt_misc m ON m.entr=g3.entr AND m.sens=g3.sens
	    WHERE g3.entr=s.entr
	    ORDER BY g3.entr,g3.sens) AS g2
	    -- U&'\300A' and U&'\300B' are open and close double angle brackets.
        ) || coalesce ((U&' \300A'||s.notes||U&'\300B'), '') AS stxt
    FROM 
	(SELECT DISTINCT entr,notes FROM sens) as s);

-----------------------------------------------------------
-- Summarize each entry (one per row) with readings, kanji, 
-- and sense/gloss column.  

CREATE OR REPLACE VIEW vt_entr AS (
    SELECT e.*,
	r.rtxt,
	k.ktxt,
	s.stxt,
	(SELECT COUNT(*) FROM sens WHERE sens.entr=e.id) AS nsens,
	(SELECT p FROM is_p WHERE is_p.id=e.id) AS p
    FROM entr e
    LEFT JOIN vt_rdng r ON r.entr=e.id
    LEFT JOIN vt_kanj k ON k.entr=e.id
    LEFT JOIN vt_sens s ON s.entr=e.id);

-----------------------------------------------------------
-- Summarize each entry (one per row) with readings, kanji, 
-- and sense/gloss columns.  Reading and kanji include inf
-- tags, 

CREATE OR REPLACE VIEW vt_entr3 AS (
    SELECT e.*,
	r.rtxt,
	k.ktxt,
	s.stxt,
	(SELECT COUNT(*) FROM sens WHERE sens.entr=e.id) AS nsens,
	(SELECT p FROM is_p WHERE is_p.id=e.id) AS p
    FROM entr e
    LEFT JOIN vt_rdng2 r ON r.entr=e.id
    LEFT JOIN vt_kanj2 k ON k.entr=e.id
    LEFT JOIN vt_sens3 s ON s.entr=e.id);

COMMIT;
