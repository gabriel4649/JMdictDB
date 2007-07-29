-------------------------------------------------------------------------
--
-- Convert xml xref's and ant's to xrefs.
--
-- The load_jmdict.pl script saves <xref>s and <ant>s
-- (both referred to generically herein as "xrefs") to
-- table xresolv while loading jmdict xml.  The data
-- in this table is pretty much a copy of the information
-- in the xml.  The function of this sql script is to
-- convert the xresolv info (where xref targets are
-- identified by text strings) into xref records (where
-- xref targets are identified by entr and sens number). 
--
-- The process is done in two steps:
-- 1) Based on the xref text in xresolv, find the entry 
--    or entries that are the xref targets.  (This is
--    the most complex step.)
-- 2) Create the xref records to the target entry senses.
--    There may be multiple records created for a single
--    target entry if that entry has multiple senses. 
-- 
-- This process excludes any xrefs except those where
-- both the source and target have an entr.src value of
-- 1, presumed to be "jmdict", i.e. it will only resolve
-- intra-jmdict xrefs, even if there are other xrefs
-- (e.g. examples->jmdict) in the xresolv table.
--
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
--  Copyright (c) 2006,2007 Stuart McGraw 
---------------------------------------------------------------------------

\unset ON_ERROR_STOP 
DROP TABLE _xrsv;
\set ON_ERROR_STOP 

CREATE TABLE _xrsv (
    entr INT NOT NULL,
    sens INT NOT NULL,
    ord INT NOT NULL,
    xentr INT NOT NULL,
    PRIMARY KEY (entr,sens,ord,xentr)); 
CREATE INDEX _xrsv_xentr ON _xrsv(xentr);
ALTER TABLE _xrsv ADD CONSTRAINT _xrsv_entr_fkey FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;


-- The following sql will use the xml xref's and ant's that
-- were loaded into table xresolv, and which identify their
-- targets only by a reading or kanji text, to identify the
-- most likely actual target entry.
-- Those results go into an intermediate staging table, _xrsv.
-- The process is somewhat involved; one does not want to 
-- blindly create an xref to every entry with a matching kanji
-- or reading because that will produce many spurious xrefs.
-- But conversely one cannot look for enteries where the 
-- target entry kanji/readings match the source kanji/reading
-- exactly because the xml usually can't specify the target
-- exactly since it can't specify a kanji/reading pair.
-- So we use the following procedure which emperically seems
-- to strike a balance between creating an excessive number
-- of "wrong" xrefs, and missing an excessive number of "right"
-- xrefs.
--
-- Note that the XML provides for only a single text string
-- and that string may be a reading or a kanji.
-- 
-- 1. For the xml xrefs that are readings, create xrefs for
--    those for which only one entry with the given reading
--    (in any position) exists.
--
-- 2. For the remaining xml xrefs that are readings, create
--    xrefs for those for which only one entry exists with
--    the given reading as the first reading and having no
--    kanji.
--    
-- 3. For the xml xrefs that are kanji, create xrefs for
--    those for which only one entry with the given kanji
--    (in any position) exists.
--
-- 4. For the remaining xml xrefs that are kanji, create
--    xrefs for those for which only one entry exists with
--    the given kanji as the first kanji. 
--
-- The following insert statement doesn't actually create 
-- the xrefs, but rather creates a second staging table that
-- identifies the entries the xrefs will point to.
--
-- Note also, entries are restricted to src=1 so kwdsrc.id=1
-- should be jmdict, and only intra-jmdict xrefs will be 
-- resolved.

INSERT INTO _xrsv(entr,sens,ord,xentr)

    -- subselect #1: rtxt xrefs for which only one entry with 
    -- the given reading (in any position) exists.
    (SELECT 
        v.entr,v.sens,v.ord,MAX(r.entr) AS xentr
    FROM xresolv v 
    JOIN entr e ON e.id=v.entr
    JOIN rdng r ON r.txt=v.rtxt
    JOIN entr e2 ON e2.id=r.entr
    WHERE v.ktxt IS NULL AND e.src=1 AND e2.src=1
    GROUP BY v.entr,v.sens,v.ord
    HAVING COUNT(v.entr)=1

    UNION

    -- subselect #2: rtxt xrefs for which only one entry exists 
    -- with the given reading as the first reading and having
    -- no kanji.
    SELECT 
        v.entr,v.sens,v.ord,MAX(r.entr) as xentr
    FROM xresolv v 
    JOIN entr e ON e.id=v.entr
    JOIN rdng r ON r.txt=v.rtxt 
    JOIN entr e2 ON e2.id=r.entr
    WHERE v.ktxt IS NULL AND r.rdng=1 AND e.src=1 AND e2.src=1 
      AND 0=(SELECT COUNT(*) FROM kanj k WHERE k.entr=r.entr)
    GROUP BY v.entr,v.sens,v.ord
    HAVING COUNT(r.entr)=1

    UNION

    -- subselect #3: ktxt xrefs for which only one entry with 
    -- the given kanji (in any position) exists.
    SELECT 
        v.entr,v.sens,v.ord,MAX(k.entr) AS xentr
    FROM xresolv v 
    JOIN entr e ON e.id=v.entr
    JOIN kanj k ON k.txt=v.ktxt 
    JOIN entr e2 ON e2.id=k.entr
    WHERE v.rtxt IS NULL AND e.src=1 AND e2.src=1
    GROUP BY v.entr,v.sens,v.ord
    HAVING COUNT(v.entr)=1

    UNION

    -- subselect #4: ktxt xrefs for which only one entry exists 
    -- with the given kanji as the first kanji.
    SELECT 
        v.entr,v.sens,v.ord,MAX(k.entr) AS xentr
    FROM xresolv v 
    JOIN entr e ON e.id=v.entr
    JOIN kanj k ON k.txt=v.ktxt 
    JOIN entr e2 ON e2.id=k.entr
    WHERE v.rtxt IS NULL AND k.kanj=1 AND e.src=1 AND e2.src=1
    GROUP BY v.entr,v.sens,v.ord
    HAVING COUNT(v.entr)=1
    );

VACUUM ANALYZE _xrsv;


-- Since targets are identified only by kanji or 
-- kana strings (that in turn identify entire entries,
-- possibly multiple) and the database xrefs points 
-- to senses, we have little choice but to create
-- an xref to every sense in the target entries.
-- The following insert does that using the target 
-- entries in _xrsv.  The xref table column "xref" is
-- not included in the insert; there is an insert trigger
-- on the table that will automatically supply incrementing 
-- values to make the primary key of each row unique.
--
-- The select below connects the xref info in table
-- resolv to the actual target entries in table _xrsv
-- and expands the results to each sense of the target 
-- entries.  The GROUP BY is necessary because some 
-- entries (e.g. 1333970) have two xrefs that resolve
-- to the same entry (typically a kanji and reading
-- intended to convey that the intended xref is the
-- entry with that pair.)

INSERT INTO xref(entr,sens,typ,xentr,xsens,notes)
    (SELECT x.entr,x.sens,z.typ,x.xentr,s.sens as xsens,z.notes
    FROM _xrsv x 
    JOIN xresolv z ON z.entr=x.entr AND z.sens=x.sens AND z.ord=x.ord
    JOIN sens s ON s.entr=x.xentr
    WHERE x.entr != x.xentr
    GROUP BY x.entr,x.sens,z.typ,x.xentr,s.sens,z.notes
    ORDER BY x.entr,x.sens,z.typ,MIN(x.ord),x.xentr,s.sens)

VACUUM ANALYZE xref;
