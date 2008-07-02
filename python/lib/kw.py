#######################################################################
#  This file is part of JMdictDB. 
#  Copyright (c) 2008 Stuart McGraw 
# 
#  JMdictDB is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published 
#  by the Free Software Foundation; either version 2 of the License, 
#  or (at your option) any later version.
# 
#  JMdictDB is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
# 
#  You should have received a copy of the GNU General Public License
#  along with JMdictDB; if not, write to the Free Software Foundation,
#  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA
#######################################################################
from __future__ import with_statement

__version__ = ('$Revision$'[11:-2],
	       '$Date$'[7:-11]);

import sys, os.path, re
import jdb

class Kwds:
    """
    This class stores data from the jmdictdb kw* tables.  The 
    data in these tables are typically static and small in size,
    so it is effecient to read them once when an app starts.
    This class allows the data to be read either from a jmdictdb 
    database, or from kw*.csv files in a directory.  After 
    initialization, an instance will have a set of attributes,
    each corresponding to a table.  The value of each will be
    a mapping containing keys that are the tables row's 'id' 
    numbers and 'kw' strings.  The keys are distinguishable 
    because the former will always be int's and the latter,
    str's.
    The value associated with of each key is a DbRow object
    containingg a table row.  Note that because each row in 
    indexed under both it's id and kw, there will appear to be
    twice as many rows are there actually are in the corresponding
    table.  Use method .recs() to get a single set of rows.

    Typical use of this class in an app:

	KW = jdb.Kwds (cursor)  # But note this is done by dbOpen().
	KW.POS['adj-i'].id 	# => The id number of PoS 'adj-i'.
	KW.DIAL[dialect].descr	# => The description string for 
				#  'dialect'. 'dialect' may be
				#  either an int id number or kw
				#  string.
    """

    Tables = {'DIAL':"kwdial", 'FLD' :"kwfld",  'FREQ':"kwfreq", 'GINF':"kwginf",
	      'KINF':"kwkinf", 'LANG':"kwlang", 'MISC':"kwmisc", 'POS' :"kwpos",
	      'RINF':"kwrinf", 'SRC' :"kwsrc",  'STAT':"kwstat", 'XREF':"kwxref",
	      'CINF':"kwcinf"}

    def __init__( self, cursor_or_dirname=None ):
	  # Add a set of standard attributes to this instance and
	  # initialize each to an empty dict.
	for attr,table in self.Tables.items():
	    setattr (self, attr, dict())

	  # 'cursor_or_dirname' may by a directory name, a database
	  # cursor, or None.  If a string, assume the former.
	if isinstance (cursor_or_dirname, (str, unicode)):
	    self.loadcsv (cursor_or_dirname)

	  # If not None, must be a database cursor.
	elif cursor_or_dirname is not None:
	    self.loaddb (cursor_or_dirname)
	  # Otherwise it is None, and nothing else need be done.

    def loaddb( self, cursor ):
	# Load instance from database kw* tables.

	for attr,table in self.Tables.items():
	      # For item in Tables is a attribute name, database table
	      # name pair.  Read the table from the database and use 
	      # method .add() to store the records in attribute 'attr'.
	    recs = jdb.dbread (cursor, "SELECT * FROM %s" % table, ())
	    for record in recs:	self.add (attr, record)

    def loadcsv( self, dirname=None ):
	# Load instance from the csv files in directory 'dirname'.
        # If 'dirname' is not supplied or is None, it will default
        # to "../../pg/data/" relative to the location of this module.
	
        if dirname is None: dirname = std_csv_dir ()
	if dirname[-1] != '/' and dirname[-1] != '\\' and len(dirname) > 1:
            dirname += '/'
	for attr,table in self.Tables.items():
	    try: f = open (dirname + table + ".csv")
	    except IOError: continue
	    for ln in f:
		if re.match (r'\s*(#.*)?$', ln): continue
		fields = ln.rstrip('\n\r').split ("\t")
		fields = [x if x!='' else None for x in fields]
		fields[0] = int (fields[0])
		self.add (attr, fields)
	    f.close()

    def add( self, attr, row ):
	# Add the row object to the set of rows in the dict in 
	# attribute 'attr', indexed by its numeric id and its
	# name (kw).  'row' may be either a DbRow object (such
	# as returned by DbRead), or a seq.  In the latter case
	# only the first three items will be used and they will 
	# taken as the 'id', 'kw', and 'descr' values. 

	v = getattr (self, attr)
	if not isinstance (row, (jdb.Obj, jdb.DbRow)):
	    row = jdb.DbRow (row[:3], ('id','kw','descr'))
	v[row.id] = row;  v[row.kw] = row;

    def attrs( self ):
	# Return list of attr name strings for attributes that contain 
	# non-empty setsa of rows.  Note that is this instance will
	# contain every attribute listed in .Tables but some of them
	# may be empty if they haven't been loaded (because the
	# corresponding .csv file of table was missing or empty.)
	  
	return sorted([x for x in self.Tables.keys() if getattr(self, x)])

    def recs( self, attr ):
	# Return a list of DbRow objects representing the rows on the 
	# table identified by 'attr'.
	# 
	# Example (assuming 'KW' is an initialized Kwds instance):
	#    # Get the rows of the kwpos table:
	#    pos_recs = KW ('POS')

	vt = getattr (self, attr)
	r = [v for k,v in vt.items() if isinstance(k, int)]
	return r

def std_csv_dir ():
	our_dir, dummy = os.path.split (__file__)
        csv_dir = os.path.normpath (our_dir + "/../../pg/data")
        return csv_dir

def short_vars (kw):
	d = {}
	for a in kw.attrs ():
            for r in kw.recs (a):
                name = '%s_%s' % (a.upper(), r.kw.replace ('-', '_'))
                d[name] = r.id
        return d
