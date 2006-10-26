# db.py for Postgresql-8.x database and psycopg2 interface.

# Copyright (c) 2006, Stuart McGraw 
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
	rc = self.__dict__['_cursor_'].execute (sql, args)
	return rc

    def lastauto (self):
	self.execute ("SELECT LASTVAL();", ())
	return (self.fetchone ())[0]

    def __getattr__(self, attr):
        return getattr (self._cursor_, attr)
    def __setattr__(self, attr, value):
        return setattr (self._cursor_, attr, value)


import psycopg2 
import psycopg2.extensions
dbapi = psycopg2
def dbOpen (*args, **kwds):
	conn = psycopg2.connect (*args, **kwds)
	# Magic incantation to ask the dbapi god to return a 
	# unicode object rather than a utf-8 encoded str.
        psycopg2.extensions.register_type(psycopg2.extensions.UNICODE)
	#conn.set_isolation_level(0) #ISOLATION_LEVEL_AUTOCOMMIT
	return Cursor (conn)
