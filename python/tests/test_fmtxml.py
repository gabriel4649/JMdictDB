import sys, unittest, pdb
if '../lib' not in sys.path: sys.path.append ('../lib')
import jdb
from objects import *
import fmtxml

class Test_restr (unittest.TestCase):
    def test_001(_): 
	k1, k2, k3 = Kanj(txt='k1'), Kanj(txt='k2'), Kanj(txt='k3')
	kanjs = [k1, k2, k3]
	rdng = Rdng()
	xml = fmtxml.restrs (rdng, kanjs)
	_.assertEqual ([], xml)

    def test_002(_): 
	k1, k2, k3 = Kanj(txt='k1'), Kanj(txt='k2'), Kanj(txt='k3')
	kanjs = [k1, k2, k3]
	rdng = Rdng()
	rx1 = Restr(); rdng._restr.append (rx1);  k1._restr.append (rx1)
	rx3 = Restr(); rdng._restr.append (rx3);  k3._restr.append (rx3)
	xml = fmtxml.restrs (rdng, kanjs)
	_.assertEqual (['<re_restr>k2</re_restr>'], xml)

    def test_003(_): 
	k1, k2, k3 = Kanj(txt='k1'), Kanj(txt='k2'), Kanj(txt='k3')
	kanjs = [k1, k2, k3]
	rdng = Rdng()
	rx1 = Restr(); rdng._restr.append (rx1);  k2._restr.append (rx1)
	xml = fmtxml.restrs (rdng, kanjs)
	_.assertEqual (['<re_restr>k1</re_restr>','<re_restr>k3</re_restr>'], xml)

    def test_004(_): 
	k1, k2, k3 = Kanj(txt='k1'), Kanj(txt='k2'), Kanj(txt='k3')
	kanjs = [k1, k2, k3]
	rdng = Rdng()
	rx1 = Restr(); rdng._restr.append (rx1);  k1._restr.append (rx1)
	rx2 = Restr(); rdng._restr.append (rx2);  k2._restr.append (rx2)
	rx3 = Restr(); rdng._restr.append (rx3);  k3._restr.append (rx3)
	xml = fmtxml.restrs (rdng, kanjs)
	_.assertEqual (['<re_nokanji/>'], xml)


class Test_entr (unittest.TestCase):
    def setUp(_):
	jdb.KW = jdb.Kwds ('data/fmtxml/kw/')

    def test0200010 (_): 
	e = Entr(); _.dotest (e, '0200010')
    def test0201020 (_): 
	e = Entr(_grp=[Grp(kw=2,ord=1)]); _.dotest (e, '0201020')
    def test0201030 (_): 
	e = Entr(_grp=[Grp(kw=11,ord=5),Grp(kw=10,ord=2)]); _.dotest (e, '0201030')
    def test0201040 (_): 
	e = Entr(_grp=[Grp(kw=5,ord=1)]); _.dotest (e, '0201040', compat='jmdict')
    def test0201050 (_): 
	e = Entr(_grp=[Grp(kw=1)]); _.dotest (e, '0201050')

    def dotest(_, e, expected_file, **kwds):
	#pdb.set_trace()
	results = fmtxml.entr (e, **kwds)
	expected = open ('data/fmtxml/'+expected_file+'.txt').read()
	_.assertEqual (expected, results)

if __name__ == '__main__': unittest.main()





