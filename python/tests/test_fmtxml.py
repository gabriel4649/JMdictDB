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

if __name__ == '__main__': unittest.main()





