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

INSERT INTO xref(entr,sens,xentr,xsens,typ,notes) 
  (SELECT v.entr,v.sens,s.entr,s.sens,v.typ,NULL
    FROM xresolv v 
      JOIN kanj k ON k.txt=v.txt 
      JOIN sens s ON k.entr=s.entr
  UNION
  SELECT v.entr,v.sens,s.entr,s.sens,v.typ,NULL
    FROM xresolv v 
      JOIN rdng r ON r.txt=v.txt  
      JOIN sens s ON r.entr=s.entr);

-----------------------------------------------------
-- Following query will report all entries in
-- xresolv that are not resolvable...
-----------------------------------------------------
SELECT e.seq,e.id,v.sens,v.typ,v.txt
  FROM xresolv v 
  JOIN entr e ON e.id=v.entr
  LEFT JOIN rdng r ON r.txt=v.txt
  LEFT JOIN kanj k ON k.txt=v.txt
  WHERE r.txt IS NULL AND k.txt IS NULL
  ORDER BY e.seq,v.sens

