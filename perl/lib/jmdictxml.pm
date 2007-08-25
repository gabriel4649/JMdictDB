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
		'word containing irregular kana usage' => 4,
		'ateji (phonetic) reading' => 5, },
	
	RINF => {		# kwrinf
		'gikun (meaning) reading' => 1,
		'out-dated or obsolete kana usage' => 2,
		'word containing irregular kana usage' => 3,
		'word usually written using kanji alone ' => 4, },
	
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
		'poetical term' => 26, },
	
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
		'counter' => 51,
		'irregular nu verb' => 52,

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
		'std' => 1,
		'ksb' => 2,
		'ktb' => 3,
		'kyb' => 4,
		'osb' => 5,
		'tsb' => 6,
		'thb' => 7,
		'tsug' => 8,
		'kyu' => 9, },
	
	LANG => {		# kwlang
		'en' => 1,	# English
		'ai' => 2,	# Ainu
		'aa' => 3,	# Afar
		'ab' => 4,	# Abkhazian
		'af' => 5,	# Afrikaans
		'ak' => 6,	# Akan
		'am' => 7,	# Amharic
		'ar' => 8,	# Arabic
		'an' => 9,	# Aragonese
		'as' => 10,	# Assamese
		'av' => 11,	# Avaric
		'ae' => 12,	# Avestan
		'ay' => 13,	# Aymara
		'az' => 14,	# Azerbaijani
		'ba' => 15,	# Bashkir
		'bm' => 16,	# Bambara
		'be' => 17,	# Belarusian
		'bn' => 18,	# Bengali
		'bi' => 19,	# Bislama
		'bo' => 20,	# Tibetan
		'bs' => 21,	# Bosnian
		'br' => 22,	# Breton
		'bg' => 23,	# Bulgarian
		'ca' => 24,	# Catalan
		'cs' => 25,	# Czech
		'ch' => 26,	# Chamorro
		'ce' => 27,	# Chechen
		'cu' => 28,	# Church Slavic
		'cv' => 29,	# Chuvash
		'kw' => 30,	# Cornish
		'co' => 31,	# Corsican
		'cr' => 32,	# Cree
		'cy' => 33,	# Welsh
		'da' => 34,	# Danish
		'de' => 35,	# German
		'dv' => 36,	# Dhivehi
		'dz' => 37,	# Dzongkha
		'el' => 38,	# Modern Greek (1453-)
		'eo' => 39,	# Esperanto
		'et' => 40,	# Estonian
		'eu' => 41,	# Basque
		'ee' => 42,	# Ewe
		'fo' => 43,	# Faroese
		'fa' => 44,	# Persian
		'fj' => 45,	# Fijian
		'fi' => 46,	# Finnish
		'fr' => 47,	# French
		'fy' => 48,	# Western Frisian
		'ff' => 49,	# Fulah
		'gd' => 50,	# Scottish Gaelic
		'ga' => 51,	# Irish
		'gl' => 52,	# Galician
		'gv' => 53,	# Manx
		'gn' => 54,	# Guarani
		'gu' => 55,	# Gujarati
		'ht' => 56,	# Haitian
		'ha' => 57,	# Hausa
		'sh' => 58,	# Serbo-Croatian
		'he' => 59,	# Hebrew
		'hz' => 60,	# Herero
		'hi' => 61,	# Hindi
		'ho' => 62,	# Hiri Motu
		'hr' => 63,	# Croatian
		'hu' => 64,	# Hungarian
		'hy' => 65,	# Armenian
		'ig' => 66,	# Igbo
		'io' => 67,	# Ido
		'ii' => 68,	# Sichuan Yi
		'iu' => 69,	# Inuktitut
		'ie' => 70,	# Interlingue
		'ia' => 71,	# Interlingua (International Auxiliary Language Association)
		'id' => 72,	# Indonesian
		'ik' => 73,	# Inupiaq
		'is' => 74,	# Icelandic
		'it' => 75,	# Italian
		'jv' => 76,	# Javanese
		'ja' => 77,	# Japanese
		'kl' => 78,	# Kalaallisut
		'kn' => 79,	# Kannada
		'ks' => 80,	# Kashmiri
		'ka' => 81,	# Georgian
		'kr' => 82,	# Kanuri
		'kk' => 83,	# Kazakh
		'km' => 84,	# Central Khmer
		'ki' => 85,	# Kikuyu
		'rw' => 86,	# Kinyarwanda
		'ky' => 87,	# Kirghiz
		'kv' => 88,	# Komi
		'kg' => 89,	# Kongo
		'ko' => 90,	# Korean
		'kj' => 91,	# Kuanyama
		'ku' => 92,	# Kurdish
		'lo' => 93,	# Lao
		'la' => 94,	# Latin
		'lv' => 95,	# Latvian
		'li' => 96,	# Limburgan
		'ln' => 97,	# Lingala
		'lt' => 98,	# Lithuanian
		'lb' => 99,	# Luxembourgish
		'lu' => 100,	# Luba-Katanga
		'lg' => 101,	# Ganda
		'mh' => 102,	# Marshallese
		'ml' => 103,	# Malayalam
		'mr' => 104,	# Marathi
		'mk' => 105,	# Macedonian
		'mg' => 106,	# Malagasy
		'mt' => 107,	# Maltese
		'mo' => 108,	# Moldavian
		'mn' => 109,	# Mongolian
		'mi' => 110,	# Maori
		'ms' => 111,	# Malay (macrolanguage)
		'my' => 112,	# Burmese
		'na' => 113,	# Nauru
		'nv' => 114,	# Navajo
		'nr' => 115,	# South Ndebele
		'nd' => 116,	# North Ndebele
		'ng' => 117,	# Ndonga
		'ne' => 118,	# Nepali
		'nl' => 119,	# Dutch
		'nn' => 120,	# Norwegian Nynorsk
		'nb' => 121,	# Norwegian Bokmal
		'no' => 122,	# Norwegian
		'ny' => 123,	# Nyanja
		'oc' => 124,	# Occitan (post 1500)
		'oj' => 125,	# Ojibwa
		'or' => 126,	# Oriya
		'om' => 127,	# Oromo
		'os' => 128,	# Ossetian
		'pa' => 129,	# Panjabi
		'pi' => 130,	# Pali
		'pl' => 131,	# Polish
		'pt' => 132,	# Portuguese
		'ps' => 133,	# Pushto
		'qu' => 134,	# Quechua
		'rm' => 135,	# Romansh
		'ro' => 136,	# Romanian
		'rn' => 137,	# Rundi
		'ru' => 138,	# Russian
		'sg' => 139,	# Sango
		'sa' => 140,	# Sanskrit
		'si' => 141,	# Sinhala
		'sk' => 142,	# Slovak
		'sl' => 143,	# Slovenian
		'se' => 144,	# Northern Sami
		'sm' => 145,	# Samoan
		'sn' => 146,	# Shona
		'sd' => 147,	# Sindhi
		'so' => 148,	# Somali
		'st' => 149,	# Southern Sotho
		'es' => 150,	# Spanish
		'sq' => 151,	# Albanian
		'sc' => 152,	# Sardinian
		'sr' => 153,	# Serbian
		'ss' => 154,	# Swati
		'su' => 155,	# Sundanese
		'sw' => 156,	# Swahili (macrolanguage)
		'sv' => 157,	# Swedish
		'ty' => 158,	# Tahitian
		'ta' => 159,	# Tamil
		'tt' => 160,	# Tatar
		'te' => 161,	# Telugu
		'tg' => 162,	# Tajik
		'tl' => 163,	# Tagalog
		'th' => 164,	# Thai
		'ti' => 165,	# Tigrinya
		'to' => 166,	# Tonga (Tonga Islands)
		'tn' => 167,	# Tswana
		'ts' => 168,	# Tsonga
		'tk' => 169,	# Turkmen
		'tr' => 170,	# Turkish
		'tw' => 171,	# Twi
		'ug' => 172,	# Uighur
		'uk' => 173,	# Ukrainian
		'ur' => 174,	# Urdu
		'uz' => 175,	# Uzbek
		've' => 176,	# Venda
		'vi' => 177,	# Vietnamese
		'vo' => 178,	# Volapuk
		'wa' => 179,	# Walloon
		'wo' => 180,	# Wolof
		'xh' => 181,	# Xhosa
		'yi' => 182,	# Yiddish
		'yo' => 183,	# Yoruba
		'za' => 184,	# Zhuang
		'zh' => 185,	# Chinese
		'zu' => 186, },	# Zulu

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

# Bracketed  notes found in examples file A lines, mapped to MISC keywords.

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
