#!/usr/bin/env python

#----- REMINDER ------------------------------------------------------
# To make any changes to the jelparse code, edit jelparse.y.  Then
# run 'make' in the lib dir to regenerate jelparse.py from jelparse.y.
#---------------------------------------------------------------------
#----- WARNING -------------------------------------------------------
# These tests rely on the correct functioning of the fmtjel.py module.
#---------------------------------------------------------------------

import sys, unittest, pdb
if '../lib' not in sys.path: sys.path.append ('../lib')
import jdb, jellex, jelparse, fmtjel, unittest_extensions

__unittest = 1
cur = None

def main():
	globalSetup()
	unittest.main()

def globalSetup ():
	global Cur, KW, Lexer, Parser
	try:
	    import dbauth; kwargs = dbauth.auth
	except ImportError: kwargs = {}
	kwargs['autocommit'] = True
	Cur = jdb.dbOpen ('jmdict', **kwargs)
	KW = jdb.KW
        Lexer, tokens = jellex.create_lexer ()
        Parser = jelparse.create_parser (Lexer, tokens)

class Roundtrip (unittest.TestCase):

    # To debug any failing tests, run: 
    #   ../lib/jelparse.py -d258 -qnnnnnnn 
    # where 'nnnnnnn' is the entry seq number used in the 
    # failing test.  The -d258 option will print the lexer
    # tokens passed to the parser, and the parser productions
    # applied as a result.

    def setUp (self):
	try: Lexer
	except NameError: globalSetup()
    def test1000290(self): self.check(1000290)	# simple, 1H1S1Ts1G
    def test1000490(self): self.check(1000490)	# simple, 1H1K1S1Ts1G
    def test1004020(self): self.check(1004020)	# 
    def test1005930(self): self.check(1005930)	# Complex, 3KnTk4RnTr1S2Ts1G1Xf1XrNokanj
    def test1324440(self): self.check(1324440)	# restr: One 'nokanji' reading
    def test1000480(self): self.check(1000480)	# dialect
    def test1002480(self): self.check(1002480)	# lsrc lang=nl
    def test1013970(self): self.check(1013970)	# lsrc lang=en+de
    def test1017950(self): self.check(1017950)	# lsrc wasei
    def test1629230(self): self.check(1629230)	# lsrc 3 lsrc's
    def test1077760(self): self.check(1077760)	# lsrc lang w/o text
    def test1000520(self): self.check(1000520)	# sens.notes (en)
    def test1000940(self): self.check(1000940)	# sens.notes (en,jp)
    def test1002320(self): self.check(1002320)	# sens notes on mult senses
    def test1198180(self): self.check(1198180)	# sens.notes, long
    def test1079110(self): self.check(1079110)	# sens.notes, quotes
    def test1603990(self): self.check(1603990)	# gloss with starting with numeric char, stagr, stagk, restr
    def test1416050(self): self.check(1416050)	# stagr, stagk, nokanji
    def test1542640(self): self.check(1542640)	# stagr, stagk, restr
    def test1593470(self): self.check(1593470)	# gloss with aprostrophe, stagr, stagk, restr
    def test1316860(self): self.check(1316860)	# mult kinf
    def test1214540(self): self.check(1214540)	# mult kinf
    def test1582580(self): self.check(1582580)	# mult rinf
    def test1398850(self): self.check(1398850)	# mult fld
    def test1097870(self): self.check(1097870)	# mult fld, lsrc
    def test1517910(self): self.check(1517910)	# gloss in quotes
    def test1516925(self): self.check(1516925)	# gloss containg quotes and apostrophe
    def test1379360(self): self.check(1379360)	# gloss, initial paren
    def test1401950(self): self.check(1401950)	# gloss, trailing numeric and paren
    def test1414950(self): self.check(1414950)	# gloss, mult quotes
    def test1075210(self): self.check(1075210)	# gloss, initial digits
    #4 def test1000090(self): self.check(1000090)	# xref and ant with hard to classify kanji.
    def test1000920(self): self.check(1000920)	# xref w rdng (no kanj) and sense number.
    def test1000420(self): self.check(1000420)	# xref w K.R pair.
    def test1011770(self): self.check(1011770)  # ant with K.R.s triple.
    def test2234570(self): self.check(2234570)	# xref w K.s pair.
    def test1055420(self): self.check(1055420)	# dotted reb, wide ascii xref.
    def test1098650(self): self.check(1098650)	# dotted reb, kanji xref.
    def test1099200(self): self.check(1099200)	# mult rdng w dots, kanj xref.
    def test1140360(self): self.check(1140360)	# xref w kanj/katakana.
    #1 def test1578780(self): self.check(1578780)	# dotted pair (K.R) in stagk.
    #3 def test2038530(self): self.check(2038530)	# dotted keb w dotted restr.
    def test2107800(self): self.check(2107800)	# double-dotted reb.
    #2 def test2159530(self): self.check(2159530)	# wide ascii kanj w dot and restr.
    def test1106120(self): self.check(1106120)	# embedded semicolon in gloss.
    def test1329750(self): self.check(1329750)	# literal gloss.

    #1 -- Error due to dotted K.R pair in stagk.
    #2 -- Fails due to xref not found because of K/R misclassification.
    #3 -- Fails due to mid-dot in restr text which is confused with the 
    #	    mid-dot used to separate K.R pairs.
    #4 -- [ant=x] fails to parse because is is  not recognised as an xref 
    #       because "x" is neither kanji or kana so is iterpreted as a  
    #       "tag=x" and the lookup of tag type "ant" of course fails.

    def check (self, seq): _check (self, seq)

class RTpure (unittest.TestCase):
    # These tests use artificial test data intended to test single
    # parser features.

    def setUp (self):
	try: Lexer
	except NameError: globalSetup()
    def test0100010(self): self.check('0100010')  # Basic: 1 kanj, 1 rdng, 1 sens, 1 gloss
    def test0100020(self): self.check('0100020')  # Basic: 1 kanj, 1 sens, 1 gloss
    def test0100030(self): self.check('0100030')  # Basic: 1 rdng, 1 sens, 1 gloss
    def test0100040(self): self.check('0100040')  # IS-163.
    # Following worked up to rev ccc8a44ad8fd-2009-03-12 but are now syntax errors
	# Like 0100010 but all text on one line.
    def test0100040(self): self.cherr('0100040',jelparse.ParseError,"Syntax Error")
	# Like 0100020 but all text on one line.
    def test0100050(self): self.cherr('0100050',jelparse.ParseError,"Syntax Error")
	# Like 0100030 but all text on one line.
    def test0100060(self): self.cherr('0100060',jelparse.ParseError,"Syntax Error")
        # No rdng or kanj.

    def test0100070(self): self.check('0100070')  # IS-163.
    def test0100080(self): self.check('0100080')  # IS-163.
    def test0200010(self): self.cherr('0200010', jelparse.ParseError,"Syntax Error") 
    def test0200020(self): self.cherr('0200020', jelparse.ParseError,"Syntax Error") 

    def check (self, seq): _check (self, seq)
    def cherr (self, seq, exception, msg): _cherr (self, seq, exception, msg)

def _cherr (self, seq, exception, msg):
	global Cur, Lexer, Parser
	#pdb.set_trace()
	intxt = unittest_extensions.readfile_utf8 ("data/jelparse/%s.txt" % seq)
        jellex.lexreset (Lexer, intxt)
	_assertRaisesMsg (self, exception, msg, Parser.parse, intxt, lexer=Lexer)

def _assertRaisesMsg (self, exception, message, func, *args, **kwargs):
        expected = "Expected %s(%r)," % (exception.__name__, message)
        try:
            func(*args, **kwargs)
        except exception, e:
            if str(e) != message:
                msg = "%s got %s(%r)" % (
                    expected, exception.__name__, str(e))
                raise AssertionError(msg)
        except Exception, e:
            msg = "%s got %s(%r)" % (expected, e.__class__.__name__, str(e))
            raise AssertionError(msg)
        else:
            raise AssertionError("%s no exception was raised" % expected)

def _check (self, seq):
	global Cur, Lexer, Parser
	intxt = unittest_extensions.readfile_utf8 ("data/jelparse/%s.txt" % seq)
	try:
	    exptxt = unittest_extensions.readfile_utf8 ("data/jelparse/%s.exp" % seq)
	except IOError:
	    exptxt = intxt
        jellex.lexreset (Lexer, intxt)
	#pdb.set_trace()
        entr = Parser.parse (intxt, lexer=Lexer)
	entr.src = 1
        jelparse.resolv_xrefs (Cur, entr)
	for s in entr._sens: jdb.augment_xrefs (Cur, getattr (s, '_xref', []))
	for s in entr._sens: jdb.add_xsens_lists (getattr (s, '_xref', []))
	for s in entr._sens: jdb.mark_seq_xrefs (Cur, getattr (s, '_xref', []))
        outtxt = fmtjel.entr (entr, nohdr=True)
	self.assert_ (8 <= len (outtxt))    # Sanity check for non-empty entry.
	msg = "\nExpected:\n%s\nGot:\n%s" % (exptxt, outtxt)
	self.assertEqual (outtxt, exptxt, msg)

class Lookuptag (unittest.TestCase):

    # WARNING -- these tests depend on the keyword values 
    # which are subject to change with changes in Jim Breen's
    # JMdict file DTD.

    def setUp (self):
	try: lexer
	except NameError: globalSetup()
    def test001(self): self.assertEqual ([['DIAL',2]], jelparse.lookup_tag('ksb',['DIAL']))
    def test002(self): self.assertEqual ([['DIAL',2]], jelparse.lookup_tag('ksb'))
    def test003(self): self.assertEqual ([], jelparse.lookup_tag('ksb',['POS']))
    def test004(self): self.assertEqual ([['POS',17]], jelparse.lookup_tag('n',['POS']))
    def test005(self): self.assertEqual ([['POS',17]], jelparse.lookup_tag('n'))
    def test006(self): self.assertEqual ([], jelparse.lookup_tag('n',['RINF']))
    def test007(self): self.assertEqual ([['FREQ',5,12]], jelparse.lookup_tag('nf12',['FREQ']))
    def test008(self): self.assertEqual ([['FREQ',5,12]], jelparse.lookup_tag('nf12'))
    def test009(self): self.assertEqual ([], jelparse.lookup_tag('nf12',['POS']))
    def test010(self): self.assertEqual ([['LANG', 1]], jelparse.lookup_tag('eng'))
    def test011(self): self.assertEqual ([['LANG',1]], jelparse.lookup_tag('eng',['LANG']))
    def test012(self): self.assertEqual ([['LANG',346]], jelparse.lookup_tag('pol',['LANG']))
    def test013(self): self.assertEqual ([['MISC',19]], jelparse.lookup_tag('pol',['MISC']))
    def test014(self): self.assertEqual ([['LANG', 346], ['MISC', 19]], jelparse.lookup_tag('pol'))
    def test015(self): self.assertEqual ([['POS',44]], jelparse.lookup_tag('vi'))
    def test016(self): self.assertEqual ([], jelparse.lookup_tag('nf',['RINF']))
    def test018(self): self.assertEqual ([['KINF',4],['RINF',3]], jelparse.lookup_tag('ik'))
    def test019(self): self.assertEqual ([['POS',28],], jelparse.lookup_tag('v1'))

    def test101(self): self.assertEqual (None, jelparse.lookup_tag ('n',['POSS']))
      # Is the following desired behavior? Or should value for 'n' in 'POS' be returned?
    def test102(self): self.assertEqual (None, jelparse.lookup_tag ('n',['POS','POSS']))

if __name__ == '__main__': main()
