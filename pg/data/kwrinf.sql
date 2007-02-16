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

INSERT INTO kwrinf(id,kw,descr) VALUES(1,  'ateji',  'ateji (phonetic) reading');
INSERT INTO kwrinf(id,kw,descr) VALUES(2,  'gikun',  'gikun (meaning) reading');
INSERT INTO kwrinf(id,kw,descr) VALUES(3,  'ik',     'word containing irregular kana usage');
INSERT INTO kwrinf(id,kw,descr) VALUES(4,  'ok',     'out-dated or obsolete kana usage');
INSERT INTO kwrinf(id,kw,descr) VALUES(5,  'rare',   'rare');
INSERT INTO kwrinf(id,kw,descr) VALUES(6,  'uk',     'word usually written using kana alone');
INSERT INTO kwrinf(id,kw,descr) VALUES(7,  'uK',     'word usually written using kanji alone');
INSERT INTO kwrinf(id,kw,descr) VALUES(21,  'kun',    'japanese reading (kun-yomi)');
INSERT INTO kwrinf(id,kw,descr) VALUES(22,  'on',     'chinese reading (on-yomi)');
INSERT INTO kwrinf(id,kw,descr) VALUES(23,  'name',   'reading used only in names (nanori)');
INSERT INTO kwrinf(id,kw,descr) VALUES(24, 'rad',    'reading used as name of radical');
INSERT INTO kwrinf(id,kw,descr) VALUES(25, 'jouyou', 'Approved reading for jouyou kanji');