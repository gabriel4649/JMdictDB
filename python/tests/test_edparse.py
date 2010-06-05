#!/usr/env python

import sys, re, unittest, codecs, pdb
import unittest_extensions
if '../lib' not in sys.path: sys.path.append ('../lib')
import jdb, fmtxml
from objects import *
import edparse

Loaded = Test_indata = Test_expdata = None

def global_setup (loadname):
	global Loaded, Test_indata, Test_expdata
	if Loaded != loadname:
	    jdb.KW = jdb.Kwds (jdb.std_csv_dir())
	    Test_indata  = readedict ('data/edparse/%s.txt' % loadname)
	    Test_expdata = readxml   ('data/edparse/%s.xml' % loadname)
	    Loaded = loadname
	return

class Test_xmlcmp (unittest.TestCase):
    def setUp (_):
	global_setup ('xmlcmp')
	_.indata, _.expdata = Test_indata, Test_expdata

    def test_b1 (_): dotest (_, 'b1')
    def test_b2 (_): dotest (_, 'b2')
    def test_b3 (_): dotest (_, 'b3')
    def test_b4 (_): dotest (_, 'b4')
    def test_b5 (_): dotest (_, 'b5')
    def test_b6 (_): dotest (_, 'b6')
    def test_b7 (_): dotest (_, 'b7')
    def test_b8 (_): dotest (_, 'b8')
    def test_b9 (_): dotest (_, 'b9')
    def test_b10 (_): dotest (_, 'b10')
    def test_b11 (_): dotest (_, 'b11')
    def test_b12 (_): dotest (_, 'b12')
    def test_b13 (_): dotest (_, 'b13')
    def test_b14 (_): dotest (_, 'b14')

    def test_x1 (_): dotest (_, 'x1')
    def test_x2 (_): dotest (_, 'x2')
    def test_x3 (_): dotest (_, 'x3')
    def test_x4 (_): dotest (_, 'x4')
    def test_x5 (_): dotest (_, 'x5')
    def test_x6 (_): dotest (_, 'x6')
    def test_x7 (_): dotest (_, 'x7')
    def test_x8 (_): dotest (_, 'x8')
    def test_x9 (_): dotest (_, 'x9')

class Test_canonical (unittest.TestCase):
    def setUp (_):
	global_setup ('canon')
	_.indata, _.expdata = Test_indata, Test_expdata

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
    def test_b201 (_): dotest (_, 'b201', 'b200')
    def test_b202 (_): dotest (_, 'b202', 'b200')
    def test_b203 (_): dotest (_, 'b203', 'b200')
    def test_b204 (_): dotest (_, 'b204', 'b200')

    def test_r1 (_): dotest (_, 'r1')
    def test_r2 (_): dotest (_, 'r2')
    def test_r3 (_): dotest (_, 'r3')
    def test_r4 (_): dotest (_, 'r4')
    def test_r5 (_): dotest (_, 'r5')
    def test_r6 (_): dotest (_, 'r6')

    def test_kri1 (_): dotest (_, 'kri1')
    def test_kri2 (_): dotest (_, 'kri2')

    def test_fq11 (_): dotest (_, 'fq11')
    def test_fq12 (_): dotest (_, 'fq12')
    def test_fq13 (_): dotest (_, 'fq13')
    def test_fq14 (_): dotest (_, 'fq14')
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

class Test_misc (unittest.TestCase):
    # These are tests from an earlier unfinished attempt at
    # an edict2 parser.
    def setUp (_):
	global_setup ('misc')
	_.indata, _.expdata = Test_indata, Test_expdata

    def test_q1000230 (_): dotest (_, 'q1000230')
    def test_q1000540 (_): dotest (_, 'q1000540')
    def test_q1043140 (_): dotest (_, 'q1043140')
    def test_q1172510 (_): dotest (_, 'q1172510')
    def test_q1217980 (_): dotest (_, 'q1217980')
    def test_q1244760 (_): dotest (_, 'q1244760')
    def test_q1270440 (_): dotest (_, 'q1270440')
    def test_q1310500 (_): dotest (_, 'q1310500')
    def test_q1664910 (_): dotest (_, 'q1664910')
    def test_q1956130 (_): dotest (_, 'q1956130')
    def test_q1985450 (_): dotest (_, 'q1985450')
    def test_q2007200 (_): dotest (_, 'q2007200')
    def test_q2087350 (_): dotest (_, 'q2087350')
    def test_q2157980 (_): dotest (_, 'q2157980')

def dotest (_, testnum, expnum=None):
	global Test_xmlcmp_indata, Test_xmlcmp_expdata
	e = edparse.entr (_.indata[testnum])
	xml = fmtxml.entr (e, compat="jmdict")
	expected = _.expdata[expnum or testnum]
	diff = fmtxml.entr_diff (expected, xml)
	if diff:
	    #msg = "\nExpected: '%s'\nDiff: '%s'" % (expected, diff)
	    msg = "\nDiff: '%s'" % (diff)
	    _.failIf (1, msg)

def readedict (filename):
	# Read edict test data lines into a dixt, keyed by test name.
	data = {}
	f = codecs.open (filename, 'r', 'utf_8_sig ')
	for n, ln in enumerate (f):
	    ln = ln.rstrip('\n\r')
	    if re.match (r'\s*(#.*)?$', ln): continue
	    name, edict = ln.split (': ', 1)
	    if name in data:
		print >>sys.stderr, 'Duplicate test name "%s" in %s (line %d)' \
				     % (name, filename, n+1)
	    else: data[name] = edict
	f.close()
	return data

def readxml (filename):
	# Read xml test data sets into a dict, keyed by test name.
	data = {}
	f = codecs.open (filename, 'r', 'utf_8_sig ')
	for n, ln in enumerate (f):
	    ln = ln.rstrip()
	    if re.match (r'\s*(#.*)?$', ln): continue
	    if ln.startswith ('@'):
		name = re.sub (r'\s*#.*', '', ln[1:])
		name = name.strip(':')
		if name in data:
		    print >>sys.stderr, 'Duplicate test name "%s" in %s (line: %d)' \
				         % (name, filename, n+1)
		    dup = True
		else: 
		    data[name] = txt = []
		    dup = False
	    else:
		if not dup: txt.append (ln)
	f.close()
	exp = {}
	for k, v in data.items():
	    exp[k] = '\n'.join (v)
	return exp

if __name__ == '__main__': unittest.main()



