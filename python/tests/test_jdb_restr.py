# -*- coding: utf-8 -*-
import sys, unittest, pdb
if '../lib' not in sys.path: sys.path.append ('../lib')
from objects import *
import jdb
import fmtxml

class Test_restr2ext (unittest.TestCase):
    def test_001(_):
	  # An empty restr list should produce an empty result.
	k1, k2, k3 = Kanj(txt='k1'), Kanj(txt='k2'), Kanj(txt='k3')
	restrs = []
	result = jdb.restrs2ext_ (restrs, [k1,k2,k3], '_restr')
	_.assertEqual ([], result)

    def test_002(_):
	  # Restr on k2 results in list of remainder (k1, k3).
	k1, k2, k3 = Kanj(txt='k1'), Kanj(txt='k2'), Kanj(txt='k3')
	x1 = Restr()
	restrs = [x1]; k2._restr = [x1]
	result = jdb.restrs2ext_ (restrs, [k1,k2,k3], '_restr')
	_.assertEqual ([k1,k3], result)

    def test_003(_):
	  # Restr on k1,k2 results in list of remainder (k2).
	k1, k2, k3 = Kanj(txt='k1'), Kanj(txt='k2'), Kanj(txt='k3')
	x1, x3 = Restr(), Restr()
	restrs = [x1,x3]; k1._restr = [x1]; k3._restr = [x3]
	result = jdb.restrs2ext_ (restrs, [k1,k2,k3], '_restr')
	_.assertEqual ([k2], result)

    def test_004(_):
	  # All kanji restricted results in None ("nokanji" sentinal).
	k1, k2, k3 = Kanj(txt='k1'), Kanj(txt='k2'), Kanj(txt='k3')
	x1, x2, x3 = Restr(), Restr(), Restr()
	restrs = [x1,x2,x3]; k1._restr = [x1]; k2._restr = [x2]; k3._restr = [x3];
	result = jdb.restrs2ext_ (restrs, [k1,k2,k3], '_restr')
	_.assertEqual (None, result)

    def test_012(_):
	  # stagk restr on k2 results in list of remainder (k1, k3).
	k1, k2, k3 = Kanj(txt='k1'), Kanj(txt='k2'), Kanj(txt='k3')
	x1 = Restr()
	restrs = [x1]; k2._stagk = [x1]
	result = jdb.restrs2ext_ (restrs, [k1,k2,k3], '_stagk')
	_.assertEqual ([k1,k3], result)

    def test_022(_):
	  # stagr restr on r2 results in list of remainder (r1, r3).
	r1, r2, r3 = Rdng(txt='r1'), Rdng(txt='r2'), Rdng(txt='r3')
	x1 = Restr()
	restrs = [x1]; r2._stagr = [x1]
	result = jdb.restrs2ext_ (restrs, [r1,r2,r3], '_stagr')
	_.assertEqual ([r1,r3], result)


class Text_txt2restr (unittest.TestCase):
    def setUp (_):
	_.e = Entr (
		_rdng=[Rdng(txt='あ'),Rdng(txt='い')],
		_kanj=[Kanj(txt='亜'),Kanj(txt='居'),Kanj(txt='迂')],
		_sens=[Sens(_gloss=[Gloss(txt='A')]),Sens(_gloss=[Gloss(txt="B")])])
    def test001 (_):
	rtxts = []
	retval = jdb.txt2restr (rtxts, _.e._rdng[0], _.e._kanj, '_restr')
	for r in _.e._rdng: _.assertEqual ([], r._restr)
	for k in _.e._kanj: _.assertEqual ([], k._restr)
	_.assertEqual ([], retval) 
    def test002 (_):
	rtxts = []
	retval = jdb.txt2restr (rtxts, _.e._rdng[1], _.e._kanj, '_restr')
	for r in _.e._rdng: _.assertEqual ([], r._restr)
	for k in _.e._kanj: _.assertEqual ([], k._restr)
	_.assertEqual ([], retval) 
    def test011 (_):
	rtxts = ['亜']
	retval = jdb.txt2restr (rtxts, _.e._rdng[0], _.e._kanj, '_restr')
	for expect, r in zip ([2,0],   _.e._rdng): _.assertEqual (expect, len(r._restr))
	for expect, k in zip ([0,1,1], _.e._kanj): _.assertEqual (expect, len(k._restr))
	for r in _.e._rdng:
	    for x in r._restr: _.assert_ (isinstance (x, Restr))
	_.assertEqual (_.e._rdng[0]._restr[0], _.e._kanj[1]._restr[0])
	_.assertEqual (_.e._rdng[0]._restr[1], _.e._kanj[2]._restr[0])
	_.assertEqual ([2,3], retval) 
    def test012 (_):
	rtxts = None	# Equiv to "nokanji".
	retval = jdb.txt2restr (rtxts, _.e._rdng[0], _.e._kanj, '_restr')
	for expect, r in zip ([3,0],   _.e._rdng): _.assertEqual (expect, len(r._restr))
	for expect, k in zip ([1,1,1], _.e._kanj): _.assertEqual (expect, len(k._restr))
	for r in _.e._rdng:
	    for x in r._restr: _.assert_ (isinstance (x, Restr))
	_.assertEqual (_.e._rdng[0]._restr[0], _.e._kanj[0]._restr[0])
	_.assertEqual (_.e._rdng[0]._restr[1], _.e._kanj[1]._restr[0])
	_.assertEqual (_.e._rdng[0]._restr[2], _.e._kanj[2]._restr[0])
	_.assertEqual ([1,2,3], retval) 
    def test013 (_):
	rtxts = ['亜']
	retval = jdb.txt2restr (rtxts, _.e._sens[0], _.e._kanj, '_stagk')
	for expect, s in zip ([2,0],   _.e._sens): _.assertEqual (expect, len(s._stagk))
	for expect, k in zip ([0,1,1], _.e._kanj): _.assertEqual (expect, len(k._stagk))
	for s in _.e._sens:
	    for x in s._stagk: _.assert_ (isinstance (x, Stagk))
	_.assertEqual (_.e._sens[0]._stagk[0], _.e._kanj[1]._stagk[0])
	_.assertEqual (_.e._sens[0]._stagk[1], _.e._kanj[2]._stagk[0])
	_.assertEqual ([2,3], retval) 
    def test014 (_):
	rtxts = ['あ']
	retval = jdb.txt2restr (rtxts, _.e._sens[0], _.e._rdng, '_stagr')
	for expect, s in zip ([1,0], _.e._sens): _.assertEqual (expect, len(s._stagr))
	for expect, r in zip ([0,1], _.e._rdng): _.assertEqual (expect, len(r._stagr))
	for s in _.e._sens:
	    for x in s._stagr: _.assert_ (isinstance (x, Stagr))
	_.assertEqual (_.e._sens[0]._stagr[0], _.e._rdng[1]._stagr[0])
	_.assertEqual ([2], retval) 

if __name__ == '__main__': unittest.main()
