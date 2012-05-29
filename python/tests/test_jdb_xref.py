# -*- coding: utf-8 -*-

from __future__ import print_function, absolute_import, division, unicode_literals
from future_builtins import ascii, filter, hex, map, oct, zip
import sys, unittest, pdb
if '../lib' not in sys.path: sys.path.append ('../lib')
from objects import *
import jdb

Cur = None

class Test_seq (unittest.TestCase):
    def test_001(_):
        xrefs = []
        cur = MockCursor (_, None)
        jdb.mark_seq_xrefs (cur, xrefs)

    def test_002(_):
        e1 = Entr(id=200,src=1,seq=12345,stat=2,unap=False)
        x1 = Xref(entr=100,sens=1,typ=2,xentr=200,xsens=2)
        x1.TARG = e1;  x1._xsens = [2]
        cur = MockCursor (_, [1,12345,2], [[e1.src,e1.seq,1]])
        jdb.mark_seq_xrefs (cur, [x1])
        _.assert_ (hasattr (x1, 'SEQ'))
        _.assertEqual (True, x1.SEQ)

    def test_003(_):
          # 2 xrefs -> 2 senses of same target.
        e1 = Entr(id=200,src=1,seq=12345,stat=2,unap=False)
        x1 = Xref(entr=100,sens=1,typ=2,xentr=200,xsens=2)
        x1.TARG = e1;  x1._xsens = [2,3]
        x2 = Xref(entr=100,sens=1,typ=2,xentr=200,xsens=3)
        x2.TARG = e1;  x2._xsens = []
        cur = MockCursor (_, [1,12345,2], [[1,12345,1]])
        jdb.mark_seq_xrefs (cur, [x1,x2])
        _.assert_ (hasattr (x1, 'SEQ'))
        _.assertEqual (True, x1.SEQ)
        _.assert_ (hasattr (x2, 'SEQ'))
        _.assertEqual (True, x2.SEQ)    #???

    def test_004(_):
          # 2 xrefs -> 2 different seq# targets.
        e1 = Entr(id=200,src=1,seq=12345,stat=2,unap=False)
        e2 = Entr(id=201,src=1,seq=87654,stat=2,unap=False)
        x1 = Xref(entr=100,sens=1,typ=2,xentr=200,xsens=2)
        x1.TARG = e1;  x1._xsens = [2]
        x2 = Xref(entr=100,sens=1,typ=2,xentr=201,xsens=3)
        x2.TARG = e2;  x2._xsens = [3]
        cur = MockCursor (_, [1,12345,87654,2], [[1,12345,1],[1,87654,1]])
        jdb.mark_seq_xrefs (cur, [x1,x2])
          # We expect both xrefs to be tagged with a true SEQ value
          # even though they are for the same target seq because the
          # .xsens is different.  If the first has a ._xsens list,
          # then the displaying app will likely skip the second.  If
          # it doesn't, then it should display in seq form
        _.assert_ (hasattr (x1, 'SEQ'))
        _.assertEqual (True, x1.SEQ)
        _.assert_ (hasattr (x2, 'SEQ'))
        _.assertEqual (True, x2.SEQ)

    def test_005(_):
          # 2 xrefs -> 2 different targets w same seq number.
        e1 = Entr(id=200,src=1,seq=12345,stat=2,unap=False)
        e2 = Entr(id=201,src=1,seq=12345,stat=2,unap=True)
        x1 = Xref(entr=100,sens=1,typ=2,xentr=200,xsens=2)
        x1.TARG = e1;  x1._xsens = [2]
        x2 = Xref(entr=100,sens=1,typ=2,xentr=201,xsens=2)
        x2.TARG = e2;  x2._xsens = [2]
        cur = MockCursor (_, [1,12345,2], [[1,12345,2]])
        jdb.mark_seq_xrefs (cur, [x1,x2])
          # Both xrefs of the single source entry point to target
          # entries of the same seq num, and all the entries if that
          # seq number are covered by the xrefs, so first xref gets
          # a .SEQ=True attribute, subsequent ones get SEQ=False.
        _.assert_ (hasattr (x1, 'SEQ'))
        _.assertEqual (True, x1.SEQ)
        _.assert_ (hasattr (x2, 'SEQ'))
        _.assertEqual (False, x2.SEQ)

    def test_006(_):
          # 2 xrefs with different .sens -> 2 different targets w same seq number.
        e1 = Entr(id=200,src=1,seq=12345,stat=2,unap=False)
        e2 = Entr(id=201,src=1,seq=12345,stat=2,unap=True)
        x1 = Xref(entr=100,sens=1,typ=2,xentr=200,xsens=2)
        x1.TARG = e1;  x1._xsens = [2]
        x2 = Xref(entr=100,sens=1,typ=2,xentr=201,xsens=3)
        x2.TARG = e2;  x2._xsens = [3]
        cur = MockCursor (_, [1,12345,2], [[1,12345,2]])
        jdb.mark_seq_xrefs (cur, [x1,x2])
          # Both xrefs of the single source entry point to target
          # entries of the same seq num, and all the entries of that
          # seq number are covered by the xrefs, but source .xsens are
          # different, so each xref gets a .SEQ=True attribute.
        _.assert_ (hasattr (x1, 'SEQ'))
        _.assertEqual (True, x1.SEQ)
        _.assert_ (hasattr (x2, 'SEQ'))
        _.assertEqual (True, x2.SEQ)

    def test_007(_):
          # Same as test_005 but each xref in a different source entry.
        e1 = Entr(id=200,src=1,seq=12345,stat=2,unap=False)
        e2 = Entr(id=201,src=1,seq=12345,stat=2,unap=True)
        x1 = Xref(entr=100,sens=1,typ=2,xentr=200,xsens=2)
        x1.TARG = e1;  x1._xsens = [2]
        x2 = Xref(entr=101,sens=1,typ=2,xentr=201,xsens=2)
        x2.TARG = e2;  x2._xsens = [2]
        cur = MockCursor (_, [1,12345,2], [[1,12345,2]])
        jdb.mark_seq_xrefs (cur, [x1,x2])
          # Expect no .SEQ attribute because there are two q=12345
          # entries, but each of the two source entry points to only
          # one of them, hence they cannot use a seq representation.
        _.assert_ (not hasattr (x1, 'SEQ'))
        _.assert_ (not hasattr (x2, 'SEQ'))

    def test_008(_):
          # 3 xrefs -> 3 different targets w same seq number, one
          # of which is a "rejected" entry.
        e1 = Entr(id=200,src=1,seq=12345,stat=2,unap=False)
        e2 = Entr(id=201,src=1,seq=12345,stat=3,unap=False)
        e3 = Entr(id=202,src=1,seq=12345,stat=2,unap=True)
        x1 = Xref(entr=100,sens=1,typ=2,xentr=200,xsens=2)
        x1.TARG = e1;  x1._xsens = [2]
        x2 = Xref(entr=100,sens=1,typ=2,xentr=201,xsens=2)
        x2.TARG = e2;  x2._xsens = [2]
        x3 = Xref(entr=100,sens=1,typ=2,xentr=202,xsens=2)
        x3.TARG = e3;  x2._xsens = [2]
        cur = MockCursor (_, [1,12345,2], [[1,12345,2]])
        jdb.mark_seq_xrefs (cur, [x1,x2,x3])
          # Both xrefs of the single source entry point to target
          # entries of the same seq num, and all the entries of that
          # seq number are covered by the xrefs, so first xref gets
          # a .SEQ=True attribute, subsequent ones get SEQ=False.
        _.assert_ (hasattr (x1, 'SEQ'))
        _.assertEqual (True, x1.SEQ)
        _.assert_ (not hasattr (x2, 'SEQ'))
        _.assert_ (hasattr (x3, 'SEQ'))
        _.assertEqual (False, x3.SEQ)


class MockCursor:
    def __init__ (self, test, args=None, returns=None):
          # test -- TestCase object (used for access to its asset* methods.
          # args -- Arguments that are subsituted into a SQL statement that
          #    this MockCursor instance will expect to be called with, and
          #    which will result it a test fail if actual arguments are
          #    different.
          # returns -- Data that the database would have returned.
        self.test = test; self.args = args; self.returns = returns
        try: jdb.KW
        except AttributeError: jdb.KW = jdb.Kwds (jdb.std_csv_dir())
    def execute (self, sql, args=[]):
          # If self.args is None, this method should never be called.
        self.test.assert_ (self.args is not None)
        expect_sql = "SELECT src,seq,COUNT(*) FROM entr " \
                        "WHERE src=%%s AND seq IN(%s) AND stat=%%s GROUP BY src,seq" \
                        % ",".join(["%s"]*(len(args)-2))
        self.test.assertEqual (expect_sql, sql)
        self.test.assertEqual (self.args, args)
    def fetchall (self):
          # If self.args is None, this method should never be called.
        self.test.assert_ (self.args is not None)
        return self.returns

if __name__ == '__main__': unittest.main()
