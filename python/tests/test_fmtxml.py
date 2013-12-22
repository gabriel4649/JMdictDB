
import sys, unittest, pdb
if '../lib' not in sys.path: sys.path.append ('../lib')
import jdb, copy
from objects import *
import fmtxml

sys.path.append ("./data/fmtxml")
import fmtxml_data as f

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

# The following tests use data from data/fmtxml_data.py imported (as 'f'
# for brevity) above.  Module f contains two dicts., 'f.inp' and 'f.exp',
# both keyed by the test id number (as a string).  The values in f.inp
# are python code strings that will be exed'd by dotest() to produce a
# jdb.Entr object for feeding to the module-under-test, fmtxml.  The
# values in f.exp are strings with the coresponding XML that the fmtxml
# is expected to produce.

class Test_entr (unittest.TestCase):
    def setUp(_):
        jdb.KW = jdb.Kwds ('data/fmtxml/kw/')
        fmtxml.XKW = None

    def test0200010 (_): dotest (_, f.t_in['0200010'], f.t_exp['0200010'])
    def test0201020 (_): dotest (_, f.t_in['0201020'], f.t_exp['0201020'])
    def test0201030 (_): dotest (_, f.t_in['0201030'], f.t_exp['0201030'])
    def test0201040 (_): dotest (_, f.t_in['0201040'], f.t_exp['0201040'], compat='jmdict')
    def test0201050 (_): dotest (_, f.t_in['0201050'], f.t_exp['0201050'])

class Test_xrslv (unittest.TestCase):
    def setUp (_):
        jdb.KW = jdb.Kwds ('data/fmtxml/kw/')
        fmtxml.XKW = None

    def test0202010(_): dotest (_, f.t_in['0202010'], f.t_exp['0202010'], compat='jmdict')
    def test0202020(_): dotest (_, f.t_in['0202020'], f.t_exp['0202020'], compat='jmdict')
    def test0202030(_): dotest (_, f.t_in['0202030'], f.t_exp['0202030'], compat='jmdict')
    def test0202040(_): dotest (_, f.t_in['0202040'], f.t_exp['0202040'], compat='jmdict')
    def test0202050(_): dotest (_, f.t_in['0202050'], f.t_exp['0202050'], compat='jmdict')

class Test_jmnedict (unittest.TestCase):
    def setUp(_):
        jdb.KW = jdb.Kwds ('data/fmtxml/kw/')
        fmtxml.XKW = None
    def test0300010(_): dotest (_, f.t_in['0300010'], f.t_exp['0300010'], compat='jmnedict')
    def test0300020(_): dotest (_, f.t_in['0300020'], f.t_exp['0300020'], compat='jmnedict')
    def test0300030(_): dotest (_, f.t_in['0300030'], f.t_exp['0300030'], compat='jmnedict')
    def test0300040(_): dotest (_, f.t_in['0300040'], f.t_exp['0300040'], compat='jmnedict')
    def test0300050(_): dotest (_, f.t_in['0300050'], f.t_exp['0300050'], compat='jmnedict')

    def test0305001(_):  # IS-221
        dotest (_, f.t_in['0305001'], f.t_exp['0305001'], compat='jmnedict')

def dotest (_, execstr, expected, **kwds):
        lcls = {}
        exec (execstr, globals(), lcls)
        xml = fmtxml.entr (lcls['e'], **kwds)
        if xml != expected:
            msg = "\nExpected (len=%d):\n%s\nGot (len=%d):\n%s" \
                   % (len(expected), expected, len(xml), xml)
            _.failIf (1, msg)

# Tests for fmtxml.entr_diff(), see IS-227.
# Like class Test_entr above, we use data from data/fmtxml_data.py imported 
# (as 'f' for brevity) earlier.  See Test_entr above for more details.

class Test_entr_diff (unittest.TestCase):
    def setUp(_):
        jdb.KW = jdb.Kwds ('data/fmtxml/kw/')
        fmtxml.XKW = None
    def test_0001(_):
        lcls = {}
        exec (f.t_in['0400010'], globals(), lcls)
        e1, e2 = lcls['e1'], lcls['e2']
        s = fmtxml.entr_diff (e1, e2, n=0)
        _.assertEqual (s, f.t_exp['0400010']) 
    def test_0002(_):
        lcls = {}
        exec (f.t_in['0400020'], globals(), lcls)
        e1, e2 = lcls['e1'], lcls['e2']
        s = fmtxml.entr_diff (e1, e2, n=0)
        _.assertEqual (s, f.t_exp['0400020']) 

if __name__ == '__main__': unittest.main()
