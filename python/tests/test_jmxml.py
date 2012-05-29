from __future__ import print_function, absolute_import, division, unicode_literals
from future_builtins import ascii, filter, hex, map, oct, zip
import sys, unittest, pdb
if '../lib' not in sys.path: sys.path.append ('../lib')
import jmxml

__unittest = 1

class Test_extract_lit (unittest.TestCase):
        # The "(trans:...)" test strings below are a hold over from
        # earier JMdicts and previous version of extract_lit() that
        # would extract "trans:" strings to put them in lsource objects.
        # Current JMdict format has made this change in the xml so
        # extract_lit() no longer needs to or does do it.

    D = [None,                                  # There is no testdata at index 0.
        ["",                                    ('',[])],                               #1
        ["aaaa bbb",                            ('aaaa bbb', [])],                      #2
        ["(lit: xx yyyy)",                      ('', ['xx yyyy'])],                     #3
        ["(trans: xyz zz)",                     ('(trans: xyz zz)', [])],               #4
        ["abcd (lit: xyz)",                     ('abcd', ['xyz'])],                     #5
        ["(lit: qq rrr) efgh",                  ('efgh', ['qq rrr'])],                  #6
        ["dcba (trans: rr ssss)",               ('dcba (trans: rr ssss)', [])],         #7
        ["(trans: zzz xxx) abcd",               ('(trans: zzz xxx) abcd', [])],         #8
        ["aaaa (lit: kxst) mmm",                ('aaaa mmm', ['kxst'])],                #9
        ["bbbb (trans: wwww) nnn",              ('bbbb (trans: wwww) nnn', [])],        #10
        ["cccc (lit: xyz) qrs (lit: zzz) ooo",  ('cccc qrs ooo', ['xyz','zzz'])],       #11
        ["dddd (lit: yyy) qrs (trans: zzz) ppp", ('dddd qrs (trans: zzz) ppp', ['yyy'])],#12
        ["eeee (lit: www)(trans: zzz) qqq",     ('eeee (trans: zzz) qqq', ['www'])],    #13
        ["ffff (lit: xy (qqq) z)",              ('ffff', ['xy (qqq) z'])],              #14
        ["gggg (lit: xy (qqq z)",               ('gggg (lit: xy (qqq z)', [])],         #15
        ["lit: xy qqq",                         ('', ['xy qqq'])],                      #16
        ["trans: wz pppp",                      ('trans: wz pppp', [])],                #17
        ["abcd (lit: xy (q)q(q))(z)",           ('abcd (z)', ['xy (q)q(q)'])],          #18
        ["foam rubber (trans: Eversoft (tm))",  ('foam rubber (trans: Eversoft (tm))', [])], #19
        ]

    def test001 (_): _.dotest (1)
    def test002 (_): _.dotest (2)
    def test003 (_): _.dotest (3)
    def test004 (_): _.dotest (4)
    def test005 (_): _.dotest (5)
    def test006 (_): _.dotest (6)
    def test007 (_): _.dotest (7)
    def test008 (_): _.dotest (8)
    def test009 (_): _.dotest (9)
    def test010 (_): _.dotest (10)
    def test011 (_): _.dotest (11)
    def test012 (_): _.dotest (12)
    def test013 (_): _.dotest (13)
    def test014 (_): _.dotest (14)
    def test015 (_): _.dotest (15)
    def test016 (_): _.dotest (16)
    def test017 (_): _.dotest (17)
    def test018 (_): _.dotest (18)
    def test019 (_): _.dotest (19)

    def dotest (_, n): _.assertEqual (_.D[n][1], jmxml.extract_lit (_.D[n][0]))

if __name__ == '__main__': unittest.main()





