import sys, re, unittest, pdb
try: import json
except ImportError: import simplejson as json
sys.path[0] = '../lib'
import jdb, fmtxml
import serialize

Cursor = None
def globalSetup ():
	global Cursor
	try:	# Get login credentials from dbauth.py if possible.
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
    def test0005(_): _.assert_ (isEqual (serialize.obj2struc(u'abc'), u'abc'))
    def test0006(_): _.assert_ (isEqual (serialize.obj2struc(u'\u304a\u5143\u6c17\u3067'), u'\u304a\u5143\u6c17\u3067'))
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
    def test0005(_): _.assert_ (isEqual (serialize.struc2obj(u'abc'), u'abc'))
    def test0006(_): _.assert_ (isEqual (serialize.struc2obj(u'\u304a\u5143\u6c17\u3067'), u'\u304a\u5143\u6c17\u3067'))
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





