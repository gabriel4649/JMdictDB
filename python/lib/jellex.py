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

import ply.lex, re
import jdb, fmtjel

class LexSpec:

    # Note that in the strings used as regexes below, all containing
    # a "\unnnn" literal are non-raw strings in which any other
    # backslashes are doubled.  (This due to a Python 3 "improvement"
    # that causes "\unnnn" literals in raw strings to be interpreted
    # as 6 characters rather than a single unicode character as was
    # the case in Python 2.  Sigh.)

    states = (
        ('TAGLIST', 'exclusive'),
        ('GLOSS',   'exclusive'),
        ('SNUMLIST','exclusive'),)

    tokens = ('SNUM', 'SEMI', 'BRKTL', 'TEXT', 'QTEXT', 'COLON',
              'COMMA', 'DOT', 'EQL', 'SLASH', 'BRKTR', 'NL', 'FF',
              'GTEXT', 'KTEXT', 'RTEXT', 'NUMBER', 'HASH')

    def __init__(self): pass

# State: INITIAL

    def t_SNUM (self, t):
        r'\[\d+\]\s*'
        t.lexer.begin('GLOSS')
        return t

    def t_SEMI (self, t):
        '[;\uFF1B]'
        return t

    def t_BRKTL (self, t):
        r'\['
        t.lexer.push_state ('TAGLIST')
        return t

    def t_TEXT (self, t):
        '[^;\uFF1B\[\u3000 \\t\\r\\n\\f]+'
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
        r':'
        return t
    def t_TAGLIST_SEMI (self, t):
        '[;\uFF1B]'
        return t
    def t_TAGLIST_COMMA (self, t):
        '[,\u3001]'
        return t
    def t_TAGLIST_EQL (self, t):
        r'='
        return t
    def t_TAGLIST_SLASH (self, t):
        '[\\/\uFF0F]'
        return t
    def t_TAGLIST_DOT (self, t):
        '[\\.\u30FB]'
        return t
    def t_TAGLIST_HASH (self, t):
        r'\#'
        return t
    def t_TAGLIST_BRKTL (self, t):
        r'\['
        t.lexer.push_state('SNUMLIST')
        return t
    def t_TAGLIST_BRKTR (self, t):
        r'\]'
        t.lexer.pop_state()
        return t

    def t_TAGLIST_NUMBER (self, t):
        '[0-9\uFF10-\uFF19]+'
        return t

    def t_TAGLIST_TEXT (self, t):
        '[^;\uFF1B:=,\u3001\\/\\.\\#\uFF0F\u30FB\\[\\] \\t\\r\\n\\f]+'
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
        r'\]'
        t.lexer.pop_state()
        return t

    def t_SNUMLIST_COMMA (self, t):
        r','           #FIXME? include wide comma?
        return t

    def t_SNUMLIST_NUMBER (self, t):
        '[0-9\uFF10-\uFF19]+'
        return t

    def t_SNUMLIST_TEXT (self, t):
        r'.'
        return t

# State: GLOSS

    def t_GLOSS_GTEXT (self, t):
        r'(([^;\\\[])|(\\\[)|(\\;))+'
        t.lexer.lineno += t.value.count ('\n')
        t.value = gcleanup(t.value)
        if t.value: return t
        else: return None
    def t_GLOSS_SNUM (self, t):
        r'\s*\[\d+\]\s*'
        return t
    def t_GLOSS_SEMI (self, t):
        r';'
        return t
    def t_GLOSS_BRKTL (self, t):
        r'\['
        t.lexer.push_state('TAGLIST')
        return t

    def t_INITIAL_GLOSS_TAGLIST_SNUMLIST_NL (self, t):
        r'\n'
        t.lexer.lineno += 1
        return None

    def t_INITIAL_GLOSS_TAGLIST_SNUMLIST_FF (self, t):
        r'\f'
        return t

    t_ignore = ' \u3000\r\t'
    t_TAGLIST_ignore = ' \u3000\r\t'
    t_SNUMLIST_ignore = ' \u3000\r\t'
    t_GLOSS_ignore = ''

    def t_error(self, t):
        raise RuntimeError ("Illegal character '%s'" % t.value[0])

    t_TAGLIST_error = t_SNUMLIST_error = t_GLOSS_error = t_error

def gcleanup (txt):
        # Clean up a gloss string.
        # Replace multiple whitespace characters with one.
        # Remove leading and trailing whitespace from string.
        # Unescape backslash-escaped ';'s and '['s.
        #FIXME? what about other control characters?

        txt = re.sub (r'[ \t\u3000\n\r]+', ' ', txt).strip()
        #txt = re.sub (ur'\\([;\[\\])', ur'\1', txt)
        txt = re.sub (r'\\(.)', r'\1', txt)
        return txt

def qcleanup (txt):
        # Clean up a quoted string (as may occur in notes,
        # lsrc, etc.)
        # Remove leading and trailing whitespace from string.
        # Replace multiple whitespace characters with one.
        # Unescape backslash-escaped '"'s.
        #FIXME? what about other control characters?

        txt = re.sub (r'[ \t\u3000\n\r]+', ' ', txt).strip()
        #txt = re.sub (ur'\\(["\\])', r'\1', txt)
        txt = re.sub (r'\\(.)', r'\1', txt)
        return txt

def create_lexer (debug=0):
        spec = LexSpec()
        lexer = ply.lex.lex(object=spec, reflags=re.UNICODE, debug=debug)
        lexer.lineno = 1
        return lexer, spec.tokens

def lexreset (lexer, instr, begin='INITIAL'):
        lexer.input (instr)
        lexer.begin (begin)
        lexer.lineno = 1;
