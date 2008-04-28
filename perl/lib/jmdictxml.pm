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
@EXPORT_OK = ('%JM2ID','%EX2ID','@VERSION'); 

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

use xmllang;	# Imports %_xmllang.

our %JM2ID = (
	LANG => \%_xmllang,    # This is external due to the
			    #   potenial large number of entries.

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
		'word containing out-dated kanji' => 3,
		'word containing irregular kana usage' => 4,
		'ateji (phonetic) reading' => 5, },
	
	RINF => {		# kwrinf
		'gikun (meaning) reading' => 1,
		'out-dated or obsolete kana usage' => 2,
		'word containing irregular kana usage' => 3,
		'word usually written using kanji alone' => 4,
		'old or irregular kana form' => 21, },		# Used in jmnedict.
	
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
		'colloquialism' => 5,
		'derogatory' => 6,
		'exclusively kanji' => 7,
		'familiar language' => 8,
		'female term or language' => 9,
		'honorific or respectful (sonkeigo) language' => 11,
		'humble (kenjougo) language' => 12,
		'idiomatic expression' => 13,
		'manga slang' => 14,
		'male term or language' => 15,
		'obsolete term' => 17,
		'obscure term' => 18,
		'polite (teineigo) language' => 19,
		'rare' => 20,
		'slang' => 21,
		'word usually written using kana alone' => 22,
		'vulgar expression or word' => 24,
		'sensitive' => 25, 
		'poetical term' => 26,
		'onomatopoeic or mimetic word' => 27, },
	
	POS => {		# kwpos
		'adjective (keiyoushi)' => 1,
		'adjectival nouns or quasi-adjectives (keiyodoshi)' => 2,
		'nouns which may take the genitive case particle `no\'' => 3,
		'pre-noun adjectival (rentaishi)' => 4,
		'`taru\' adjective' => 5,
		'adverb (fukushi)' => 6,
		'adverb taking the `to\' particle' => 8,
		'auxiliary' => 9,
		'auxiliary adjective' => 10,
		'auxiliary verb' => 11,
		'conjunction' => 12,
		'Expressions (phrases, clauses, etc.)' => 13,
		'interjection (kandoushi)' => 14,
		'noun (common) (futsuumeishi)' => 17,
		'adverbial noun (fukushitekimeishi)' => 18,
		'noun, used as a suffix' => 19,
		'noun, used as a prefix' => 20,
		'noun (temporal) (jisoumeishi)' => 21,
		'numeric' => 24,
		'prefix' => 25,
		'particle' => 26,
		'suffix' => 27,
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
		'intransitive verb' => 44,
		'Kuru verb - special class' => 45,
		'noun or participle which takes the aux. verb suru' => 46,
		'suru verb - special class' => 47,
		'suru verb - irregular' => 48,
		'Ichidan verb - zuru verb (alternative form of -jiru verbs)' => 49,
		'transitive verb' => 50,
		'counter' => 51,
		'irregular nu verb' => 52,
		'Yondan verb with `ru\' ending (archaic)' => 53,
		'Godan verb with `zu\' ending' => 55, 
		'noun or verb acting prenominally' => 56,
		'former adjective classification (being removed)' => 57,

		# JMnedict names
		'family or surname' => 181,
		'place name' => 182,
		'unclassified name' => 183,
		'company name' => 184,
		'product name' => 185,
		'male given name or forename' => 186,
		'female given name or forename' => 187,
		'full name of a particular person' => 188,
		'given name or forename, gender not specified' => 189,
		'railway station' => 190, },
	
	DIAL => {		# kwdial
		'Kansai-ben' => 2,
		'Kantou-ben' => 3,
		'Kyoto-ben' => 4,
		'Osaka-ben' => 5,
		'Tosa-ben' => 6,
		'Touhoku-ben' => 7,
		'Tsugaru-ben' => 8,
		'Kyuushuu-ben' => 9,
		'Ryuukyuu-ben' => 10, },

	XREF =>	{		# kwxref;
		'syn' => 1,
		'ant' => 2,
		'see' => 3,
		'cf' => 4,
		'ex' => 5,
		'uses' => 6,
		'pref' => 7, },

	LSRC => {		# kwlsrc;
		'full' => 1,
		'part' => 2, },

	GINF => {		# Not yet finalized!
		'equ' => 1,
		'lit' => 2,
		'id' => 3,
		'trans' => 4, }, );

# Bracketed  notes found in "examples" file A lines, mapped to MISC keywords.

our %EX2ID = (
	'aphorism'		=> [82],
	'bible'			=> [83,"Biblical"],
	'f'			=> [9],
	'idiom'			=> [13],
	'm'			=> [15],
	'nelson at trafalgar.'	=> [83,"Nelson at Trafalgar"],
	'prov'			=> [81],
	'proverb. shakespeare'	=> [81,'Shakespeare'],
	'proverb'		=> [81],
	'psalm 26'		=> [83,"Biblical"],
	'quotation'		=> [83],
	'bible quote'		=> [83,"Biblical"],
	'from song lyrics'	=> [83,"Song lyrics"],
	'senryuu'		=> [83,"Senryuu"],);

1;
