# -*- coding: utf-8 -*-


import sys, re, unittest, pdb
try: import json
except ImportError: import simplejson as json
if '../lib' not in sys.path: sys.path.append ('../lib')
import jdb, fmtxml
from objects import *
import serialize

Cursor = None
def globalSetup ():
        global Cursor
        try:    # Get login credentials from dbauth.py if possible.
            import dbauth; kwargs = dbauth.auth
        except ImportError: kwargs = {}
          # FIXME: don't hardwire dbname.
        Cursor = jdb.dbOpen ('jmdict', **kwargs)

class Test_obj2struc (unittest.TestCase):

      # Scalars...
    def test0001(_): _.assert_ (isEqual (serialize.obj2struc(None), None))
    def test0002(_): _.assert_ (isEqual (serialize.obj2struc(1), 1))
    def test0003(_): _.assert_ (isEqual (serialize.obj2struc(2000000000000), 2000000000000))
    def test0004(_): _.assert_ (isEqual (serialize.obj2struc('abc'), 'abc'))
    def test0005(_): _.assert_ (isEqual (serialize.obj2struc('abc'), 'abc'))
    def test0006(_): _.assert_ (isEqual (serialize.obj2struc('\u304a\u5143\u6c17\u3067'), '\u304a\u5143\u6c17\u3067'))
    def test0007(_): _.assert_ (isEqual (serialize.obj2struc(1.1428), 1.1428))
    def test0008(_): _.assert_ (isEqual (serialize.obj2struc(True), True))
    def test0009(_): _.assert_ (isEqual (serialize.obj2struc(False), False))

      # lists, tuples
    def test0101(_): _.assert_ (isEqual (serialize.obj2struc([]),         ['list',[]]))
    def test0102(_): _.assert_ (isEqual (serialize.obj2struc([3]),        ['list',[3]]))
    def test0103(_): _.assert_ (isEqual (serialize.obj2struc(['abc', 7]), ['list',['abc',7]]))
    def test0104(_): _.assert_ (isEqual (serialize.obj2struc(()),         ['list',[]]))
    def test0105(_): _.assert_ (isEqual (serialize.obj2struc((3,)),       ['list',(3.)]))
    def test0106(_): _.assert_ (isEqual (serialize.obj2struc(('abc', 7)), ['list',('abc',7)]))

      # TBS... objects, hashes?...

class Test_struc2obj (unittest.TestCase):

      # Scalars...
    def test0001(_): _.assert_ (isEqual (serialize.struc2obj(None), None))
    def test0002(_): _.assert_ (isEqual (serialize.struc2obj(1), 1))
    def test0003(_): _.assert_ (isEqual (serialize.struc2obj(2000000000000), 2000000000000))
    def test0004(_): _.assert_ (isEqual (serialize.struc2obj('abc'), 'abc'))
    def test0005(_): _.assert_ (isEqual (serialize.struc2obj('abc'), 'abc'))
    def test0006(_): _.assert_ (isEqual (serialize.struc2obj('\u304a\u5143\u6c17\u3067'), '\u304a\u5143\u6c17\u3067'))
    def test0007(_): _.assert_ (isEqual (serialize.struc2obj(1.1428), 1.1428))
    def test0008(_): _.assert_ (isEqual (serialize.struc2obj(True), True))
    def test0009(_): _.assert_ (isEqual (serialize.struc2obj(False), False))

      # TBS... lists, tuples, hashes?...

class Test_obj2struc (unittest.TestCase):

    def test01(_): _.assert_ (isEqual (serialize.obj2struc(None), None))

class Test_multirefs (unittest.TestCase):
      # Test that multiple references to a single object aren't
      # lost when serializing/deserializing.

    def test001(_):
        a = [3, 4, 5]
        b = jdb.Obj (x=a, y=a)
        b2 = serialize.unserialize (serialize.serialize (b))
        _.assertEqual (a, b2.x)
        _.assertEqual (b2.x, b2.y)
        _.assertEqual (id(b2.x), id(b2.y))

    def test002(_):
        a1 = [3, 4, 5]
        a2 = [3, 4, 5]
        b = jdb.Obj (x=a1, y=a2)
        b2 = serialize.unserialize (serialize.serialize (b))
        _.assertEqual (a1, b2.x)
        _.assertEqual (b2.x, b2.y)
        _.assertNotEqual (id(b2.x), id(b2.y))

class Test_roundtrip (unittest.TestCase):

    def test001(_): rt (_, 1005250)
    def test002(_): rt (_, 1005930)
    def test003(_): rt (_, 1000920)
    def test004(_): rt (_, 2013840)

class Test_objects (unittest.TestCase):
    def test001(_):
        e1 = Obj (id=555, seq=222, stat=2)
        e2 = serialize.unserialize (serialize.serialize (e1))
        _.assertEqual (type(e1), type(e2))
        _.assertEqual (e1.id, e2.id)
        _.assertEqual (e1.seq, e2.seq)
        _.assertEqual (e1.stat, e2.stat)
    def test002(_):
        e1 = DbRow ([555,222,2],['id','seq','stat'])
        e2 = serialize.unserialize (serialize.serialize (e1))
        _.assertEqual (type(e1), type(e2))
        _.assertEqual (e1.id, e2.id)
        _.assertEqual (e1.seq, e2.seq)
        _.assertEqual (e1.stat, e2.stat)

    def test011(_):
        e1 = Entr (id=555, seq=222, stat=2)
        e2 = serialize.unserialize (serialize.serialize (e1))
        _.assertEqual (type(e1), type(e2))
        _.assertEqual (e1.id, e2.id)
        _.assertEqual (e1.seq, e2.seq)
        _.assertEqual (e1.stat, e2.stat)
        _.assertEqual (e1.unap, e2.unap)
        _.assertEqual (e1.notes, e2.notes)
    def test012(_):
        e1 = Rdng (txt='あいうえお', rdng=2, entr=555)
        e2 = serialize.unserialize (serialize.serialize (e1))
        _.assertEqual (type(e1), type(e2))
        _.assertEqual (e1.entr, e2.entr)
        _.assertEqual (e1.rdng, e2.rdng)
        _.assertEqual (e1.txt, e2.txt)
    def test013(_):
        e1 = Kanj (txt='田中さん', kanj=2, entr=555)
        e2 = serialize.unserialize (serialize.serialize (e1))
        _.assertEqual (type(e1), type(e2))
        _.assertEqual (e1.entr, e2.entr)
        _.assertEqual (e1.kanj, e2.kanj)
        _.assertEqual (e1.txt, e2.txt)
    def test014(_):
        e1 = Sens (notes='abcd', sens=2, entr=555)
        e2 = serialize.unserialize (serialize.serialize (e1))
        _.assertEqual (type(e1), type(e2))
        _.assertEqual (e1.entr, e2.entr)
        _.assertEqual (e1.sens, e2.sens)
        _.assertEqual (e1.notes, e2.notes)
    def test015(_):
        e1 = Gloss (txt='abcd', sens=2, gloss=3, entr=555, lang=33)
        e2 = serialize.unserialize (serialize.serialize (e1))
        _.assertEqual (type(e1), type(e2))
        _.assertEqual (e1.entr, e2.entr)
        _.assertEqual (e1.sens, e2.sens)
        _.assertEqual (e1.gloss, e2.gloss)
        _.assertEqual (e1.lang, e2.lang)
    # TBS... test cases for every object type?  Or just assume that,
    #   since objects are all very similar, that the existing tests
    #  are sufficient.
    def test101(_):
        e1 = Entr (id=555, seq=222, stat=2,
                _rdng = [Rdng (txt='あいうえお'),
                         Rdng (txt='たちつてと')],
                _kanj = [Kanj (txt='田中さん')],
                _sens = [Sens (_gloss = [Gloss (txt='abcd')]),
                         Sens (_gloss = [Gloss (txt='abcd'),
                                         Gloss (txt='efg')])])
        e2 = serialize.unserialize (serialize.serialize (e1))
        _.assertEqual (e1, e2)
        _.assertEqual (e1._rdng[1].txt, e2._rdng[1].txt)
        _.assertEqual (e1._sens[1]._gloss[1].txt, e2._sens[1]._gloss[1].txt)

def isEqual (a, b):
        if type(a) != type(b) : return False
        return a == b

Cursor = None
def rt(_, seq):
        # Test round trip from entry object through
        # serialize.serialize, serialize.unserialize, back to
        # object.  Compare input and output objects
        # by converting both to xml and comparing
        # text.  (Watch out for order problems).

          # FIXME: reading database to slow, too volatile.
          #   read from a test xml file instead.
        if not Cursor: globalSetup()
          # FIXME: don't hardwire corpus (aka src).
        sql = "SELECT id FROM entr WHERE seq=%s AND src=1"
        elist,r = jdb.entrList (Cursor, sql, [seq], ret_tuple=1)
        e1 = elist[0]
        jdb.augment_xrefs (Cursor, r['xref'])
        s = serialize.serialize (e1)
        e2 = serialize.unserialize (s)
        f1 = fmtxml.entr (e1)
        _.assert_ (len (f1) > 40)  # Sanity check to detect empty entry.
        f2 = fmtxml.entr (e2)
        _.assertEqual (f1, f2)

if __name__ == '__main__': unittest.main()





