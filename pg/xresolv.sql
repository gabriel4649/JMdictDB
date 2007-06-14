-----------------------------------------------------
-- Resolve xref's and ant's.
--
-- The load_jmdict.pl script saves <xref>s and <ant>s
-- to table xresolv while loading jmdict xml.  This
-- statement will create the xref table entries from
-- the data in xresolv, after all the data has been
-- loaded.
-- Since targets are indentified only by kanji or 
-- kana strings (that in turn identify entire entries,
-- possibly multiple) and the database xrefs points 
-- to senses, we have little choice but to create
-- an xref to every sense in the target entries.

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

CREATE TABLE _xrsv (
    entr INT NOT NULL,
    sens INT NOT NULL,
    ord INT NOT NULL,
    xentr INT NOT NULL,
    PRIMARY KEY (entr,sens,ord,xentr)); 
CREATE INDEX _xrsv_xentr ON _xrsv(xentr);
ALTER TABLE _xrsv ADD CONSTRAINT _xrsv_entr_fkey FOREIGN KEY (entr,sens) REFERENCES sens(entr,sens) ON DELETE CASCADE ON UPDATE CASCADE;

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
    -- with the given reading as the first reading and having no kanji.
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
    -- the given kanji (in any position) exists.. 
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

INSERT INTO xref(entr,sens,xentr,xsens,typ,notes)
    (SELECT DISTINCT x.entr,x.sens,x.xentr,s.sens,z.typ,z.notes
    FROM _xrsv x 
    JOIN xresolv z ON z.entr=x.entr AND z.sens=x.sens AND z.ord=x.ord
    JOIN sens s ON s.entr=x.xentr
    WHERE x.entr != x.xentr);

VACUUM ANALYZE xref;
