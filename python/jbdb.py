
# Copyright (c) 2006, Stuart McGraw 
_VERSION_=("$Revision$"[11:-2],"$Date$"[7:-11])

# FIXME: define error class instead of overloading the
#   python's standard errors.

class DbRow (object):
    #-----------------------------------------------------
    """Provides a base class that can be subclassed to 
    model rows from database tables or other query result-
    sets.  The subclass specializes DbRow to describe a 
    particular resultset by defining the following class
    static variables:
        _cols:  A sequence of strings naming the columns
		of the resultset.
	_table: String naming the table this resultset was 
		generated from.  Optional and only required 
		if the insert() method is used.
	_pk:	A sequence of strings naming the columns 
		that constitute the primary key for this 
		table.
	_related: (Optional) A sequence of *classes* 
		representing tables containing foreign keys 
		referencing this table.  Only needed if 
		related data is to be loaded with this data.  
		Note that the class defining the fk will 
		usually have a "_parent" attribute naming 
		this class.
		FIXME: DbRow assumes that the foreign key 
		column has the same name as the parent table.
	_auto:  (Optional) If there is a auto-increment (aka
		"counter" or "serial") column, this should be 
		set to its name (string).
	_parent: (Optional) If this is a child table of another 
		table (i.e. has a foreign key referencing 
		the pk of the parent table) then this string
		names that table.
		Hack: DbRow assumes that the foreign key 
		column has the same name as the parent table."""
    #-----------------------------------------------------

    def __init__(self, values=None):
	# No argument means, create an empty instance with
	# all trhe column values set to None.  Otherwise the
	# argument is a sequence of N values, where N is the 
	# number of columns in the corresponding table (same
	# as len(self._cols).)

	if values is None: values = [None] * len(self._cols)
        if len(values) != len(self._cols):
            raise ValueError("%s() expects an iterable with %s items" %
                             (self.__class__.__name__, len(self._cols)))
	for n,v in zip (self._cols, values): setattr (self, n, v)
	  # Initialize all the "related" attributes...
	if hasattr (self, "_related"):
	    for k in self._related: setattr( self, k._table, [] )
    def __getitem__ (self, idx): return getattr (self, self._cols[idx])
    def __setitem__ (self, idx, value):
	name = self._cols[idx]
	setattr (self, name, value)
    def __len__(self): return len(self._cols)
    def __iter__(self):
	for n in self._cols: yield getattr (self, n)
	raise StopIteration
    def __repr__ (self):
	vals = [repr (getattr (self, c)) for c in self._cols]
	return "%s((%s))" % (str(self.__class__.__name__), ",".join (vals))

    def _read (self, cursor, pkvals=None):

	# Set the data in this object by reading a row from 
	# the corresponding table in the database opened by
	# <cursor>.  Any existing data is overwritten.
	# The row read is identified my the the primary key
	# values is <pkvals> which is a sequence, allowing
	# multi-column primary keys.  As a convenience, a 
	# single scalar value may be given, in the common
	# case where there is a single column pk.  
	# If there are any related tables, (i.e., self._related
	# exists and is non-empty) they will be read recursively.
	#
	# WARNING: This is not an efficient way to read a large
	# number of entries.  

	if pkvals is None: 
	    pkvals = [getattr (self, x) for x in self._pk]

	# If pkvals is a scalar, turn it into a list.  It is a scalar
	# FIXME: the test for scalar-ness breaks if pkval is a string.
	# I don't use and string pk's yet so I haven't fixed this. 

	if not hasattr (pkvals, "__iter__") and not \
	       hasattr (pkvals, "__getitem__"): pkvals = [pkvals]
	whr = " AND ".join ([x+"=%s" for x in self._pk])
	if not hasattr(self, "_ord") or not self._ord: ordby = ""
	else: ordby = " ORDER BY " + self._ord
	sql = "SELECT * FROM %s WHERE %s%s" % (self._table, whr, ordby)
	cursor.execute (sql, pkvals)
	rs = cursor.fetchmany(2);  
	if len(rs) > 1: raise RuntimeError("Multiple rows received!")
	# FIXME: What to do when len(rs)==0?  Return unchanged self? 
	#  return self.__init__(None)? Return None?  Raise error?
	if len(rs) == 0: rs = None

	# Use our own .__init__() method because that alse sets
	# attributes properly.

	else: self.__init__( rs[0] )

	# Now recusively create and attach lists of any related 
	# rows in other tables.

	self._readrel (cursor)
	if hasattr (self, "related"):
	    for cls in self.related: self._readrel (cursor, cls, pk)
	return self  # So that things like x=Entr()._read(...) will work.

    def _readrel (self, cursor):
	if not hasattr (self, "_related") or not self._related: return
	pk = [getattr (self, x) for x in self._pk]
	for cls in self._related:
	    tbl = cls._table;  fk = cls._parent
	    if not hasattr(cls, "_ord") or not cls._ord: ordby = ""
	    else: ordby = " ORDER BY " + cls._ord
	    sql = "SELECT * FROM %s WHERE %s=%%s%s" % (tbl, fk, ordby)
	    cursor.execute (sql, pk)
	    lst = [];  setattr (self, tbl, lst)
	    for r in cursor.fetchall():
		o = cls (r);  lst.append (o)
		o._readrel (cursor)

    def _insert (self, cursor, parent=None):
	# Insert this object, and any related child objects, into
	# new rows in the appropriate database tables.
	#
	# WARNING: This is not an efficient way to insert a large
	# number of entries.  

	cols = self._cols
	if parent is not None and parent != 0 and hasattr (self, "_parent"):
	    setattr (self, self._parent, parent)

	# Get the column names (intersection of the cols defined
	# for this table, and the attributes actually on this object).
	attrs = [x for x in cols if hasattr (self, x)]

	# ...and a value (to be inserted) for each column.  If the 
	# column name is a "_useid" column, then it if a reference 
	# to an object whose id we we use.  Otherwise, it is the
	# the value of the attribute itself.

	vals = [];  bind = []
	for x in attrs:
	    val = getattr (self, x)
	    if hasattr (self, "_auto") and x == self._auto and val == 0:
		bind.append ("DEFAULT")
	    else:
		vals.append (val)
		bind.append ("%s")

	# Create the sql statement text.

	sql = "INSERT INTO %s(%s) VALUES(%s);" \
		% (self._table, ",".join(attrs), ",".join(bind) )

	# Do it, and a sanity check.

	#print "%s; %s" % (sql, str(vals));  n = 1
	cursor.execute (sql, vals);  n = cursor.rowcount
	if n < 1: raise RuntimeError( "No rows inserted" )
	if n > 1: raise RuntimeError( "Multiple rows inserted" )

	# If we have an "_auto" column, retrieve the value it
	# got set to because we need it for the child table rows.

	id = None
	if hasattr (self, "_auto") and self._auto: 
	    id = cursor.lastauto ()
	    # Update the row object's auto number attribute  
	    # with the value that was assigned in the table.
	    setattr (self, self._auto, id)

	# Insert child table data recursively...

	if hasattr (self, "_related"):
	    attrs = dir (self)
	    related = [x for x in self._related if x._table in attrs]
	    for rel in related:
		objs = getattr (self, rel._table)
		for o in objs: o._insert (cursor, parent=id)

	# Return the auto_id number in case caller wants to know.

	return id

#======================================================================

class Kwds:
    # Instances of this object will read in data from the 
    # jbdb database keyword keyword tables when the instance
    # is created, and make it available in either atrribute 
    # ".something") of dictionary ("['something']") form.
    # The indexing hierarchy is:
    #   Kwds_object / kw table / row / column
    # - The kw table is named by removing the "kw" from the
    #   table name and capitalizing the rest: kwkinf -> KINF
    #   This name is always an attribute, i.e, kwds.KINF...
    #   will work but kwds['KINF'] won't.
    # - row.  May be either the pk id number, or the the value
    #   of the row's "kw" column and may be specified with
    #   either attribute or indexing syntax.  All three of
    #   these forms work:
    #     kwds.POS[2];  kwds.POS['adj'];  kwds.POS.adj;
    #   Note that some keyword can't be used in attribute
    #   form due to conflict with Python syntax: 
    #     kwds.POS.adj-na 
    #   will fail because the "-" is interpreted as the 
    #   subtraction operator.  
    # - The column can also be indexed by name, with attribute
    #   syntax, or by column number using index syntax:
    #     kwds.POS.adj.descr;  kwds.POS.adj[2]
    # 
    # Example of use:
    # 	>>> cursor = <data base specific object or function>
    #   >>> KW = jbdb.Kwds (cursor)   # Get keyword table data.
    #   >>> kw.KINF[2]
    #   [2, u'io', u'irregular okurigana usage']
    #   >>> kw.KINF['io']
    #   [2, u'io', u'irregular okurigana usage']
    #   >>> kw.KINF.io
    #   [2, u'io', u'irregular okurigana usage']
    #   >>> kw.KINF.io.id
    #   2
    #   >>> kw.KINF.io[0]
    #   2
    #   >>> kw.KINF.io.descr
    #   u'irregular okurigana usage'
    #
    def __init__( self, cursor ):
	for table in ("kwaudit","kwdial","kwfld","kwfreq","kwkinf","kwlang",
		     "kwmisc","kwpos","kwrinf","kwsrc","kwxref",):
	    sql = "SELECT * FROM %s;" % table
	    cursor.execute( sql, ())
	    setattr( self, table[2:].upper(), KwdRow( cursor.fetchall()))
    def __repr__( self ):
	return "<Kwds object (" + \
	  ",".join([nm for nm in dir (self) if nm.isupper()]) + \
	  ") at 0x%08X>" % id(self)

class KwdRow( dict ):
    def __init__( self, rows ):
	for r in rows: self._addrow (r)
    def _addrow (self, r):
	rx = Kwd(r)
	self[rx.id] =  rx;  self[rx.kw] =  rx
	setattr( self, rx.kw, rx)

class Kwd (list):
    def __init__( self, data=None ):
	if len (data) != 3: raise ValueError, "Wrong length"
	self.extend (data)
	self.id = data[0];  self.kw = data[1]; self.descr = data[2]

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
	    elif n >= 0x4E00 and n <= 0x9FFF: r |= KANJI
	return r

def listdiff (a, b, cmp=None):
	# Return those items in list 'a' that are not
	# in list 'b'.  Unlike python's set_difference
	# operator, this preserves the order of items 
	# from 'a'.  If present, 'cmp' should be a function
	# of two arguments that returns 0 if the first 
	# argument is "==" to the second, or non-zero
	# otherwise.  The first argument should be compatible
	# with items in 'a', and the second with items in 
	# 'b'.  It will be use to determine when an 'a'
	# item is in 'b'.  If not supplied, python's "in"
	# operator (based in turn on "==") is used.

	r = []
	for x in a:
	    if cmp:
	        for y in b:
		    if 0 == cmp (x, y): break
		else: r.append (x)
	    else:
		if x not in b: r.append (x)
	return r

def load (cls, cursor, sql, sqlargs):
	# Execute sql statement 'sql' with bound arguments 'sqlargs'
	# Create a new instance of 'cls' for each row, and use the 
	# row data to initialize it.  Return a list of the instances
	# in the same order as the rows.

	cursor.execute (sql, sqlargs)
	rs = cursor.fetchall ()
	return [cls (x) for x in rs]

def build_search_sql (condlist):
	"""\
	Build a sql statement that will find the id numbers of
	all entries matching the conditions given in <condlist>.
	Note: This function does not provide for generating
	arbitrary SQL statements; it is only intented to support 
	limited search capabilities that are typically provided 
	on a search form.

	<condlist> is a list of 3-tuples.  Each 3-tuple specifies
	one condition:
	  0: Name of table that contains the field being searched on.
	  1: Sql snippit that will be AND'd into the WHERE clause.
	    Field names must be qualified by table.  When looking 
	    for a value in a field.  A "?" may (and should) be used 
	    where possible to denote an exectime parameter.  The value
	    to be used when the sql is executed is is provided in
	    the 3rd member of the tuple (see #2 next).
	  2: A sequence of argument values for any exec-time parameters
	    ("?") used in the second value of the tuple (see #1 above).

	Example:
	    [("entr","entr.typ=1", ()),
	     ("gloss", "gloss.text LIKE ?", ("'%'+but+'%'",)),
	     ("pos","pos.kw IN (?,?,?)",(8,18,47))]

	  This will generate the SQL statement and arguments:
	    "SELECT entr.id FROM (((entr INNER JOIN sens ON sens.entr=entr.id) 
		INNER JOIN gloss ON gloss.sens=sens.id) 
		INNER JOIN pos ON pos.sens=sens.id) 
		WHERE entr.typ=1 AND (gloss.text=?) AND (pos IN (?,?,?))"
	    ('but',8,18,47)
	  which will find all entries that have a gloss containing the
	  substring "but" and a sense with a pos (part-of-speech) tagged
	  as a conjunction (pos.kw=8), a particle (18), or an irregular
	  verb (47)."""

	from topsort import topsort 
	rels = {
	    "entr":None, "kana":"entr", "kanj":"entr", "sens":"entr", "gloss": "sens", 
	    "pos":"sens", "misc":"sens", "fld":"sens", "rinf":"kana", "dial":"entr",
	    "rfreq":"kana", "kinf":"kanj", "kfreq":"kanj", "lang":"entr",}

	tables = set(); wclauses = []; args = []
	for tbl,cond,arg in condlist:
	      ##Add tbl, and all of tbl's parents to the table list.
	    while tbl:
		tables.add (tbl)
		tbl = rels[tbl]
	    wclauses.append (cond)
	    args.extend (arg)
	  ##Do a topological sort to put tables in right order. 
	tables = topsort ([(p,t) for t,p in rels.items() if t in tables])[1:]
	frm = mk_from_clause( tables )
	where = " AND ".join (wclauses)
	return "SELECT DISTINCT entr.id FROM %s WHERE %s" % (frm, where), tuple(args)

def mk_from_clause (tables): 
	# Given a list of table in the proper order (parent tables
	# occur in the list before child tables), create a string
	# that can be used in a SQL "FROM" clause that joins all
	# the tables.  We assume that the primary key column of 
	# each parent table is named "id" and the foreign key column
	# of each child table has the same name as the parent table.

	tbls = tables[:];  t0 = tbls.pop(0);  clause = t0 
	for tx in tbls:
	    clause = "%s JOIN %s ON %s.%s=%s.%s" \
		% (clause, tx, tx, t0, t0, "id")
	    clause = "(" + clause + ")"
	    t0 = tx
	return clause
