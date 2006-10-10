# db.py for Mysql-5.0 database and MySQLdb interface.

_VERSION_=("$Revision$"[11:-2],"$Date$"[7:-11])

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


import MySQLdb;  dbapi = MySQLdb
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
