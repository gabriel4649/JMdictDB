import sys
import psycopg2, psycopg2.extras
from psycopg2 import Error, Warning, InterfaceError, DatabaseError, \
    DataError, OperationalError,IntegrityError, InternalError, \
    ProgrammingError, NotSupportedError
dbapi = psycopg2

def connect (dburi, cursors=psycopg2.extras.DictCursor):
        dbargs = parse_pguri (dburi)
        dbconn = dbapi.connect (**dbargs)
        return dbconn

def ex (dbconn, sql, args=(), cursor_factory=psycopg2.extras.DictCursor):
        cur = dbconn.cursor (cursor_factory=cursor_factory)
        cur.execute (sql, args)
        return cur

def query (dbconn, sql, args=(), one=False,
           cursor_factory=psycopg2.extras.DictCursor):
        cur = ex (dbconn, sql, args, cursor_factory=cursor_factory)
        if one: return cur.fetchone()
        else: return cur.fetchall()

def query1 (dbconn, sql, args=(), cursor_factory=psycopg2.extras.DictCursor):
        return query (dbconn, sql, args, one=True,
                      cursor_factory=cursor_factory)

  # When passed as sql argument to a sql statement executed by psycopg2,
  # DEFAULT will result in a postgresql DEFAULT argument.
  # See https://www.postgresql.org/message-id/CA+mi_8ZQx-vMm6PMAw72a0sRATEh3RBXu5rwHHhNNpQk0YHwQg@mail.gmail.com:

class Default(object):
    def __conform__(self, proto):
        if proto is psycopg2.extensions.ISQLQuote: return self
    def getquoted(self): return 'DEFAULT'
DEFAULT = Default()

if sys.version_info.major == 2: import urlparse 
else: import urllib.parse as urlparse

def dburi_norm (dburi, scheme='postgres'):
        o = urlparse.urlsplit (dburi, scheme=scheme)
        scheme, netloc, path, query, fragment = o
        if scheme == 'pg': o = o._replace (scheme='postgres')
        if not netloc:
              # The following is to work around another Python PITA: 
              # urllib treats a "netloc" value of '//' as empty and
              # normalizes it away when it reconstructing the URI.
              # That is, 
              #   >>> urlunsplit (urlsplit('postgres://localhost/jmdict'))
              #   'postgres://localhost/jmdict'
              # returns what one would expect but,
              #   >>> urlunsplit (urlsplit('postgres:///jmdict'))
              #   'postgres:/jmdict'
              # removes the netloc part completely resulting in an invalid
              # Postgresql URI.  To preserve the "//" in the reconstructed
              # URI, there has to be something following it.  We create a
              # random text string (in order to avoid both unintentional
              # and intentional collisions with text in the URI) for this
              # purpose and remove it later to leave the "//" part.
            placeholder = "%012.12x"%random.randint(0,16777215)
            o = o._replace (netloc=placeholder)
        else: placeholder = None
          # Postgresql URI path value may not be relative.  We allow it
          # and change it to absolute here, so that "dbname" is valid and
          # results in "postgres:///dbname".
        if o.path and not o.path.startswith ('/'):
            o = o._replace (path='/' + o.path)
        newuri = o.geturl()
        if placeholder:
            newuri = newuri.replace (placeholder, '')
        return newuri

def dburi_sanitize (dburi):
        '''
        Remove the username and password parts (if either is present)
        from a postgresql database URI string.
        WARNING: UNTESTED
        '''
        scheme, netloc, path, query, frags = urlparse.urlsplit (dburi)
          # Note that this:
          #   o =  urlparse.urlsplit (dburi)
          #   o._replace(netloc'=...)
          # doesn't work.  The 'o' object keeps the username and password
          # as (AFAIK unchangable) attribute values and happily reinserts
          # them when reconstructing the URI, no matter what the netloc
          # value was changed to.
        if '@' in netloc:
              # Use 'rfind' rather than 'find' since the password might
              # contain a '@' character.
            netloc = netloc[1+netloc.rfind ('@'):]
        parts = [scheme, netloc, path, query, frags]
        newuri = urlparse.urlunsplit (parts)
        return newuri

def parse_pguri (uri_string, allow_params=False):
        '''
        Parse a Postgresql URI connection string and return a dict() suitable
        for use as the **kwds argument to psycopg2,connect() or jdb.dbOpen()
        functions.
        For URI syntax see the Postgresql libpq docs for "Connection URIs" in:
          http://www.postgresql.org/docs/current/static/libpq-connect.html#LIBPQ-PARAMKEYWORDS

        Examples:
          postgresql:///jmdict
          pg://localhost:5678/jmdict
        (Note: Allowing "pg" as an abbreviation for "postgresql" on the URI
        scheme designator is our own local enhancement.)

        If <allow_params> is true, any query string in the URI will also be
        parsed and the keyword,value pairs included in the output dict and
        will subsequently be interpreted as additional Postgresql libpq
        keyword,value pairs when passed to Pssycopg2's connect() function
        bt dbOpen().  This in general should only be done if the URI is
        from a trusted source as such parameters can affect things like
        connection timeouts and ssl modes.
        If <allow_params> is false, any query string part of the URI will be
        ignored.
        '''

        result = urlparse.urlsplit (uri_string)
        query = urlparse.parse_qs (result.query)
        scheme = result.scheme
        if not scheme: scheme = 'postgresql'
        if scheme not in ('pg', 'postgresql','postgres'):
            raise ValueError ("Bad scheme name ('%s') in URI: %s" % (result.scheme, uri_string))
          # Add query items to results dict first so that uri parameters added
          #  sencond will overwrite if there are duplicates.
        connargs = query if allow_params else {}
        if result.username: connargs['user']     = result.username
        if result.password: connargs['password'] = result.password
        if result.path:     connargs['database'] = result.path.lstrip('/')
        if result.hostname: connargs['host']     = result.hostname
        if result.port:     connargs['port']     = result.port
        return connargs

def make_pguri (connargs):
        '''
        Convert dict of connection arguments such as is returned from jdb.parse_pguri()
        into a URI string.   The result will always have a scheme, "postgresql:"
        '''
        # Postgresql URI syntax:
        #   postgresql://[user[:password]@][netloc][:port][/dbname][?param1=value1&...]

        # Why, oh why, does urllib not provide better support for this??
        # Its urlunsplit() function does not seem to have any way to accept username
        # password, port, etc.
        auth = connargs.get('user','')
        if auth and connargs.get ('password'): auth += ':' + connargs['password']
        host = connargs.get('host','')
        if connargs.get('port'): host += ':' + str(connargs['port'])
        if auth: host = auth + '@' + host
        q = []
        for k,v in connargs.items():
            if k in ('user','password','database','host','port',): continue
            if not isinstance (v, (list,tuple)): v = [v]
            for vx in v: q.append ("%s=%s" % (k,vx))
        query = '&'.join (q)
        uri = urlparse.urlunsplit (('postgresql',host,connargs.get('database',''),query,''))
        return uri

def require (dbconn, want, table='db'):
        ''' Given a list of update id numbers, return a subset of
        those numbers that are *not* present in the "db" table.
        These will usuable represent database updates that the
        application requires to run correctly but which haven't
        been applied to the database.  If all the required
        updates are present in the database, an empty set is
        returned.

        want -- A list or set of update numbers that we require
            to be in the database's "db" table and have the 
            "active" value set.  May be either 6-digit hexidecimal
            strings or ints.
        Returns: A set of update id (int) numbers in <want> that
            are not in the database "db" table.'''

        cursor = dbconn.cursor()
        want_i = [int(x,16) if isinstance(x, str) else int(x) for x in want]
        sql = "SELECT id FROM %s WHERE id IN %%s AND active" % table
        try: cursor.execute (sql, (tuple(want_i),))
        except dbapi.ProgrammingError as e:
            raise ValueError ("No table '%s', wrong database?" % table)
        have = [x[0] for x in cursor.fetchall()]
        missing = set(want_i) - set(have)
        return missing

def rowget (dbconn, tblname, pkey, cols=None):
    # Get a single row selected by primry key from a named table.
        whr = " AND ".join ([('%s=%%s' % k) for k in pkey.keys()])
        sqlargs = list (pkey.values())
        cols = ','.join (cols) if cols else '*'
        sql = "SELECT %s FROM %s WHERE %s" % (cols, tblname, whr)
        rs = db.query (dbconn, sql, sqlargs)
        if len (rs) > 1:  raise KeyError()
        if len (rs) == 0: return None
        return rs[0]

def rowop (dbconn, tblname, pkey, values, minupd=False,
                   autokey=None, returning=True):
    # Perform a basic IUD (Insert, Update or Delete) operation on
    # a single row identified by primary key on a single table.
    # 'pkey' is a dict whose keys are column names and values 
    # identify the row wanted.
    #   dbconn -- Open DBAPI connection obbject.
    #   tblname -- Name of table.
    #   pkey -- A dict whose key(s) are the name(s) of primary key
    #      column(s) for table 'tblname' and the values identify the
    #      row to be updated.
    #   values -- A dict whose keys are the names of the columns to 
    #      be updated and the values the give the values to update to.
    #   minupd -- If false (default), all column mentioned in values 
    #      will be updated, whether or not the current value in the
    #      database is the same.  In 'minupd' is true, the current row
    #      row will be retrieved for comparison and only those columns
    #      that are different will be updated.  Please be aware of the 
    #      possible concurrency implications of this.
    #   autokey -- Allows insert of new rows with an auto-increment of
    #      of a 2-part composite integer primary key.  A 2-item sequence
    #      comprised of:
    #        - The name of the first column of the primary key.
    #        - The name of the second column of the primary key.
    #      The first column must also be present in 'values'.
    #      The mechanism used is to insert the 1+MAX value of the second
    #      primary key column over the rows matching the first column.
    #      This may result in IntegrityError failures and performance
    #      issues in an environment with many concurrent operations or
    #      high insert rates.
    #   returning -- (bool) if true (default) return
 
    ##  The following explict conversion is not needed if dicts are
    ##  registered with psycopg2 to be automatically adapted to json
    ##  as is currently done in lib/db.py.  See also the ## comments
    ##  in two "sqlargs =" statements below. 
    ##    def A(x): return db.Json(x) if isinstance(x,dict) else x

        if pkey and values:            # Update
            diffs = values
            if minupd:
                currentrow = rowget (dbconn, tblname, pkey)
                if not currentrow:
                    raise KeyError('No row to update in table "%s", pk=%r' % pkey)
                diffs = rowchanges (values, currentrow)
            cols = ','.join(["%s=%%s"%x for x in diffs.keys()])
            sqlargs = list (diffs.values())  ## = [A(x) for x in diffs.values()]
            whr = " AND ".join ([("%s=%%s"%x) for x in pkey.keys()])
            ret = " RETURNING *" if returning else ""
            sqlargs.extend (pkey.values())
            sql = "UPDATE %s SET %s WHERE %s%s" % (tblname, cols, whr, ret)
            if not cols or not whr: sql = None

        elif pkey and not values:      # Delete
            whr = " AND ".join ([("%s=%%s"%x) for x in pkey.keys()])
            sqlargs = list (pkey.values())
            sql = "DELETE FROM %s WHERE %s RETURNING *" % (tblname, whr)
            if not whr: sql = None

        elif not pkey and values:      # Insert
            cols = ','.join(list (values.keys()))
            sqlargs = list(values.values())  ## = [A(x) for x in values.values()]
            pmarks = ','.join (['%s'] * len (sqlargs))
            akexpr = ''
            if autokey: 
                pk1, pk2 = autokey    # Names of the primary key columns.
                if pk1 not in values.keys():  # We must have a value for 
                    raise KeyError (pk1)      #  the first part of the pk.
                akexpr = ',(SELECT 1+COALESCE(MAX(%s),0) FROM %s WHERE %s=%%s)' \
                         % (pk2, tblname, pk1)
                  # 'akexpr', when executed, will be like:
                  #   SELECT 1+MAX(pk2) FROM tblname WHERE pk1=values[pk1]
                  # This is added onto the end of VALUES items.
                cols += ',' + pk2
                sqlargs.append (values[pk1])
            sql = "INSERT INTO %s(%s) VALUES(%s%s) RETURNING *"\
                   % (tblname, cols, pmarks, akexpr)
            if not cols: sql = None

        else:                           # No pkey and no values
            raise ValueError ()

        if not sql: return {}, 0
        cursor = db.sqlex (dbconn, sql, sqlargs)
        rowcount = cursor.rowcount
        if not returning: return rowcount

        rs = cursor.fetchall()
          # If caller specifed a 'pk' that was not in fact a primary 
          # key, more than one record could be affect, which for safety
          # we complain about.
        if len(rs) > 1: raise KeyError ((tblname, pkey))
        if len(rs) == 0: return {}, rowcount
        return rs[0], rowcount

def rowdiff (a, b, raise_missing=False):
        diff = {}; amissing = set(); bmissing = set()
        for k,v in a.items():
            if k not in b: bmissing.add (k)
            else: 
                if b[k] != v: diff[k] = (v,b[k])
        for k,v in b.items():
            if k not in a: amissing.add (k)
        if raise_missing and (amissing or bmissing):
            raise KeyError ((amissing, bmissing))
        if raise_missing: return diff
        return diff, amissing, bmissing

def rowchanges (new, old, raise_missing=False):
          # Return a dict consisting of those items in 'new' that
          # have a value different than in 'old' or don't occur in
          # 'old'.  If 'raise_missing is true, the latter condition
          # will result in an exception instead.
        diff = {}
        for k,v in new.items():
            if k not in old and raise_missing: raise KeyError (k)
            if k not in old or old[k] != v: diff[k] = v
        return diff
