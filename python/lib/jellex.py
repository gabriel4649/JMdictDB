#/usr/bin/env python
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

__version__ = ('$Revision$'[11:-2],
	       '$Date$'[7:-11]);

import ply.lex, re
import jdb, fmtjel

class LexSpec:

    states = (
	('TAGLIST', 'exclusive'),
	('GLOSS',   'exclusive'),
	('SNUMLIST','exclusive'),)

    tokens = ('SNUM', 'SEMI', 'BRKTL', 'TEXT', 'QTEXT', 'COLON', 'COMMA', 'DOT',
	      'EQL', 'SLASH', 'BRKTR', 'GTEXT', 'KTEXT', 'RTEXT', 'NUMBER')

    def __init__(self): pass

# State: INITIAL

    def t_SNUM (self, t):
	ur'\s*\[\d+\]\s*'
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
	ur','
	return t
    def t_TAGLIST_EQL (self, t):
	ur'='
	return t
    def t_TAGLIST_SLASH (self, t):
	ur'[\/\uFF0F]'
	return t
    def t_TAGLIST_DOT (self, t):
	ur'[\u30FB]'
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
	ur'[^;\uFF1B:=,\/\uFF0F\u30FB\[\] \t\r\n]+'
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
	return None

    t_ignore = u' \u3000\r\t'
    t_TAGLIST_ignore = u' \u3000\r\t'
    t_SNUMLIST_ignore = u' \u3000\r\t'
    t_GLOSS_ignore = u''

    def t_error(self, t):
	print "Illegal character '%s'" % t.value[0]
	t.lexer.skip(1)

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

def main (args, opts):
	global KW, tokens

        lexer, tokens = create_lexer (debug=opts.debug)
	if opts.seq:
	    instr = _get_text_from_database (opts.seq, 1)
	    print instr
	    print "----------"
	    test (lexer, instr)
	else:
	    while 1:
	        instr = _get_text_interactively()
	        if not instr: break
		test (lexer, instr)

def test (lexer, instr):
	lexreset (lexer, instr)
	while 1:
	    tok = lexer.token()
	    if not tok: break
	    print tok

def _get_text_from_database (seq, src):
	cur = jdb.dbOpen ('jmdict')
	KW = jdb.KW
	sql = "SELECT id FROM entr WHERE seq=%s AND src=%s"
	elist = jdb.entrList (cur, sql, [seq, src])
	if not elist:
	    print "Entry %s not found" % seq
	    return
	entr = elist[0]
	for s in entr._sens:
	    jdb.augment_xrefs (cur, getattr (s, '_xref', []))
	txt = fmtjel.entr (entr)
	txt = txt.partition('\n')[2]
	return txt

def _get_text_interactively ():
	instr = '';  cnt = 0;  prompt = 'test> '
	while cnt < 1:
            try: s = raw_input(prompt).decode('sjis')
            except EOFError: break
	    prompt = ''
            if s: cnt = 0
	    else: cnt += 1
	    if cnt < 1: instr += s + '\n'
	return instr.rstrip()


def _parse_cmdline ():
	from optparse import OptionParser 
	u = \
"""\n\tpython %prog [-d n][-q SEQ]
	
  This is a simple test/exerciser for the JEL parser.  It operates
  in two different modes depending on the presence or absense of 
  the --seq (-q) option.  

  When present it will read the entry with the given seq number
  from the jmdict corpus in the database, format it as a JEL text 
  string, and parse it.  It prints both the input text and the
  object generated from the parse in the same format, and both
  should be functionally identical.  (There may be non-significant
  differences such as tag order.)

  If the --seq (-q) option is not given, this program will read 
  text input interactively until a blank line is entered, feed the 
  text to the parser, and print the resulting object. 

Arguments: (None)
"""
	p = OptionParser (usage=u)
	p.add_option ("-q", "--seq", 
            type="int", dest="seq", default=None,
            help="Parse text generated by reading jmdict seq SEQ from" 
		" database rather than the default behavior of prompting" 
		" interactively for input text.")
	p.add_option ("-d", "--debug",
            type="int", dest="debug", default=0,
            help="Debug value to pass to parser:"
		" 1: Lexer tokens")
	opts, args = p.parse_args ()
	#...arg defaults can be setup here...
	return args, opts

if __name__ == '__main__': 
	args, opts = _parse_cmdline ()
	main (args, opts)

	