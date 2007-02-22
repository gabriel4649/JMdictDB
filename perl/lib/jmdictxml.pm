#######################################################################
#   This file is part of JMdictDB. 
#   Copyright (c) 2006,2007 Stuart McGraw 
# 
#   JMdictDB is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published 
#   by the Free Software Foundation; either version 2 of the License, 
#   or (at your option) any later version.
# 
#   JMdictDB is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
# 
#   You should have received a copy of the GNU General Public License
#   along with JMdictDB; if not, write to the Free Software Foundation,
#   51 Franklin Street, Fifth Floor, Boston, MA  02110#1301, USA
#######################################################################

package jmdictxml;
use Exporter ();  @ISA = 'Exporter';
@EXPORT_OK = ('%JM2ID','@VERSION'); 

@VERSION = (substr('$Revision$',11,-2), \
	    substr('$Date$',7,-11));

# The following hash maps JMdict xml entity and CDATA 
# strings to id numbers in the database kw* tables.
#
# It is useful when parsing a JMdict xml file, for getting
# a keyword id number corresponding to an xml entity or
# element value.  Note that the database kw*.kw or kw*.descr
# values are not appropriate for this since they are not
# neccessarily the same as the xml entity strings.
#
# Deprecated items were used in jmdict at one time but 
# are not supposed to occur in current versions.  They
# remain in here in case they reappear (has been known
# to happen), or there is a need to load an old version
# of jmdict.  They are given values >=200 and if encountered
# by load_jmdict.pl, will elicit a warning message.
# References are edict list posts from Jim Breen:
#   2006-09-15, 2007-02-19, 2007-02-21
#
# !!!!!
# This file should be updated if the data in any of the
# xml-related kw* tables is changed, and visa versa.
# !!!!!

our %JM2ID = (
	FREQ => {		# kwfreq
		'ichi' => 1,
		'gai' => 2,
		'spec' => 4,
		'nf' => 5, 
		'news' => 7, },
	
	NAME => {		# kwmisc
		'family or surname' => 81,
		'place name' => 82,
		'unclassified name' => 83,
		'company name' => 84,
		'product name' => 85,
		'male given name or forename' => 86,
		'female given name or forename' => 87,
		'full name of a particular person' => 88,
		'given name or forename, gender not specified' => 89, },
	
	KINF => {		# kwkinf
		'word containing irregular kanji usage' => 1,
		'irregular okurigana usage' => 2,
		'word containing out-dated kanji ' => 3,
		'word containing irregular kana usage' => 4, },
	
	RINF => {		# kwrinf
		'ateji (phonetic) reading' => 1,
		'gikun (meaning) reading' => 2,
		'out-dated or obsolete kana usage' => 3,
		'word containing irregular kana usage' => 4,
		'word usually written using kanji alone ' => 5,

		# Deprecated...
		'rare' => 201,
		'word usually written using kana alone ' => 202, },
	
	FLD => {		# kwfld
		'Buddhist term' => 1,
		'computer terminology' => 2,
		'food term' => 3,
		'geometry term' => 4,
		'linguistics terminology' => 5,
		'martial arts term' => 6,
		'mathematics' => 7,
		'military' => 8,
		'physics terminology' => 9, },
	
	MISC => {		# kwmisc
		'rude or X-rated term (not displayed in educational software)' => 1,
		'abbreviation' => 2,
		'archaism' => 3,
		'children\'s language' => 4,
		'colloquialism ' => 5,
		'derogatory' => 6,
		'exclusively kanji' => 7,
		'familiar language ' => 8,
		'female term or language' => 9,
		'gikun (meaning) reading' => 10,
		'honorific or respectful (sonkeigo) language ' => 11,
		'humble (kenjougo) language ' => 12,
		'idiomatic expression ' => 13,
		'manga slang' => 14,
		'male term or language' => 15,
		'obsolete term' => 17,
		'obscure term' => 18,
		'polite (teineigo) language ' => 19,
		'rare' => 20,
		'slang' => 21,
		'word usually written using kana alone ' => 22,
		'vulgar expression or word ' => 24,
		'sensitive' => 25,

		# Deprecated...
		'male slang' => 201, 
		'ateji (phonetic) reading' => 202,
		'word usually written using kanji alone ' => 203, },
	
	POS => {		# kwpos
		'adjective (keiyoushi)' => 1,
		'adjectival nouns or quasi-adjectives (keiyodoshi)' => 2,
		'nouns which may take the genitive case particle `no\'' => 3,
		'pre-noun adjectival (rentaishi)' => 4,
		'`taru\' adjective' => 5,
		'adverb (fukushi)' => 6,
		'adverb taking the `to\' particle' => 8,
		'auxiliary' => 9,
		'auxiliary adjective' => 54,
		'auxiliary verb' => 10,
		'conjunction' => 12,
		'Expressions (phrases, clauses, etc.)' => 13,
		'interjection (kandoushi)' => 14,
		'noun (common) (futsuumeishi)' => 17,
		'adverbial noun (fukushitekimeishi)' => 18,
		'noun, used as a suffix' => 19,
		'noun, used as a prefix' => 20,
		'noun (temporal) (jisoumeishi)' => 21,
		'numeric' => 24,
		'prefix ' => 25,
		'particle ' => 26,
		'suffix ' => 27,
		'Ichidan verb' => 28,
		'Godan verb (not completely classified)' => 29,
		'Godan verb - -aru special class' => 30,
		'Godan verb with `bu\' ending' => 31,
		'Godan verb with `gu\' ending' => 32,
		'Godan verb with `ku\' ending' => 33,
		'Godan verb - Iku/Yuku special class' => 34,
		'Godan verb with `mu\' ending' => 35,
		'Godan verb with `nu\' ending' => 36,
		'Godan verb with `ru\' ending' => 37,
		'Godan verb with `ru\' ending (irregular verb)' => 38,
		'Godan verb with `su\' ending' => 39,
		'Godan verb with `tsu\' ending' => 40,
		'Godan verb with `u\' ending' => 41,
		'Godan verb with `u\' ending (special class)' => 42,
		'Godan verb - Uru old class verb (old form of Eru)' => 43,
		'intransitive verb ' => 44,
		'Kuru verb - special class' => 45,
		'noun or participle which takes the aux. verb suru' => 46,
		'suru verb - special class' => 47,
		'suru verb - irregular' => 48,
		'zuru verb - (alternative form of -jiru verbs)' => 49,
		'transitive verb' => 50,

		# Deprecated...
		'adverbial noun' => 201,
		'computer terminology' => 202,
		'irregular okurigana usage' => 203,
		'irregular verb' => 204,
		'negative (in a negative sentence, or with negative verb)' => 205,
		'negative verb (when used with)' => 206,
		'masculine gender' => 207,
		'feminine gender' => 208,
		'neuter gender' => 209, },
	
	DIAL => {		# kwdial
		'std' => 1,
		'ksb' => 2,
		'ktb' => 3,
		'kyb' => 4,
		'osb' => 5,
		'tsb' => 6,
		'thb' => 7,
		'tsug' => 8, },
	
	LANG => {		# kwlang
		'ja' => 0,
		'en' => 1,
		'ai' => 2,
		'ar' => 3,
		'de' => 4,
		'el' => 5,
		'eo' => 6,
		'es' => 7,
		'fr' => 8,
		'in' => 9,
		'it' => 10,
		'ko' => 11,
		'lt' => 12,
		'nl' => 13,
		'no' => 14,
		'pt' => 15,
		'ru' => 16,
		'sanskr' => 17,
		'uk' => 18,
		'zh' => 19,
		'iw' => 20,
		'pl' => 21,
		'sv' => 22,
		'bo' => 23,
		'hi' => 24,
		'ur' => 25,
		'mn' => 26,
		'kl' => 27,
		'kr' => 28,
		'sa' => 29, },

	XREF =>	{		# kwxref;
		'syn' => 1,
		'ant' => 2,
		'see' => 3,
		'cf' => 4,
		'ex' => 5,
		'uses' => 6,
		'pref' => 7,},);
1;
