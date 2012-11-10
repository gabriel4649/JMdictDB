# -*- coding: utf-8 -*-  # non-ascii used in comments only.
#######################################################################
#  This file is part of JMdictDB.
#  Copyright (c) 2006-2011 Stuart McGraw
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


__version__ = ('$Revision$'[11:-2],
               '$Date$'[7:-11]);

import sys, os, os.path, random, re, datetime, operator, \
    warnings
from time import time
from collections import defaultdict
import pylib; from pylib.config import Config
import fmtxml
from objects import *

global KW
Debug = {}

class AuthError (Exception): pass

def dbread (cur, sql, args=None, cols=None, cls=None):
        # Execute a result returning sql statement(s) and return the
        # result set as a list of 'cls' object, one object per row.
        #
        # cur -- Open DBAPI cursor object.
        # args -- (optional) A list of args corresponding to parameter
        #       markers in the sql statement.  May be omitted, None, or
        #       an empty sequence if 'sql' contains no pmarks.
        # cols -- (optional) A list of column names to be used for each
        #       column of the results set.  If not given, the dbapi will
        #       be queried from the column names.
        # cls -- (optional) A class that will be used for row objects.
        #       Must be a class, not a factory function.  If not given,
        #       DbRow will be used.

          # If there are no args, set args (which might be [], or ())
          # to None to avoid bug in psycopg2 (at least version 2.0.7)
          # Specifically, if 'sql' contains a sql wildcard character,
          # '%', the psycopg2 DBAPI will interpret it as a partial
          # parameter marker (it uses "%s" as the parameter marker)
          # and will fail with an IndexError exception if sql_args is
          # an empty list or tuple rather than 'None'.
          # See: http://www.nabble.com/DB-API-corner-case-(psycopg2)-td18774677.html
        if not args: args = None
          # Execute the sql in a try statement to catch any errors.
        try: cur.execute (sql, args)
        except dbapi.Error as e:
              # If the execute failed, append the sql and args to the
              # error message.
            msg = e.args[0] if len(e.args) > 0 else ''
            msg += "\nSQL: %s\nArgs: %r" % (sql, args)
            e.args = [msg] + list(e.args[1:])
              # If a rollback is not done, all subsequent operations on this
              # cursor's connection will (with the psycopg2 DBAPI) result
              # in a InternalError("current transaction is aborted, commands
              # ignored until end of transaction block\n") error.
              # Catch any errors from this operation to prevent them from
              # being raised, rather than the original error.
            try: cur.execute ("ROLLBACK")
            except dbi.Error: pass
            raise       # Re-raise the original error.
          # If not given column name by the caller, get them from the cursor.
        if not cols: cols = [x[0] for x in cur.description]
        v = []
        for r in cur.fetchall ():
              # For each row, create a generic DbRow object...
            x = DbRow (r, cols)
              # ...and coerce it to the desired type.
              # FIXME: is there a cleaner way?...
            if cls: x.__class__ = cls
            v.append (x)
        return v

def dbinsert (dbh, table, cols, row, wantid=False):
        # Insert a row into a database table named by 'table'.
        # coumns that will be used in the INSERT statement are
        # given in list 'cols'.  The values are given in object
        # 'row' which is expected to contain attributes matching
        # the columns listed in 'cols'.

        args = None
        sql = "INSERT INTO %s(%s) VALUES(%s)" \
                % (table, ','.join(cols), pmarks(cols))
          #FIXME: we want to take column values from attributes of 'row'
          # if possible, or sequentially from seq elements if not (i.e.
          # assume a list, tuple, etc), but DbRow objects can be accessed
          # either way.  Access by attribute should assume None if attribute
          # missing so we can't rely on missing attributes to switch to seq
          # access.  For now we will test explicitly for Obj (DbRow is Obj
          # subclass) but this is obviously a hack.

        if isinstance (row, Obj):
            args = [getattr (row, x, None) for x in cols]
        else:
            if len(row) != len(cols): raise ValueError(row)
            args = row
        if not args: raise ValueError (args)
        if Debug.get ('prtsql'): print (repr(sql), repr(args))
        try: dbh.execute (sql, args)
        except Exception as e:
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

def dbexecsp (cursor, sql, args, savepoint_name="sp"):
        # Execute a sql statement with a savepoint.  If the statement succeeds,
        # the savepint is deleted.  If the statement fails, the database state
        # is rolled back to the savepoint and the failure exception reraised.
        cursor.execute ("SAVEPOINT %s" % savepoint_name)
        try:
            cursor.execute (sql, args)
        except dbapi.Error as e:
            cursor.execute ("ROLLBACK TO %s" % savepoint_name)
            raise e
        else:
            cursor.execute ("RELEASE %s" % savepoint_name)

def get_query_cost (cur, sql, sql_args=None):
        # Return Postgresql's idea of the cost of executing the the
        # given sql statement with the given args.  The cost is a
        # float number and in units of estimated disk page fetches.
        # NOTE: This function is Postgresql specific.
        # Ref: See the Postgresql Docs, Section VI (SQL Commands), "EXPLAIN".

          # Wrap the explain execution in a BEGIN/ROLLBACK in case it
          # is (or contains) a statement like "delete" with side effects.
          # Execute within a try/finally to ensure rollback is done, even
          # if an exception is raised.
        cur.execute ("BEGIN")
        try:
            if sql_args == []: sql_args = None
            cur.execute ("EXPLAIN " + sql, sql_args)
            rs = cur.fetchall()
        finally:
            cur.execute ("ROLLBACK")
        if len(rs) < 1:
            raise ValueError ("No results received from postgresql EXPLAIN")
        firstline = rs[0][0]
        mo = re.search (r'cost=(\d+(\.\d+)?)\.\.(\d+(\.\d+)?)', firstline)
        if not mo: raise ValueError ("Unexpected result from postgresql EXPLAIN: %s" % firstline)
        return float (mo.group(3))

def entrFind (cur, sql, args=None):
        if args is None: args = []
        tmptbl = Tmptbl (cur)
        tmptbl.load (sql, args)
        return tmptbl

def entrList (dbh, crit=None, args=None, ord='', tables=None, ret_tuple=False):

        # Return a list of database objects read from the database.
        #
        # dbh -- An open DBI database handle.
        #
        # crit -- Criteria that specifies the entries to be
        #   retrieved and returned.  Is one of three forms:
        #
        #   1. Tmptbl object returned from a call to Find()
        #   2. A sql statement that will give a results set
        #       with one column named "id" containing the entr
        #       id numbers of the desired entries.  The sql
        #       may contain parameter markers which will be
        #       replaced by items for 'args' by the database
        #       driver.
        #   3. None.  'args' is expected to contain a list of
        #       entry id numbers.
        #   3a. (Deprecated) A list of integers or parameter
        #       markers, each an entr id number of an entry
        #       to be returned.
        #
        # args -- (optional) Values that will be bound to any
        #   parameter markers used in 'crit' of forms 2 or 3.
        #   Ignored if form 1 given.
        #
        # ord -- (optional) An ORDER BY specification (without
        #   the "ORDER BY" text) used to order the entries in the
        #   returned list.  When qualifying column names by table,
        #   the entr table has the alias "x", and the 'crit' table
        #   or subselect has the alias "t".
        #   If using a Tmptbl returned by Find() ('crit' form 1),
        #   'ord' is ignored and internally forced to "t.ord".

        t = {}; e = []
        if args is None: args = []
        if not crit and not args: raise ValueError("Either 'crit' or 'args' must have a value.")
        if not crit:
            crit = "SELECT id FROM entr WHERE id IN (%s)" % pmarks(args)
        if isinstance (crit, Tmptbl):
            t = entr_data (dbh, crit.name, args, "t.ord")
        elif isinstance (crit, str):
            t = entr_data (dbh, crit, args, ord, tables)
        else:
            # Deprecated - use 'crit'=None and put a real list in 'args'.
            t = entr_data (dbh, ",".join([str(x) for x in crit]), args, ord, tables)
        if t: e = entr_bld (t)
        if ret_tuple: return e,t
        return e

OrderBy = {
        'rdng':"x.entr,x.rdng",          'kanj':"x.entr,x.kanj",
        'sens':"x.entr,x.sens",          'gloss':"x.entr,x.sens,x.gloss",
        'xref':"x.entr,x.sens,x.xref",   'hist':"x.entr,x.hist",
        'kinf':"x.entr,x.kanj,x.ord",    'rinf':"x.entr,x.rdng,x.ord",
        'pos':"x.entr,x.sens,x.ord",     'misc':"x.entr,x.sens,x.ord",
        'fld':"x.entr,x.sens,x.ord",     'dial':"x.entr,x.sens,x.ord",
        'lsrc':"x.entr,x.sens,x.ord",    'xresolv':"x.entr,x.sens,x.typ,x.ord",
        'restr':"x.entr,x.rdng,x.kanj",
        'stagk':"x.entr,x.sens,x.kanj",  'stagr':"x.entr,x.sens,x.rdng" }

def entr_data (dbh, crit, args=None, ord=None, tables=None):
        #
        # dbh -- An open database handle.
        #
        # crit -- A string that specifies the selection criteria
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
        #       may contain parameter marks which will be bound to
        #       values from 'args'.
        #
        #    3. A list of entry id numbers.  'crit' is one or more
        #       of a number or parameter markers ("?" or "%s"
        #       depending on the DBI interface in use) separated
        #       by commas.  Parameter marks which will be bound to
        #       values from 'args'.
        #
        #    4. Select statement (not in parenthesis).  'crit'
        #       contains space characters and doesn't start with
        #       a double quote or left paren character.
        #       It must produce a result set that includes a column
        #       named "id" that contains the entry id numbers of
        #       the entries to be fetched.  The select statement
        #       may contain parameter marks which will be bound to
        #       values from 'args'.
        #
        #    Formats 1 and 2 above will be joined with a generic
        #    select to retrieve data from the entry object tables.
        #    Forms 3 and 4 will be used in a "WHERE ... IN()"
        #    clause attached the the generic retrieval sql.
        #    When a large number of results are expected, the
        #    latter two formats are likely to be more efficient
        #    than the former two.
        #
        #  args -- A list of values that will be bound to
        #    any parameters marks in 'crit'.
        #
        #  ord -- (optional) string giving an ORDER BY clause
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
            'entr','hist','rdng','rinf','kanj','kinf',
            'sens','gloss','misc','pos','fld','dial','lsrc',
            'restr','stagr','stagk','freq','xref','xrer',
            'rdngsnd','entrsnd','grp','chr','cinf','xresolv')
        if args is None: args = []
        if ord is None: ord = ''
        if re.search (r'^((\d+|\?|%s),)*(\d+|\?|%s)$', crit):
            typ = 'I'                           # id number list
        elif  (crit.startswith ('"')            # quoted table name
                or crit.find(' ')==-1           # no spaces: table name
                or crit.startswith ('(')):      # parenthesised sql
            typ = 'J'
        else: typ ='I'                          # un-parenthesised sql.

        if typ == 'I': tmpl = "SELECT x.* FROM %s x WHERE x.%s IN (%s) %s %s"
        else:          tmpl = "SELECT x.* FROM %s x JOIN %s t ON t.id=x.%s %s %s"

        t = {}
        for tbl in tables:
            key = iif (tbl == "entr", "id", "entr")

            if tbl == "entr": ordby = ord
            else: ordby = OrderBy.get (tbl, "")
            if ordby: ordby = "ORDER BY " + ordby

            if tbl == "xrer":
                tblx = "xref"; key = "xentr"
            else: tblx = tbl
            ##if tblx == "xref": limit = "LIMIT 20"
            ##else: limit = ''
            limit = ''
            # FIXME: cls should not be dependent on lexical table name.
            # FIXME: rename database table "xresolv" to "xrslv".
            if tblx == "xresolv": cls_name = "Xrslv"
            else: cls_name = tblx.title()
            cls = globals()[cls_name]

            if   typ == 'J': sql = tmpl % (tblx, crit, key, ordby, limit)
            elif typ == 'I': sql = tmpl % (tblx, key, crit, ordby, limit)
            try:
                ##start2 = time()
                t[tbl] = dbread (dbh, sql, args, cls=cls)
                ##Debug['table read time, %s'%tbl] = time()start2
            except (psycopg2.ProgrammingError) as e:
                print (e, end='', file=sys.stderr)
                print ('%s %s' % (sql, args), file=sys.stderr)
                dbh.connection.rollback()
        Debug['Obj retrieval time'] = time() - start;
        return t

def entr_bld (t):
        # Put rows from child tables into lists attached to their
        # parent rows, thus building the object structure that
        # application programs will work with.

        entr, rdng, kanj, sens, chr = [t.get (x, [])
                                       for x in ('entr', 'rdng', 'kanj', 'sens', 'chr')]
        mup ('_rdng',  entr, ['id'],          rdng,              ['entr'])
        mup ('_kanj',  entr, ['id'],          kanj,              ['entr'])
        mup ('_sens',  entr, ['id'],          sens,              ['entr'])
        mup ('_hist',  entr, ['id'],          t.get('hist', []), ['entr'])
        mup ('_inf',   rdng, ['entr','rdng'], t.get('rinf', []), ['entr','rdng'])
        mup ('_inf',   kanj, ['entr','kanj'], t.get('kinf', []), ['entr','kanj'])
        mup ('_gloss', sens, ['entr','sens'], t.get('gloss',[]), ['entr','sens'])
        mup ('_pos',   sens, ['entr','sens'], t.get('pos',  []), ['entr','sens'])
        mup ('_misc',  sens, ['entr','sens'], t.get('misc', []), ['entr','sens'])
        mup ('_fld',   sens, ['entr','sens'], t.get('fld',  []), ['entr','sens'])
        mup ('_dial',  sens, ['entr','sens'], t.get('dial', []), ['entr','sens'])
        mup ('_lsrc',  sens, ['entr','sens'], t.get('lsrc', []), ['entr','sens'])
        mup ('_restr', rdng, ['entr','rdng'], t.get('restr',[]), ['entr','rdng'])
        mup ('_restr', kanj, ['entr','kanj'], t.get('restr',[]), ['entr','kanj'])
        mup ('_stagr', sens, ['entr','sens'], t.get('stagr',[]), ['entr','sens'])
        mup ('_stagr', rdng, ['entr','rdng'], t.get('stagr',[]), ['entr','rdng'])
        mup ('_stagk', sens, ['entr','sens'], t.get('stagk',[]), ['entr','sens'])
        mup ('_stagk', kanj, ['entr','kanj'], t.get('stagk',[]), ['entr','kanj'])
        mup ('_freq',  rdng, ['entr','rdng'], [x for x in t.get('freq',[]) if x.rdng],  ['entr','rdng'])
        mup ('_freq',  kanj, ['entr','kanj'], [x for x in t.get('freq',[]) if x.kanj],  ['entr','kanj'])
        mup ('_xref',  sens, ['entr','sens'], t.get('xref', []), ['entr','sens']);
        mup ('_xrer',  sens, ['entr','sens'], t.get('xrer', []), ['xentr','xsens'])
        mup ('_snd',   entr, ['id'],          t.get('entrsnd',[]), ['entr'])
        mup ('_snd',   rdng, ['entr','rdng'], t.get('rdngsnd',[]), ['entr','rdng'])
        mup ('_grp',   entr, ['id'],          t.get('grp',[]),     ['entr'])
        mup ('_cinf',  chr,  ['entr'],        t.get('cinf',[]),    ['entr'])
        if chr: mup ( None, chr, ['entr'], entr, ['id'], 'chr')
        mup ('_xrslv', sens, ['entr','sens'],t.get('xresolv',[]),['entr','sens'])
        return entr

def filt (parents, pks, children, fks):
        # Return a list of all parents (each a hash) in 'parents' that
        # are not matched (in the 'pks'/'fks' sense of lookup()) in
        # 'children'.
        # One use of filt() is to invert the restr, stagr, stagk, etc,
        # lists in order to convert them from the "invalid pair" form
        # used in the database to the "valid pair" form typically needed
        # for display (and visa versa).
        # For example, if 'restr' contains the restr list for a single
        # reading, and 'kanj' is the list of kanji from the same entry,
        # then
        #        filt (kanj, ["kanj"], restr, ["kanj"]);
        # will return a list of kanj hashes that do not occur in 'restr'.

        list = []
        for p in parents:
            if not lookup (children, fks, p, pks): list.append (p)
        return list

def lookup (parents, pks, child, fks, multpk=False):
        # 'parents' is a list of hashes and 'child' a hash.
        # If 'multpk' if false, lookup will return the first
        # element of 'parents' that "matches" 'child'.  A match
        # occurs if the hash values of the parent element identified
        # by the keys named in list of strings 'pks' are "="
        # respectively to the hash values in 'child' corresponding
        # to the keys listed in list of strings 'fks'.
        # If 'multpk' is true, the matching is done the same way but
        # a list of matching parents is returned rather than the
        # first match.  In either case, an empty list is returned
        # if no matches for 'child' are found in 'parents'.

        results = []
        for p in parents:
            if matches (p, pks, child, fks):
                if multpk: results.append (p)
                else: return p
        return results

def matches (parent, pks, child, fks):
        # Return True if the values of the attributes of object 'parent'
        # listed in 'pks' (a list of strings) are equal to the attributes
        # of object 'child' listed in 'fks' (a list of strings).  Otherwise
        # return False.  'pks' and 'fks' should have the same length.

        for pk,fk in zip (pks, fks):
            if getattr (parent, pk) != getattr (child, fk): return False
        return True

def mup (attr, parents, pks, childs, fks, pattr=None):
        # Assign each element of list 'childs' to its matching parent
        # and/or "assign" each parent to each matching child.
        # A parent item and child item "match" when the values of the
        # parent item attributes named in list 'pks' are equal to the
        # child item attributes named in list 'fks'.
        #
        # The child is "assigned" to the parent by adding it to the
        # list in the parent's attribute 'attr', if attr is not None.
        # Alternatively (or in addition) the parent will be "assigned"
        # to each matching child by setting the child's attribute named
        # by pattr, to the parent, if 'pattr' is not None.
        #
        # Note that if both 'attr' and 'pattr' are not None, a reference
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
              # We prevent KeyErrors by using .get() below so that we can build
              # an Entr object even if some of the constitutent records are
              # bad.  That can happen in jmedit.py for example when an Entr
              # object is built from records that are only partially complete
              # of have been changed so that a foreign key refers to rows that
              # are not in the parent row set.
              # The downside is that we do not detect unintentionally bad data
              # rows -- they simply will not appear in the result object.
              # FIXME: why do we skip error checking for the benefit of a
              #   single app?
            for p in (index.get (ckey, [])):
                if attr: getattr (p, attr).append (c)
                if pattr: setattr (c, pattr, p)

#-------------------------------------------------------------------
# The following functions deal with restriction lists.
#-------------------------------------------------------------------
        # Restriction lists limit readings to specific kanji (restr),
        # or senses to specific readings (stagr) or kanji (stagk).
        # In some external representations such as JMdict XML, these
        # restrictions are given as text strings that list the kanji,
        # readings, or kanji that the reading, sense, or sense respectively
        # are limited to, with absence indicating that there are no
        # restrictions.  In the case of "restr" (reading-kanji) restrictions
        # there may also be a "nokanji" flag indicating that there are
        # no kanji associated with the reading.  (The flag is needed
        # since the absence of restr items indicate all kanji are allowable.)
        #
        # In the jdb API, restrictions are represented by lists of Restr
        # objects attached dually to the lists Rdng._restr,Kanj._restr
        # (for reading restrictions), Sens._stagr,Kanj._stagr (for stagr
        # restrictions) or Sens._kanj, and Kanj._stagk (for stagk restrictions).
        # A Restr object exists for each pair of Rdng,Kanj (or Sens,Rdng, or
        # Sens,Kanj) that is *disallowed* (opposite of the XML).  There is
        # in no need for a "nokanji" flag since that condition is effected
        # when every kanji in the entry is given in a rdng object's _restr
        # list.

def find_restr (restrobj, objlist):
        # Given an Restr object, 'restrobj', find the (first[*]) item
        # in 'objlist' list that points (via an item in it's "_restr"
        # list) to 'restrobj'.
        #
        # restrobj -- A Restr object.
        # objlist -- A list of Kanj, Rdng, or Sens objects to search.
        #
        # Returns: A 2-tuple consisting of the found object, and its
        #   0-based index in 'objectlist'.  If 'restrobj' is not found,
        #   a KeyError is raised.
        #
        # [*] In a correctly structured entry, only one 'obj' in 'objlist'
        # will reference a given 'restrobj'.  However it is of course
        # possible to contruct an entry that violates this.
        #
        # Often in entries read from an external source, Restr objects
        # will have .rdng, ,kanj, or .sens attributes that give the
        # index (1-based) of the Rdng, Kanj, or Sens object that contains
        # the Restr object.  However, because the lists are short and
        # constructed entries may not have these values initialized, it
        # is more convenient not to rely on the index values but use this
        # function to search the list for the containing object.

        for n, obj in enumerate (objlist):
            restrlist = getattr (obj, '_restr', [])
            for robj in restrlist:
                if robj is restrobj: return obj, n
        raise KeyError (restrobj)

def find_restrs (restrobjs, objlist):
        # Like find_restr() but first parameter is a list of Restr objects
        # and returns a list of the 2-tuples returned by find_restr().

        return [find_restr(x, objlist) for x in restrobjs]

def restrs2txts (rdng, kanjs, attr='_restr'):
        # Given a Rdng object and a list of Kanj objects from the
        # same entry, return a list of text strings that give the
        # allowed kanji for the reading as determined by the Rdng's
        # ._restr list.
        # This is similar to restrs2ext but returns a list of text
        # strings rather than a list of Kanj objects.

        restrs = getattr (rdng, attr, [])
        if not restrs: return restrs
        if len(restrs) == len(kanjs): return ['no' +
                {'_restr':"kanji", '_stagr':"readings", '_stagk':"kanji"}[attr]]
        return [x.txt for x in restrs2ext_ (restrs, kanjs, attr)]

  #FIXME: fix modules using either of the following two functions
  # function to standardize on one of them and remove the other.
def restrs2ext (rdng, kanjs, attr='_restr'):
        restrs = getattr (rdng, attr, [])
        return restrs2ext_ (restrs, kanjs, attr)

def restrs2ext_ (restrs, kanjs, attr='_restr'):
        # Given a list of Restr objects, 'restr', create a list Kanj
        # objects taken from 'kanjs' such that each Kanj object's
        # ._restr list contains no Restr objects in 'restrs'.  However,
        # if 'restrs' is an empty list, return an empty list.  And if
        # every Kanj object in 'kanjs' has a ._restr list item that
        # in in 'restrs', return None.  Note that common membership
        # of a Restr object in the 'restrs', and kanj._restr lists
        # constitutes a restriction -- the values of the attributes
        # of the Restr objects ('.rdng', .kanj', etc) are ignored.
        #
        # This function can be used in generating restr text when
        # displaying an entry in JMdict XML, JEL, or similar textual
        # output from jdb entry objects.  A return value [] indicates
        # there are no restr's, a return of None indicates "nokanji",
        # and a list of kanji are the "restr" kanji for the reading
        # 'restrs' is from.
        #
        # Although parameter names assume reading-kanji restrictions
        # defined in 'rdng._restr", this function can be used for
        # stagr or stagk restrictions by supplying a Sens object
        # and list of Rdng or Kanj objects respectively for 'rdng'
        # and 'kanj', and setting 'attr' to "_stagr" or "stagk"
        # respectively.
        #
        # restr -- A list of Restr objects on a Rdng (or Sens) object.
        # kanjs -- A list of Kanj (or Rdng) objects.
        # attr -- Name of the attribute on the 'rdng' and 'kanj' object(s)
        #   that contains the restriction list, one of: "_restr", "_stagr",
        #   "_stagk".

        invrestr = []
        if len(restrs) > 0:
              # Check for "nokanji" condition.
              # FIXME: len test only reliable if we assume no dups in 'restrs'.
            if len(restrs) == len(kanjs): return None
            for kanj in kanjs:
                for rk in getattr (kanj, attr, []):
                      # See if restriction 'rk' is in 'restrs'.  "In" here
                      # requires an identity test rather than the equality
                      # test done by the "in" operator, which is the test
                      # used by jdb.isin().  If so, this kanj is not one
                      # that should go into the returned list.
                    if isin (rk, restrs): break
                else:
                      # Get here if no break in above loop, i.e., this kanji
                      # has no restr items in the 'restrs' list.  So we want
                      # this kanji in the returned list.
                    invrestr.append (kanj)
        return invrestr

def add_restrobj (rdng, rattr, kanj, kattr, pattr):
        """
        Create a restriction row object and link it to two items
        that constitute the restriction.

        rdng -- A Rdng, Sens, or Sens object.
        rattr -- One of "rdng", "sens", or "sens".
        kanj -- A Kanj, Rdng, or Kanj object.
        kattr -- One of "kanj", "rdng", or "kanj".
        pattr -- One of "_restr", "_stagr", or "_stagk".

        Examples:
        To create a reading restr:
            add_restr (rdng, 'rdng', kanj, 'kanj', '_restr')
        To create a stagr restr:
            add_restr (sens, 'sens', rdng, 'rdng', '_stagr')
        To create a stagk restr:
            add_restr (sens, 'sens', kanj, 'kanj', '_stagk')
        """
        if not hasattr (rdng, pattr): setattr (rdng, pattr, [])
        if not hasattr (kanj, pattr): setattr (kanj, pattr, [])
          #FIXME: gotta be a better way...
        cls = globals()[pattr[1:].title()]
        restr = cls ()
        setattr (restr, rattr, getattr (rdng, rattr))
        setattr (restr, kattr, getattr (kanj, kattr))
        getattr (rdng, pattr).append (restr)
        getattr (kanj, pattr).append (restr)

def add_restr (rdng, kanj):
        add_restrobj (rdng, 'rdng', kanj, 'kanj', '_restr')
def add_stagr (sens, rdng):
        add_restrobj (sens, 'sens', rdng, 'rdng', '_stagr')
def add_stagk (sens, kanj):
        add_restrobj (sens, 'sens', kanj, 'kanj', '_stagk')

def txt2restr (restrtxts, rdng, kanjs, attr, bad=None):
        # Converts a list of text strings, 'restrtxts', into a list of
        # Restr objects and sets the value of the attribute named by 'attr'
        # on 'rdng' to that list.  Each Restr is also attached to the
        # restr list, 'attr', on the appropriate object in list 'kanjs'.
        #
        # restrtxts -- List of texts (that occur in kanjs) of allowed
        #   restrictions.  However, if 'restrtxts' is empty, there
        #   are no restrictions (all 'kanjs' items are ok.)  If
        #   'restrtxts' is None, every 'kanjs' ietm is disallowed.
        # kanjs -- List of Kanj (or Rdng) objects.
        # attr -- Name of restr list attribute on Kanj objects ('_restr',
        #   'stagr', or 'stagk').
        # bad -- If not none, should be an empty list onto which
        #    will be appended any items in restrtxts that are not
        #    in kanjs.
        # Returns: A list of ints giving the 1-based indexes of the
        #  kanji objects matching the restr list set on 'rdng'.

        if attr == '_restr': restr_factory = Restr
        elif attr == '_stagr': restr_factory = Stagr
        elif attr == '_stagk': restr_factory = Stagk

          # Check that all the restrtxts match a kanjs.
        if bad is not None:
            ktxts = [x.txt for x in kanjs]
            for x in restrtxts:
                if x not in ktxts: bad.append (x)

        restrs = []; nkanjs = []
        if restrtxts or restrtxts is None:
            for n,k in enumerate (kanjs):
                if restrtxts is None or k.txt not in restrtxts:
                    r = restr_factory()
                    restrs.append (r)
                    a = getattr (k, attr, [])
                    if not a: setattr (k, attr, a)
                    a.append (r)
                    nkanjs.append (n + 1)
        setattr (rdng, attr, restrs)
        return nkanjs

def headword (entr):
        # Return a 2-tuple giving the rdng / kanj numbers (base-1)
        # or reading-kanji pair that represents the entry and which
        # takes into consideration restrictions and 'uk' sense
        # tags.  Either element of the 2-tuple, but not both,
        # may be None if a reading of kanji element is not available
        # or not appropriate.
        # FIXME: I don't know how to pick headword.  Since there is
        #  is no mention of "headword" in the JMdict DTD, I am not
        #  even sure what a headword is.  Code below is just a guess.
        rdngs = getattr (entr, '_rdng', [])
        kanjs = getattr (entr, '_kanj', [])
        if not rdngs and not kanjs:
            raise ValueError ("Entry has no readings and no kanji")
        if not rdngs: return None, 1
        if not kanjs: return 1, None

          # If the first reading is "nokanji", return only it.
        if rdngs and len(getattr (rdngs[0], '_restr', [])) \
                  == len(getattr (entr, '_kanj', [])):
            return 1, None

          # If first sense is 'uk', return only first reading.
        uk = KW.MISC['uk'].id in [x.kw for x in
                getattr (getattr (entr, '_sens', [None])[0], '_misc', [])]
        if uk:
            stagr = getattr (entr._sens[0], '_stagr', [])
            for n, r in enumerate (rdngs):
                if not isin (r, stagr): return n+1, None

          # Otherwise return the first reading-kanji pair allowed
          # by restrs, ordering by kanji before selection.
          # FIXME: does not consider stagr, stagk.
        rk = list (restr_expand (rdngs, kanjs))
        rk.sort (key=lambda x: (x[1],x[0]))
        nr, nk = rk[0]
        return nr+1, nk+1

def restr_expand (rdngs, kanjs, attr='_restr'):
        for nr, r in enumerate (rdngs):
            rrestr = getattr (r, attr, [])
            for nk, k in enumerate (kanjs):
                krestr = getattr (k, attr, [])
                invalid = False
                for rx in rrestr:
                    for kx in krestr:
                        if rx is kx:
                            invalid = True;  break
                    if invalid: break
                else:
                    yield nr, nk

#-------------------------------------------------------------------
# The following three functions deal with freq objects.
#-------------------------------------------------------------------

def make_freq_objs (fmap, entr):
        """
        Convert the freq information collected in 'fmap' into Freq
        objects attached to reading and kanji lists in 'entr._rdng'
        and 'entr._kanj'.  'fmap' should be dict.  Items in 'fmap'
        will have keys that are a 2-tuple of freq kw number (eg,
        4 for "spec") and value number (e.g. 2 if the freq item
        was "spec2").  The value of each 'fmap' item is a sequence
        (e.g. list) of length 2, and both of the sequence items are
        lists.  The first is a list of all the Rdng objects which
        have a the freq tag specified by the dict item key.  The
        second is a similar list of Kanj objects.

        Often when parsing a textual description of entries (e.g.
        xml or jel), it will be convenient to define 'fmap' using
        a collections.defauldict, which will automatically create
        the lists when needed:

            fmap = collections.defaultdict (lambda:([list(),list()]))

        and as freq specs are parsed on a reading (or kanji) description,
        they should be added to 'fmap' with something like the following:

            rlist = fmap[kw_val][1]
            if not jdb.first (rlist, lambda x:x is rdng):
                rlist.append (rdng)

        where 'kw_val' is a 2-tuple of freq keyword id and value, and
        'rdng' is a Rdng object to which the freq spec will apply.

        After all the freq data has been collected for an entry, 'entr'
        Freq objects are created by calling:

           errs = make_freq_objs (fmap, entr):
           id errs: print '\n'.join (errs)

        """
          # 'fmap' is a dictionary, keyed by freq tuples (kw-id, value).
          # Each value in 'fmap' is a 2-tuple of lists.  The first list is
          # all the rdng's having that freq, the second is a list of all
          # the kanj's having that freq.  (In most cases the length of
          # each list will be either 0 or 1).

        frecs = {};  errs = []
        for (kw,val),(rdngs,kanjs) in list(fmap.items()):
            #kw, val = parse_freq (freq, '')
            dups = []; repld = []
            if not rdngs:
                for k in kanjs:
                    _freq_bin (None, k, kw, val, frecs, dups, repld)
            elif not kanjs:
                for r in rdngs:
                    _freq_bin (r, None, kw, val, frecs, dups, repld)
            else:
                for r,k in crossprod (rdngs, kanjs):
                    _freq_bin (r, k, kw, val, frecs, dups, repld)
            for r, k, kw, val in dups:
                errs.append (("Duplicate", r, k, kw, val))
            for r, k, kw, val in repld:
                errs.append (("Conflicting", r, k, kw, val))

        for r, k, kw, val in list(frecs.values()):
            fo = Freq (rdng=getattr(r,'rdng',None), kanj=getattr(k,'kanj',None),
                          kw=kw, value=val)
            if r:
                if not hasattr (r, '_freq'): r._freq = []
                r._freq.append (fo)
            if k:
                if not hasattr (k, '_freq'): k._freq = []
                k._freq.append (fo)

        return errs

def _freq_bin (r, k, kw, val, freqs, dups, repld):
        """
        This function takes a freq 2-tuple (freq kw id number,
        freq value) in the context of a specific reading/kanji
        pair (given as the associated Rdng and Kanj objects) and
        puts it into one of three dicts:
          * 'freqs' if the freq item will is selected to go into
            the database.
          * 'dups' if the freq item in a duplicate of one selected
            to go into the database.
          * 'replcd' for freq items that have the same domain (kw
            id) as one going into the database but with a greater
            value (that is, given two freq items, "nf22", and "nf15",
            the "nf15" will go into 'freqs' and "nf22" in 'replcd'
            since they both have the same "nf" domain and the
            latter's value of "22" is greater than the former's
            "15".)

        r -- Rdng object that this freq item is associated with
                 or None.
        k -- Kanj object that this freq item is associated with
                 or None.
        kw -- The id number in table kwfreq of the freq item.
        val -- The value of the freq item.
        freqs -- A dict that will receive freq items selected to go
                into the database.
        dups -- A dict that will receive freq items that are duplicates
                of ones selected to go into the database.
        replcd -- A dict that will receive freq items that are rejected
                because they have the same domain but a higher value as
                one selected to go into the database.
        """
        key = (getattr (r,'txt',None), getattr (k,'txt',None), kw)
        if key in freqs:
            if val < freqs[key]:
                repld.append ((r, k, kw, freqs[key][3]))
            elif val > freqs[key]:
                repld.append ((r, k, kw, val))
            else:
                dups.append ((r, k, kw, val))
        else:
            freqs[key] = (r, k, kw, val)

def freq2txts (freqs):
        flist = []
        for f in freqs:
            kwstr = KW.FREQ[f.kw].kw
            fstr = ('%s%02d' if kwstr=='nf' else '%s%d') % (kwstr, f.value)
            if fstr not in flist: flist.append (fstr)
        return sorted (flist)

def copy_freqs (old_entr, new_entr):
        # Copy the freq objects on the ._rdng and ._kanj lists of
        # Entr object 'old_entr', to Entr object 'new_entr'.  Any
        # preexisting freq items in 'new_entr' are removed.
        #
        # Reading and kanji items are matched between the old
        # and new entries based in their .txt attribute, not
        # their indexed position.  If only a matching reading
        # (or a matching kanji) is found for a Freq object that
        # has both on 'old_entr', the Freq object will be added
        # to the list of the found object only.
        #
        # Duplicate freq objects (ones with the same 'kw' and 'value'
        # values as an existing one on the same 'new_entr' Rdng/Kanj
        # pair) are not copied.
        #
        # Currently copying is by reference; that is, the Freq objects
        # that end up in 'new_entr' are refernces to the corresponding
        # Freq object in 'old_entr', i.e, they are shared.

        dupl = _copy_freqs (old_entr, new_entr)
        del_superfluous_freqs (dupl)

def _copy_freqs (old_entr, new_entr):
          # Invert the freq structure: 'finv' will be a map keyed by
          # every Freq object in 'old_entr' and each value the (Rdng,
          # Kanj) pair the Freq object is in the ._freq list of (or
          # (Rdng,None) or (None,Kanj) if the Freq object is in the
          # ._freq list of only a Rdng or Kanj object rather than a
          #  pair).
        finv = freq_inv (old_entr)
          # Create lookup dicts to map reading (or kanji) text
          # the Rdng (or Kanj) objects having that text.
        rmap = dict(((r.txt, r) for r in new_entr._rdng))
        kmap = dict(((k.txt, k) for k in new_entr._kanj))
        dupl = {}  # Used for checking for duplicates.
          # Erase any existing freq tags in 'new_entr's readings or kanji.
        for r in new_entr._rdng: r._freq = []
        for k in new_entr._kanj: k._freq = []
          # All of 'old_entr's Freq objects are keys in 'finv'.  The
          # value of each 'finv' item is the Rdng object or Kang object
          # the Freq is attached to.  Get each Freq object and its
          # Rng and Kanj objects, and locate the corresponding reading
          # or kanji (by text) on 'new_entr' and attach the Freq object
          # there.
        for f, (r, k) in list(finv.items()):
            rnew = rmap.get (r.txt) if r else None
            knew = kmap.get (k.txt) if k else None
              # Don't add the two Freq with the same (kw,value) to
              # a particular (rnew,knew) reading/kanji combination
              # by recording each added freq in 'dupl' and checking
              # 'dupl' before adding.
              # This does not prevent the addition of "superfluous"
              # freq tags, although the 'dupl' dict is also used
              # later to remove them.  See del_superfluous_freqs()
              # below for definition of "superfluous").
            signature = rnew, knew, f.kw, f.value
            if signature in dupl: continue
              # Because there is currently no need for the copied Freq
              # object in 'new_entr' to be distinct from the corresponding
              # ones in 'old_entr', we simply reference the latter from
              # the former.  If distinct objects are needed, uncomment
              # the next line.
            #f = Freq (kw=f.kw, value=f.value)
            dupl[signature] = f
            if rnew: rnew._freq.append (f)
            if knew: knew._freq.append (f)
        return dupl  # Can be used by caller to remove superfluous freqs.

def del_superfluous_freqs (dupl):
        # Remove superfluous Freq tags from an entry.
        # A superfluous tag is a freq object on a Rdng or Kanj that is
        # not referenced any other Kanj or Rdng, but which has the
        # same value (kw and value attributes) that another Freq object
        # on the same Rdng or Kanj that is refernced by some other Kanj
        # or Rdng.  For example:
        #    ichi1a = Freq (kw=<ichi>, value=1)
        #    ichi1b = Freq (kw=<ichi>, value=1)
        #    entr._rdng[n]._freq.append (ichi1a)
        #    entr._kanj[m]._freq.append (ichi1a)
        #    entr._rdng[n]._freq.append (ichi1b)
        # rdng[n] has two "ichi1" tags, one also referenced by kanj[m]
        # (ichi1a) and referenced by rdng[n] alone.  The latter is
        # superfluous because it will not be shown in any displays
        # (rdng[n] will already be tagged "ichi1" by virtue of the
        # ichi1a object) and if the object is serialized to XML or JEL
        # and recreated, the superfluous object will not be recreated.
        # To avoid cuttering up the database with such unnecessary
        # objects, this function will delete them.
        #
        # 'dupl' is a dict that is created internally by jdb.copy_freqs().
        # Each key is a 4-tuple, (rndg,kanj,kw,val) that is the "signature"
        # of a Freq object:
        #   rdng -- the Rdng object in whose ._freq list the Freq object is,
        #   kanj -- the Kanj object in whose ._freq list the Freq object is,
        #   kw -- the value of the Freq object's .kw attribute.
        #   val -- the value of the Freq object's .value attribute.
        # The value of each dict item is the Freq object itself.

        for (rdng,kanj,kw,val),freq in list(dupl.items()):
            if not rdng or not kanj:
                continue        # Skip any freq items that aren't on both
                                #  a reading and a kanji.
              # For each that has a reading and kanji parent, see if there
              # also exists an equi-valued freq object on the only the same
              # reading, or only on the same kanji and if so, delete it.
            if (rdng,None,kw,val) in dupl:
                del_item_by_ident (rdng._freq, dupl[(rdng,None,kw,val)])
            if (None,kanj,kw,val) in dupl:
                del_item_by_ident (kanj._freq, dupl[(None,kanj,kw,val)])

def freq_inv (entr):
        # Return a dict having keys consisting of all the
        # Freq objects in the Entr, and the value of each key
        # a 2-seq where the first item is the Rdng object
        # on whose ._freq list the Freq object apppears (or
        # None), and the second item is the Kanj object on
        # whose ._freq list the the Freq object appears (or
        # None).  That is, the returned map provides an
        # inversion of the normal k,r -> f access path to
        # f -> k,r.
        #
        # For example, given the following entry:
        #   夏期 [ ichi1] ； 夏季 [ ichi1,news1,nf13]
          #   【 かき [ ichi1,news1,nf13] ； なつき ( 夏季 ) 】
        # the dict returned by freq_inv() would look like:
        #  {Freq(kw=ichi,value=1): [entr._rdng[0], entr._kanj[0]],
        #   Freq(kw=ichi,value=1): [entr._rdng[0], entr._kanj[1]],
        #   Freq(kw=news,value=1): [entr._rdng[0], entr._kanj[1]],
        #   Freq(kw=nf, value=13): [entr._rdng[0], entr._kanj[1]]}
        # The freq objects in the returned dict are references
        # to the actual freq objects in the entry, they are not
        # copies.

        b = {}
          # The assert statements below check that each freq
          # object is on the ._freq list list of no more than
          # one reading and no more than one kanji.  No check
          # is done for duplicate Freq objects (i.e. two different
          # Freq objject ion the same reading and/or kanji but
          # having the same 'kw' and 'value' attributes.)
        for r in entr._rdng:
            for f in r._freq:
                assert f not in b
                b[f] = [r, None]
        for k in entr._kanj:
            for f in k._freq:
                if f in b:
                    assert b[f][1] is None
                    b[f][1] = k
                else: b[f] = [None, k]
        return b

#-------------------------------------------------------------------
# The following four functions deal with xrefs.
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
        # an xref from an existing entry's sense to another existing
        # entry's sense.  It will have attributes 'typ' (attribute type
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
        # is in the form of an "abbreviated" entry object found in the
        # xref attribute "TARG".  The entry object is "abbreviated" in
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

def collect_xrefs (entrs, rev=False):
        # Given a list of Entr objects, 'entrs', collect all the
        # Xref's on their Sens' _xref lists (or _xrer if 'rev' is
        # true) into a single list which is returned, typically so
        # the caller can call augment_xrefs() on them.
        # (The _xref or _xrer lists are not changed.)

        attr = '_xrer' if rev else '_xref'
        xrefs = []
        for e in entrs:
           for s in getattr (e, '_sens', []):
                xrefs.extend (getattr (s, attr, []))
        return xrefs

def augment_xrefs (dbh, xrefs, rev=False):
        # Augment a set of xrefs with extra information about the
        # xrefs' targets.  After augment_xrefs() returns, each xref
        # item in 'xrefs' will have an additional attribute, "TARG"
        # that is a reference to an entr object describing the xref's
        # target entry.  Unlike ordinary entr objects, the TARG objects
        # have only a subset of sub items: they have no _inf, _freq,
        # _hist, _lsrc, _pos, _misc, _fld, _xrer, _restr,
        # _stagr, _stagk, _entrsnd, _edngsnd, lists.

        global Debug; start = time()

        tables = ('entr','rdng','kanj','sens','gloss','xref')
        if rev: attr = 'entr'
        else: attr = 'xentr'
        ids = set ([getattr(x,attr) for x in xrefs])
        if len (ids) > 0:
            elist = entrList (dbh, list(ids), tables=tables)
            mup (None, elist, ['id'], xrefs, [attr], 'TARG')

        Debug['Xrefsum2 retrieval time'] = time() - start

def add_xsens_lists (xrefs, rev=False):
        # Add an ._xsens attribute to the first xref is each
        # set of xrefs with the same .entr, .sens, .typ, .xentr
        # and .notes, that contains a list of all xsens numbers
        # of the xrefs in that set.

        index = {}
        for x in xrefs:
            if not rev:
                key = (x.entr,  x.sens, x.typ, x.xentr, x.notes)
                var = x.xsens
            else:
                key = (x.xentr, x.xsens, x.typ, x.entr,  x.notes)
                var = x.sens
            p = index.get (key, None)
            if p is None:
                x._xsens = [var]
                index[key] = x
            else:
                x._xsens = []
                p._xsens.append (var)

def mark_seq_xrefs (cur, xrefs):
        # Go through the list of xrefs and add a '.SEQ' attribute
        # to any that can be displayed as a seq-type xref, that is
        # the xref group (common entr, sens, typ, note, values)
        # contains xrefs to every active entry of the target's
        # seq number, and the list of target senses for each of
        # those target entries is the same.

          # Get a list of all target xref seq numbers, categorized
          # by corpus (aka src).
        srcseq = defaultdict (set)
        try:
            for x in xrefs: srcseq[x.TARG.src].add (x.TARG.seq)
        except AttributeError:
              # Assume attribute error is due to missing .TARG, presumably
              # because jdb,augment_xrefs() was not called on xrefs.  In
              # this case bail since we can't group by seq number if seq
              # numbers (which are in .TARG entries) aren't available.
            return

          # Get a count of all the "active" entries for each (corpus,
          # seq-number) pair and put in dict 'seq_count' keyed by (corpus,
          # seq) with values being the corresponding counts.
        seq_counts = {};  args = []
        for src,seqs in list(srcseq.items()):
            sql = "SELECT src,seq,COUNT(*) FROM entr " \
                  "WHERE src=%%s AND seq IN(%s) AND stat=%%s GROUP BY src,seq" \
                  % ",".join (["%s"]*len(seqs))
            args.append (seqs)
            cur.execute (sql, [src]+list(seqs)+[KW.STAT['A'].id])
            rs = cur.fetchall()
            for r in rs: seq_counts[(r[0],r[1])] = r[2]
            # 'seq_counts' is now a dict, keyed by (src,seq) 2-tuple and
            # values being the number of active entries with that src,seq.

          # Categorize each xref by source (.entr, .sens, .typ, .notes),
          # then target (corpus, seq), then, sense list.  Gather a count
          # of the number of xrefs per category in dict 'collect'.
          # Don't count any non-active (rejected or deleted) ones,
        collect = defaultdict(lambda:defaultdict(set))
        for x in xrefs:
              # JEL only represents xrefs to stat=A entries.
            if not hasattr (x, 'TARG'): continue
            if x.TARG.stat != KW.STAT['A'].id: continue
            key1 = (x.entr,x.sens,x.typ,x.notes)
            key2 = (x.TARG.src,x.TARG.seq)
            collect[key1][key2].add (x.TARG.id)

          # Go through the xrefs again, skipping non-active ones, and re-
          # categorizing as above, compare to number of xrefs for that
          # category set (counts are in 'collect') with the total number
          # of potential target entries in the database.  If the numbers
          # are equal, there is an xref to every target and we can use a
          # seq-style xref for that set of xrefs and we mark (only) the
          # first xref of each set with a .SEQ attribute.
        marked = defaultdict(lambda:defaultdict(lambda:defaultdict(bool)))
        for x in xrefs:
            if not hasattr (x, 'TARG'): continue
            if x.TARG.stat != KW.STAT['A'].id: continue
            #if getattr (x, 'SEQ', None) is None:
            key1 = (x.entr,x.sens,x.typ,x.notes)
            key2 = (x.TARG.src,x.TARG.seq)
            if len (collect[key1][key2]) == seq_counts[key2]:
                key3 = tuple (getattr (x, '_xsens', (x.xsens,)))
                if marked[key1][key2][key3]:
                    x.SEQ = False
                else:
                    marked[key1][key2][key3] = x.SEQ = True

def resolv_xref (dbh, typ, rtxt, ktxt, slist=None, enum=None, corpid=None,
                 one_entr_only=True, one_sens_only=False, krdetect=False):

        # Find entries and their senses that match 'ktxt','rtxt','enum'.
        # and return a list of augmented xref records that points to
        # them.  If a match is not found (because nothing matches, or
        # the 'one_entr_only' or 'one_sens_only' criteria are not satisfied),
        # a ValueError is raised.
        #
        # dbh (dbapi cursor) -- Handle to open database connection.
        # typ (int) -- Type of reference per table kwxref.
        # rtxt (string or None) -- Cross-ref target(s) must have this
        #   reading text.  May be None if 'ktxt' is non-None, or if
        #   'enum' is non-None.
        # ktxt (string or None) -- Cross-ref target(s) must have this
        #   kanji text.  May be None if 'rtxt' is non-None, or if
        #   'enum' is non-None.
        # slist (list of ints or None) -- Resolved xrefs will be limited
        #   to these target senses.  A Value Error is raised in a sense
        #   is given in 'slist' that does not exist in target entry.
        # enum (int or None) -- If 'corpid' (below) value is non-None
        #   then this parameter is interpreted as a seq number.  Other-
        #   wise it is interpreted as an entry id number.
        # corpid (int or None) -- If given search for target will be
        #   limited to the given corpus, and 'enum' if given will be
        #   interpreted as a seq number.  If None, 'enum' if given
        #   will be interpreted as an entry id number, otherwise,
        #   all entries will be searched for matching ktxt/rtxt.
        # one_entr_only (bool) -- Raise error if xref resolves to more
        #   than one set of entries having the same seq number.  Regard-
        #   less of this value, it is always an error if 'slist' is given
        #   and the xref resolves to more than one set of entries having
        #   the same seq number.
        # one_sens_only (bool) -- Raise error if 'slist' not given and
        #   any of the resolved entries have more than one sense.
        #
        # resolv_xref() returns a list of augmented xrefs (see function
        # augment_xrefs() for description) except each xref has no {entr},
        # {sens}, or {xref} elements, since those will be determined by
        # the parent sense to which the xref will be attached.
        #
        # Prohibited conditions such as resolving to multiple seq sets
        # when the 'one_entr_only' flag is true, are signaled by raising
        # a ValueError.  The caller may want to call resolv_xref() within
        # a "try" block to catch these conditions.

        #FIXME: Use a custom error rather than ValueError to signal
        # resolution failure so the caller can distinguish failure
        # to resolve from a parameter error that causes a ValueError.

        if not rtxt and not ktxt and not enum:
            raise ValueError ("No rtxt, ktxt, or enum value, need at least one.")

          # If there is only one of 'ktxt', 'rtxt', and if 'krdetect' is true,
          # we take it that whichever of 'ktxt', 'rtxt' was given could be
          # be either kanji or reading and we will test and reassign correctly
          # to 'ktxt' or 'rtxt' according to the result.
        if krdetect and (ktxt or rtxt) and not (ktxt and rtxt):
            if ktxt and not jstr_keb (ktxt): ktxt, rtxt = rtxt, ktxt
            if rtxt and     jstr_keb (rtxt): ktxt, rtxt = rtxt, ktxt

          # Build a string for use in error messages.
        krtxt = (ktxt or '') + ('\u30fb' if ktxt and rtxt else '') + (rtxt or '')

          # Build a SQL statement that will find all entries
          # that have a kanji and reading matching 'ktxt' and
          # 'rtxt'.  If further restrictions are necessary (such
          # as limiting the search to entries in a specific
          # corpus), they are given the the 'whr' and 'wargs'
          # parameters.

        condlist = []
        if ktxt: condlist.append (('kanj k', "k.txt=%s", [ktxt]))
        if rtxt: condlist.append (('rdng r', "r.txt=%s", [rtxt]))
          # Exclude Deleted and Rejected entries from consideration.
        condlist.append (('entr e', 'e.stat=%d' % (KW.STAT['A'].id), []))
        if enum and not corpid:
            condlist.append (('entr e', 'e.id=%s', [enum]))
        elif enum and corpid:
            condlist.append (('entr e', 'e.seq=%s AND e.src=%s', [enum,corpid]))
        elif not enum and corpid:
            condlist.append (('entr e', 'e.src=%s', [corpid]))

        sql, sql_args = build_search_sql (condlist)
        tables = ('entr','rdng','kanj','sens','gloss')
        entrs = entrList (dbh, sql, sql_args, tables=tables)

        if not entrs: raise ValueError ('No entry found for cross-reference "%s".' % krtxt)
        seqcnt = len (set ([x.seq for x in entrs]))
        if seqcnt > 1 and (one_entr_only or slist):
            raise ValueError ('Xref "%s": Multiple entries found.' % krtxt)

        # For every target entry, get all it's sense numbers.  We need
        # these for two reasons: 1) If explicit senses were targeted we
        # need to check them against the actual senses. 2) If no explicit
        # target senses were given, then we need them to generate erefs
        # to all the target senses.
        # The code currently assumes that sense numbers of database entries
        # are always sequential and start at 1.

        if slist:
              # The submitter gave some specific senses that the xref will
              # target, so check that they actually exist in the target entry(s).
            for e in entrs:
                snums = len (e._sens); nosens = []
                for s in slist:
                    if s<1 or s>snums:
                        raise ValueError ('Xref "%s": Sense %s not in target id %d.'
                                          % (krtxt, s, e.id))
        else:
              # No specific senses given, so this xref(s) should target every
              # sense in the target entry(s), unless $one_sens_only is true
              # in which case all the xrefs must have only one sense or we
              # raise an error.
            entr_multsens = first (entrs, lambda x: len(x._sens)>1)
            if one_sens_only and entr_multsens:
                raise ValueError ('Xref "%s": Target entry id %d has more than one sense.'
                                  % (krtxt, entr_multsens.id))

          # Create an xref object for each entry/sense.

        xrefs = []
        for e in entrs:
              # All xrefs require an .rtxt and/or.ktxt value which is the
              # position (indexed from 1) of a reading or kanji in the target
              # entry's reading of kanji lists, of the reading or kanji to
              # to be used when displaying the xref.  'nrdng' and 'nkanj'
              # will be set to these positions.

            nrdng = nkanj = None
            if not rtxt and not ktxt:
                  # If no rtxt or ktxt received from caller, then call
                  # headword() which will find reasonable values taking
                  # things like "nokanji", "uk", and other restrictions
                  # into account.  headword() returns rdng/kanj positions
                  # (ints, base-1).
                  # FIXME: 'e' here is an abbreviated Entr without restr
                  #  or misc data, which headword() needs to generate good
                  #  results.  So currently it will just return the numbers
                  #  for the first rdng/kanj.
                nrdng, nkanj = headword (e)

              # If the caller did provide explicit rtxt and/or ktxt strings,
              # find their position in the entry's rdng or kanj lists.
            if rtxt:
                try: nrdng = [x.txt for x in e._rdng].index (rtxt) + 1
                except ValueError: raise ValueError ("No reading '%s' in entry %d" % (rtxt, e.id))
            if ktxt:
                try: nkanj = [x.txt for x in e._kanj].index (ktxt) + 1
                except ValueError: raise ValueError ("No kanji '%s' in entry %d" % (ktxt, e.id))

              # Create an augmented xref for each target sense.
            for s in e._sens:
                if not slist or s.sens in slist:
                    x = Xref (typ=typ, xentr=e.id, xsens=s.sens, rdng=nrdng, kanj=nkanj)
                    x.TARG = e
                    xrefs.append (x)
        return xrefs

#-------------------------------------------------------------------
# The following functions deal with history lists.
#-------------------------------------------------------------------

def add_hist (
    entr,       # Entry object (.stat, .unap, .dfrm must be correctly set).
    pentr,      # Parent of 'entr' (an Entr object) or None if no parent.
    userid,     # Userid from session or None.
    name,       # Submitter's name.
    email,      # Submitter's email address.
    notes,      # Comments for history record.
    refs,       # Reference comments for history record.
    use_parent): # If false, return 'entr' with updated hist including diff.
                # If true, return 'pentr' (or raise error) with updated
                # hist and diff=''.  Latter is used when we want to ignore
                # any changes to the entry made by the submitter, as in when
                # he/she has requested deletion of the entry.
        # Attach history info to an entry.  The history added is the
        # history from entry 'pentr' to which a new history record,
        # generated from the parameters to this function, is appended.
        # Any existing hist on the 'entr' is ignored'.
        # If 'use_parent' is true, the history list is attached to the
        # 'pentr' entry object, and that object returned.  If
        # 'use_parent' is false, the history list is attached to the
        # 'entr' object, and that object returned.

        if pentr and (pentr.id is None or pentr.id != entr.dfrm):
            raise ValueError ("Entr 'drfm' (%s) does not match parent entr id (%s)"
                              % (entr.dfrm, pentr.id))
        if not pentr:
            if entr.dfrm: raise ValueError ("Entr has parent %s but no 'pentr' arg given." \
                                            % (entr.dfrm))
            if use_parent: raise ValueError ("'use_parent' requested but no 'pentr' arg given.")

        h = Obj (dt= datetime.datetime.utcnow().replace(microsecond=0),
                stat=entr.stat, unap=entr.unap, userid=userid, name=name,
                email=email, diff=None, notes=notes, refs=refs)

        e = entr
        if use_parent:
            e = pentr
            e.stat, e.unap, e.dfrm = entr.stat, entr.unap, entr.dfrm
        if pentr:
            e._hist = getattr (pentr, '_hist', [])
        else:
            e._hist = []
        if pentr:
            h.diff = fmtxml.entr_diff (pentr, e, n=0) \
                        if pentr is not e \
                        else ''
        e._hist.append (h)
        return e

#-------------------------------------------------------------------
# The following functions deal with writing entries to a database.
#-------------------------------------------------------------------

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
          # Postgresql function lastval() will contain the auto-assigned
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
            dbinsert (cur, "hist", ['entr','hist','stat','unap','dt','userid','name','email','diff','refs','notes'], h)
        for k in getattr (entr, '_kanj', []):
            dbinsert (cur, "kanj", ['entr','kanj','txt'], k)
            for x in getattr (k, '_inf',   []): dbinsert (cur, "kinf",  ['entr','kanj','ord','kw'], x)
            for x in getattr (k, '_freq',  []):
                                  # Don't write any freq records that have rdng references; since
                                  # the readings have not been written yet, the foreign key constraint
                                  # will be violated and the write will fail.  They will written later
                                  # when the readings are written.
                if not getattr (x,'rdng',None): dbinsert (cur, "freq",  ['entr','rdng','kanj','kw','value'], x)
        for r in getattr (entr, '_rdng', []):
            dbinsert (cur, "rdng", ['entr','rdng','txt'], r)
            for x in getattr (r, '_inf',   []): dbinsert (cur, "rinf",  ['entr','rdng','ord','kw'], x)
            for x in getattr (r, '_restr', []): dbinsert (cur, "restr", ['entr','rdng','kanj'], x)
            for x in getattr (r, '_freq',  []): dbinsert (cur, "freq",  ['entr','rdng','kanj','kw','value'], x)
            for x in getattr (r,   '_snd', []): dbinsert (cur, "rdngsnd", ['entr','rdng','ord','snd'], x)
        for x in freqs:
            dbinsert (cur, "freq",  ['entr','rdng','kanj','kw','value'], x)
        for s in getattr (entr, '_sens'):
            dbinsert (cur, "sens", ['entr','sens','notes'], s)
            for g in getattr (s, '_gloss', []): dbinsert (cur, "gloss", ['entr','sens','gloss','lang','ginf','txt'], g)
            for x in getattr (s, '_pos',   []): dbinsert (cur, "pos",   ['entr','sens','ord','kw'], x)
            for x in getattr (s, '_misc',  []): dbinsert (cur, "misc",  ['entr','sens','ord','kw'], x)
            for x in getattr (s, '_fld',   []): dbinsert (cur, "fld",   ['entr','sens','ord','kw'], x)
            for x in getattr (s, '_dial',  []): dbinsert (cur, "dial",  ['entr','sens','ord','kw'], x)
            for x in getattr (s, '_lsrc',  []): dbinsert (cur, "lsrc",  ['entr','sens','ord','lang','txt','part','wasei'], x)
            for x in getattr (s, '_stagr', []): dbinsert (cur, "stagr", ['entr','sens','rdng'], x)
            for x in getattr (s, '_stagk', []): dbinsert (cur, "stagk", ['entr','sens','kanj'], x)
            for x in getattr (s, '_xref',  []): dbinsert (cur, "xref",  ['entr','sens','xref','typ','xentr','xsens','rdng','kanj','notes'], x)
            for x in getattr (s, '_xrer',  []): dbinsert (cur, "xref",  ['entr','sens','xref','typ','xentr','xsens','rdng','kanj','notes'], x)
            for x in getattr (s, '_xrslv', []): dbinsert (cur,"xresolv",['entr','sens','typ','ord','rtxt','ktxt','tsens','notes','prio'], x)
        for x in getattr (entr, '_snd', []): dbinsert (cur, "entrsnd", ['entr','ord','snd'], x)
        for x in getattr (entr, '_grp', []): dbinsert (cur, "grp",     ['entr','kw','ord'], x)
        if getattr (entr, 'chr', None):
            c = e.chr
            dbinsert (cur, "chr", ['entr','chr','bushu','strokes','freq','grade','jlpt','radname'], c)
            for x in getattr (c, '_cinf',  []): dbinsert (cur, "cinf",  ['entr','kw','value','mctype'], x)
        return eid, entr.seq, entr.src

def setkeys (e, id=0):
          # Set the foreign and primary key values in each record
          # in the entry, 'e'.  If 'id' is provided, it will be used
          # as the entry id number.  Otherwise, it is assumed that
          # the id number has already been set in 'e'.
          # Please note that this function assumes that items with
          # multiple parents such as '_freq', '_restr', etc, are
          # listed under both parents.
        if id!=0: e.id = id
        else: id = e.id
        for n,r in enumerate (getattr (e, '_rdng', [])):
            n += 1; (r.entr, r.rdng) = (id, n)
            for p,x in enumerate (getattr (r, '_inf',   [])): (x.entr, x.rdng, x.ord) = (id, n, p+1)
            for x in getattr (r, '_freq',  []): (x.entr, x.rdng) = (id, n)
            for x in getattr (r, '_restr', []): (x.entr, x.rdng) = (id, n)
            for x in getattr (r, '_stagr', []): (x.entr, x.rdng) = (id, n)
            for m,x in enumerate (getattr (r, '_snd',   [])): (x.entr, x.rdng, x.ord) = (id, n, m+1)
        for n,k in enumerate (getattr (e, '_kanj', [])):
            n += 1; (k.entr, k.kanj) = (id, n)
            for p,x in enumerate (getattr (k, '_inf',   [])): (x.entr, x.kanj, x.ord) = (id, n, p+1)
            for x in getattr (k, '_freq',  []): (x.entr, x.kanj) = (id, n)
            for x in getattr (k, '_restr', []): (x.entr, x.kanj) = (id, n)
            for x in getattr (k, '_stagk', []): (x.entr, x.kanj) = (id, n)
        for n,s in enumerate (getattr (e, '_sens', [])):
            n += 1; (s.entr, s.sens) = (id, n)
            for m,x in enumerate (getattr (s, '_gloss', [])): (x.entr,x.sens,x.gloss) = (id, n, m+1)
            for p,x in enumerate (getattr (s, '_pos',   [])): (x.entr, x.sens, x.ord) = (id, n, p+1)
            for p,x in enumerate (getattr (s, '_misc',  [])): (x.entr, x.sens, x.ord) = (id, n, p+1)
            for p,x in enumerate (getattr (s, '_fld',   [])): (x.entr, x.sens, x.ord) = (id, n, p+1)
            for p,x in enumerate (getattr (s, '_dial',  [])): (x.entr, x.sens, x.ord) = (id, n, p+1)
            for p,x in enumerate (getattr (s, '_lsrc',  [])): (x.entr, x.sens, x.ord) = (id, n, p+1)
            for x in getattr (s, '_stagr', []): (x.entr, x.sens) = (id, n)
            for x in getattr (s, '_stagk', []): (x.entr, x.sens) = (id, n)
            for m,x in enumerate (getattr (s, '_xrslv', [])): (x.entr, x.sens, x.ord) = (id, n, m+1)
            for m,x in enumerate (getattr (s, '_xref',  [])): (x.entr, x.sens, x.xref)= (id, n, m+1)
            for x in getattr (s, '_xrer',  []): (x.xentr, x.xsens) = (id, n)
        for n,x in enumerate (getattr (e, '_snd',  [])): (x.entr, x.ord) = (id, n+1)
        for n,x in enumerate (getattr (e, '_hist', [])): (x.entr,x.hist) = (id, n+1)
        # Note: do not set grp.ord; order is based on position in grp table, not entr._grp list.
        for x in getattr (e, '_grp', []): x.entr = id
        if getattr (e, 'chr', None):
            c = e.chr
            c.entr = id
            for x in getattr (c, '_cinf', []): x.entr = id
        for x in getattr (e, '_krslv', []): x.entr = id

#-------------------------------------------------------------------
# The following functions deal with searches.
#-------------------------------------------------------------------

def build_search_sql (condlist, disjunct=False, allow_empty=False):

        # Build a sql statement that will find the id numbers of
        # all entries matching the conditions given in <condlist>.
        # Note: This function does not provide for generating
        # arbitrary SQL statements; it is only intended to support
        # limited search capabilities that are typically provided
        # on a search form.
        #
        # <condlist> is a list of 3-tuples.  Each 3-tuple specifies
        # one condition:
        #   0: Name of table that contains the field being searched
        #     on.  The name may optionally be followed by a space and
        #     an alias name for the table.  It may also optionally be
        #     preceded (no space) by an asterisk character to indicate
        #     the table should be joined with a LEFT JOIN rather than
        #     the default INNER JOIN.
        #     Caution: if the table is "entr" it *must* have "e" as an
        #     alias, since that alias is expected by the final generated
        #     sql.
        #   1: Sql snippet that will be AND'd into the WHERE clause.
        #     Field names must be qualified by table.  When looking
        #     for a value in a field.  A sql parameter marker ("%s" for
        #     the Postgresql psycopg2 adapter) may (and should) be used
        #     where possible to denote an exec-time parameter.  The value
        #     to be used when the sql is executed is provided in the
        #     3rd member of the tuple (see #2 next).
        #   2: A sequence of argument values for any exec-time parameters
        #     ("%s") used in the second value of the tuple (see #1 above).
        #
        # Example:
        #     [("entr e","e.stat=4", ()),
        #      ("gloss", "gloss.txt LIKE %s", ("'%'+but+'%'",)),
        #      ("pos","pos.kw IN (%s,%s,%s)",(8,18,47))]
        #
        #   This will generate the SQL statement and arguments:
        #     "SELECT e.id FROM (((entr e INNER JOIN sens ON sens.entr=entr.id)
        #       INNER JOIN gloss ON gloss.entr=entr.id)
        #       INNER JOIN pos ON pos.entr=entr.id)
        #       WHERE e.stat=4 AND (gloss.txt=%s) AND (pos IN (%s,%s,%s))"
        #     ('but',8,18,47)
        #   which will find all entries that have a gloss containing the
        #   substring "but" and a sense with a pos (part-of-speech) tagged
        #   as a conjunction (pos.kw=8), a particle (18), or an irregular
        #   verb (47).

        # The following check is to reduce the effect of programming
        # errors that pass an empty condlist, which in turn will result
        # in generating sql that will attempt to retrieve every entry
        # in the database.  It does not guarantee reasonable behavior
        # though: a condlist of [('entr', 'NOT unap', [])] will produce
        # almost the same results.

        if not allow_empty and not condlist:
            raise ValueError ("Empty condlist parameter")

        # 'fclause' will become the FROM clause of the generated sql.  Since
        # all queries will require table "entr" to be included, we start off
        # with that table in the clause.

        fclause = 'entr e'
        regex = re.compile (r'^([*])?(\w+)(\s+(\w+))?$')
        wclauses = [];  args = [];  havejoined = {}

        # Go through the condition list.  For each 3-tuple we will add the
        # table name to the FROM clause, and the where and arguments items
        # to their own arrays.

        for tbl,cond,arg in condlist:

            # To make it easier for code generating condlist's allow
            # them to generate empty cond elements that we skip here.

            if not cond: continue

            # The table name may be preceded by a "*" to indicate that
            # it is to be joined with a LEFT JOIN rather than the usual
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
        #   2 -- "Starts", 'srchtext' matched a leading substring
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
          # To-do: LIKE 'xxx%' doesn't use index unless the argument value
          # is embedded in the sql (which we don't currently do).  When
          # the 'xxx%' is supplied as a separate argument, the query
          # planner (runs when the sql is parsed) can't use index because
          # it doesn't have access to the argument (which is only available
          # when the query is executed) and doesn't know that it is not
          # something like '%xxx'.

        sin = stype = m = 0
        try: sin = int(srchin)
        except ValueError: pass
        try: stype = int(srchtype)
        except ValueError: pass

        if sin==1: m = jstr_classify (srchtext)
        if   sin==3 or (sin==1 and jstr_reb (m)):  tbl,col = 'rdng r%s',  'r%s.txt'
        elif sin==4 or (sin==1 and jstr_gloss(m)): tbl,col = 'gloss g%s', 'g%s.txt'
        elif sin==2 or sin==1:                     tbl,col = 'kanj k%s',  'k%s.txt'
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
        it is longer than half the length of all kw's in the domain.
        If so, return the shorter complement of the given list, along
        with an inversion string, "NOT", which can be used to build
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
            except KeyError as e:
                raise ValueError ("'%s' is not a known %s keyword" % (x, kwtyp))
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
                if is_pj (r): return True
        for k in getattr (entr, '_kanj', []):
            for f in getattr (k, '_freq', []):
                if is_pj (k): return True
        return False

def is_pj (kr):
        """
        Return True if the Kanj or Rdng object, 'kr', meets the
        wwwjdic criteria for a "P" (popular) marker.  Currently
        true if the object has a FREQ tag of "ichi1", "gai1",
        "news1", "spec1".
        """
        #FIXME: I believe J.B. posted a note to the Edict list
        #  saying that spec2 -> P.

        for f in getattr (kr, '_freq', []):
            if f.kw in (1,2,4,7) and f.value == 1: return True
        return False

#-------------------------------------------------------------------
#   The following functions are for accessing entry and reading
#   audio clips.
#-------------------------------------------------------------------

class Snds:
    def __init__ (self, cur):
        self.cur = cur
        sql = "SELECT * FROM sndvol"
        self.vols = dbread (cur, sql)
        sql = "SELECT * FROM sndfile"
        self.sels = dbread (cur, sql)
        mup (None, self.vols,  ['id'], self.sels, ['vol'],  'VOL')

    def augment_snds (sndrecs):
        augment_snds (self.cur, sndrecs, self.sels)

def collect_snds (entrs):
        # Given a list of Entr objects, 'entrs', collect all the
        # snd's on their Entr and Rdng ._snd lists into a single
        # list which is returned, typically so the caller can call
        # augment_snds() on them, for example:
        #   augment_snds (dbh, collect_snds (entrs))
        # (The Entr._snd and Rdng._snd lists are not changed.)

        snds = []
        for e in entrs:
           snds.extend (getattr (e, '_snd', []))
           for r in getattr (e, '_rdng', []):
                snds.extend (getattr (r, '_snd', []))
        return snds

def augment_snds (dbh, snds):
        # Augment a set of snds with extra information about the
        # snds' clips.  After augment_snds() returns, each snd
        # item in 'snds' will have an additional attribute, "CLIP"
        # that is a reference to a Clip object describing the snd's
        # clip information.

        if not snds: return
        sql = "SELECT * FROM vsnd WHERE id IN (%s)" % ','.join(['%s']*len(snds))
        args = [x.snd for x in snds]
        data = dbread (dbh, sql, args,
                       ('id','strt','leng','sfile','sdir','iscd','sdid','trns'))
        mup (None, data, ['id'], snds, ['snd'], 'CLIP')

def xx_augment_snds (cur, sndrecs, sels=None):
        """
        Augments entrsnd or rdngsnd records ('sndrecs') with sound
        objects that describe the sound clip identified in each sndrec
        only by id number.  The augmenting object is attached to each
        sndrec items in attribute 'CLIP'.

        cur -- An open DBAPI cursor to the jmdict database containing
            the sound records of interest.
        sndrecs -- A list of entrsnd or rdngsnd records.
        sels -- If provided, is a list of sound selection (aka file)
            records that have already matched it with volume records.
            If None, the appropriate selection and volume records will
            be read from the database.
        """
        ids = [x.snd for x in sndrecs]
        snds = get_recs (cur, 'snd', ids)
        if sels is not None:
            sels = get_recs (cur, 'sndfile', [x.file for x in t['snd']])
            vols  = get_recs (cur, 'sndvol',  [x.vol  for x in t['sndfile']])
            mup (None, vols,  ['id'], sels, ['vol'],  'VOL')
        mup (None, sels, ['id'], snds, ['file'], 'FILE')
        mup (None, snds, ['id'], sndrecs, ['snd'],  'CLIP')

#@memoize
def get_recs (cur, table, ids):
        s = set (ids)
        sql = "SELECT * FROM %s WHERE id IN (%s)" % (table, ','.join(['%s'] * len (s)))
        rs = dbread (cur, sql, list (s))
        return rs

def iter_snds (cur):
        sql = "SELECT * FROM sndvol"
        vols = dbread (cur, sql)
        sql = "SELECT * FROM sndfile"
        sels = dbread (cur, sql)
        sql = "SELECT * FROM snd"
        snds = dbread (cur, sql)
        mup ('_snd',  sels, ['id'], snds, ['file'], None)
        mup ('_file', vols, ['id'], sels, ['vol'],  None)
        return vols, sels, snds

class Kwds:
    """
    This class stores data from the jmdictdb kw* tables.  The
    data in these tables are typically static and small in size,
    so it is efficient to read them once when an app starts.
    This class allows the data to be read either from a jmdictdb
    database, or from kw*.csv files in a directory.  After
    initialization, an instance will have a set of attributes,
    each corresponding to a table.  The value of each will be
    a mapping containing keys that are the tables row's 'id'
    numbers and 'kw' strings.  The keys are distinguishable
    because the former will always be int's and the latter,
    str's.
    The value associated with of each key is a DbRow object
    containing a table row.  Note that because each row in
    indexed under both it's id and kw, there will appear to be
    twice as many rows are there actually are in the corresponding
    table.  Use method .recs() to get a single set of rows.

    Typical use of this class in an app:

        KW = jdb.Kwds (cursor)  # But note this is done by dbOpen().
        KW.POS['adj-na'].id     # => The id number of PoS 'adj-na'.
        KW.DIAL[dialect].descr  # => The description string for
                                #  'dialect'. 'dialect' may be
                                #  either an int id number or kw
                                #  string.

    For the special (but common) case of mapping a kw to an id number,
    each row in a Kwds instance also creates an attribute of the form,
    XXX_kw where XXX of the table identifier, and kw is the kw string.
    The attribute's value is the kw's id number.  For example,

        KW.POS_vt       # => 50.

    If the kw string contains a "-", it is changed to a "_" in the
    attribute:

        KW.POS_adj_na   # => 2
    """

    Tables = {'DIAL':"kwdial", 'FLD' :"kwfld",  'FREQ':"kwfreq", 'GINF':"kwginf",
              'KINF':"kwkinf", 'LANG':"kwlang", 'MISC':"kwmisc", 'POS' :"kwpos",
              'RINF':"kwrinf", 'STAT':"kwstat", 'XREF':"kwxref", 'CINF':"kwcinf",
              'SRC' :"kwsrc",  'GRP':"kwgrp"}

    def __init__( self, cursor_or_dirname=None ):
        # Create and optionally load a Kwds instance.  If
        # 'cursor_or_dirname' is None, an empty instance is
        # created and may be loaded later using the methods
        # loadcsv() or loaddb().  Otherwise 'cursor_or_dirname'
        # should be an open DBI cursor to a jmdictdb database,
        # or a string giving the path to a directory containing
        # kw table csv files.  In the former case, the instance
        # will be loaded from the database's kw tables.  In the
        # latter, from the directory's csv files.
        # You may find function jdb.std_csv_dir() useful for
        # providing a path to call this method with.

          # Add a set of standard attributes to this instance and
          # initialize each to an empty dict.
        failed = []
        for attr,table in list(self.Tables.items()):
            setattr (self, attr, dict())

          # 'cursor_or_dirname' may by a directory name, a database
          # cursor, or None.  If a string, assume the former.
        if isinstance (cursor_or_dirname, str):
            failed = self.loadcsv (cursor_or_dirname)

          # If not None, must be a database cursor.
        elif cursor_or_dirname is not None:
            failed = self.loaddb (cursor_or_dirname)

        if len (failed) >= len (self.Tables):
              # Raise error if no tables were loaded.
            raise IOError ("Failed to load kw tables: %s"
                           % ','.join(failed))

          # Otherwise 'cursor_or_dirname' is None, and we won't
          # load anything, just return the empty instance.

    def loaddb( self, cursor, tables=None ):
        # Load instance from database kw* tables.

        failed = []
        if tables is None: tables = self.Tables
        for attr,table in list(tables.items()):
              # For item in Tables is a attribute name, database table
              # name pair.  Read the table from the database and use
              # method .add() to store the records in attribute 'attr'.
              # If there is a exception (typically because the table
              # does not exist or is not readable due to permissions)
              # catch it and add the table name to the 'failed' list.
            try: recs = dbread (cursor, "SELECT * FROM %s" % table, ())
            except dbapi.ProgrammingError as e:
                failed.append (table)
            else:
                for record in recs: self.add (attr, record)
        return failed

    def loadcsv( self, dirname=None, tables=None ):
        # Load instance from the csv files in directory 'dirname'.
        # If 'dirname' is not supplied or is None, it will default
        # to "../../pg/data/" relative to the location of this module.

        if dirname is None: dirname = std_csv_dir ()
        if tables is None: tables = self.Tables
        if dirname[-1] != '/' and dirname[-1] != '\\' and len(dirname) > 1:
            dirname += '/'
        failed = []
        for attr,table in list(tables.items()):
            fname = dirname + table + ".csv"
            try: f = open (fname, encoding='utf-8')
            except IOError:
                failed.append (table); continue
            for ln in f:
                if re.match (r'\s*(#.*)?$', ln): continue
                fields = ln.rstrip('\n\r').split ("\t")
                fields = [x if x!='' else None for x in fields]
                fields[0] = int (fields[0])
                self.add (attr, fields)
            f.close()
        return failed

    def add( self, attr, row ):
        # Add the row object to the set of rows in the dict in
        # attribute 'attr', indexed by its numeric id and its
        # name (kw).  'row' may be either a DbRow object (such
        # as returned by DbRead), or a seq.  In the latter case
        # only the first three items will be used and they will
        # taken as the 'id', 'kw', and 'descr' values.
        #
        # Additionally, every row added results in the creation
        # of an additional attribute with a name based on 'attr'
        # and the row.kw value separated by a "_" and assigned
        # a value 'row.id'.
        # For example, if 'attr' is "POS", 'row.id' is 50, and
        # 'row.kw' is "vt", then attribute "POS_vt" is created
        # with a value of 50.
        # If the kw string contains a "-" character it is changed
        # to "_" in the attribute name: POS kw "adj-i" results
        # in attribute self.POS_adj_i.

        v = getattr (self, attr)
        if not isinstance (row, (Obj, DbRow)):
            row = DbRow (row[:3], ('id','kw','descr'))
        v[row.id] = row;  v[row.kw] = row;
        shortname = '%s_%s' % (attr, row.kw.replace ('-', '_'))
        setattr (self, shortname, row.id)

    def attrs( self ):
        # Return list of attr name strings for attributes that contain
        # non-empty sets of rows.  Note that this instance will
        # contain every attribute listed in .Tables but some of them
        # may be empty if they haven't been loaded (because the
        # corresponding .csv file of table was missing or empty.)

        return sorted([x for x in list(self.Tables.keys()) if getattr(self, x)])

    def recs( self, attr ):
        # Return a list of DbRow objects representing the rows on the
        # table identified by 'attr'.
        #
        # Example (assuming 'KW' is an initialized Kwds instance):
        #    # Get the rows of the kwpos table:
        #    pos_recs = KW ('POS')

        vt = getattr (self, attr)
        r = [v for k,v in list(vt.items()) if isinstance(k, int)]
        return r

def std_csv_dir ():
        # Return the path to the directory containing the
        # kw table csv data files.  We use the location of
        # of our own module as a reference point.

        our_dir, dummy = os.path.split (__file__)
        if our_dir: our_dir += '/'
        csv_dir = os.path.normpath (our_dir + "../../pg/data")
        return csv_dir

class Tmptbl:
    def __init__ (self, cursor, tbldef=None, temp=True):
        """Create a temporary table in the database.

        cursor -- An open DBAPI cursor that identifies the data-
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
        cursor.execute (sql)
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
            cur.execute (s)
        else: raise ValueError ("Either 'sql' or 'args' must have a value")
        self.rowcount = cur.rowcount
        cur.connection.commit ()

          # We have to vacuum the table, or queries based on joins
          # with it may run extrordinarily slowly.  AutoCommit must
          # be on to do this.
        ac = cur.connection.isolation_level         # Save current AutoCommit setting.
        cur.connection.set_isolation_level (0)      # Turn AutoCommit on
        cur.execute ("VACUUM ANALYZE " + self.name) # Do the vacuum.
        cur.connection.set_isolation_level (ac)     # Restore original setting..

    def delete (self):
        #print >>sys.stderr, "Deleting temp table", self.name
        sql = "DROP TABLE %s;" % self.name
        self.cursor.execute (sql)
        self.cursor.connection.commit ()

    def __del__ (self):
        self.delete ()

    def mktmpnm (self):
        cset = "abcdefghijklmnopqrstuvwxyz0123456789"
        t =''.join (random.sample(cset,10))
        return "_T" + t


#=======================================================================
# Bits used in the return value of function jstr_classify() below.
KANA=1; KANJI=2; KSYM=4; LATIN=16; OTHER=32


def jstr_classify (s):
        """\
        Returns an integer with bits set according to whether
        the certain types of characters are present in string <s>.
        The bit settings are given by constants above.

        See IS-26 and Edict email list posts,
          2008-06-27,"jmdict/jmnedict inconsistency"
          2009-02-26,"Tighter rules for reading fields"
        and followups for details of distinguishing reb text strings,
        and latter particularly for the rationale for the use of
        u+301C (WAVE DASH) rather than u+FF5E (FULLWIDTH TILDE)
        in the JMdict XML file.
          2010-08-14, "keb vs reb (again)" for the justification for
        treating KATAKANA MIDDLE DOT (U+30FB) as a keb rather than
        reb character."""

        r = 0
        for c in s:
            n = uord (c)
            if    n >= 0x0000 and n <= 0x02FF:       r |= LATIN
            elif (n >= 0x3040 and n <= 0x30FF                   # Hiragana/katakana
                  and n != 0x30FB                               #  but not MIDDOT
                  or n == 0x301C):                   r |= KANA  #  or WAVE DASH char.
            elif (n >= 0x3000 and n <= 0x303F                   # CJK Symbols
                  or n == 0x30FB):                   r |= KSYM  #  or MIDDOT.
            elif (n >= 0x4E00 and n <= 0x9FFF                   # CJK Unified.
                  or n >= 0xFF00 and n <= 0xFF5F                # Fullwidth ascii.
                  or n >= 0x20000 and n <= 0x2FFFF): r |= KANJI # CJK Unified ExtB+Supl.
            else:                                    r |= OTHER
        return r

def jstr_reb (s):
        # Return a true value if the string 's' is a valid string
        # for use in an XML <reb> element or 'rdng' table.
        # It must consist exclusively of characters marked as KANA
        # by jstr_classify.

        if isinstance (s, str):
            b = jstr_classify (s)
        else: b = s
        if b == 0: return True  # Empty string.
          # Must not have any characters other than kana and ksyms
          # and must have at least one kana.  (Following expression
          # also used in jstr_keb(); if changed here, change there
          # too.)
        return (b & KANA) and not (b & ~(KANA | KSYM))

def jstr_gloss (s):
        # Return a true value if the string 's' consists only
        # of LATIN characters.
        # FIXME: this won't work in a multi-lingual corpus when we
        #  may have cryllic, or korean, or chinese, etc, glosses.

        if isinstance (s, str):
            b = jstr_classify (s)
        else: b = s
        if b == 0: return True  # Empty string.
          # Must be exclusively latin characters.
        return not (b & ~LATIN)

def jstr_keb (s):
        # Return a true value if the string 's' is acceptable
        # for use in a <keb> element.  This is any string that
        # is not usable as a reb or a gloss.

        if isinstance (s, str):
            b = jstr_classify (s)
        else: b = s
        if b == 0: return True  # Empty string.
          # Any string that does not qualify as a gloss or a
          # reb.  (Expression below intentionally not simplified
          # to facilitate visual verification.)
        return not (
                 (not (b & ~LATIN))     # gloss
                 or
                 ((b & KANA) and not (b & ~(KANA | KSYM)))) #reb


#=======================================================================
import psycopg2
import psycopg2.extensions
dbapi = psycopg2
def dbOpen (dbname_, **kwds):
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
          # of local interest, then delete them from kwargs to prevent
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
        if dbname_: kwargs['database'] = dbname_

          # Remove kwds with None values since psycopg2 doesn't
          # seem to like them.
        nonekwds = [k for k,v in list(kwargs.items()) if v is None]
        for k in nonekwds: del kwargs[k]

        conn = psycopg2.connect (**kwargs)

          # Magic psycopg2 incantation to ask the dbapi gods to return
          # a unicode object rather than a utf-8 encoded str.
        psycopg2.extensions.register_type(psycopg2.extensions.UNICODE)

        if autocommit: isolation = 0    # 0 = ISOLATION_LEVEL_AUTOCOMMIT
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

          # FIXME? Make nokw the default?
        if not nokw:
            global KW
            KW = Kwds (conn.cursor())

        return conn.cursor()

def dbexecute (cur, sql, sql_args):
        # Use this funtion rather than cur.execute() directly.
        # If 'sql' contains a sql wildcard character, '%', the
        # psycopg2 DBAPI will interpret it as a partial parameter
        # marker (it uses "%s" as the parameter marker) and will
        # fail with an IndexError exception if sql_args is '[]'
        # rather than 'None'.  This bug exists in at least
        # psycopg2-2.0.7.
        # See: http://www.nabble.com/DB-API-corner-case-(psycopg2)-td18774677.html
        if not sql_args: sql_args = None
        return cur.execute (sql, sql_args)

def dbopts (opts):
        # Convenience function for converting database-related
        # OptionParser options to the keyword dictionary required
        # by dbOpen().  It is typically used like:
        #
        #   jdb.dbOpen (opts.database, **jdb.dbopts (opts))
        #
        # where opts is a optparse.Options object that may
        # have .database, .host, .user, or .password attributes
        # in addition to other application options.

        openargs = {}
        if opts.user: openargs['user'] = opts.user
        if opts.password: openargs['password'] = opts.password
        if opts.host: openargs['host'] = opts.host
        return openargs

def _extract_hostname (connection):
        # CAUTION: Specific to pyscopg2 DBI cursors.
        dsn = connection.dsn
        dsns = dsn.split()
        strs = [x for x in dsns if x.startswith ('host=')]
        if len (strs) == 0: return ""
        elif len (strs) == 1: return strs[0][5:].strip()
        raise ValueError ("Multiple host specs in dsn: '%s'" % dsn)

def pmarks (sqlargs):
        "Create and return a string consisting of N comma-separated "
        "parameter marks, where N is the number of items in sequence"
        "'sqlargs'.  "

        return ','.join (('%s',) * len (sqlargs))

def cfgOpen (cfgname):
        # Open and parse a config file returning the resulting
        # config.Config() object.  If 'cfgname' contains a path
        # separator character (either a back- or forward-slash)
        # it is treated as a filename.  Otherwise it is a path-
        # less filename that is searched for in sys.path.
        # To explicitly open a file in the current directory
        # without searching sys.path, prefix the filename with
        # "./".

        if '\\' in cfgname or '/' in cfgname:
            fname = cfgname
        else:
            dir = find_in_syspath (cfgname)
            if not dir:
                raise IOError (2, 'File not found on sys.path', cfgname)
            fname = os.path.join (dir, cfgname)
        cfg = pylib.config.Config (fname)
        cfg.__filename__ = fname
        return cfg

def getSvc (cfg, svcname, readonly=False, session=False):
        # Get the authentication values from config.Config
        # instance 'cfg' for a specific database service
        # identified name name 'svcname'.
        # *** CAUTION ***
        # The options returned by this function are specific
        # to the psycopg2 DBAPI.

        cfgsec = cfg['db_' + svcname]
        if session: cfgsec = cfg[cfgsec['session_db']]
        if readonly: user, pw = 'sel_user', 'sel_pw'
        else: user, pw = 'user', 'pw'
        dbopts = {}
        dbopts['database'] = cfgsec['dbname']
        if cfgsec.get (user):   dbopts['user']     = cfgsec[user]
        if cfgsec.get (pw):     dbopts['password'] = cfgsec[pw]
        if cfgsec.get ('host'): dbopts['host']     = cfgsec['host']
        return dbopts

def dbOpenSvc (cfg, svcname, readonly=False, session=False, **kwds):
        # Open the database identified by 'svcname' getting the
        # authenication values from 'cfg' which may be either a
        # config.Config instance or configuration filename.
        # The authenication values are looked for in section
        # "db_"+'svcname'.
        # If 'readonly' is true, open with the read-only user.
        # Otherwise, open the database with the full-access user.
        # If 'session' is true open the session database given in
        # the svcname section rather than the 'svcname' database
        # itself.

        if isinstance (cfg, str): cfg = cfgOpen (cfg)
        dbopts = getSvc (cfg, svcname, readonly, session)
        dbopts.update (kwds)
        cur = dbOpen (None, **dbopts)
        return cur

def iif (c, a, b):
        """Stupid Python! at least prior to 2.5"""
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

_sentinal = object()
def isin (object, seq):
        """Returns True if 'object' is "in" 'seq', when "in" is
        based on object identity (i.e. the "is" operator) rather
        thn equality ("==") as is used by the "in" operator.
        Returns False otherwise.  'object' may be None."""

        return _sentinal is not first (seq, lambda x: x is object, _sentinal)

def del_item_by_ident (list, item):
        """Remove first occurance of 'item' from 'list'.  'item'
        is identified in 'list' by an "is" comparison rather
        than the usual "==" comparison."""

        for i in range (len (list)):
              # We can't use list.index() or the like to find
              # 'f' in 'list' because such method use equality
              # comparisions and we need 'is' to be sure we
              # identify the right object.
            if item is list[i]:
                del list[i]
                break

def unique (key, dupchk):
        """
        key -- A hashable object (i.e. usable as a dict key).
        dupchk -- An (initially empty) mapping object.

        """
        if key in dupchk: return False
        dupchk[key] = 1
        return True

def rmdups (recs, key=None):
        """
        recs -- A list of objects
        key -- None, or a one-parameter function that will be
          called with objects of 'recs' and is expected to return
          an immutable value that identifies "same" objects of
          'recs'.
        Returns: a 2-tuple:
          [0] -- List of unique objects in 'recs' (order preserved).
          [1] -- List of duplicate objects in 'recs'.
        """
        uniq=[]; dups=[]; dupchk={}
        for x in recs:
            if key: k = key (x)
            else: k = x
            if unique (k, dupchk): uniq.append (x)
            else: dups.append (x)
        return uniq, dups

def crossprod (*args):
        """
        Return the cross product of an arbitrary number of lists.
        """
        # From http://aspn.activestate.com/ASPN/Cookbook/Python/Recipe/159975
        # N.B. Could be replaced by itertools.product() in Python-2.6+.
        result = [[]]
        for arg in args:
            result = [x + [y] for x in result for y in arg]
        return result

def find_in_syspath (fname):
        # Search the directories in sys.path for the first occurance
        # of a readable file or directory named fname, and return
        # the sys.path directory in which it was found.

        for d in sys.path:
            if os.access (os.path.join (d, fname), os.R_OK):
                return d or '.'
        return None

def get_dtd (filename, root="JMdict", encoding="UTF-8"):
        with open (filename, encoding=encoding) as f:
            txt = f.read()
            txt %= {'root':root, 'encoding':encoding}
        return txt
