-------------------------------------------------------------------------
--  This file is part of JMdictDB.  
--  JMdictDB is free software; you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation; either version 2 of the License, or
--  (at your option) any later version.
--   JMdictDB is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--  You should have received a copy of the GNU General Public License
--  along with Foobar; if not, write to the Free Software Foundation, Inc.,
--  51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
--
--  Copyright (c) 2006,2007 Stuart McGraw 
---------------------------------------------------------------------------

INSERT INTO kwpos(id,kw,descr) VALUES( 1, 'adj',    'adjective (keiyoushi)');
INSERT INTO kwpos(id,kw,descr) VALUES( 2, 'adj-na', 'adjectival nouns or quasi-adjectives (keiyodoshi)');
INSERT INTO kwpos(id,kw,descr) VALUES( 3, 'adj-no', 'nouns which may take the genitive case particle `no''');
INSERT INTO kwpos(id,kw,descr) VALUES( 4, 'adj-pn', 'pre-noun adjectival (rentaishi)');
INSERT INTO kwpos(id,kw,descr) VALUES( 5, 'adj-t',  '`taru'' adjective');
INSERT INTO kwpos(id,kw,descr) VALUES( 6, 'adv',    'adverb (fukushi)');
INSERT INTO kwpos(id,kw,descr) VALUES( 7, 'adv-n',  'adverbial noun');
INSERT INTO kwpos(id,kw,descr) VALUES( 8, 'adv-to', 'adverb taking the `to'' particle');
INSERT INTO kwpos(id,kw,descr) VALUES( 9, 'aux',    'auxiliary');
INSERT INTO kwpos(id,kw,descr) VALUES(54, 'aux-adj','auxiliary adjective');
INSERT INTO kwpos(id,kw,descr) VALUES(10, 'aux-v',  'auxiliary verb');
INSERT INTO kwpos(id,kw,descr) VALUES(11, 'comp',   'computer terminology');
INSERT INTO kwpos(id,kw,descr) VALUES(12, 'conj',   'conjunction');
INSERT INTO kwpos(id,kw,descr) VALUES(13, 'exp',    'Expressions (phrases, clauses, etc.)');
INSERT INTO kwpos(id,kw,descr) VALUES(14, 'int',    'interjection (kandoushi)');
INSERT INTO kwpos(id,kw,descr) VALUES(15, 'io',     'irregular okurigana usage');
INSERT INTO kwpos(id,kw,descr) VALUES(16, 'iv',     'irregular verb');
INSERT INTO kwpos(id,kw,descr) VALUES(17, 'n',      'noun (common) (futsuumeishi)');
INSERT INTO kwpos(id,kw,descr) VALUES(18, 'n-adv',  'adverbial noun (fukushitekimeishi)');
INSERT INTO kwpos(id,kw,descr) VALUES(19, 'n-suf',  'noun, used as a suffix');
INSERT INTO kwpos(id,kw,descr) VALUES(20, 'n-pref', 'noun, used as a prefix');
INSERT INTO kwpos(id,kw,descr) VALUES(21, 'n-t',    'noun (temporal) (jisoumeishi)');
INSERT INTO kwpos(id,kw,descr) VALUES(22, 'neg',    'negative (in a negative sentence, or with negative verb)');
INSERT INTO kwpos(id,kw,descr) VALUES(23, 'neg-v',  'negative verb (when used with)');
INSERT INTO kwpos(id,kw,descr) VALUES(24, 'num',    'numeric');
INSERT INTO kwpos(id,kw,descr) VALUES(25, 'pref',   'prefix');
INSERT INTO kwpos(id,kw,descr) VALUES(26, 'prt',    'particle');
INSERT INTO kwpos(id,kw,descr) VALUES(27, 'suf',    'suffix');
INSERT INTO kwpos(id,kw,descr) VALUES(28, 'v1',     'Ichidan verb');
INSERT INTO kwpos(id,kw,descr) VALUES(29, 'v5',     'Godan verb (not completely classified)');
INSERT INTO kwpos(id,kw,descr) VALUES(30, 'v5aru',  'Godan verb - -aru special class');
INSERT INTO kwpos(id,kw,descr) VALUES(31, 'v5b',    'Godan verb with `bu'' ending');
INSERT INTO kwpos(id,kw,descr) VALUES(32, 'v5g',    'Godan verb with `gu'' ending');
INSERT INTO kwpos(id,kw,descr) VALUES(33, 'v5k',    'Godan verb with `ku'' ending');
INSERT INTO kwpos(id,kw,descr) VALUES(34, 'v5k-s',  'Godan verb - Iku/Yuku special class');
INSERT INTO kwpos(id,kw,descr) VALUES(35, 'v5m',    'Godan verb with `mu'' ending');
INSERT INTO kwpos(id,kw,descr) VALUES(36, 'v5n',    'Godan verb with `nu'' ending');
INSERT INTO kwpos(id,kw,descr) VALUES(37, 'v5r',    'Godan verb with `ru'' ending');
INSERT INTO kwpos(id,kw,descr) VALUES(38, 'v5r-i',  'Godan verb with `ru'' ending (irregular verb)');
INSERT INTO kwpos(id,kw,descr) VALUES(39, 'v5s',    'Godan verb with `su'' ending');
INSERT INTO kwpos(id,kw,descr) VALUES(40, 'v5t',    'Godan verb with `tsu'' ending');
INSERT INTO kwpos(id,kw,descr) VALUES(41, 'v5u',    'Godan verb with `u'' ending');
INSERT INTO kwpos(id,kw,descr) VALUES(42, 'v5u-s',  'Godan verb with `u'' ending (special class)');
INSERT INTO kwpos(id,kw,descr) VALUES(43, 'v5uru',  'Godan verb - Uru old class verb (old form of Eru)');
INSERT INTO kwpos(id,kw,descr) VALUES(44, 'vi',     'intransitive verb');
INSERT INTO kwpos(id,kw,descr) VALUES(45, 'vk',     'Kuru verb - special class');
INSERT INTO kwpos(id,kw,descr) VALUES(46, 'vs',     'noun or participle which takes the aux. verb suru');
INSERT INTO kwpos(id,kw,descr) VALUES(47, 'vs-s',   'suru verb - special class');
INSERT INTO kwpos(id,kw,descr) VALUES(48, 'vs-i',   'suru verb - irregular');
INSERT INTO kwpos(id,kw,descr) VALUES(49, 'vz',     'zuru verb - (alternative form of -jiru verbs)');
INSERT INTO kwpos(id,kw,descr) VALUES(50, 'vt',     'transitive verb');
INSERT INTO kwpos(id,kw,descr) VALUES(51, 'mg',     'masculine gender');
INSERT INTO kwpos(id,kw,descr) VALUES(52, 'fg',     'feminine gender');
INSERT INTO kwpos(id,kw,descr) VALUES(53, 'ng',     'neuter gender');

