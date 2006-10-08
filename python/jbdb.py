_VERSION_=("$Revision$"[11:-2],"$Date$"[7:-11])

class DbRow (list):
    #-----------------------------------------------------
    """Provides a base class that can be subclassed to 
    model rows from database tables or other query result-
    sets.  The subclass specializes DbRow to describe a 
    particular resultset by defining the following class
    static variables (only _cols is required):
        _cols:  A sequence of strings naming the columns
		of the resultset.
	_table: String naming the table this resultset
		was generated from.  Optional and only
		required if the insert() method is used.
	_related: A sequence of strings naming (classes
		representing) tables containing foreign 
		keys referencing this table.  Optional
		and only needed if related data is to be
		loaded with this data.  Note that the class
		defining the fk will usually have a "_parent" 
		attribute naming this class.
	_auto:  If there is a auto-increment (aka "counter"
		or "serial") column, this should be set to
		its name (string).
	_parent: If this is a child table of another 
		table (i.e. has a foreign key referencing 
		the pk of the parent table) then this string
		names that table."""
    #-----------------------------------------------------

    def __init__ (self, data=None):
	if data: 
	    self.extend( data )
	    if len( self ) != len( self._cols ): 
		raise ValueError, "Wrong length"
	else: self.extend( [data] * len( self._cols ))
	for c,x in zip (self._cols, data): 
	    if c: setattr (self, c, x)
	if not hasattr (self, "_related"): self._related = []
	for k in self._related: setattr( self, k, [] )

    def _insert (self, cursor, parent=None):
	cols = self._cols
	if parent is not None and parent != 0 and hasattr (self, "_parent"):
	    setattr (self, self._parent, parent)

	# Get the column names (intersection of the cols defined
	# for this table, and the attributes actually on this object).
	attrs = [x for x in self._cols if hasattr (self, x)]

	# ...and a value (to be inserted) for each column.  If the 
	# column name is a "_useid" column, then it if a reference 
	# to an object whose id we we use.  Otherwise, it is the
	# the value of the attribute itself.
	vals = [];  bind = []
	for x in attrs:
	    val = getattr (self, x)
	    if hasattr (self, "_useid") and x in self._useid: 
		val = val.id
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
	    cursor.execute ("SELECT LAST_INSERT_ID();", ())
	    id = (cursor.fetchone ())[0]
	    # Update the row object's auto number attribute  
	    # with the value that was assigned in the table.
	    setattr (self, self._auto, id)

	# Insert child table data recursively...
	related = [x for x in dir (self) if x in self._related]
	for rel in related:
	    objs = getattr (self, rel)
	    for o in objs: o._insert (cursor, parent=id)

	# Return the auto_id number in case caller wants to know,
	return id

    def __repr__ (self):
	args = []
	for c in self._cols: 
	    args.append (repr (getattr (self, c)))
	return "%s(%s)" % (str(self.__class__)[8:-2], ",".join (args))

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


#=======================================================================


class Cursor:
    """\
    This class wraps a Python DBI cursor instance by delegating
    all undefined (in here) operations to the wrapped object.
    The purpose is to allow us to intercept .execute() calls
    so can convert unicode strings to utf fro broken versions
    of MySQLdb."""

  # WARNING....
  # All assignments to instance properties below must be done
  # using the form "self.__dict__['property'] = value" rather
  # that "self.property = value" to avoid an infinite recursion
  # in self.getattr()

    def __init__ (self, conn): 
	self.__dict__['conn'] = conn
	self.__dict__['_cursor_'] = conn.cursor ()
    def execute (self, sql, args=None): 
	if args is None: args = []
	if MySQLdb.__version__ == "1.2.1_p2": pass
	elif MySQLdb.__version__ == "1.2.0":
	    args = self.utf8ize (args)
	    sql = sql.encode("utf8")
	else: raise RuntimeError ("Unprepared for MySQLdb version %s" \
			         % MySQLdb.__version__)
	rc = self.__dict__['_cursor_'].execute (sql, args)
	return rc
    def __getattr__(self, attr):
        return getattr (self._cursor_, attr)
    def __setattr__(self, attr, value):
        return setattr (self._cursor_, attr, value)

    def utf8ize (self, args):
	uargs = []	
	for a in args:
	    if not isinstance (a, unicode): uargs.append (a)
	    else: uargs.append (a.encode("utf-8"))
	return uargs


import MySQLdb
def dbOpen (user="root", pw="", db="jb", host="localhost"):
	if MySQLdb.__version__ == "1.2.1_p2":
            conn = MySQLdb.connect (user=user, passwd=pw, host=host,
                                    db=db, use_unicode=True,
				    charset="utf8")
	else:
            conn = MySQLdb.connect (user=user, passwd=pw, host=host,
                                    db=db, use_unicode=True)
	conn.cursor().execute("SET NAMES 'utf8'")
	conn.charset = "utf-8"
	return Cursor (conn)
