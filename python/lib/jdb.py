#######################################################################
#  This file is part of JMdictDB. 
#  Copyright (c) 2006,2008 Stuart McGraw 
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
#  51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
#######################################################################

__version__ = ('$Revision$'[11:-2],
	       '$Date$'[7:-11]);

import sys, random, re, datetime
from time import time
import pdb

global KW

Debug = {}

class AuthError (Exception): pass

class Obj(object):
    # This creates "bucket of attributes" objects.  That is,
    # it creates a generic object with no special behavior
    # that we can set and get atrribute values from.  One
    # could use a keys in a dict the same way, but sometimes
    # the attribute syntax is nicer.
    def __init__ (self, **kwds):
	for k,v in kwds.items(): setattr (self, k, v)
    def __repr__ (self):
	return self.__class__.__name__ + '(' \
		 + ', '.join([k + '=' + _p(v)
			      for k,v in self.__dict__.items()]) + ')'	

class DbRow (object):
    def __init__(self, values=None, cols=None):
	if values is not None: 
	    if cols is not None:
		self.__cols__ = cols
		for n,v in zip (cols, values): setattr (self, n, v)
	    else:
		self.__cols__ = values.keys()
		for n,v in values.items(): setattr (self, n, v)
    def __getitem__ (self, idx): 
	return getattr (self, self.__cols__[idx])
    def __setitem__ (self, idx, value):
        name = self.__cols__[idx]
        setattr (self, name, value)
    def __len__(self): 
	return len(self.__cols__)
    def __iter__(self):
        for n in self.__cols__: yield getattr (self, n)
        raise StopIteration
    def __repr__(self):
	return self.__class__.__name__ + '(' \
		 + ', '.join([k + '=' + _p(v)
			      for k,v in self.__dict__.items() 
				if not k.startswith('__')]) + ')'	
    def __clone__(self):
	c = DbRow ()
	c.__dict__.update (self.__dict__)
	return c

def _p (o):
	if isinstance (o, (int,long,str,unicode,bool)):
	    return repr(o)
	if isinstance (o, list):
	    if len(o) == 0: return "[]"
	    else: return "[...]"
	if isinstance (o, dict):
	    if len(o) == 0: return "{}"
	    else: return "{...}"
	else: return o.__class__.__name__

class _Nothing: pass

def o_compare (self, other):
	try: attrs = set (self.__dict__.keys() + other.__dict__.keys())
	except AttributeError: return cmp (id(self), id(other))
	for a in attrs:
	    s = getattr (self, a, _Nothing)
	    o = getattr (other, a, _Nothing)
	    if s is _Nothing: return -1
	    if o is _Nothing: return +1
	    c = cmp (s, o)
	    if c: return c
	return 0

def dbread (cur, sql, args=None, cols=None):
	if args is None: args = []
	try: cur.execute (sql, args)
	except StandardError, e:
	    e.sql = sql;  e.sqlargs = args
	    e.message += "  %s [%s]" % (sql, ','.join(repr(x) for x in args))
	    raise e
	if not cols: cols = [x[0] for x in cur.description]
	v = []
	for r in cur.fetchall ():
	    x = DbRow (r, cols)
	    v.append (x)
	return v

def dbinsert (dbh, table, cols, row, wantid=False):
	# Insert a row into a database table named by $table.
	# coumns that will be used in the INSERT statement are 
	# given in list @$cols.  The values are given in hash
	# %$hash which is ecepected to contain keys matching 
	# the columns listed in @$cols.

	sql = "INSERT INTO %s(%s) VALUES(%s)" \
		% (table, ','.join(cols), pmarks(cols))
	args = [getattr (row, x, None) for x in cols] 
	if Debug.get ('prtsql'): print repr(sql), repr(args)
	try: dbh.execute (sql, args)
	except StandardError, e:
	    e.sql = sql;  e.sqlargs = args
	    e.message += "  %s [%s]" % (sql, ','.join(repr(x) for x in args))
	    raise e
	id = None
	if wantid: id = dblastid (dbh, table)
	return id

def dblastid (dbh, table):
	# Need to make this work like Perl's DBD:Pg:last_insert_id()
	# but for now following is ok.
	dbh.execute ('SELECT LASTVAL()')
	rs = dbh.fetchone()
	return rs[0]

def entrFind (cur, sql, args=None):
	if args is None: args = []
	tmptbl = Tmptbl (cur)
	tmptbl.load (sql, args)
	return tmptbl
	
def entrList (dbh, crit=None, args=None, ord='', tables=None, ret_tuple=False):

	# Return a list of database objects read from the database.
	#
	# $dbh -- An open DBI database handle.
	#
	# $crit -- Criteria that specifies the entries to be
	#   retieved and returned.  Is one of three forms:
	#
	#   1. Tmptbl object returned from a call to Find()
	#   2. A sql statement that will give a results set
	#	with one column named "id" containing the entr
	#	id numbers of the desired entries.  The sql
	#       may contain parameter markers which will be 
	#       replaced by items for @$args by the database
	#	driver.
	#   3. None.  'args' is expected to contain a list of
	#       entry id numbers.
	#   3a. (Deprecated) A list of integers or parameter
	#       markers, each an entr id number of an entry
	#	to be returned.
	#
	# @$args -- (optional) Values that will be bound to any
	#   parameter markers used in $crit of forms 2 or 3.
	#   Ignored if form 1 given. 
	#
	# $ord -- (optional) An ORDER BY specification (without 
	#   the "ORDER BY" text) used to order the entries in the
	#   returned list.  When qualifying column names by table,
	#   the entr table has the alias "x", and the $crit table
	#   or subselect has the alias "t".
	#   If using a Tmptbl returned by Find() ($crit form 1),
	#   $ord is ignored and internally forced to "t.ord".

	t = {}; e = []
	if args is None: args = []
	if not crit and not args: raise ValueError("Either 'crit' or 'args' must have a value.")
	if not crit:
	    crit = "SELECT id FROM entr WHERE id IN (%s)" % pmarks(args)
	if isinstance (crit, Tmptbl):
	    t = entr_data (dbh, crit.name, args, "t.ord")
	elif isinstance (crit, (str, unicode)):
	    t = entr_data (dbh, crit, args, ord, tables)
	else:
	    # Deprecated - use 'crit'=None and put a real list in 'args'.
	    t = entr_data (dbh, ",".join([str(x) for x in crit]), args, ord, tables)
	if t: e = entr_bld (t)
	if ret_tuple: return e,t
	return e

OrderBy = {
	'rdng':"x.entr,x.rdng", 'kanj':"x.entr,x.kanj", 'sens':"x.entr,x.sens", 
	'gloss':"x.entr,x.sens,x.gloss", 'xref':"x.entr,x.sens,x.xref", 
	'hist':"x.entr,x.hist"}

def entr_data (dbh, crit, args=None, ord=None, tables=None):
	#
	# $dbh -- An open database handle. 
	#
	# $crit -- A string that specifies the selection criteria
	#    for the entries that will be returned and is in one
	#    of the following formats.  
	#
	#    1. Table name.  'crit' either starts with a double
	#       quote character or contains no space characters,
	#       and is not an id number list (#3 below).  
	#       The table named must exist and contain at least a
	#       column named "id" containing entry id numbers of
	#       the entries to be fetched.
	#       jdb.entr.Find() is one way to create such a table.
	#
	#    2. Select statement (in parenthesis).  'crit' starts
	#       with a "(" character.  
	#       It must produce a result set that includes a column
	#       named "id" that contains the entry id numbers of 
	#       the entries to be fetched.  The select statement
	#	may contain parameter marks which will be bound to
	#       values from @$args.
	#
	#    3. A list of entry id numbers.  'crit' is one or more 
	#       of a number or parameter markers ("?" or "%s"
	#	depending on the DBI interface in use) separated
	#       by commas.  Parameter marks which will be bound to
	#       values from @$args.
	#
	#    4. Select statement (not in parenthesis).  'crit'
	#       contains space characters and doesn't start with
	#       a double quote or left paren character.
	#       It must produce a result set that includes a column
	#       named "id" that contains the entry id numbers of 
	#       the entries to be fetched.  The select statement
	#	may contain parameter marks which will be bound to
	#       values from @$args.
	#
	#    Formats 1 and 2 above will be joined with a generic
	#    select to retrieve data from the entry object tables.
	#    Forms 3 and 4 will be used in a "WHERE ... IN()"
	#    clause attached the the generic retrieval sql.
	#    When a large number of results are expected, the
	#    latter two formats are likely to be more effcient
	#    than the former two.
	#
	#  @$args -- A list of values that will be bound to
	#    any paramaters marks in $crit.
	#
	#  $ord -- (optional) string giving an ORDER BY clause
	#    (without the "ORDER BY" text) that will be used 
	#    to order the read of the entr rows and thus the 
	#    order entries are placed in the returned list.
	#    When qualifying column names by table, the entr
	#    table has the alias "x", and the $crit table or 
	#    subselect has the alias "t".
	#    If using the Tmptbl returned by Find(), $ord will
	#    usually be: "t.ord".

	global Debug; start = time()

	if not tables: tables = (
	    'entr','hist','rdng','rinf','audio','kanj','kinf',
	    'sens','gloss','misc','pos','fld','dial','lsrc',
	    'restr','stagr','stagk','freq','xref','xrer',
	    'tsndasn')
	if args is None: args = []
	if ord is None: ord = ''
	if re.search (r'^((\d+|\?|%s),)*(\d+|\?|%s)$', crit):
	    type = 'I'				# id number list
	elif  (crit.startswith ('"')		# quoted table name
	        or crit.find(' ')==-1		# no spaces: table name
	        or crit.startswith ('(')): 	# parenthesised sql
	    type = 'J'
	else: type ='I'				# un-parenthesised sql.

	if type == 'I': tmpl = "SELECT x.* FROM %s x WHERE x.%s IN (%s) %s %s"
	else:           tmpl = "SELECT x.* FROM %s x JOIN %s t ON t.id=x.%s %s %s"

	t = {}
	for tbl in tables:
	    key = iif (tbl == "entr", "id", "entr")

	    if tbl == "entr": ordby = ord
	    else: ordby = OrderBy.get (tbl, "")
	    if ordby: ordby = "ORDER BY " + ordby

	    if tbl == "xrer": 
		tblx = "xref"; key = "xentr"
	    else: tblx = tbl
	    if tblx == "xref": limit = "LIMIT 20"
	    else: limit = ''

	    if   type == 'J': sql = tmpl % (tblx, crit, key, ordby, limit)
	    elif type == 'I': sql = tmpl % (tblx, key, crit, ordby, limit)
	    try: t[tbl] = dbread (dbh, sql, args)
	    except (psycopg2.ProgrammingError), e:
	        print >>sys.stderr, e,
		print >>sys.stderr, '%s %s' % (sql, args)
		dbh.connection.rollback()
	Debug['Obj retrieval time'] = time() - start;
	return t

def entr_bld (t):
	# Put rows from child tables into lists attached to their
	# parent rows, thus building the object structure that
	# application programs wil work with.

	entr=t['entr']; 
	rdng=t.get('rdng',[])
	kanj=t.get('kanj',[])
	sens=t.get('sens',[])
	mup ('_rdng',  entr, ['id'],          rdng,       ['entr'])
	mup ('_kanj',  entr, ['id'],          kanj,       ['entr'])
	mup ('_sens',  entr, ['id'],          sens,       ['entr'])
	mup ('_hist',  entr, ['id'],          t.get('hist', []), ['entr'])
	mup ('_inf',   rdng, ['entr','rdng'], t.get('rinf', []), ['entr','rdng'])
	mup ('_audio', rdng, ['entr','rdng'], t.get('audio',[]), ['entr','rdng'])
	mup ('_inf',   kanj, ['entr','kanj'], t.get('kinf', []), ['entr','kanj'])
	mup ('_gloss', sens, ['entr','sens'], t.get('gloss',[]), ['entr','sens'])
	mup ('_pos',   sens, ['entr','sens'], t.get('pos',  []), ['entr','sens'])
	mup ('_misc',  sens, ['entr','sens'], t.get('misc', []), ['entr','sens'])
	mup ('_fld',   sens, ['entr','sens'], t.get('fld',  []), ['entr','sens'])
	mup ('_dial',  sens, ['entr','sens'], t.get('dial', []), ['entr','sens'])
	mup ('_lsrc',  sens, ['entr','sens'], t.get('lsrc', []), ['entr','sens'])
	mup ('_restr', rdng, ['entr','rdng'], t.get('restr',[]), ['entr','rdng'], '_rdng')
	mup ('_restr', kanj, ['entr','kanj'], t.get('restr',[]), ['entr','kanj'], '_kanj')
	mup ('_stagr', sens, ['entr','sens'], t.get('stagr',[]), ['entr','sens'], '_sens')
	mup ('_stagr', rdng, ['entr','rdng'], t.get('stagr',[]), ['entr','rdng'], '_rdng')
	mup ('_stagk', sens, ['entr','sens'], t.get('stagk',[]), ['entr','sens'], '_sens')
	mup ('_stagk', kanj, ['entr','kanj'], t.get('stagk',[]), ['entr','kanj'], '_kanj')
	mup ('_freq',  rdng, ['entr','rdng'], [x for x in t.get('freq',[]) if x.rdng],  ['entr','rdng'], '_rdng')
	mup ('_freq',  kanj, ['entr','kanj'], [x for x in t.get('freq',[]) if x.kanj],  ['entr','kanj'], '_kanj')
	mup ('_xref',  sens, ['entr','sens'], t.get('xref', []), ['entr','sens']);
	mup ('_xrer',  sens, ['entr','sens'], t.get('xrer', []), ['xentr','xsens']);
	mup ('_snd',   entr, ['id'],          t.get('tsndasn',[]),['entr']);

	return entr

def filt (parents, pks, children, fks):
	# Return a list of all parents (each a hash) in @$parents that
	# are not matched (in the $pks/$fks sense of lookup()) in
	# @$children.
	# One use of filt() is to invert the restr, stagr, stagk, etc,
	# lists in order to convert them from the "invalid pair" form
	# used in the database to the "valid pair" form typically needed
	# for display (and visa versa).
	# For example, if $restr contains the restr list for a single
	# reading, and $kanj is the list of kanji from the same entry,
	# then 
	#        filt ($kanj, ["kanj"], $restr, ["kanj"]);
	# will return a list of kanj hashes that do not occur in @$restr.

	list = []
	for p in parents:
	    if not lookup (children, fks, p, pks): list.append (p)
	return list

def lookup (parents, pks, child, fks, multpk=False):
	# @$parents is a list of hashes and %$child a hash.
	# If $multpk if false, lookup will return the first
	# element of @$parents that "matches" %$child.  A match
	# occurs if the hash values of the parent element identified
	# by the keys named in list of strings @$pks are "="
	# respectively to the hash values in %$child corresponding
	# to the keys listed in list of strings @$fks. 
	# If $multpk is true, the matching is done the same way but
	# a list of matching parents is returned rather than the 
	# first match.  In either case, an empty list is returned
	# if no matches for %$child are found in @$parents.

	results = []
	for p in parents:
	    if matches (p, pks, child, fks):
		if multpk: results.append (p)
		else: return p
	return results

def matches (parent, pks, child, fks):
	# Return True if the attributes of object a listed in ak 
	# are equal to the attributes of b listed in bk.  ak and
	# bk are seq
	
	for pk,fk in zip (pks, fks):
	    if getattr (parent, pk) != getattr (child, fk): return False
	return True

def mup (attr, parents, pks, childs, fks, pattr=None):
	# Assign each element of list 'childs' to its matching parent
	# and/or "assign" each parent to each matching child.
	# A parent item ands child item "match" when the values of the
	# parent item attributes named in list 'pks' are equal to the
	# child item attributes named in list 'fks'. 
	#
	# The child is "assigned" to the parent by adding it to the
	# list in the parent's attribute 'attr', if attr in not None.
	# Alternatively (or in addition) the parent will be "assigned"
	# to each matching child by setting the child's attribute named
	# by pattr, to the parent, if 'pattr' is not None.
	#
	# Not that if both 'attr' and 'pattr' are not None, a reference
	# cycle will be created.  Refer to the description of reference
	# counting and garbage collection in the Python docs for the
	# implications of that.
  
	  # Build an index of the keys of parents, to speed up lookups.
	index = dict();
	for p in parents:
	    pkey = tuple ([getattr (p, x) for x in pks])
	    index.setdefault (pkey, []).append (p)
	    if attr: setattr (p, attr, [])

	  # Go through the childs, for each looking up the parent with
	  # a pk matching the child's fk, and adding the child to that 
	  # parent's list, in attribute 'attr'.
	for c in childs:
	    ckey = tuple ([getattr (c, x) for x in fks])
	    for p in (index[ckey]):
		if attr: getattr (p, attr).append (c)
	    if pattr: setattr (c, pattr, p)

#-------------------------------------------------------------------
# The followng three functions deal with xrefs. 
#-------------------------------------------------------------------
	# An xref (in the jdb api) is an object that represents 
	# a record in the "xref" table (or "xresolv" table in the
	# case of unresolved xrefs).  The database xref records
	# in turn represent a <xref> or <ant> element in the
	# JMdict xml file, although there are some differences:
	#
	#  * Database xref records can have other type besides
	#    "xref" and "ant".
	#  * Database xref records always point to a specific sense
	#    in the target entry; jmdict xrefs/ants can point to a
	#    specific sense, or no sense (i.e. the entire entry.)
	#  * Database xrefs always point to (a sense in) a specific
	#    entry; jmdict xrefs identify the target entry with a 
	#    kanji text, reading text, or both, and may not uniquely
	#    identify a single entry. 
	#
	# There are actually three flavours of xref objects:
	#
	# "ordinary" (or unqualified) xrefs represent only the info 
	# stored in the database xref table where each row represents
	# an xref from an existing enty's sense to another existing
	# entrys sense.  It will have attributes 'typ' (attribute type
	# id number as defined in table kwxref), 'xentr' (id number of
	# target entry), 'xsens' (sense number of target sense), and 
	# optionally 'kanj' (kanj number of the kanji whose text will
	# be used when displaying the xref textually), 'rdng' (like
	# 'kanj' but for reading), 'notes'.  When jdb.entrList() reads
	# an entry object, it creates ordinary xrefs. 
	# 
	# "augmented" xrefs are provide additional information about 
	# the xref's target entry that are useful when presenting the
	# xref textually to an end-user.  The additional information
	# is in the form of an "abreviated" entry object found in the 
	# xref attribute "TARG".  The entry object is "abreviated" in
	# that it contains only data from the rdng, kanj, sens, and
	# gloss tables, but not from kinfo, lsrc, etc that are not
	# relevant when providing only a summary of an entry. 
	# ordinary xrefs can be turned into augmented xrefs with the
	# function jdb.augment_xrefs().  Note that augmented xrefs 
	# are a superset of ordinary xrefs and should work wherever 
	# ordinary xrefs are accepted. 
	#
	# "unresolved" xrefs represent xref information read from a
	# textual source and correspond to database records in table
	# "xresolv".  They have attributes 'typ' (attribute type id
	# number as defined in table kwxref), 'ktxt' (target kanji),
	# 'rtxt' (reading text), and optionally, 'notes', 'xsens'
	# (target sense), 'ord' (ordinal position within a set of
	# related xrefs).  These xrefs have not been verified and
	# and a unique entry with the given kanji or reading texts
	# may not exist in the database or it may not have the given
	# target senses.  The api function jdb.resolv_xrefs() can be
	# used to turn unresolved xrefs into ordinary xrefs.

def augment_xrefs (dbh, xrefs, rev=False):
	# Augment a set of xrefs with extra information about the 
	# xrefs' targets.  After augment_xrefs() returns, each xref
	# item in 'xrefs' will have an additional atttribute, "TARG"
	# that is a reference to an entr object describing the xref's
	# target entry.  Unlike ordinary entr objects, the TARG objects
	# have only a subset of sub items: they have no _inf, _freq, 
	# _hist, _lsrc, _pos, _misc, _fld, _audio, _xrer, _restr, 
	# _stagr, _stagk lists.

	global Debug; start = time()

	tables = ('entr','rdng','kanj','sens','gloss','xref')
	if rev: attr = 'entr'
	else: attr = 'xentr'
	ids = set ([getattr(x,attr) for x in xrefs])
	if len (ids) > 0:
	    elist = entrList (dbh, list(ids), tables=tables)
	    mup (None, elist, ['id'], xrefs, [attr], 'TARG')

	Debug['Xrefsum2 retrieval time'] = time() - start

def grp_xrefs (xrefs, rev=0):

	# Group the xrefs in list @$xrefs into groups such that xrefs
	# in each group have the same {entr}, {sens}, {typ}, {xentr},
	# and {notes} values and differ only in the values of {sens}.
	# Order is preserved so each xref will have the same relative
	# position within its group as it did in @$xrefs.
	# The grouped xrefs are returned as a (reference to) a list
	# of lists of xrefs.
	#
	# If $rev is true, the xrefs are treated as reverse xrefs
	# and grouped by {xentr}, {xsens}, {typ}, {entr}.
	#
	# This function is useful for grouping together all the senses
	# of each xref target entry when it is desired to to display
	# information for an xref entry once, even when multiple
	# target senses exist.
	# 
	# WARNING -- this function currently assumes that the input
	# list @$xrefs is already sorted by {entr}, {sens}, {typ}, 
	# {xentr} (or {xentr}, {xsens}, {typ}, {entr} if $rev is
	# true).  If that is not true then you may get duplicate
	# groups in the result list.  However, it is true for xref
	# lists in the entry structure returned by EntrList().

	results = [];  prev = None
	for x in xrefs:
	    if ((not rev and (not prev
		  or (hasattr(x,'entr')  and prev.entr  != x.entr)
		  or (hasattr(x,'sens')  and prev.sens  != x.sens
		  or (hasattr(x,'typ')   and prev.typ   != x.typ)
		  or (hasattr(x,'xentr') and prev.xentr != x.xentr)
		  or (hasattr(x,'rdng')  and prev.rdng  != x.rdng)
		  or (hasattr(x,'kanj')  and prev.kanj  != x.kanj))))
	        or (rev and (not prev
		  or (hasattr(x,'xentr') and prev.xentr != x.xentr)
		  or (hasattr(x,'xsens') and prev.xsens != x.xsens
		  or (hasattr(x,'typ')   and prev.typ   != x.typ)
		  or (hasattr(x,'entr')  and prev.entr  != x.entr)
		  or (hasattr(x,'rdng')  and prev.rdng  != x.rdng)
		  or (hasattr(x,'kanj')  and prev.kanj  != x.kanj)))) ):
		b = [x]
		results.append (b)
	    else:
		b.append(x)
	    prev = x
	return results

def resolv_xref (dbh, typ, rtxt, ktxt, slist=None, enum=None, corpid=None, 
		 one_entr_only=True, one_sens_only=False):

	# Find entries and their senses that match $ktxt and $rtxt
	# and create list of augmented xref records that points to
	# them.
	#
	# dbh (dbapi cursor) -- Handle to open database connection.
	# typ (int) -- Type of reference per table kwxref.
	# rtxt (string or None) -- Cross-ref target(s) must have this
	#   reading text.
	# ktxt (string or None) -- Cross-ref target(s) must have this
	#   kanji text.
	# slist (list of ints or None) -- Resolved xrefs will be limited
	#   to these target senses.  A Value Error is raised in a sense
	#   is given in 'slist' that does not exist in target entry.
	# enum (int or None) -- If 'corpid' value is given (below) then
	#   this parameter is interpreted as a seq number.  Otherwise it
	#   is interprested as an entry id number.
	# corpid (int or None) -- If given the resolved target must have
	#   the same value of .src.
	# one_entr_only (bool) -- Raise error if xref resolves to more
	#   than one entry.  Regardless of this value, it is always an
	#   error if 'slist' is given and the xref resolves to more than
	#   one entry.  
	# one_sens_only (bool) -- Raise error if 'slist' not given and 
	#   any of the resolved entries have more than one sense. 
	# 
	# resolv_xref() returns a list of augmented xrefs (see function 
	# augment_xrefs() for description) except each xref has no {entr},
	# {sens}, or {xref} elements, since those will be determined by
	# the parent sense to which the xref is attached.
	# 
	# Prohibited conditions such as resolving to multiple
	# entries when the $one_entr_only flag is true, are 
	# signalled with die().  The caller may want to call 
	# resolv_xref() within an eval() to catch these conditions.
	
	if not rtxt and not ktxt and not enum:
	    raise ValueError ("No rtxt, ktxt, or enum value, need ay least one.")
	krtxt = (ktxt or '') + (u'\u30fb' if ktxt and rtxt else '') + (rtxt or '')

	  # Build a SQL statement that will find all entries
	  # that have a kanji and reading matching 'ktxt' and
	  # 'rtxt'.  If further restrictions are necessary (such
	  # as limiting the search to entries in a specific
	  # corpus), they are given the the 'whr' and 'wargs'
	  # parameters. 

	condlist = []
	if ktxt: condlist.append (('kanj k', "k.txt=%s", [ktxt]))
	if rtxt: condlist.append (('rdng r', "r.txt=%s", [rtxt]))
	if enum:
	    if not corpid:
		condlist.append (('entr e', 'e.id=%s', [enum]))
	    else:
		condlist.append (('entr e', 'e.seq=%s AND e.src=%s', [enum,corpid]))
	sql, sql_args = build_search_sql (condlist)
	tables = ('entr','rdng','kanj','sens','gloss')
	entrs = entrList (dbh, sql, sql_args, tables=tables)

	if not entrs: raise ValueError ('No entries found for cross-reference "%s".' % krtxt)
	if len (entrs) > 1 and (one_entr_only or slist):
	    raise ValueError ('Multiple entries found for cross-reference "%s".' % krtxt)

	# For every target entry, get all it's sense numbers.  We need
	# these for two reasons: 1) If explicit senses were targeted we
	# need to check them against the actual senses. 2) If no explicit
	# target senses were given, then we need them to generate erefs 
	# to all the target senses.
	# The code currently compares actual sense numbers; if the database
	# could guarantee that sense numbers are always sequential from
	# one, this code could be simplified and speeded up.

	if slist:
	    # The submitter gave some specific senses that the xref will
	    # target, so check that they actually exist in the target entry.
	    # We know (from previous code) that if there was an slist, there
	    # must be exactly one entry here.

	    snums = [s.id for s in entrs[0]._sens]
	    for s in slist:
		if s not in snums: nosens.append (str(s))
	    if nosens:
		raise ValueError ('Sense(s) %s not in target "%s".' % (",".join(nosens), krtxt))
	else:
	    # No specific senses given, so this xref(s) should target every
	    # sense in the target entry(s), unless $one_sens_only is true
	    # in which case all the xrefs must have only one sense or we 
	    # raise an error.
	    if one_sens_only and first (entrs, lambda x: len(x._sens)>1):
		raise ValueError ('The "%s" target(s) has more than one sense.' % (krtxt))

	xrefs = []
	for e in entrs:
	    xrdng = xkanj = None
	    if rtxt: xrdng = (first (e._rdng, lambda x: x.txt==rtxt)).rdng
	    if ktxt: xkanj = (first (e._kanj, lambda x: x.txt==ktxt)).kanj
	    for s in e._sens:
		if not slist or s.sens in slist:
		    xrefs.append (Obj (typ=typ, xentr=e.id, xsens=s.sens,
				  rdng=xrdng, kanj=xkanj, TARG=e))
	return xrefs

def addentr (cur, entr):
	# Write the entry, 'entr', to the database open on connection
	# 'cur'.  
	# WARNING: This function will modify the values of some of the
	# attributes in the entr object: entr.id, entr.seq (if None),
	# all the sub-object pk attributes, e.g., rdng.entr, rdng.rdng,
	# gloss.entr, gloss.sens, gloss.gloss, etc.

	# Note the some of the values in the entry object ignored when
        # writing to the database.  Specifically:
	#   entr.id -- The database entr record is written to database  
	#     ignoring the entr.id value in the entr object.  This
	#     results in the database assigning the next auto-sequence
	#     id number to the id column in the entr row.
	#     This id number is read back, and the entr object's .id
	#     attribute updated with it.  All sub-object foreign key
	#     .entr attributes (e.g. rdng.entr, gloss.entr, etc) are
	#     also set to that value.
	#   sub-object id's (rdng.rdng, etc) -- Are rewritten as the
	#      object's index position in it's list, plus one.  That 
	#      number is also used when writing to the database.
	#   entr.seq -- Used if present and not false, but otherwise,
	#      the entr record is written without a seq number causing
	#      the database's entr table trigger to assign an appropriate
	#      seq number.  That number is read back and the entr object's
	#      .seq attribute updated with it.
	# The caller is responsible for starting a transaction prior to
	# calling this function, and doing a commit after, if an atomic
	# write of the complete entry is desired.

	  # Insert the entr table row.  If 'seq' is None, an appropriate
	  # seq number will be automatically generated by a trigger on the
	  # entr table, using a sequence table named in the kwsrc table row
	  # corresponding to 'src'.
	dbinsert (cur, "entr", ['src','stat','seq','dfrm','unap','srcnote','notes'], entr)
	  # Postgres function lastval() will contain the auto-assigned
	  # seq number if one was generated.  We need to get the auto-
	  # assigned id number directly from its sequence.
	if not getattr (entr, 'seq', None):
	    cur.execute ("SELECT LASTVAL()")
	    entr.seq = cur.fetchone()[0]
	cur.execute ("SELECT CURRVAL('entr_id_seq')")
	eid = cur.fetchone()[0]
	  # Update all the foreign key attributes in the entr object to
	  # match the real entr.id  setkeys() will also set the relative
	  # part of each row object's pk (rdng.rdng, gloss.sens, gloss.gloss,
	  # etc.) to the objects position (0-based) in it's list plus one,
	  # overwriting any preexisting values.
	setkeys (entr, eid)
	  # Walk through the entr object tree writing each row object to
	  # a new database row.
	freqs = set()
	for h in getattr (entr, '_hist', []):
	    dbinsert (cur, "hist", ['entr','hist','stat','edid','dt','name','email','diff','refs','notes'], h)
	for k in getattr (entr, '_kanj', []):
	    dbinsert (cur, "kanj", ['entr','kanj','txt'], k)
	    for x in getattr (k, '_inf',   []): dbinsert (cur, "kinf",  ['entr','kanj','kw'], x)
	    for x in getattr (k, '_freq',  []): dbinsert (cur, "freq",  ['entr','rdng','kanj','kw','value'], x)
	for r in getattr (entr, '_rdng', []):
	    dbinsert (cur, "rdng", ['entr','rdng','txt'], r)
	    for x in getattr (r, '_inf',   []): dbinsert (cur, "rinf",  ['entr','rdng','kw'], x)
	    for x in getattr (r, '_audio', []): dbinsert (cur, "audio", ['entr','rdng','fname','strt','leng'], x)
	    for x in getattr (r, '_restr', []):	dbinsert (cur, "restr", ['entr','rdng','kanj'], x)
	    for x in getattr (r, '_freq',  []): 
				  # Any freq recs with a non-null 'kanj' value were written when the kanji
				  # records were processed, so we need write only the rdng-only freq's. 
		if not getattr (x,'kanj',None): dbinsert (cur, "freq",  ['entr','rdng','kanj','kw','value'], x)
	for x in freqs:
	    dbinsert (cur, "freq",  ['entr','rdng','kanj','kw','value'], x)
	for s in getattr (entr, '_sens'):
	    dbinsert (cur, "sens", ['entr','sens','notes'], s)
	    for g in getattr (s, '_gloss', []):	dbinsert (cur, "gloss", ['entr','sens','gloss','lang','ginf','txt'], g)
	    for x in getattr (s, '_pos',   []): dbinsert (cur, "pos",   ['entr','sens','kw'], x)
	    for x in getattr (s, '_misc',  []): dbinsert (cur, "misc",  ['entr','sens','kw'], x)
	    for x in getattr (s, '_fld',   []): dbinsert (cur, "fld",   ['entr','sens','kw'], x)
	    for x in getattr (s, '_dial',  []): dbinsert (cur, "dial",  ['entr','sens','kw'], x)
	    for x in getattr (s, '_lsrc',  []): dbinsert (cur, "lsrc",  ['entr','sens','lang','txt','part','wasei'], x)
	    for x in getattr (s, '_stagr', []): dbinsert (cur, "stagr", ['entr','sens','rdng'], x)
	    for x in getattr (s, '_stagk', []): dbinsert (cur, "stagk", ['entr','sens','kanj'], x)
	    for x in getattr (s, '_xref',  []): dbinsert (cur, "xref",  ['entr','sens','xref','typ','xentr','xsens','rdng','kanj','notes'], x)
	if getattr (entr, 'chr', None):
	    c = e.chr
	    dbinsert (cur, "chr", ['entr','bushu','strokes','freq','grade'], c)
	    for x in getattr (c, '_cinf',  []): dbinsert (cur, "cinf",  ['entr','kw','value'], x)
	return eid, entr.seq, entr.src

def add_hist (cur, e, edid, name, email, notes, refs):
	# Attach a history info to an entry.  Any existing hist on the 
	# entry is discarded. If this is a new entry, a single new hist
	# record is added. If this is an edit of an existing entry, 
	# the hist records of the 'dfrm' entry are read, and the new 
	# hist record appended to them and the list is attached to the
	# entry.
	# e.dfrm indicates whether this is a new (dfrm null) or old 
	# (dfrm has a value) entry.  Caller should set dfrm to e.id
	# before calling add_hist() if this is an edit of an existing
	# entry. 
	if not e.unap and not edid: 
	    # This check for convenience -- database authentication 
	    # and integrity rules will also catch.
	    raise AuthError ("Only logged in editors can create approved entries")
	dfrm = None
	if e.dfrm:
	    # Get source entry
	    dfrm = entrList (cur, [e.dfrm])
	    if not dfrm:
		raise ValueError ("No entry matching dfrm value of %d" % e.dfrm) 
	    dfrm = dfrm[0]
	h = Obj (stat=e.stat, edid=edid, dt=datetime.datetime.utcnow(), 
		 name=name, email=email, refs=refs, notes=notes)
	if dfrm: 
	    e._hist = getattr (dfrm, '_hist', [])
	    h.diff = None #diff (dfrm, e)  # FIXME: need diff function.
	else: 
	    e._hist = []
	    h.diff = None
	e._hist.append (h)
	return e;

def setkeys (e, id=None):
	  # Set the foreign and primary key values in each record
	  # in the entry, 'e'.  If 'id' is provided, it will be used
	  # as the entry id number.  Otherwise, it is assumed that 
	  # the id number has already been set in 'e'.
	  # Please note that this function assumes that items with
	  # multiple parents such as '_freq', '_restr', etc, are 
	  # listed under both parents.
	if id: e.id = id
	else: id = e.id
	for n,r in enumerate (getattr (e, '_rdng', [])):
	    n += 1; (r.entr, r.rdng) = (id, n)
	    for x in getattr (r, '_inf',   []): (x.entr, x.rdng) = (id, n)
	    for x in getattr (r, '_freq',  []): (x.entr, x.rdng) = (id, n)
	    for x in getattr (r, '_restr', []): (x.entr, x.rdng) = (id, n)
	    for x in getattr (r, '_stagr', []): (x.entr, x.rdng) = (id, n)
	for n,k in enumerate (getattr (e, '_kanj', [])):
	    n += 1; (k.entr, k.kanj) = (id, n)
	    for x in getattr (k, '_inf',   []): (x.entr, x.kanj) = (id, n)
	    for x in getattr (k, '_freq',  []): (x.entr, x.kanj) = (id, n)
	    for x in getattr (k, '_restr', []): (x.entr, x.kanj) = (id, n)
	    for x in getattr (k, '_stagk', []): (x.entr, x.kanj) = (id, n)
	for n,s in enumerate (getattr (e, '_sens', [])):
	    n += 1; (s.entr, s.sens) = (id, n)
	    for m,x in enumerate (getattr (s, '_gloss', [])): (x.entr,x.sens,x.gloss) = (id,n,m+1)
	    for x in getattr (s, '_pos',   []): (x.entr, x.sens) = (id, n)
	    for x in getattr (s, '_misc',  []): (x.entr, x.sens) = (id, n)
	    for x in getattr (s, '_fld',   []): (x.entr, x.sens) = (id, n)
	    for x in getattr (s, '_dial',  []): (x.entr, x.sens) = (id, n)
	    for x in getattr (s, '_lsrc',  []): (x.entr, x.sens) = (id, n)
	    for x in getattr (s, '_stagr', []): (x.entr, x.sens) = (id, n)
	    for x in getattr (s, '_stagk', []): (x.entr, x.sens) = (id, n)
	    for m,x in enumerate (getattr (s, '_xref', [])): (x.entr,x.sens,x.xref) = (id,n,m+1)
	    for x in getattr (s, '_xrer',  []): (x.entr, x.sens) = (id, n)
	    for x in getattr (s, '_xrslv', []): (x.entr, x.sens) = (id, n)
	for n,x in enumerate (getattr (e, '_hist', [])): (x.entr,x.hist) = (id,n+1)
	if getattr (e, 'chr', None):
	    c = e.chr
	    c.entr = id
	    for x in getattr (c, '_cinf', []): x.entr = id
	for x in getattr (e, '_krslv', []): x.entr = id

def entrDiff (e1, e2): pass
	

def build_search_sql (condlist, disjunct=False, allow_empty=False):

	# Build a sql statement that will find the id numbers of
	# all entries matching the conditions given in <condlist>.
	# Note: This function does not provide for generating
	# arbitrary SQL statements; it is only intented to support 
	# limited search capabilities that are typically provided 
	# on a search form.
	#
	# <condlist> is a list of 3-tuples.  Each 3-tuple specifies
	# one condition:
	#   0: Name of table that contains the field being searched
	#     on.  The name may optionally be followed by a space and
	#     an alias name for the table.  It may also optionally be
	#     preceeded (no space) by an astrisk character to indicate
	#     the table should be joined with a LEFT JOIN rather than
	#     the default INNER JOIN. 
	#     Caution: if the table is "entr" it *must* have "e" as an
	#     alias, since that alias is expected by the final generated
	#     sql.
	#   1: Sql snippit that will be AND'd into the WHERE clause.
	#     Field names must be qualified by table.  When looking 
	#     for a value in a field.  A "?" may (and should) be used 
	#     where possible to denote an exectime parameter.  The value
	#     to be used when the sql is executed is is provided in
	#     the 3rd member of the tuple (see #2 next).
	#   2: A sequence of argument values for any exec-time parameters
	#     ("?") used in the second value of the tuple (see #1 above).
	#
	# Example:
	#     [("entr e","e.typ=1", ()),
	#      ("gloss", "gloss.text LIKE ?", ("'%'+but+'%'",)),
	#      ("pos","pos.kw IN (?,?,?)",(8,18,47))]
	#
	#   This will generate the SQL statement and arguments:
	#     "SELECT e.id FROM (((entr e INNER JOIN sens ON sens.entr=entr.id) 
	# 	INNER JOIN gloss ON gloss.sens=sens.id) 
	# 	INNER JOIN pos ON pos.sens=sens.id) 
	# 	WHERE e.typ=1 AND (gloss.text=?) AND (pos IN (?,?,?))"
	#     ('but',8,18,47)
	#   which will find all entries that have a gloss containing the
	#   substring "but" and a sense with a pos (part-of-speech) tagged
	#   as a conjunction (pos.kw=8), a particle (18), or an irregular
	#   verb (47).

	# The following check is to reduce the effect of programming 
	# errors that pass an empty condlist, which in turn will result
	# in generating sql that will attempt to retrieve every entry
	# in the database.  It does not garauntee reasonable behavior
	# though: a condlist of [('entr', 'NOT unap', [])] will produce
	# almost the same results.

	if not allow_empty and not condlist:
	    raise ValueError ("Empty condlist parameter")

	# $fclause will become the FROM clause of the generated sql.  Since
	# all queries will rquire "entr" to be included, we start of with 
	# that table in the clause.

	fclause = 'entr e'
	regex = re.compile (r'^([*])?(\w+)(\s+(\w+))?$')
	wclauses = [];  args = [];  havejoined = {}

	# Go through the condition list.  For each 3-tuple we will add the
	# table name to the FROM clause, and the where and arguments items 
	# to there own arrays.

	for tbl,cond,arg in condlist:

	    # To make it easier for code generating condlist's allow
	    # them to generate empty cond elements that we skip here.

	    if not cond: continue

	    # The table name may be preceeded by a "*" to indicate that
	    # it is to be joinged with a LEFT JOIN rather than the usual
	    # INNER JOIN".  It may also be followed by a space and an 
	    # alias name.  Unpack these things.

	    mg = regex.search (tbl)
	    jt,tbl,alias = mg.group (1,2,4)
	    if jt: jointype = 'LEFT JOIN' 
	    else: jointype = 'JOIN'

	    # Add the table (using the desired alias if any) to the FROM 
	    # clause (except if the table is "entr" which is aleady in 
	    # the FROM clause).

	    tbl_w_alias = tbl
	    if alias: tbl_w_alias += " " + alias
	    if tbl != 'entr' and tbl_w_alias not in havejoined:
		fclause += ' %s %s ON %s.entr=e.id' \
			   % (jointype,tbl_w_alias,(alias or tbl))
		havejoined[tbl_w_alias] = True
	    else:
		# Sanity check...
		if tbl == 'entr' and alias and alias != 'e':
		    raise ValueError (
			"table 'entr' in condition list uses alias other than 'e': %s" % alias)

	    # Save the cond tuple's where clause and arguments each in 
	    # their own array.

	    wclauses.append (cond)
	    args.extend (arg)

	# AND all the where clauses together.

	if disjunct: conj = ' OR '
	else: conj = ' AND '
	where = conj.join ([x for x in wclauses if x])

	# Create the sql we need to find the entr.id numbers from 
	# the tables and where conditions given in the @$condlist.

	sql = "SELECT DISTINCT e.id FROM %s WHERE %s" % (fclause, where)

	# Return the sql and the arguments which are now suitable
	# for execution.

	return sql, args

def autocond (srchtext, srchtype, srchin, inv=None, alias_suffix=''):
	#
	# srchtext -- The text to search for. 
	#
	# srchtype: where to search of 'srchtext' in the txt column.
	#   1 -- "Is", exact (and case-sensitive) match required.
	#   2 -- "Starts", 'srchtext' matched a lreading substring
	#        of the target string.
	#   3 -- "Contains", 'srchtext' appears as a substring anywhere
	#        in the target text.
	#   4 -- "Ends", 'srchtext' matches at the end of the target text.
	#
	# srchin: table to search in
	#   1 -- auto (choose table based on presence of kanji or kana
	#        in 'srchtext'.
	#   2 -- kanj
	#   3 -- kana
	#   4 -- gloss
	#
	  # The following generates implements case insensitive search
	  # for gloss searches, and non-"is" searches using the sql LIKE
	  # operator.  The case-insensitive part is a work-around for
	  # Postgresql's lack of support for standard SQL's COLLATION
	  # feature.  We can't use ILIKE for case-insensitive searches
	  # because it won't use an index and thus is very slow (~25s
	  # vs ~.2s with index on developer's machine.  So instead, we
	  # created two functional indexes on gloss.txt: "lower(txt)"
	  # and "lower(txt) varchar-pattern-ops".  The former will be
	  # used for "lower(xx)=..." searches and the latter for
	  # "lower(xx) LIKE ..." searches.  So when do a gloss search,
	  # we need to lowercase the search text, and generate a search
	  # clause in one of the above forms.  
	  #
	  # To-do: LIKE 'xxx%' dosn't use index unless the argument value 
	  # is embedded in the sql (which we don't currently do).  When
	  # the 'xxx%' is supplied as a separate argument, the query
	  # planner (runs when the sql is parsed) can't use index because
	  # it doesn't have access to the argument (which is only available
	  # when the query is executed) and doesn't know that it is not
	  # something like '%xxx'.

	sin = stype = 0
	try: sin = int(srchin)
	except ValueError: pass
	try: stype = int(srchtype)
	except ValueError: pass

	if sin == 1: m = jstr_classify (srchtext)
	if   sin == 2 or (m & KANJI): tbl,col = 'kanj k%s',  'k%s.txt'
	elif sin == 3 or (m & KANA):  tbl,col = 'rdng r%s',  'r%s.txt' 
	elif sin == 4 or sin == 1: tbl,col = 'gloss g%s', 'g%s.txt'
	else:
	    raise ValueError ("autocond(): Bad 'srchin' parameter value: %r" % srchin)
	tbl %= alias_suffix;  col %= alias_suffix
	if tbl.startswith("gloss "):
	    srchtext = srchtext.lower(); 
	    col = "lower(%s)" % col
	if   stype == 1: whr,args = '%s=%%s',      [srchtext]
	elif stype == 2: whr,args = '%s LIKE %%s', [srchtext + '%']
	elif stype == 3: whr,args = '%s LIKE %%s', ['%' + srchtext + '%']
	elif stype == 4: whr,args = '%s LIKE %%s', ['%' + srchtext]
	else:
	    raise ValueError ("autocond(): Bad 'srchtype' parameter value: %r", srchtype)
	if inv: whr = "NOT %s" % whr
	return tbl, (whr % col), args

def kwnorm (kwtyp, kwlist, inv=None):
	"""
	Return either the given 'kwlist' or its complement
	(and the string "NOT"), whichever is shorter.

	Given as list of kw's all from the same domain, see if
	it is longer than half the length af all kw's in the domain.
	If so, return the shorter complent of the given list, along
	with an inversion strin, "NOT", which can be used to build
	a short SQL WHERE clause that will produce the same results
	as the longer given kw list. 
	"""
	global KW
	if inv is None:
	    if 'NOT' in kwlist: kwlist.remove ('NOT'); inv = True
	    else: inv = False
	nkwlist = []
	for x in kwlist:
	    try: x = int(x)
	    except ValueError: pass
	    try: v = getattr (KW, kwtyp)[x].id
	    except KeyError,e:
		e.message = "'%s' is not a known %s keyword" % (x, kwtyp)
		raise
	    nkwlist.append (v)
	kwall = KW.recs(kwtyp)
	inv_is_shorter = len (nkwlist) > len (kwall) / 2 
	if inv_is_shorter:
	    nkwlist = [x.id for x in kwall if x.id not in nkwlist]
	invrv = 'NOT ' if inv_is_shorter != bool(inv) else ''
	return nkwlist, invrv

def is_p (entr):
	"""
	Return a bool value indicating whether or not an entry
	object 'entr' meets the wwwjdic criteria for a "P"
	(popular) marker.  Currently true if any of the entry's
	kanji or readings have a FREQ tag of "ichi1", "gai1",
	"spec1", or "news1".
	"""
	for r in getattr (entr, '_rdng', []):
	    for f in getattr (r, '_freq', []):
		if f.kw in (1,2,4,7) and f.value == 1: return True
	for k in getattr (entr, '_kanj', []):
	    for f in getattr (k, '_freq', []):
		if f.kw in (1,2,4,7) and f.value == 1: return True
	return False


class Tmptbl:
    def __init__ (self, cursor, tbldef=None, temp=True):
	"""Create a temporary table in the database.

	cursor -- An open DBAPI cursor that idendifies the data-
	    base in which the temporary table will be created.
	tbldef -- If 'tbldef' is given, it is expected to be a
	    string that gives the SQL for the table definition
	    after the "create table xxx (" part.  It should not
	    include the closing paren.
	    If not given, the table will be created with a single
	    integer primary key column named "id" and a counter
	    (autonumber) column named "ord".  
	temp -- If not true, table will be created with the "TEMPORARY"
	    option.  If true, it will be created without this option.
	    "TEMPORARY" causes the table to not be visible from
	    other connections and to be automatically deleted when
	    the connection it was created on is closed.  Setting the
	    'temp'parameter to False can be useful when debugging or
	    testing.  Note that the table will be explicitly deleted
	    when a Tmptbl instance is deleted, whether 'temp' is True
	    or False.

        When a Tmptbl instance is deleted (due to explicit deletion
	or because no other objects are referencing it and it is 
	being garbage collected) it will explicitly delete it's
	database table."""

	  # The 'ord' column's purpose is to preserve the order
	  # that 'id' values were inserted in.
	if not tbldef: tbldef = "id INT, ord SERIAL PRIMARY KEY"
	nm = self.mktmpnm()
	tmp = 'TEMPORARY ' if temp else ''
	sql = "CREATE %s TABLE %s (%s)" % (tmp, nm, tbldef)
	cursor.execute (sql, ())
	self.name = nm
	self.cursor = cursor

    def load (self, sql=None, args=[]):
	# FIXME: this method is too specific, assumes column name
	#  is 'id', when sql is None, args is list of ints (why not
	# strings if tmptbl was defined so?)
	cur = self.cursor
	if sql:
	    s = "INSERT INTO %s(id) (%s)" % (self.name, sql)
	    cur.execute (s, args)
	elif args: 
	    vallist = ','.join(["(%d)"%x for x in args])
	    s = "INSERT INTO %s(id) VALUES %s" % (self.name, vallist)
	    cur.execute (s, [])
	else: raise ValueError ("Either 'sql' or 'args' must have a value")
	self.rowcount = cur.rowcount
	cur.connection.commit ()

	  # We have to vacuum the table, or queries based on joins
	  # with it may run extrordinarily slowly.  AutoCommit must 
	  # be on to do this.
	ac = cur.connection.isolation_level	    # Save current AutoCommit setting.
	cur.connection.set_isolation_level (0)      # Turn AutoCommit on
	cur.execute ("VACUUM ANALYZE " + self.name) # Do the vacuum.
	cur.connection.set_isolation_level (ac)     # Restore original setting..

    def delete (self):
	#print >>sys.stderr, "Deleting temp table", self.name
	sql = "DROP TABLE %s;" % self.name
	self.cursor.execute (sql, ())
	self.cursor.connection.commit ()

    def __del__ (self):
	self.delete ()

    def mktmpnm (self):
	cset = "abcdefghijklmnopqrstuvwxyz0123456789"
	t =''.join (random.sample(cset,10))
	return "_T" + t


#=======================================================================
class Kwds:
    Tables = {'DIAL':"kwdial", 'FLD' :"kwfld",  'FREQ':"kwfreq", 'GINF':"kwginf",
	      'KINF':"kwkinf", 'LANG':"kwlang", 'MISC':"kwmisc", 'POS' :"kwpos",
	      'RINF':"kwrinf", 'SRC' :"kwsrc",  'STAT':"kwstat", 'XREF':"kwxref",
	      'CINF':"kwcinf"}

    def __init__( self, cursor_or_dirname=None ):
	if cursor_or_dirname is not None:
	    if isinstance (cursor_or_dirname, (str, unicode)):
		self.loadcsv (cursor_or_dirname)
	    else:
		self.loaddb (cursor_or_dirname)

    def loaddb( self, cursor ):
	# Load instance from database.
	for attr,table in self.Tables.items():
	    d = dict(); setattr (self, attr, d)
	    cursor.execute( "SELECT * FROM %s;" % table, ())
	    for record in cursor.fetchall():	
		self.add (attr, record[:3])

    def loadcsv( self, dirname ):
	# Load instance from csv files.
	if dirname[-1] != '/' and dirname[-1] != '\\': dirname += '/'
	for attr,table in self.Tables.items():
	    if table == "kwsrc": continue
	    d = dict(); setattr (self, attr, d)
	    f = open (dirname + table + ".csv")
	    for ln in f:
		if re.match (r'\s*(#.*)?$', ln): continue
		record = (ln.rstrip().split ("\t"))
		self.add (attr, (int(record[0]),record[1],record[2]))
	    f.close()

    def add( self, attr, record ):
	# Add a kw record.
	try: v = getattr (self, attr)
	except AttributeError: 
	    v = {}; setattr (self, attr, v)
	r = DbRow (record[:3], ('id','kw','descr'))
	v[record[0]] = r;  v[record[1]] = r;

    def attrs( self ):
	# Return list of attr name strings.
	return sorted([x for x in self.Tables.keys() if x in dir(self)])

    def recs( self, attr ):
	vt = getattr (self, attr)
	r = [v for k,v in vt.items() if isinstance(k, int)]
	return r

#=======================================================================
# Bits used in the return value of function jstr_classify() below.
KANA=1; HIRAGANA=2; KATAKANA=4; KANJI=8

def jstr_classify (s):
	"""\
	Returns an integer with bits set according to whether
	the indicated type of characters are present in string <s>.
	    1 - Kana (either hiragana or katakana)
	    2 - Hiragana
	    4 - Katakana
	    8 - Kanji
	"""
	r = 0
	for c in s:
	    n = ord (c)
	    if   n >= 0x3040 and n <= 0x309F: r |= (HIRAGANA | KANA)
	    elif n >= 0x30A0 and n <= 0x30FF: r |= (KATAKANA | KANA)
	      # FIXME: FF01-FF5E are full-width ascii chars including
	      #  puctuations.  FF61-FF9F are half width katakana and
	      #  Jpanese puctuations.  D800-DFFF are unicode surrogate
	      #  characters.  How to classify?
	    elif n >= 0x4E00 and n <= 0xFFFF: r |= KANJI
	return r

def pmarks (sqlargs):
	"Create and return a string consisting of N comma-separated "
	"parameter marks, where N is the number of items in sequence"
	"'sqlargs'.  "

	return ','.join (('%s',) * len (sqlargs))

def dbopts (opts):
	# Convenience function for converting database-related
	# OptionParser options to the keyword dictionary required
	# by dbOpen().

	openargs = {}
	if opts.user: openargs['user'] = opts.user
	if opts.password: openargs['password'] = opts.password
	if opts.host: openargs['host'] = opts.host
	return openargs

import psycopg2 
import psycopg2.extensions
dbapi = psycopg2
def dbOpen (dbname, **kwds):
	"""\
	Open a DBAPI cursor to a jmdict database and initialize
	a Kwds instance with the name KW.

	dbOpen() accepts all the same keyword (only) arguments that 
	the underlying dbapi connect() call takes ('user', 'host',
	'port', etc., and such are passed on to it), and takes two
	additional ones:

	    autocommit -- If true puts the connection in "autocommit"
		mode.  If false or not given, the connection is opened
		in the dbapi or driver default mode.  For psycopg2, 
		"autocommit=True" is the same as "isolation=0".
	    isolation -- if given and not None, connection is opened 
		at the isolation level given.  Choices are:
		  0 -- psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT
		  1 -- psycopg2.extensions.ISOLATION_LEVEL_READ_COMMITTED
		    or psycopg2.extensions.ISOLATION_LEVEL_READ_UNCOMMITTED
		  2 -- psycopg2.extensions.ISOLATION_LEVEL_REPEATABLE_READ
		    or psycopg2.extensions.ISOLATION_LEVEL_SERIALIZABLE
		Note that the last two levels (1, 2) correspond to
		Postgresql's isolation levels but the first (0) is
		implemented purely within psycopg2.

	Only one of autocommit and isolation may be non-None.
	It also accepts one other keyword argument:

	    nokw -- Suppress the reading of keyword data from the
		database and the creation of the jdb.KW variable.
		Note that many other api functions refer to this 
		variable so if you suppress it's creation you are
		responsible for creating it yourself, or not using
		any api functions that use it."""
 
	  # Copy kwds dict since we are going to modify the copy.

	kwargs = dict (kwds)

	  # Extract from the parameter kwargs those which are strictly
	  # of local intest, them delete them from kwargs to prevent
	  # them from being passed on to the dbapi.connect() call
	  # which may object to parameters it does not know about.

	autocommit = kwargs.get('autocommit'); 
	if 'autocommit' in kwargs: del kwargs['autocommit']
	isolation = kwargs.get('isolation'); 
	if 'isolation' in kwargs: del kwargs['isolation']
	nokw = kwargs.get('nokw'); 
	if 'nokw' in kwargs: del kwargs['nokw']
	if isolation is not None and autocommit:
	    raise ValueError ("Only one of 'autocommit' and 'isolation' may be given.")

	if dbname: kwargs['database'] = dbname

	conn = psycopg2.connect (**kwargs)

	  # Magic psycopg2 incantation to ask the dbapi gods to return 
	  # a unicode object rather than a utf-8 encoded str.

        psycopg2.extensions.register_type(psycopg2.extensions.UNICODE)

	if autocommit: isolation = 0	# 0 = ISOLATION_LEVEL_AUTOCOMMIT
	if isolation is not None:
	    conn.set_isolation_level(isolation) 

	  # Most of the the jdb api expects jdb.KW to point to a
	  # jdb.Kwds() object (not to be confused with the kwds
	  # (lowercase "k") parameter of this function) initialized
	  # from the current database connection.  
	  # Since KW is so widely used a global seemed like the best,
	  # although still poor, solution.  Do it here to eliminate a
	  # small piece of boilerplate code in every application program.
	  # For those few that don't need/want it, conditionalize with
	  # a parameter.  If connecting to a database in which the kw*
	  # tables don't exist (e.g. for testing or in tools that will
	  # create the database)` ignore the error that will result
	  # when Kwds.__init_() tries to read non-existent tables.

	if not nokw:
	    global KW
	    try: KW = Kwds (conn.cursor())
	    except dbapi.ProgrammingError: pass
	return conn.cursor()

def iif (c, a, b):
	"""Stupid Python!"""
	if c: return a
	return b

def uord (s):
	"""More stupid Python!  Despite the fact that Python-2.5's
	unichr() function produces unicode surrogate pairs (on Windows)
	it's ord() function throws an error when given such a pair!"""

	if len (s) != 2: return ord (s)
	s0n = ord (s[0]); s1n = ord (s[1]) 
	if (s0n < 0xD800 or s0n > 0xDBFF or s1n < 0xDC00 or s1n > 0xDFFF): 
	    raise TypeError ("Illegal surrogate pair")
	n = (((s0n & 0x3FF) << 10) | (s1n & 0x3FF)) + 0x10000
	return n

def first (seq, f, nomatch=None):
	for s in seq:
	    if f(s): return s
	return nomatch


