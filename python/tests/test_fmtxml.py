from __future__ import print_function, absolute_import, division, unicode_literals
from future_builtins import ascii, filter, hex, map, oct, zip
import sys, unittest, codecs, pdb
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
        fmtxml.XKW = None

    def test0200010 (_):
        e = Entr(); dotest (_, e, '0200010')
    def test0201020 (_):
        e = Entr(_grp=[Grp(kw=2,ord=1)]); dotest (_, e, '0201020')
    def test0201030 (_):
        e = Entr(_grp=[Grp(kw=11,ord=5),Grp(kw=10,ord=2)]); dotest (_, e, '0201030')
    def test0201040 (_):
        e = Entr(_grp=[Grp(kw=5,ord=1)]); dotest (_, e, '0201040', compat='jmdict')
    def test0201050 (_):
        e = Entr(_grp=[Grp(kw=1)]); dotest (_, e, '0201050')

class Test_xrslv (unittest.TestCase):
    def setUp (_):
        jdb.KW = jdb.Kwds ('data/fmtxml/kw/')
        fmtxml.XKW = None

    def test0202010(_):
        e = Entr (src=99, _sens=[Sens (_xrslv=[Xrslv(typ=3, ktxt=u'\u540c\u3058')])])
        dotest (_, e, '0202010', compat='jmdict')
    def test0202020(_):
        e = Entr (src=99, _sens=[Sens (_xrslv=[Xrslv(typ=2, ktxt=u'\u540c\u3058')])])
        dotest (_, e, '0202020', compat='jmdict')
    def test0202030(_):
        e = Entr (src=99, _sens=[Sens (_xrslv=[Xrslv(typ=3, rtxt=u'\u304a\u306a\u3058')])])
        dotest (_, e, '0202030', compat='jmdict')
    def test0202040(_):
        e = Entr (src=99, _sens=[Sens (_xrslv=[Xrslv(typ=3, ktxt=u'\u540c\u3058',
                                                rtxt=u'\u304a\u306a\u3058')])])
        dotest (_, e, '0202040', compat='jmdict')
    def test0202050(_):
        e = Entr (src=99, _sens=[Sens (_xrslv=[Xrslv(typ=3, ktxt=u'\u540c\u3058',
                                                rtxt=u'\u304a\u306a\u3058', tsens=3)])])
        dotest (_, e, '0202050', compat='jmdict')


u'\u304a\u306a\u3058'
def dotest(_, e, expected_file, **kwds):
        results = fmtxml.entr (e, **kwds)
        expected = codecs.open ('data/fmtxml/'+expected_file+'.txt', 'r', 'utf_8_sig').read()
        expected = expected.replace ('\r', '')  # In case we're running on windows.
        expected = expected.rstrip ('\n')       # fmtxml results have no trailing "\n".
        if results != expected:
            msg = "\nExpected (len=%d):\n%s\nGot (len=%d):\n%s" \
                   % (len(expected), expected, len(results), results)
            _.failIf (1, msg)

if __name__ == '__main__': unittest.main()
