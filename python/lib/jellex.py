#######################################################################
#  This file is part of JMdictDB. 
#  Copyright (c) 2008 Stuart McGraw 
# 
#  JMdictDB is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published 
#  by the Free Software Foundation; either version 2 of the License, 
#  or (at your option) any later version.
# 
#  JMdictDB is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
# 
#  You should have received a copy of the GNU General Public License
#  along with JMdictDB; if not, write to the Free Software Foundation,
#  51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
#######################################################################
from __future__ import print_function

__version__ = ('$Revision$'[11:-2],
	       '$Date$'[7:-11]);

import ply.lex, re
import jdb, fmtjel

class LexSpec:

    states = (
	('TAGLIST', 'exclusive'),
	('GLOSS',   'exclusive'),
	('SNUMLIST','exclusive'),)

    tokens = ('SNUM', 'SEMI', 'BRKTL', 'TEXT', 'QTEXT', 'COLON', 
	      'COMMA', 'DOT', 'EQL', 'SLASH', 'BRKTR', 'NL',
	      'GTEXT', 'KTEXT', 'RTEXT', 'NUMBER', 'HASH')

    def __init__(self): pass

# State: INITIAL

    def t_SNUM (self, t):
	ur'\[\d+\]\s*'
	t.lexer.begin('GLOSS')
	return t

    def t_SEMI (self, t):
	ur'[;\uFF1B]'
	return t

    def t_BRKTL (self, t):
	ur'\['
	t.lexer.push_state ('TAGLIST')
	return t

    def t_TEXT (self, t):
	ur'[^;\uFF1B\[\u3000 \t\r\n]+'
	  # Classify it as kanji, reading (kana), or ordinary
	  # text and return token accordingly.
	m = jdb.jstr_classify (t.value)
	if jdb.jstr_reb (m): t.type = 'RTEXT'
	elif jdb.jstr_gloss (m): pass
	else: t.type = 'KTEXT'
	return t

# State: TAGLIST

    def t_TAGLIST_QTEXT (self, t):
	'"([^"\\\\]|(\\\\"))+"'
	  # A string that starts and ends with double quote characters
	  # and includes any number of double quote characters that are 
	  # escaped with backslash characters.
	return t
    def t_TAGLIST_COLON (self, t):
	ur':'
	return t
    def t_TAGLIST_SEMI (self, t):
	ur'[;\uFF1B]'
	return t
    def t_TAGLIST_COMMA (self, t):
	ur'[,\u3001]'
	return t
    def t_TAGLIST_EQL (self, t):
	ur'='
	return t
    def t_TAGLIST_SLASH (self, t):
	ur'[\/\uFF0F]'
	return t
    def t_TAGLIST_DOT (self, t):
	ur'[\.\u30FB]'
	return t
    def t_TAGLIST_HASH (self, t):
	ur'\#'
	return t
    def t_TAGLIST_BRKTL (self, t):
	ur'\['
	t.lexer.push_state('SNUMLIST')
	return t
    def t_TAGLIST_BRKTR (self, t):
	ur'\]'
	t.lexer.pop_state()
	return t

    def t_TAGLIST_NUMBER (self, t):
	ur'[0-9\uFF10-\uFF19]+'
	return t

    def t_TAGLIST_TEXT (self, t):
	ur'[^;\uFF1B:=,\u3001\/\.\#\uFF0F\u30FB\[\] \t\r\n]+'
	  # Classify it as kanji, reading (kana), or ordinary
	  # text and return token accordingly.
	t.value = qcleanup(t.value)
	m = jdb.jstr_classify (t.value)
	if jdb.jstr_reb (m): t.type = 'RTEXT'
	elif jdb.jstr_gloss (m): pass
	else: t.type = 'KTEXT'
	return t

# State: SNUMLIST

    def t_SNUMLIST_BRKTR (self, t):
	ur'\]'
	t.lexer.pop_state()
	return t

    def t_SNUMLIST_COMMA (self, t):
	ur','
	return t

    def t_SNUMLIST_NUMBER (self, t):
	ur'[0-9\uFF10-\uFF19]+'
	return t

    def t_SNUMLIST_TEXT (self, t):
	ur'.'
	return t

# State: GLOSS

    def t_GLOSS_GTEXT (self, t):
	ur'(([^;\\\[])|(\\\[)|(\\;))+'
	t.lexer.lineno += t.value.count ('\n')
	t.value = gcleanup(t.value)
	if t.value: return t
	else: return None
    def t_GLOSS_SNUM (self, t):
	ur'\s*\[\d+\]\s*'
	return t
    def t_GLOSS_SEMI (self, t):
	ur';'
	return t
    def t_GLOSS_BRKTL (self, t):
	ur'\['
	t.lexer.push_state('TAGLIST')
	return t

    def t_INITIAL_GLOSS_TAGLIST_SNUMLIST_NL (self, t):
	r'\n'
	t.lexer.lineno += 1
	if t.lexer.current_state() == 'INITIAL':
	    return t
	return None

    t_ignore = u' \u3000\r\t'
    t_TAGLIST_ignore = u' \u3000\r\t'
    t_SNUMLIST_ignore = u' \u3000\r\t'
    t_GLOSS_ignore = u''

    def t_error(self, t):
	raise RuntimeError ("Illegal character '%s'" % t.value[0])

    t_TAGLIST_error = t_SNUMLIST_error = t_GLOSS_error = t_error

def gcleanup (txt):
	# Clean up a gloss string.
	# Remove leading and trailing whitespace from string.
	# Replace multiple whitespace characters with one.
	# Unescape backslash-escaped ';'s and '['s.

	txt = re.sub (ur'^[\s\u3000\n\r]+', '', txt)
	txt = re.sub (ur'[\s\u3000\n\r]+$', '', txt)
	txt = re.sub (ur'[\s\u3000\n\r]+$', ' ', txt)
	#txt = re.sub (ur'\\([;\[\\])', ur'\1', txt)
	txt = re.sub (ur'\\(.)', ur'\1', txt)
	return txt

def qcleanup (txt):
	# Clean up a quoted string (as may occur in notes,
	# lsrc, etc.)
	# Remove leading and trailing whitespace from string.
	# Replace multiple whitespace characters with one.
	# Unescape backslash-escaped '"'s.

	txt = re.sub (ur'^[\s\u3000\n\r]+', '', txt)
	txt = re.sub (ur'[\s\u3000\n\r]+$', '', txt)
	txt = re.sub (ur'[\s\u3000\n\r]+$', ' ', txt)
	#txt = re.sub (ur'\\(["\\])', r'\1', txt)
	txt = re.sub (ur'\\(.)', r'\1', txt)
	return txt

def create_lexer (debug=0):
	spec = LexSpec()
	lexer = ply.lex.lex(object=spec, reflags=re.UNICODE, debug=debug)
	lexer.lineno = 1
	return lexer, spec.tokens

def lexreset (lexer, instr):
	lexer.input (instr)
	lexer.begin ('INITIAL')
	lexer.lineno = 1;
