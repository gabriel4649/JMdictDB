#!/usr/bin/env python

# Tests the jdb.Kwds class.

import sys, pdb, unittest
sys.path.append ('../lib')
import jdb

KwdsAttrs = set (('DIAL','FLD','FREQ','GINF','KINF','LANG','MISC',
		  'POS','RINF','SRC','STAT','XREF','CINF',))
__unittest = 1

class Test_Empty (unittest.TestCase):
    def setUp (_):
	_.o = jdb.Kwds()
    def test001 (_):
	  # Check that .Tables has the expected set of attribute 
	  # names since we will use them in later tests.
	_.assert_ (hasattr (_.o, 'Tables'))
	_.assertEquals (set (_.o.Tables.keys()), KwdsAttrs)
    def test002 (_):
	  # .attrs() method should return empty list for empty instance.
	_.assertEquals (_.o.attrs(), [])
    def test003 (_): 
	  # .recs() method should return an empty list for every attribute.
	for a in KwdsAttrs:
	    _.assertEquals (_.o.recs(a), [])
    def test004 (_):
	  # .recs() method should fail with an unknown attribute.
	_.assertRaises (AttributeError, _.o.recs, 'XXX')
    def test005 (_):
	values = (22,'abc','a description')
	rec = jdb.DbRow (values,('id','kw','descr'))
	_.o.add ('DIAL', rec)
	validate_rec (_, _.o.DIAL, *values)
    def test006 (_):
	values = (22,'abc','a description')
	_.o.add ('DIAL', values)
	validate_rec (_, _.o.DIAL, *values)

class Test_loadcsv (unittest.TestCase):
    def setUp (_):
	_.o = jdb.Kwds ('data/kwds')
    def test001 (_): 
	_.assert_ (hasattr (_.o, 'KINF'))
	_.assert_ (hasattr (_.o, 'GINF'))
	validate_rec (_, _.o.KINF, 13, 'xxx', 'line 1')
	validate_rec (_, _.o.KINF, 27, 'yy')
	validate_rec (_, _.o.GINF, 1, 'equ',  'equivalent')
	validate_rec (_, _.o.GINF, 2, 'lit',  'literaly')
	validate_rec (_, _.o.GINF, 3, 'id',   'idiomatically')
	validate_rec (_, _.o.GINF, 4, 'expl', 'explanatory')
    def test002 (_):
	_.assertEqual (_.o.attrs(), ['GINF', 'KINF'])
    def test003 (_):
	expect = set (((13, 'xxx', 'line 1'),(27, 'yy', None)))
	recs = _.o.recs('KINF')
	_.assertEqual (len(recs), 2)
	comparable_recs = set ((tuple(x) for x in recs))
	_.assertEqual (comparable_recs, expect)
    def test004 (_): 
	expect = set (((1,'equ','equivalent'),(2,'lit','literaly'),
		       (3,'id','idiomatically'),(4,'expl','explanatory')))
	recs = _.o.recs('GINF')
	_.assertEqual (len(recs), 4)
	comparable_recs = set ((tuple(x) for x in recs))
	_.assertEqual (comparable_recs, expect)

class Test_loaddb (unittest.TestCase):
    def setUp (_):
	  #FIXME: use dedicated test database, or mock database
	cur = jdb.dbOpen ('jmdict')
	_.o = jdb.Kwds (cur)
    def test001 (_):
	expect = set (((1,'equ','equivalent'),(2,'lit','literaly'),
		       (3,'id','idiomatically'),(4,'expl','explanatory')))
	recs = _.o.recs('GINF')
	_.assertEqual (len(recs), 4)
	comparable_recs = set ((tuple(x) for x in recs))
	_.assertEqual (comparable_recs, expect)

def validate_rec (_, kwdict, idx, kw, descr=None):
	  # Given the value if a Kwds attribute (like .POS), vaidate
	  # by confirming that the the same object is referenced
	  # when looked up by id number and kw string, and that the
	  # row's id number, kw string, and description match those 
	  # given in the arguments.
 
	_.assertEqual (id(kwdict[idx]), id(kwdict[kw]))

	_.assertEqual (kwdict[idx].id, idx)
	_.assertEqual (kwdict[idx].kw, kw)
	_.assertEqual (kwdict[idx].descr, descr)

	_.assertEqual (kwdict[kw].id, idx)
	_.assertEqual (kwdict[kw].kw, kw)
	_.assertEqual (kwdict[kw].descr,  descr)
	   
if __name__ == '__main__': unittest.main()