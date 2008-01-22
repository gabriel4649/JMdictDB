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
--  Copyright (c) 2007 Stuart McGraw 
---------------------------------------------------------------------------


-- $Revision$ $Date$

SELECT setval('entr_id_seq',  (SELECT max(id) FROM entr));

-- The following properly resets the state of the sequences that 
-- generate entry "seq" column values.  The sequence used for a 
-- particular entry is given by the kwsrc.seq datum in the kwsrc 
-- row referenced by the entry.
-- The values must be reset following a bulk load of data by programs
-- such as jmload.pl, etc.

SELECT setval('seq_jmdict',   (SELECT MAX(e.seq) FROM entr e JOIN kwsrc k ON k.id=e.src WHERE k.seq='seq_jmdict' AND e.seq<9000000));
SELECT setval('seq_jmnedict', (SELECT MAX(e.seq) FROM entr e JOIN kwsrc k ON k.id=e.src WHERE k.seq='seq_jmnedict'));
SELECT setval('seq_examples', (SELECT MAX(e.seq) FROM entr e JOIN kwsrc k ON k.id=e.src WHERE k.seq='seq_examples'));
SELECT setval('seq_kanjidic', (SELECT MAX(e.seq) FROM entr e JOIN kwsrc k ON k.id=e.src WHERE k.seq='seq_kanjidic'));
SELECT setval('seq',          (SELECT MAX(e.seq) FROM entr e JOIN kwsrc k ON k.id=e.src WHERE k.seq='seq'));

