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
SELECT setval('snd_id_seq',  (SELECT max(id) FROM snd));
SELECT setval('sndfile_id_seq',  (SELECT max(id) FROM sndfile));
SELECT setval('sndvol_id_seq',  (SELECT max(id) FROM sndvol));

-- The following function (defined in mktables.sql) resets the
-- state of the sequences that generate entry "seq" column values.
-- The values must be reset following a bulk load of data or any
-- other load tha gets seq numbers from somewhere other than the
-- sequence tables.

SELECT syncseq();
