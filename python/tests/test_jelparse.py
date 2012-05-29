#!/usr/bin/env python

#----- REMINDER ------------------------------------------------------
# To make any changes to the jelparse code, edit jelparse.y.  Then
# run 'make' in the lib dir to regenerate jelparse.py from jelparse.y.
#---------------------------------------------------------------------
#----- WARNING -------------------------------------------------------
# These tests rely on the correct functioning of the fmtjel.py module.
# The tests in class Roundtrip use data from database 'jmdict' which 
#  may change from time to time.
#---------------------------------------------------------------------

from __future__ import print_function, absolute_import, division
from future_builtins import ascii, filter, hex, map, oct, zip 
import sys, unittest, pdb
if '../lib' not in sys.path: sys.path.append ('../lib')
import jdb, jellex, jelparse, fmtjel, unittest_extensions

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
	kwargs['autocommit'] = True
	Cur = jdb.dbOpen ('jmdict', **kwargs)
	KW = jdb.KW
        Lexer, tokens = jellex.create_lexer ()
        Parser = jelparse.create_parser (Lexer, tokens)
	return True

class Roundtrip (unittest.TestCase):

    # [After update to Ply-3.x from Ply-2.5, the following 
    # method of debugging no loger works...]
    # To debug any failing tests, run: 
    #   ../lib/jelparse.py -d258 -qnnnnnnn 
    # where 'nnnnnnn' is the entry seq number used in the 
    # failing test.  The -d258 option will print the lexer
    # tokens passed to the parser, and the parser productions
    # applied as a result.

    def setUp (self): globalSetup()
    def test1000290(_): check(_,1000290)	# simple, 1H1S1Ts1G
    def test1000490(_): check(_,1000490)	# simple, 1H1K1S1Ts1G
    def test1004020(_): check(_,1004020)	# 
    def test1005930(_): check(_,1005930)	# Complex, 3KnTk4RnTr1S2Ts1G1Xf1XrNokanj
    def test1324440(_): check(_,1324440)	# restr: One 'nokanji' reading
    def test1000480(_): check(_,1000480)	# dialect
    def test1002480(_): check(_,1002480)	# lsrc lang=nl
    def test1013970(_): check(_,1013970)	# lsrc lang=en+de
    def test1017950(_): check(_,1017950)	# lsrc wasei
    def test1629230(_): check(_,1629230)	# lsrc 3 lsrc's
    def test1077760(_): check(_,1077760)	# lsrc lang w/o text
    def test1000520(_): check(_,1000520)	# sens.notes (en)
    def test1000940(_): check(_,1000940)	# sens.notes (en,jp)
    def test1002320(_): check(_,1002320)	# sens notes on mult senses
    def test1198180(_): check(_,1198180)	# sens.notes, long
    def test1079110(_): check(_,1079110)	# sens.notes, quotes
    def test1603990(_): check(_,1603990)	# gloss with starting with numeric char, stagr, stagk, restr
    def test1416050(_): check(_,1416050)	# stagr, stagk, nokanji
    def test1542640(_): check(_,1542640)	# stagr, stagk, restr
    def test1593470(_): check(_,1593470)	# gloss with aprostrophe, stagr, stagk, restr
    def test1316860(_): check(_,1316860)	# mult kinf
    def test1214540(_): check(_,1214540)	# mult kinf
    def test1582580(_): check(_,1582580)	# mult rinf
    def test1398850(_): check(_,1398850)	# mult fld
    def test1097870(_): check(_,1097870)	# mult fld, lsrc
    def test1517910(_): check(_,1517910)	# gloss in quotes
    def test1516925(_): check(_,1516925)	# gloss containg quotes and apostrophe
    def test1379360(_): check(_,1379360)	# gloss, initial paren
    def test1401950(_): check(_,1401950)	# gloss, trailing numeric and paren
    def test1414950(_): check(_,1414950)	# gloss, mult quotes
    def test1075210(_): check(_,1075210)	# gloss, initial digits
    #def test1000090(_): check(_,1000090)	# xref and ant with hard to classify kanji.
    def test1000920(_): check(_,1000920)	# xref w rdng (no kanj) and sense number.
    def test1000420(_): check(_,1000420)	# xref w K.R pair.
    def test1011770(_): check(_,1011770)	# ant with K.R.s triple.
    def test2234570(_): check(_,2234570)	# xref w K.s pair.
    def test1055420(_): check(_,1055420)	# dotted reb, wide ascii xref.
    def test1098650(_): check(_,1098650)	# dotted reb, kanji xref.
    def test1099200(_): check(_,1099200)	# mult rdng w dots, kanj xref.
    def test1140360(_): check(_,1140360)	# xref w kanj/katakana.
    def test1578780(_): check(_,1578780)	# dotted pair (K.R) in stagk.
    def test2038530(_): check(_,2038530)	# dotted keb w dotted restr.
    def test2107800(_): check(_,2107800)	# double-dotted reb.
    def test2159530(_): check(_,2159530)	# wide ascii kanj w dot and restr.
    def test1106120(_): check(_,1106120)	# embedded semicolon in gloss.
    def test1329750(_): check(_,1329750)	# literal gloss.

    #1000090 -- Fails due to xref not found because of K/R misclassification.

class RTpure (unittest.TestCase):
    # These tests use artificial test data intended to test single
    # parser features.

    def setUp (self): globalSetup()
    def test0100010(_): check(_,'0100010')  # Basic: 1 kanj, 1 rdng, 1 sens, 1 gloss
    def test0100020(_): check(_,'0100020')  # Basic: 1 kanj, 1 sens, 1 gloss
    def test0100030(_): check(_,'0100030')  # Basic: 1 rdng, 1 sens, 1 gloss
    def test0100040(_): check(_,'0100040')  # IS-163.
    # Following worked up to rev ccc8a44ad8fd-2009-03-12 but are now syntax errors
	# Like 0100010 but all text on one line.
    def test0100040(_): cherr(_,'0100040',jelparse.ParseError,"Syntax Error")
	# Like 0100020 but all text on one line.
    def test0100050(_): cherr(_,'0100050',jelparse.ParseError,"Syntax Error")
	# Like 0100030 but all text on one line.
    def test0100060(_): cherr(_,'0100060',jelparse.ParseError,"Syntax Error")
        # No rdng or kanj.

    def test0100070(_): check(_,'0100070')  # IS-163.
    def test0100080(_): check(_,'0100080')  # IS-163.
    def test0200010(_): cherr(_,'0200010', jelparse.ParseError,"Syntax Error") 
    def test0200020(_): cherr(_,'0200020', jelparse.ParseError,"Syntax Error") 

class Restr (unittest.TestCase):
    def setUp (_): 
	globalSetup() 
	_.data = loadData ('data/jelparse/restr.txt', r'# ([0-9]{7}[a-zA-Z0-9_]+)')

    def test0300010(_): check2(_,'0300010')
    # def test0300011(_): check2(_,'0300011')	Dotted pair w/o quotes fails. (Supposed to?)
    def test0300020(_): check2(_,'0300020')
    def test0300030(_): check2(_,'0300030')
    def test0300040(_): check2(_,'0300040')
    def test0300050(_): check2(_,'0300050')
    def test0300110(_): check2(_,'0300110')
    def test0300120(_): check2(_,'0300120')
    def test0300130(_): check2(_,'0300130')
    def test0300140(_): check2(_,'0300140')
    def test0300150(_): check2(_,'0300150')
    def test0300170(_): check2(_,'0300170')
    def test0300210(_): check2(_,'0300210')
    def test0300220(_): check2(_,'0300220')
    def test0300230(_): check2(_,'0300230')
    def test0300240(_): check2(_,'0300240')
    def test0300250(_): check2(_,'0300250')
    def test0300270(_): check2(_,'0300270')
    def test0300280(_): check2(_,'0300280')

class Xref (unittest.TestCase):
    def setUp (_): 
	globalSetup()
	_.data = loadData ('data/jelparse/xref.txt', r'# ([0-9]{7}[a-zA-Z0-9_]+)')

    def test0310010(_): check2(_,'0310010')
    def test0310020(_): check2(_,'0310020')
    def test0310030(_): check2(_,'0310030')
    def test0310040(_): check2(_,'0310040')
    def test0310050(_): check2(_,'0310050')
    def test0310060(_): check2(_,'0310060')
    def test0310070(_): check2(_,'0310070')
    def test0310080(_): check2(_,'0310080') 
    #def test0310090(_): check2(_,'0310090') 
    def test0310100(_): check2(_,'0310100') 
    def test0310210(_): check2(_,'0310210') 
    def test0310310(_): check2(_,'0310310') 
    def test0310320(_): check2(_,'0310320') 
    def test0310330(_): check2(_,'0310330') 

# 0310090 fails, xref senses in sorted order rather than order given.

class Ginf (unittest.TestCase):
    def setUp (_): 
	globalSetup()
	_.data = loadData ('data/jelparse/ginf.txt', r'# ([0-9]{7}[a-zA-Z0-9_]+)')

    def test0320010(_): check2(_,'0320010')
    def test0320020(_): check2(_,'0320020')
    def test0320030(_): check2(_,'0320030')
    def test0320040(_): check2(_,'0320040')
    def test0320050(_): check2(_,'0320050')
    def test0320060(_): check2(_,'0320060')
    def test0320310(_): check2(_,'0320310')
    def test0320320(_): check2(_,'0320320')
    def test0320330(_): check2(_,'0320330')

class Lsrc (unittest.TestCase):
    def setUp (_): 
	globalSetup()
	_.data = loadData ('data/jelparse/lsrc.txt', r'# ([0-9]{7}[a-zA-Z0-9_]+)')

    def test0330010(_): check2(_,'0330010')
    def test0330020(_): check2(_,'0330020')
    def test0330030(_): check2(_,'0330030')
    def test0330040(_): check2(_,'0330040')
    def test0330050(_): check2(_,'0330050')
    def test0330051(_): check2(_,'0330051')
    def test0330060(_): check2(_,'0330060')
    def test0330070(_): check2(_,'0330070')
    def test0330080(_): check2(_,'0330080')

def cherr (self, seq, exception, msg):
	global Cur, Lexer, Parser
	intxt = unittest_extensions.readfile_utf8 ("data/jelparse/%s.txt" % seq)
        jellex.lexreset (Lexer, intxt)
	_assertRaisesMsg (self, exception, msg, Parser.parse, intxt, lexer=Lexer)

def _assertRaisesMsg (self, exception, message, func, *args, **kwargs):
        expected = "Expected %s(%r)," % (exception.__name__, message)
        try:
            func(*args, **kwargs)
        except exception as e:
            if str(e) != message:
                msg = "%s got %s(%r)" % (
                    expected, exception.__name__, str(e))
                raise AssertionError(msg)
        except Exception as e:
            msg = "%s got %s(%r)" % (expected, e.__class__.__name__, str(e))
            raise AssertionError(msg)
        else:
            raise AssertionError("%s no exception was raised" % expected)

def check (self, seq, exp=None):
	global Cur, Lexer, Parser
	if exp is None: exp = seq
	intxt = unittest_extensions.readfile_utf8 ("data/jelparse/%s.txt" % seq)
	try:
	    exptxt = unittest_extensions.readfile_utf8 ("data/jelparse/%s.exp" % exp)
	except IOError:
	    exptxt = intxt
	outtxt = roundtrip (Cur, intxt)
	self.assert_ (8 <= len (outtxt))    # Sanity check for non-empty entry.
	msg = "\nExpected:\n%s\nGot:\n%s" % (exptxt, outtxt)
	self.assertEqual (outtxt, exptxt, msg)

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
