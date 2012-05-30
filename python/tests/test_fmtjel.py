# -*- coding: utf-8 -*-

from __future__ import print_function, absolute_import, division, unicode_literals
from future_builtins import ascii, filter, hex, map, oct, zip
import sys, unittest, codecs, os.path, pdb
if '../lib' not in sys.path: sys.path.append ('../lib')
import jdb, fmtjel, jmxml, xmlkw, jelparse, jellex
from objects import *
import unittest_extensions

__unittest = 1
Cur = None

def main():
        globalSetup()
        unittest.main()

def globalSetup ():
        global Cur, KW, Lexer, Parser
        if Cur: return False
        try: import dbauth; kwargs = dbauth.auth
        except ImportError: kwargs = {}
        Cur = jdb.dbOpen ('jmdict', **kwargs)
        KW = jdb.KW
        Lexer, tokens = jellex.create_lexer ()
        Parser = jelparse.create_parser (Lexer, tokens)
        return True

class Test_general (unittest.TestCase):
    def setUp (self): globalSetup ()
    def test1000290(self): self.check(1000290)  # simple, 1H1S1Ts1G
    def test1000490(self): self.check(1000490)  # simple, 1H1K1S1Ts1G
    def test1004020(self): self.check(1004020)  #
    def test1005930(self): self.check(1005930)  # Complex, 3KnTk4RnTr1S2Ts1G1Xf1XrNokanj
    def test1324440(self): self.check(1324440)  # restr: One 'nokanji' reading
    def test1000480(self): self.check(1000480)  # dialect
    def test1002480(self): self.check(1002480)  # lsrc lang=nl
    def test1013970(self): self.check(1013970)  # lsrc lang=en+de
    def test1017950(self): self.check(1017950)  # lsrc wasei
    def test1629230(self): self.check(1629230)  # lsrc 3 lsrc's
    def test1077760(self): self.check(1077760)  # lsrc lang w/o text
    def test1000520(self): self.check(1000520)  # sens.notes (en)
    def test1000940(self): self.check(1000940)  # sens.notes (en,jp)
    def test1002320(self): self.check(1002320)  # sens notes on mult senses
    def test1198180(self): self.check(1198180)  # sens.notes, long
    def test1079110(self): self.check(1079110)  # sens.notes, quotes
    def test1603990(self): self.check(1603990)  # gloss with starting with numeric char, stagr, stagk, restr
    def test1416050(self): self.check(1416050)  # stagr, stagk, nokanji
    def test1542640(self): self.check(1542640)  # stagr, stagk, restr
    def test1593470(self): self.check(1593470)  # gloss with aprostrophe, stagr, stagk, restr
    def test1316860(self): self.check(1316860)  # mult kinf
    def test1214540(self): self.check(1214540)  # mult kinf
    def test1582580(self): self.check(1582580)  # mult rinf
    def test1398850(self): self.check(1398850)  # mult fld
    def test1097870(self): self.check(1097870)  # mult fld, lsrc
    def test1517910(self): self.check(1517910)  # gloss in quotes
    def test1516925(self): self.check(1516925)  # gloss containg quotes and apostrophe
    def test1379360(self): self.check(1379360)  # gloss, initial paren
    def test1401950(self): self.check(1401950)  # gloss, trailing numeric and paren
    def test1414950(self): self.check(1414950)  # gloss, mult quotes
    def test1075210(self): self.check(1075210)  # gloss, initial digits
    #2 def test1000090(self): self.check(1000090)       # xref and ant with hard to classify kanji.
    def test1000920(self): self.check(1000920)  # xref w rdng (no kanj) and sense number.
    def test1000420(self): self.check(1000420)  # xref w K.R pair.
    def test1011770(self): self.check(1011770)  # ant with K.R.s triple.
    def test2234570(self): self.check(2234570)  # xref w K.s pair.
    def test1055420(self): self.check(1055420)  # dotted reb, wide ascii xref.
    def test1098650(self): self.check(1098650)  # dotted reb, kanji xref.
    def test1099200(self): self.check(1099200)  # mult rdng w dots, kanj xref.
    def test1140360(self): self.check(1140360)  # xref w kanj/katakana.
    def test1578780(self): self.check(1578780)  # dotted pair (K.R) in stagk.
    #2 def test2038530(self): self.check(2038530)       # dotted keb w dotted restr.
    def test2107800(self): self.check(2107800)  # double-dotted reb.
    #3 def test2159530(self): self.check(2159530)       # wide ascii kanj w dot and restr.
    def test1106120(self): self.check(1106120)  # semicolon in gloss.
    def test1329750(self): self.check(1329750)  # literal gloss.

    #1 -- Error due to dotted K.R pair in stagk.
    #2 -- Fails due to xref not found because of K/R misclassification.
    #3 -- Fails due to mid-dot in restr text which is confused with the
    #       mid-dot used to separate K.R pairs.

    def check (self, seq):
        global Cur, KW
          # Read expected text, remove any unicode BOM or trailing whitespace
          # that may have been added when editing.
        expected = open ("data/fmtjel/"+str(seq)+".txt").read().decode('utf-8').rstrip()
        if expected[0] == u'\ufeff': expected = expected[1:]
          # Read the entry from the database.  Be sure to get from the right
          # corpus and get only the currently active entry.  Assert that we
          # received excatly one entry.
        sql = "SELECT id FROM entr WHERE src=1 AND seq=%s AND stat=2 AND NOT unap"
        entrs,data = jdb.entrList (Cur, sql, (seq,), ret_tuple=True)
        self.assertEqual (1, len (entrs))
          # Add the annotations needed for dislaying xrefs in condensed form.
        jdb.augment_xrefs (Cur, data['xref'])
        jdb.augment_xrefs (Cur, data['xrer'], rev=True)
        fmtjel.markup_xrefs (Cur, data['xref'])
          # Test fmtjel by having it convert the entry to JEL.
        resulttxt = fmtjel.entr (entrs[0]).splitlines(True)
          # Confirm that the received text matched the expected text.
        if resulttxt: resulttxt = ''.join(resulttxt[1:])
        self.assert_ (10 < len (resulttxt))
        msg = "\nExpected:\n%s\nGot:\n%s" % (expected, resulttxt)
        self.assertEqual (expected, resulttxt, msg)

class Test_restr (unittest.TestCase):
    def setUp (self): globalSetup ()
    def test_001(_):
        e1 = Entr (id=100, src=1, seq=1000010, stat=2, unap=False)
        expect = 'jmdict 1000010 A {100}\n\n\n'
        jeltxt = fmtjel.entr (e1)
        _.assertEqual (expect, jeltxt)
    def test_002(_):
        e1 = Entr (id=100, src=1, seq=1000010, stat=2, unap=False)
        e1._kanj = [Kanj(txt=u'手紙',), Kanj(txt=u'切手')]
        e1._rdng = [Rdng(txt=u'てがみ'), Rdng(txt=u'あとで'), Rdng(txt=u'きって')]
        r = Restr(); e1._rdng[0]._restr.append (r); e1._kanj[1]._restr.append(r)
        r = Restr(); e1._rdng[1]._restr.append (r); e1._kanj[0]._restr.append(r)
        r = Restr(); e1._rdng[2]._restr.append (r); e1._kanj[0]._restr.append(r)
        r = Restr(); e1._rdng[2]._restr.append (r); e1._kanj[1]._restr.append(r)
        expect =  'jmdict 1000010 A {100}\n' \
                  '手紙；切手\n' \
                  'てがみ[手紙]；あとで[切手]；きって[nokanji]\n'
        jeltxt = fmtjel.entr (e1)
        msg = "\nA:\n%s\nB:\n%s" % (expect, jeltxt)
        _.assertEqual (expect, jeltxt, msg)

class Test_extra (unittest.TestCase):
    def setUp (_):
        globalSetup()
        XKW = xmlkw.make (jdb.KW)
        jmxml.XKW = XKW    # FIXME: gross
    def test_x00001(_): dotest (_, 'x00001')    # dotted restrs in quotes.

class Base (unittest.TestCase):
    def setUp (_):
        globalSetup()
        _.data = loadData ('data/fmtjel/base.txt', r'# ([0-9]{7}[a-zA-Z0-9_]+)')

    def test0000010(_): check2(_,'0000010')     # lsrc wasei
    def test0000020(_): check2(_,'0000020')     # lsrc partial
    def test0000030(_): check2(_,'0000030')     # lsrc wasei,partial
    def test0000040(_): check2(_,'0000040')     # lsrc wasei,partial


def check2 (_, test, exp=None):
        intxt = _.data[test + '_data']
        try: exptxt = (_.data[test + '_expect']).strip('\n')
        except KeyError: exptxt = intxt.strip('\n')
        outtxt = roundtrip (Cur, intxt).strip('\n')
        _.assert_ (8 <= len (outtxt))    # Sanity check for non-empty entry.
        msg = "\nExpected:\n%s\nGot:\n%s" % (exptxt, outtxt)
        _.assertEqual (outtxt, exptxt, msg)

def roundtrip (cur, intxt):
        jellex.lexreset (Lexer, intxt)
        entr = Parser.parse (intxt, lexer=Lexer)
        entr.src = 1
        jelparse.resolv_xrefs (cur, entr)
        for s in entr._sens: jdb.augment_xrefs (cur, getattr (s, '_xref', []))
        for s in entr._sens: jdb.add_xsens_lists (getattr (s, '_xref', []))
        for s in entr._sens: jdb.mark_seq_xrefs (cur, getattr (s, '_xref', []))
        outtxt = fmtjel.entr (entr, nohdr=True)
        return outtxt

def loadData (filename, secsep, last=[None,None]):
        # Read test data file 'filename' caching its data and returning
        # cached data on subsequent consecutive calls with same filename.
        if last[0] != filename:
            last[1] = unittest_extensions.readfile_utf8 (filename,
                         rmcomments=True, secsep=secsep)
            last[0] = filename
        return last[1]


def loadData (filename, secsep, last=[None,None]):
        # Read test data file 'filename' caching its data and returning
        # cached data on subsequent consecutive calls with same filename.
        if last[0] != filename:
            last[1] = unittest_extensions.readfile_utf8 (filename,
                         rmcomments=True, secsep=secsep)
            last[0] = filename
        return last[1]

def dotest (_, testid, xmlfn=None, jelfn=None, dir='data/fmtjel', enc='utf_8_sig'):
        if xmlfn is None: xmlfn = os.path.join (dir, testid + '.xml')
        if jelfn is None: jelfn = os.path.join (dir, testid + '.jel')
        expected = readfile (jelfn, enc)
        xmlu = readfile (xmlfn, enc)
        xml8 = xmlu.encode ('utf-8')
        elist = jmxml.parse_entry (xml8)
        got = fmtjel.entr (elist[0], nohdr=True)
        msg = "\nExpected:\n%s\nGot:\n%s" % (expected, got)
        _.assertEqual (expected, got, msg)

def readfile (filename, enc):
        with codecs.open (filename, 'r', enc) as f:
            contents = f.read()
        return contents.strip()

if __name__ == '__main__': unittest.main()
