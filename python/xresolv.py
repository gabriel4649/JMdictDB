#!/usr/bin/env python3
#######################################################################
#  This file is part of JMdictDB.
#  Copyright (c) 2008,2014 Stuart McGraw
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
#  51 Franklin Street, Fifth Floor, Boston, MA  02110#1301, USA
#######################################################################


__version__ = ('$Revision$'[11:-2],
               '$Date$'[7:-11]);

# This program creates rows in table "xref" based on the
# textual (kanji and kana) xref information saved in table
# "xresolv".  xresolv contains "unresolved" xrefs -- that
# is, xrefs defined only by a kanji/kana text(s) which for
# which there may be zero or multiple target entries..
#
# Each xresolv row contains the entr id and sens number
# of the entry that contained the xref, the type of xref,
# and the xref target entry kanji and or reading, and
# optionally, sense number.
#
# This program searchs for an entry matching the kanji
# and reading and creates one or more xref records using
# the target entry's id number.  The matching process is
# more involved than doing a simple search because a kanji
# xref may match several entries, and our job is to find
# the right one.  This is currently done by a fast but
# inaccurate method that does not take into account restr,
# stagr, and stag restrictions which limit certain reading-
# kanji combinations and thus would make unabiguous some
# xrefs that this program considers ambiguous.  See the
# comments in sub choose_entry() for a description of
# the algorithm.
#
# When an xref text is not found, or multiple candidate
# entries still exist after applying the selection
# algorithm, the fact is reported and that xref skipped.
#
#FIXME: It would be nice to be able to run this program
# incrementally: if an entry has both resolved and unresolved
# xrefs, this program should resolve the unresolved ones and
# use the results to add to the xrefs already present or 
# replace some of those present when the new ones are the 
# "same".  The problem is determining "sameness".  How does
# the xrefs' order number (column 'xref') affect comparison? 

import sys, os, inspect, pdb
_ = os.path.abspath(os.path.split(inspect.getfile(inspect.currentframe()))[0])
_ = os.path.join (os.path.dirname(_), 'python', 'lib')
if _ not in sys.path: sys.path.insert(0, _)

import re
from collections import defaultdict
import jdb

#-----------------------------------------------------------------------

def main (args, opts):
        global Opts
        Opts = opts
          # Debugging flags:
          #  1 -- Print generated xref records.
          #  2 -- Print executed sql.
          #  4 -- Print info about read xresolve records.
        if opts.debug & 0x02: Debug.prtsql = True
        if opts.verbose: opts.keep = True

        try: dbh = jdb.dbOpen (opts.database, **jdb.dbopts(opts))
        except jdb.dbapi.OperationalError as e:
            perr ("Error, unable to connect to database, do you need -u or -p?\n" % str(e))

        try: xref_src = get_src_ids (opts.source_corpus)
        except KeyError: perr ("Unknown corpus: '%s'" % opts.source_corpus)
        try: targ_src = get_src_ids (opts.target_corpus)
        except KeyError: perr ("Unknown corpus: '%s'" % opts.target_corpus)

          #FIXME: need to make work with multiple srcs in targ_src and
          # provide limiting the scope (eg to one src or an entry) of
          # the K/R pairs in the file.
        #krmap = read_krmap (dbh, opts.filename, targ_src)
        krmap = {}

        blksz = 1000
        for xresolv_rows in get_xresolv_block (dbh, blksz, xref_src):
            if not xresolv_rows: break
            resolv (dbh, xresolv_rows, targ_src, krmap)
            if opts.noaction:
                if opts.verbose: print ("ROLLBACK")
                dbh.connection.rollback()
            else:
                if opts.verbose: print ("COMMIT")
                dbh.connection.commit()
        dbh.close()

def get_xresolv_block (dbh, blksz, xref_src, read_xref=False):
        # Read and yield sucessive blocks of 'blksz' rows from table "xresolv"
        # (or, despite our name, table "xref" if 'read_xref' is true).  Rows
        # are ordered by (target) entr id, sens, xref type and xref ord (or 
        # xref.xref for table "xref") and limited to entries having a .src
        # attribute of 'xref_src'.  None is returned when no more rows are
        # available.
        table = "xref" if read_xref else "xresolv"
        lastpos = 0, 0, 0, 0
        while True:
            e0, s0, t0, o0 = lastpos
              # Following sql will read 'blksz' xref rows, starting
              # at 'lastpos' (which is given as a 4-tuple of xresolv.entr,
              # .sens, .typ and .ord).  Note that the result set must be
              # ordered on exactly this same set of values in order to
              # step through them block-wise.
            sql_args = []
            if xref_src:
                srcs, neg = xref_src
                src_condition = "e.src %sIN %%s AND " % ('NOT ' if neg else '')
                sql_args.append (tuple(srcs))
            else: src_condition = ''
            sql = "SELECT v.*,e.src,e.seq,e.stat,e.unap FROM %s v JOIN entr e ON v.entr=e.id " \
                            "WHERE %s" \
                              " (v.entr>%%s OR (v.entr=%%s " \
                               "AND (v.sens>%%s OR (v.sens=%%s " \
                                "AND (v.typ>%%s OR (v.typ=%%s " \
                                 "AND (v.ord>%%s))))))) " \
                            "ORDER BY v.entr,v.sens,v.typ,v.ord " \
                            "LIMIT %s" % (table, src_condition, blksz)
            if read_xref:
                  # If reading the xref rather than the xresolv table make some
                  # adjustments:
                sql = sql.replace ('.ord', '.xref')    # The "ord" field is named "xref".
                t0, o0 = o0, t0  # The typ and xref (aka ord) fields are swapped in xref rows.
            sql_args.extend ([e0,e0,s0,s0,t0,t0,o0])
            rs = jdb.dbread (dbh, sql, sql_args)
            savepoint (dbh, 'CLEAR', '')  # The read seems to invalidate existing savepoints.)
            if len (rs) == 0: return None
            if Opts.debug & 0x04:
                print ("Read %d %s rows from %s" % (len(rs), table, lastpos), file=sys.stderr)
              # Slicing doesn't seem to currently work on DbRow objects or we could 
              #  write "lastpos = rs[-1][0:4]" below.
            lastpos = rs[-1][0], rs[-1][1], rs[-1][2], rs[-1][3]
            yield rs
        assert True, "Unexpected break from loop"
        return

def resolv (dbh, xresolv_rows, targ_src, krmap):

        for v in xresolv_rows:
              # Skip this xref if the "--ignore-nonactive" option was
              # given and the entry is not active (i.e. is deleted or
              # rejected) or is unapproved.  Unapproved entries will
              # be checked during approval submission and unresolved
              # xrefs in rejected/deleted entries are usually moot.
            if Opts.ignore_nonactive and \
                (v.stat != jdb.KW.STAT['A'].id or v.unap): continue
            e = None
            if krmap:
                  # If we have a user supplied map, lookup the xresolv
                  # reading and kanji in it first.
                e = krlookup (krmap, v.rtxt, v.ktxt)

            if not e:
                  # If there was no map, or the xresolv reading/kanji
                  # was not found in it, look in the database for them.
                  # get_entries() will return an abbreviated entry
                  # summary record for each entry that has a matching
                  # reading-kanji pair (if the xresolv rec specifies
                  # both), reading or kanji (if the xresolv rec specifies
                  # one).
                entries = get_entries (dbh, targ_src, v.rtxt, v.ktxt, None)

                  # If we didn't find anything, and we did not have both
                  # a reading and a kanji, try again but search for reading
                  # in kanj table or kanji in rdng table because our idea
                  # of when a string is kanji and when it is a reading still
                  # still does not agree with JMdict's in all cases (IS-26).
                  # This hack will be removed when IS-26 is resolved.

                if not entries and (not v.rtxt or not v.ktxt):
                    entries = get_entries (dbh, targ_src, v.ktxt, v.rtxt, None)

                  # Choose_target() will examine the entries and determine if
                  # if it can narrow the target down to a single entry, which
                  # it will return as a 7-element array (see get_entries() for
                  # description).  If it can't find a unique entry, it takes
                  # care of generating an error message and returns a false value.
                e = choose_target (v, entries)
                if not e: continue

              # Check that the chosen target entry isn't the same as the
              # referring entry.

            if e[0] == v.entr:
                msg (fs(v), "self-referential", kr(v))
                continue

              # Now that we know the target entry, we can create the actual
              # db xref records.  There may be more than one if the target
              # entry has multiple senses and no explicit sense was given
              # in the xresolv record.
            xrefs = mkxrefs (v, e)

            if Opts.verbose and xrefs: prnt (sys.stdout,
                "%s resolved to %d xrefs: %s" % (fs(v),len(xrefs),kr(v)))

              # We may get a "duplicate key" error when trying to add
              # an xref for this xresolv row if the xref already exists
              # (perhaps due having previously run this program with the
              # --keep option).  If that happens we will write an error
              # message but want to contine processing the rest of the
              # xresolv rows.  Postgresql will not allow continuing after
              # an error without a ROLLBACK but a full rollback will undo
              # all the xrefs we've written so far.  Instead we will create
              # a savepoint that we can rollback to that will undo only
              # the xrefs created for this xresolv row.
            savepoint (dbh, "CREATE", "sp1")
              # Write each xref record to the database...
            failed = False
            for x in xrefs:
                  # We don't need 'failed=False' here because the 'for' loop is
                  # always exited below the first time 'failed' is set to True.
                if Opts.debug & 0x01:
                    prnt (sys.stderr, "not yet"
                    )#      "(x.entr,x.sens,x.xref,x.typ,x.xentr"
                    #           .  "x.xsens}," . (x.rdng}||"") . "," . (x.kanj}||"")
                    #           . ",x.notes})\n")
                try:
                    sql = "INSERT INTO xref VALUES(%s,%s,%s,%s,%s,%s,%s,%s,%s)"
                    dbh.execute (sql, (x.entr,x.sens,x.xref,x.typ,x.xentr,
                                       x.xsens,x.rdng,x.kanj,None))
                except jdb.dbapi.IntegrityError as e:
                    if "duplicate key value" not in str(e):
                          # If some exception other than a duplicate key
                          #  error then reraise it.
                          #FIXME? should we release savepoint sp1 here?
                        raise
                      # Format and print a warning message.
                    mo = re.search (r'\(.+\)', str(e), flags=re.I)
                      # An 'mo' that is None here (causing an AttributeError
                      #  exception) indicates the exception text was not what
                      #  we expected.
                    prnt (sys.stderr, "%s duplicate key: %s"
                                      % (fs(v), mo.group(0)))
                      # Postgresql won't continue after an error.
                      #  A ROLLBACK would allow it to continue but we would
                      #  lose all the previous xrefs that have been written
                      #  but not commited.  Rolling back to the savepoint
                      #  created just before the INSERT is what's needed.
                    dbh.execute ("ROLLBACK TO SAVEPOINT sp1", ())
                      # Since we undid any xrefs added so far for this
                      # xresolv row we don't want to add any additional
                      # ones; so exit the for loop.
                    failed = True
                    break       # Continue with the next xresolv row.

            if not Opts.keep and not failed:
                  # The xrefs created from this xresolv row were successfully
                  # added to the database above so we can delete the xresolv
                  # row.
                dbh.execute ("DELETE FROM xresolv "
                             "WHERE entr=%s AND sens=%s AND typ=%s AND ord=%s",
                             (v.entr,v.sens,v.typ,v.ord))

def savepoint (dbh, action, name, _active=set()):
          # Postgresql's SAVEPOINT command is non-standard in that it exhibits
          # stacking behavior: a second SAVEPOINT command with the same name as 
          # an earlier one will shadow the earlier one and the earlier one will
          # become active again when the savepoint name is released.
          # This function ameliorates that deviant behavor a little bit.
        #L('savepoint').debug("%s %s (active=%r)" % (action, name, _active))
        if action == 'CLEAR':
            _active.clear()
        elif action == 'CREATE':
            if name in _active: dbh.execute ("RELEASE SAVEPOINT " + name)
            dbh.execute ("SAVEPOINT " + name)
            _active.add (name)
        elif action == 'RELEASE':
            if name not in _active: return
            dbh.execute ("RELEASE SAVEPOINT " + name)
            _active.remove (name)
        else: raise ValueError (action)

class Memoize:
    def __init__( self, func ):
        self.func = func
        self.cache = {}
    def __call__( self, *args ):
        if not args in self.cache:
            self.cache[args] = self.func( *args )
        return self.cache[args]

@Memoize
def get_entries (dbh, targ_src, rtxt, ktxt, seq):

        # Find all entries in the corpora targ_src that have a
        # reading and kanji that match rtxt and ktxt.  If seq
        # is given, then the matched entries must also have a
        # as sequence number that is the same.  Matches are
        # restricted to entries with stat=2 ("active");
        #
        # The records in the entry list are lists, and are
        # indexed as follows:
        #
        #       0 -- entr.id
        #       1 -- entr.seq
        #       2 -- rdng.rdng
        #       3 -- kanj.kanj
        #       4 -- total number of readings in entry.
        #       5 -- total number of kanji in entry.
        #       6 -- total number of senses in entry.

        KW = jdb.KW
        if not ktxt and not rtxt:
            raise ValueError ("get_entries(): 'rtxt' and 'ktxt' args are are both empty.")
        args = [];  cond = [];
        if targ_src:
            srcs, neg = targ_src
            args.append (tuple (srcs)); 
            cond.append ("src %sIN %%s" % ('NOT ' if neg else ''));
        if seq:
            args.append (seq); cond.append ("seq=%s")
        if rtxt:
            args.append (rtxt); cond.append ("r.txt=%s")
        if ktxt:
            args.append (ktxt); cond.append ("k.txt=%s")
        sql = "SELECT DISTINCT id,seq," \
                + ("r.rdng," if rtxt else "NULL AS rdng,") \
                + ("k.kanj," if ktxt else "NULL AS kanj,") \
                + "(SELECT COUNT(*) FROM rdng WHERE entr=id) AS rcnt," \
                  "(SELECT COUNT(*) FROM kanj WHERE entr=id) AS kcnt," \
                  "(SELECT COUNT(*) FROM sens WHERE entr=id) AS scnt" \
                " FROM entr e " \
                + ("JOIN rdng r ON r.entr=e.id " if rtxt else "") \
                + ("JOIN kanj k ON k.entr=e.id " if ktxt else "") \
                + "WHERE stat=%s AND %s" \
                % (KW.STAT['A'].id, " AND ".join (cond))
        dbh.execute (sql, args)
        rs = dbh.fetchall()
        return rs

def choose_target (v, entries):
        # From that candidate target entries in entries,
        # choose the one we will use for xref target for
        # the xresolv record in v.
        #
        # The current algorithm is what was intended to be
        # implemented by the former xresolv.sql script.
        # Like that script, it does not take into account
        # any of the restr, stagk, stagr information.
        # Ideally, if we find a single match based on the
        # first valid (considering those restrictions)
        # reading/kanji we should use that as a target.
        # The best way to do that is under review.
        #
        # The list of entries we received are those that
        # have a matching reading and kanji (in any positions)
        # if the xresolv record had both reading and kanji,
        # or a matching reading or kani (in any position)
        # if the xresolv record had only a reading or kanji.

        rtxt = v.rtxt;  ktxt = v.ktxt

          # If there is only a single entry that matched,
          # that must be the target.
        if 1 == len (entries): return entries[0]

          # And if there were no matching entries at all...
        if 0 == len (entries):
            msg (fs(v), "not found", kr(v)); return None

        if not ktxt:
              # If there is only one entry that has the
              # given reading as the first reading, and no
              # kanji, that's it.
            candidates = [x for x in entries if x[5]==0 and x[2]==1]
            if 1 == len (candidates): return candidates[0]

              # If there is only one entry that has the
              # given reading and no kanji, that's it.
            candidates = [x for x in entries if x[5]==0]
            if 1 == len (candidates): return candidates[0]

              # Is there is only one entry with reading
              # as the first reading?
            candidates = [x for x in entries if x[2]==1]
            if 1 == len (candidates): return candidates[0]

        elif not rtxt:
              # Is there only one entry whose 1st kanji matches?
            candidates = [x for x in entries if x[3]==1]
            if 1 == len (candidates): return candidates[0]

          # At this point we either failed to resolve in one
          # of the above suites, or we had both a reading and
          # kanji with multiple matches -- either way we give up.
        msg (fs(v), "multiple targets", kr(v))
        return None

Prev = None

def mkxrefs (v, e):
        global Prev
        cntr = 1 + (Prev.xref if Prev else 0)
        xrefs = []
        for s in range (1, e[6]+1):

              # If there was a sense number given in the xresolv
              # record (field "tsens") then step through the
              # senses until we get to that one and generate
              # an xref only for it.  If there is no tsens,
              # generate an xref for every sense.
            if v.tsens and v.tsens != s: continue

              # The db xref records use column "xref" as a order
              # number and to distinguish between multiple xrefs
              # in the same entr/sens.  We use cntr to maintain
              # its value, and it is reset to 1 here whenever we
              # see an xref record with a new entr or sens value.
            if not Prev or Prev.entr != v.entr \
                        or Prev.sens != v.sens: cntr = 1
            xref = jdb.Obj (entr=v.entr, sens=v.sens, xref=cntr, typ=v.typ,
                            xentr=e[0], xsens=s, rdng=e[2], kanj=e[3])
            cntr += 1;  Prev = xref
            xrefs.append (xref)

        if not xrefs:
            if v.tsens: msg (fs(v), "Sense not found", kr(v))
            else: raise ValueError ("No senses in retrieved entry!")

        return xrefs

def read_krmap (dbh, infn, targ_src):
        if not infn: return None
        fin = open (infn, "r", encoding="utf8_sig")

        krmap = {}
        for lnnum, line in enumerate (fin):
            if line.isspace() or re.search (r'^\s*\#', line): continue
            rtxt, ktxt, seq = line.split ('\t', 3)
            try: seq = int (seq)
            except ValueError: raise ValueError ("Bad seq# at line %d in '%s'" % (lnnum, infn))
            entrs = get_entries (dbh, targ_src, rtxt, ktxt, seq)
            if not entrs:
                raise ValueError ("Entry seq not found, or kana/kanji"
                                  " mismatch at line %d in '%s'" % (lnnum, infn))
            krmap[(ktxt,rtxt)] = entrs[0]
        return krmap

def lookup_krmap (krmap, rtxt, ktxt):
        key = ((ktxt or ""),(rtxt or ""))
        return krmap[key]

def kr (v):
        s = fmt_jitem (v.ktxt, v.rtxt, [v.tsens] if v.tsens else [])
        return s

def fs (v):
        s = "%s.%d (%d,%d,%d):" % (jdb.KW.SRC[v.src].kw, v.seq,v.entr,v.sens,v.ord)
        return s

def fmt_jitem (ktxt, rtxt, slist):
          # FIXME: move this function into one of the formatting
          # modules (e.g. fmt.py or fmtjel.py).
        jitem = (ktxt or "") + ('/' if ktxt and rtxt else '') + (rtxt or "")
        if slist: jitem += '[' + ','.join ([str(s) for s in slist]) + ']'
        return jitem

def msg (source, msg, arg):
        if not Opts.quiet:
            print ("%s %s: %s" % (source,msg,arg))

def prnt (f, msg):
        print (msg, file=f)

def perr (msg):
        print (msg, file=sys.stderr)
        sys.exit(1)

def get_src_ids (srclist):
        if not srclist: return None
        neg = False
        if srclist.startswith ('-'):
            neg = True; srclist = srclist[1:]
        srcs = srclist.split(',')
        ids = tuple([get_src_id (x) for x in srcs if x])
        return ids, neg

def get_src_id (id_or_name):
          # Return the kwsrc.id value corresponding to 'id_or_name'.
        if not id_or_name: return None
        src = id_or_name
        try: src = int (src)
        except (ValueError): pass
        src = jdb.KW.SRC[src].id
        return src

#-----------------------------------------------------------------------

from optparse import OptionParser
from pylib.optparse_formatters import IndentedHelpFormatterWithNL

def parse_cmdline ():
        u = \
"""\n\t%prog [options]

%prog will convert textual xrefs in table "xresolv", to actual
entr.id xrefs and write them to database table "xref".

Arguments: none"""

        v = sys.argv[0][max (0,sys.argv[0].rfind('\\')+1):] \
                + " Rev %s (%s)" % __version__
        p = OptionParser (usage=u, version=v, add_help_option=False,
                          formatter=IndentedHelpFormatterWithNL())

        p.add_option ("--help",
            action="help", help="Print this help message.")

        p.add_option ("-n", "--noaction", default=False,
            action="store_true",
            help="Resolve xrefs and generate log file but don't make "
                "any changes to database. (This implies --keep.)")

        p.add_option ("-v", "--verbose", default=False,
            action="store_true",
            help="Print a message for every successfully resolved xref.")

        p.add_option ("-q", "--quiet", default=False,
            action="store_true",
            help="Do not print a warning for each unresolvable xref.")

        p.add_option ("-f", "--filename", default=None,
            help="Name of a file containing kanji/reading to seq# map.")

        p.add_option ("-k", "--keep", default=False, action="store_true",
            help="Do not delete unresolved xrefs after they are resolved.")

        p.add_option ("-i", "--ignore-nonactive", default=False,
            action="store_true",
            help="Ignore unresolved xrefs belonging to entries with a"
                "status of deleted or rejected or which are unapproved ")

        p.add_option ("-s", "--source-corpus", default=None,
            metavar='CORPORA',
            help="Limit to xrefs occuring in entries of CORPORA (a comma-"
                "separated list of corpus names or id numbers).  If preceeded "
                "by a \"-\", all corpora will be included except those listed.")

        p.add_option ("-t", "--target-corpus", default=None,
            metavar='CORPORA',
            help="Limit to xrefs that resolve to targets in CORPORA (a comma-"
                "separated list of corpus names or id numbers).  If preceeded "
                "by a \"-\", all corpora will be included except those listed.")

        p.add_option ("-e", "--encoding", default="utf-8",
            type="str", dest="encoding",
            help="Encoding for output (typically \"sjis\", \"utf8\", "
              "or \"euc-jp\"")

        p.add_option ("-d", "--database",
            type="str", dest="database", default="jmdict",
            help="Name of the database to load.")
        p.add_option ("-h", "--host", default=None,
            type="str", dest="host",
            help="Name host machine database resides on.")
        p.add_option ("-u", "--user", default=None,
            type="str", dest="user",
            help="Connect to database with this username.")
        p.add_option ("-p", "--password", default=None,
            type="str", dest="password",
            help="Connect to database with this password.")

        p.add_option ("-D", "--debug", default=0,
            type="int", metavar="NUM",
            help="Print debugging output to stderr.  The number NUM "
                "controls what is printed.  See source code.")

        p.epilog = """\
When a program such as jmparse.py or exparse.py parses
a corpus file, any xrefs in that file are in textual
form (often a kanji and/or kana text string that identifies
the target of the xref).  The database stores xrefs using
the actual entry id number of the target entry but the
textual form canot be resolved into the id form at parse
time since the target entry may not even be in the database
yet. Instead, the parser programs save the textual form of
the xref in a table, 'xresolv', and it is the job of this
program, when run later, to convert the textual 'xresolv'
table xrefs into the id form of xrefs and load them into
table 'xref'.

Each xresolv row contains the entr id and sens number
of the entry that contained the xref, the type of xref,
and the xref target entry kanji and/or reading, and
optionally, sense number.

This program searches for an entry matching the kanji
and reading and creates one or more xref records using
the target entry's id number.  The matching process is
more involved than doing a simple search because a kanji
xref may match several entries, and our job is to find
the right one.  This is currently done by a fast but
inaccurate method that does not take into account restr,
stagr, and stag restrictions which limit certain reading-
kanji combinations and thus would make unabiguous some
xrefs that this program considers ambiguous.  See the
comments in sub choose_entry() for a description of
the algorithm.

When an xref text is not found, or multiple candidate
entries still exist after applying the selection
algorithm, the fact is reported (unless the -q option
was given) and that xref skipped.

Before the program exits, it prints a summary of all
unresolvable xrefs, grouped by reason and xref text.
Following the xref text, in parenthesis, is the number
of xresolv xrefs that included that unresolvable text.
All normal (non-fatal) messages (other than debug
messages generated via the -D option) are written to
stdout.  Fatal errors and debug messages are written
to stderr."""

        opts, args = p.parse_args ()
        return args, opts

if __name__ == '__main__':
        args, opts = parse_cmdline()
        main (args, opts)

