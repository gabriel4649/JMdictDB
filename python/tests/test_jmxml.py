# -*- coding: utf-8 -*-

import sys, unittest, pdb
if '../lib' not in sys.path: sys.path.append ('../lib')
import jdb
from objects import *

# Module to test...
import jmxml

__unittest = 1
KW = None

class Test_parsexml (unittest.TestCase):
    def setUp (_):
        global KW
        if not KW:
            jdb.KW = KW = jdb.Kwds (jdb.std_csv_dir())
          # Use mode='b' in getxml call because we need undecoded
          # utf-8 for Jmparser.parse_entry() (which gives it to
          # ElementTree which needs utf-8.)
        _.getxml = lambda testid: getxml ('data/jmxml/parse_entry.xml', testid, 'b')
        _.jmparser = jmxml.Jmparser (KW)

    def dotest (_, testid):
        xml, exp = _.getxml (testid)
        entrs = _.jmparser.parse_entry (xml)
        exec ("expect=" + exp)      
        _.assertEqual (entrs, expect)
        return entrs, expect

    def test_000010(_): _.dotest ('000010')
    def test_000020(_): _.dotest ('000020')
    def test_000030(_): _.dotest ('000030')
    def test_000040(_): _.dotest ('000040')
    def test_000050(_): _.dotest ('000050')
    def test_000060(_): _.dotest ('000060')  # rinf
    def test_000070(_): _.dotest ('000070')  # kinf
    def test_000080(_):                      # restr
        en, ex = _.dotest ('000080')
        _.assertIs (en[0]._rdng[0]._restr[0], 
                    en[0]._kanj[1]._restr[0])

    # To do: restr combos, freq, pos, misc, fld, dial, lsrc, stagr, 
    #   stagk, xrslv, gloss (lang, ginf), hist, grp
    #   jmnedict: name_type and others
    #   kanjdic: cinf, chr, krslv
    #   jmdict-ex stuff.

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

def getxml (fname, testid, mode=''):
        # Read and return test data from a file.  The file may contain
        # multiple sets of test data and contents should be utf-8.
        # encoded.  Each set of test data starts with a line like,
        # "## xxxxx" where "xxxxx" is an arbitrary testid string.
        # Following that are lines containing XML for an entry.
        # The XML is followed by a line starting with "##--", and that
        # is followed by Python code to created an Entr object equal to
        # what is expected from parsing the XML.  The python code must
        # start with "expect =" since it will be exex'd and the test code 
        # will look for a variable named "expect".  The Python code may
        # be followed by another test data section of the end of the file.
        # Throughout out the test data file, blank lines and lines
        # starting with a hash and a space, "# ", (comment line) are
        # ignored.  
        # This function returns a two-tuple of test data (xml and opython
        # code) for the test data identified by 'testid'.  The first item
        # is either a bytes object with the undecoded XML text if mode was
        # 'b', or decoded XML text string is mode was not 'b'.  The second
        # item is always a decoded text string containing the Python code
        # part of the test data set.
        # If the requested test data set is not found, an Error is raised. 

        with open (fname, 'r'+mode) as f:
            state = '';  xml = [];  exp = []
            for lnnum, raw in enumerate (f):
                  # In Py2 'raw' is undecoded utf-8.  We need to decode 
                  # it (in principle) to detect the testid lines.  If 
                  # mode is 'b', we'll collect and return utf-8 lines.
                  # Otherwise, collect and return decoded unicode lines.   
                ln = raw.decode ('utf-8').strip()
                if mode != 'b': raw = ln
                if not ln: continue                  # Skip blank lines.
                if (len(ln)==1 and ln.startswith ("#")) or ln.startswith ("# "):
                    continue                         # Skip comment lines.
                #print ("%d %s: %s" % (lnnum, state, ln))
                if ln == "## %s" % testid:           # Start of our test section.
                    state = "copying1"; continue
                if ln.startswith ("## "):            # Start of next section.
                    if state.startswith('copying'): break
                if ln.startswith ("##--"):           # Start of exec section.
                    if state == "copying1": 
                        state = "copying2"; continue
                if state == "copying1":
                    xml.append (raw)
                if state == "copying2":
                    exp.append (ln)
            if not xml: raise RuntimeError ('Test section "%s" not found in %s'
                                            % (testid, fname))
            expstr = '\n'.join (exp) + '\n'
            if mode == 'b': 
                return b''.join (xml), expstr
            return ('\n'.join (xml) + '\n'), expstr

if __name__ == '__main__': unittest.main()





