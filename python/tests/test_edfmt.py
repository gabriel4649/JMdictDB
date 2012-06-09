#!/usr/env python


import sys, re, unittest, pdb
import unittest_extensions
if '../lib' not in sys.path: sys.path.append ('../lib')
import jdb; from objects import *
import xslfmt

Test_xmlcmp_xmldata = Test_xmlcmp_edictdata = None

def global_setup():
        global Test_xmlcmp_xmldata, Test_xmlcmp_edictdata
        if Test_xmlcmp_xmldata is None:
            jdb.KW = jdb.Kwds (jdb.std_csv_dir())
            Test_xmlcmp_xmldata   = readxml   ('data/edfmt/testset.xml')
            Test_xmlcmp_edictdata = readedict ('data/edfmt/testset.txt')

class Test_xslfmt (unittest.TestCase):
    def setUp (_):
        global_setup()
        _.indata  = Test_xmlcmp_xmldata
        _.expdata = Test_xmlcmp_edictdata

    def test_b1 (_): dotest (_, 'b1')
    def test_b2 (_): dotest (_, 'b2')
    def test_b3 (_): dotest (_, 'b3')
    def test_b4 (_): dotest (_, 'b4')
    def test_b5 (_): dotest (_, 'b5')
    def test_b6 (_): dotest (_, 'b6')
    def test_b101 (_): dotest (_, 'b101')
    def test_b102 (_): dotest (_, 'b102')
    def test_b103 (_): dotest (_, 'b103')
    def test_b104 (_): dotest (_, 'b104')

    def test_r1 (_): dotest (_, 'r1')
    def test_r2 (_): dotest (_, 'r2')
    def test_r3 (_): dotest (_, 'r3')
    def test_r4 (_): dotest (_, 'r4')
    def test_r5 (_): dotest (_, 'r5')
    def test_r6 (_): dotest (_, 'r6')

    def test_kri1 (_): dotest (_, 'kri1')
    def test_kri2 (_): dotest (_, 'kri2')

    def test_fq1 (_): dotest (_, 'fq1')
    def test_fq11 (_): dotest (_, 'fq11')
    def test_fq12 (_): dotest (_, 'fq12')
    def test_fq13 (_): dotest (_, 'fq13')
    def test_fq14 (_): dotest (_, 'fq14')
    def test_fq15 (_): dotest (_, 'fq15')
    def test_fq16 (_): dotest (_, 'fq16')
    def test_fq21 (_): dotest (_, 'fq21')
    def test_fq22 (_): dotest (_, 'fq22')
    def test_fq23 (_): dotest (_, 'fq23')
    def test_fq24 (_): dotest (_, 'fq24')
    def test_fq25 (_): dotest (_, 'fq25')
    def test_fq26 (_): dotest (_, 'fq26')
    def test_fq31 (_): dotest (_, 'fq31')
    def test_fq32 (_): dotest (_, 'fq32')
    def test_fq33 (_): dotest (_, 'fq33')
    def test_fq34 (_): dotest (_, 'fq34')
    def test_fq41 (_): dotest (_, 'fq41')
    def test_fq42 (_): dotest (_, 'fq42')
    def test_fq43 (_): dotest (_, 'fq43')
    def test_fq44 (_): dotest (_, 'fq44')
    def test_fq45 (_): dotest (_, 'fq45')
    def test_fq46 (_): dotest (_, 'fq46')
    def test_fq47 (_): dotest (_, 'fq47')
    def test_fq48 (_): dotest (_, 'fq48')
    def test_fq49 (_): dotest (_, 'fq49')
    def test_fq50 (_): dotest (_, 'fq50')

    def test_s1 (_): dotest (_, 's1')
    def test_s2 (_): dotest (_, 's2')
    def test_s21 (_): dotest (_, 's21')

# To do: xrefs/ants, lsource, lit's, s_inf vs gloss with leading paren'd text,
#   mult fld, mult dial, stagr,stagk, failure mode tests.

def dotest (_, testnum):
        xml = _.indata[testnum]
        result = xslfmt.entr (xml, 'edict2.xsl')
        expected = _.expdata[testnum]
        if expected != result:
            msg = "\nExpected: '%s'\nGot:      '%s'" % (expected, result)
            _.failIf (1, msg)

def readedict (filename):
        data = {}
        f = open (filename, 'r', 'utf_8_sig ')
        for n, ln in enumerate (f):
            ln = ln.rstrip('\n\r')
            if ln.startswith ('#') or ln.lstrip() == '': continue
            name, edict = ln.split (': ', 1)
            if name in data:
                print ('Duplicate test name "%s", %s: %d' \
                                     % (name, filename, n+1), file=sys.stderr)
            else: data[name] = edict
        f.close()
        return data

def readxml (filename):
        data = {}
        f = open (filename, 'r', 'utf_8_sig ')
        for n, ln in enumerate (f):
            ln = ln.rstrip()
            if re.match (r'\s*(#.*)?$', ln): continue
            if ln.startswith ('@'):
                name = re.sub (r'\s*#.*', '', ln[1:])
                if name in data:
                    print ('Duplicate test name "%s", %s: %d' \
                                         % (name, filename, n+1), file=sys.stderr)
                    dup = True
                else:
                    data[name] = txt = []
                    dup = False
            else:
                if not dup: txt.append (ln)
        f.close()
        exp = {}
        for k, v in list(data.items()):
            exp[k] = '\n'.join (v)
        return exp

if __name__ == '__main__': unittest.main()
