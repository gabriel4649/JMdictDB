#!/usr/bin/env python

#----- REMINDER ------------------------------------------------------
# To make any changes to the jelparse code, edit jelparse.y.  Then
# run 'make' in the lib dir to regenerate jelparse.py from jelparse.y.
#---------------------------------------------------------------------

import sys, unittest, pdb
sys.path.insert (0, '../lib')
import jdb, jellex, jelparse, fmtjel

__unittest = 1
cur = None

def main():
	globalSetup()
	unittest.main()

def globalSetup ():
	global cur, KW, lexer, parser
	try:
	    import dbauth; kwargs = dbauth.auth
	except ImportError: kwargs = {}
	kwargs['autocommit'] = True
	cur = jdb.dbOpen ('jmdict', **kwargs)
	KW = jdb.KW
        lexer, tokens = jellex.create_lexer ()
        parser = jelparse.create_parser (tokens)

class Roundtrip (unittest.TestCase):

    # To debug any failing tests, run: 
    #   ../lib/jelparse.py -d258 -qnnnnnnn 
    # where 'nnnnnnn' is the entry seq number used in the 
    # failing test.  The -d258 option will print the lexer
    # tokens passed to the parser, and the parser productions
    # applied as a result.

    def setUp (self):
	try: lexer
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
    def test1000090(self): self.check(1000090)	# xref and ant with hard to classify kanji.
    def test1000920(self): self.check(1000920)	# xref w rdng (no kanj) and sense number.

    def check (self, seq):
	global cur, lexer, parser
	jeltxt, jeltxt2 = jelparse._roundtrip (cur, lexer, parser, seq, 1)
	self.assert_ (3 < len (jeltxt))
	msg = "\nA:\n%s\nB:\n%s" % (jeltxt, jeltxt2)
	self.assertEqual (jeltxt, jeltxt2, msg)

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
    def test010(self): self.assertEqual ([], jelparse.lookup_tag('eng'))
    def test011(self): self.assertEqual ([['LANG',1]], jelparse.lookup_tag('eng',['LANG']))
    def test012(self): self.assertEqual ([['LANG',346]], jelparse.lookup_tag('pol',['LANG']))
    def test013(self): self.assertEqual ([['MISC',19]], jelparse.lookup_tag('pol',['MISC']))
    def test014(self): self.assertEqual ([['MISC',19]], jelparse.lookup_tag('pol'))
    def test015(self): self.assertEqual ([['POS',44]], jelparse.lookup_tag('vi'))
    def test016(self): self.assertEqual ([], jelparse.lookup_tag('nf',['RINF']))
    def test017(self): self.assertEqual ([['RESTR',1]], jelparse.lookup_tag('nokanji',['RESTR']))
    def test018(self): self.assertEqual ([['KINF',4],['RINF',3]], jelparse.lookup_tag('ik'))

      # Should following raise an exception?
    def test101(self): self.assertEqual ([],  jelparse.lookup_tag('n',['POSS']))
      # Is the following desired behavior? Or should value for 'n' in 'POS' be returned?
    def test102(self): self.assertEqual ([],  jelparse.lookup_tag('n',['POS','POSS']))


if __name__ == '__main__': main()
