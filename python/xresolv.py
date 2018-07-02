#!/usr/bin/env python3
#######################################################################
#  This file is part of JMdictDB.
#  Copyright (c) 2008,2014,2018 Stuart McGraw
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

# This program creates rows in table "xref" based on the
# textual (kanji and kana) xref information saved in table
# "xresolv".  xresolv contains "unresolved" xrefs -- that
# is, xrefs defined only by a kanji/kana text(s) which for
# which there may be zero or multiple target entries.
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
# NOTE: references in the comments to 'xresolv' rows are not
# strictly accurate: the rows returned by get_xresolv_block()
# and subsequently by get_xresolv_set() are rows from the
# xresolv table augmented with additional info from the
# associated entry: .src, .seq, .stat, .unap.

import sys, os, inspect, pdb
_ = os.path.abspath(os.path.split(inspect.getfile(inspect.currentframe()))[0])
_ = os.path.join (os.path.dirname(_), 'python', 'lib')
if _ not in sys.path: sys.path.insert(0, _)

import re, itertools, threading, queue
import db, jdb
import logging, logger; from logger import L
  # Set to True to disable multiple threads for debugging.
  #FIXME: doesn't work.
Debug = 0 # True

NWRITERS = 8    # Number of threads doing inserts.
NDELETERS = 2   # Number of threads deleting xresolv rows.  If this
  # is set to zero, and deletions are needed, they will be done in
  # the writers threads after the xref insert.

#-----------------------------------------------------------------------

def main (cmdln_args):
        args = parse_cmdline (cmdln_args)
        dburi = args.database
        try: dbconn = db.connect (dburi)
        except jdb.dbapi.OperationalError as e:
            sys.exit ("Error, unable to connect to database: %s" % str(e))
        KW = jdb.Kwds (dbconn.cursor())
          # Monkey patch jdb module until migration to db module is complete
          # because many lib functions still expect KW as a jdb global.
        jdb.KW = KW
        level = loglevel (args.level)
        logger.log_config (level=1 if args.messages else level,
                           filename=args.logfile)
        if args.messages:
            try: filter = parse_mlist (args.messages, level)
            except ValueError as e: sys.exit("Bad -m option: '%s'" % str (e))
            L().handlers[0].addFilter (filter)

        global Args;  Args = args

        try: xref_src = get_src_ids (args.source_corpus)
        except KeyError:
            L('unknown corpus').warning(args.source_corpus)
            sys.exit (0)
        try: targ_src = get_src_ids (args.target_corpus)
        except KeyError:
            L('unknown corpus').warning(args.target_corpus)
            sys.exit (0)
          #FIXME: need to make work with multiple srcs in targ_src and
          # provide limiting the scope (eg to one src or an entry) of
          # the K/R pairs in the file.
        #krmap = read_krmap (dbconn, args.krmap, targ_src)
        krmap = {}

        if args.keep: NDELETERS = 0   # Disable deleter threads. 
        qwriter = queue.Queue();  qdeleter = queue.Queue();  threads = []

        nwriters = NWRITERS if not Debug else 1
        writer = lambda: \
            thprocess_entr_cands (qwriter, dburi, upsert=False, keep=args.keep,
                                  delq=qdeleter if NDELETERS>0 else None)
        for n in range (nwriters):
            thname = 'ins%s' % n
            L().debug("starting thread %s" % thname)
            threads.append (thstart (thname, writer))

        ndeleters = NDELETERS if not Debug else 0
        deleter = lambda: thdel_xresolv (qdeleter, dburi)
        for n in range (ndeleters):
            thname = 'del%s' % n
            L().debug("starting thread %s" % thname)
            threads.append (thstart (thname, deleter))

        for rows in get_entr_cands (dbconn, xref_src, targ_src,
                                    start=args.start, stop=args.stop):
              # 'rows' is a set of target candidate rows for all the
              # unresolved xrefs for a single entry.
            qwriter.put (rows)
            #process_entr_cands (dbconn, rows, upsert=False, keep=args.keep)
        for n in range (nwriters): qwriter.put (None)
        for n in range (ndeleters): qdeleter.put (None)
        for t in threads: t.join()
        L().info("normal exit")

def thstart (name, func):
        if Debug:
            func(); return
        t = threading.Thread (name=name, target=func)
        t.daemon = True;  t.start()
        return t

def thprocess_entr_cands (workq, dburi, upsert, keep, delq):
        dbconn = db.connect (dburi)
        me = threading.current_thread()
        while True:
            L(me.name).debug("reading queue, len=%d" % workq.qsize())
            rows = workq.get (block=True)
            if rows:
                L(me.name).debug("got %s rows for entry %s" % (len(rows), rows[0].entr))
                process_entr_cands (dbconn, rows, upsert, keep, delq)
            else:
                L(me.name).debug("commit")
                #dbconn.commit()
                break

def thdel_xresolv (workq, dburi):
        dbconn = db.connect (dburi)
        me = threading.current_thread()
        while True:
            L(me.name).debug("reading queue, len=%d" % workq.qsize())
            xref = workq.get (block=True)
            if xref:
                L(me.name).info("deleting xresolv %r" % (xref,))
                del_xresolv (dbconn, xref)
            else:
                L(me.name).debug("commit")
                #dbconn.commit()
                break

def process_entr_cands (dbconn, rows, upsert, keep, delq=None):
        key = lambda x: (x.entr, x.sens, x.typ, x.ord)
        for _,cands in itertools.groupby (rows, key=key):
              # 'cands' is the set of target candidate rows for
              # each single unresolved xref in 'rows'.
            row = choose_candidate (list(cands))
            if not row: continue
            xref = mkxref (row)
            if not xref: continue
            result = wrxref (dbconn, xref, upsert, keep)
            if result and not keep:
               if delq: delq.put (xref)
               else: del_xresolv (dbconn, xref)

def get_entr_cands (dbconn, xref_src, targ_src, start=None, stop=None):
        # Yield sets of candidates rows for all unresolved xrefs 
        # for a single entry.
        #
        # dbconn -- An open dbapi connection to a jmdictdb database.
        # xref_src -- A 2-tuple consiting of:
        #   0: a sequence of numbers identifying the entr.src numbers
        #     to be included or excluded when searching for xrefs to 
        #     resolve.
        #   1: (bool) if false the values in item 0 specify src numbers
        #     to include; if false they are numbers to exclude.
        # targ_src -- Same format as 'xref_src' but for target entry 
        #   .src numbers.
        # start -- lowest entry id number to process.  If None of not
        #   given default is 1.
        # stop -- process entries up to but not including this id number.

        xs_lst, xs_inv = xref_src
        ts_lst, ts_inv = targ_src
        L().info("reading candidates from database, may take a while...")
        r1 = "entr>=%s" if start else ""
        r2 = "entr<%s" if stop else ""
        range = r1 + (" AND " if r1 and r2 else "") + r2
        range = (" AND " + range) if range else ""  
        sql = "SELECT * FROM rslv"\
              " WHERE src %sIN %%s AND (tsrc %sIN %%s OR tsrc IS NULL)"\
              " %s"\
              " ORDER BY entr,sens,typ,ord,targ"\
              % ('NOT ' if xs_inv else '', 'NOT ' if xs_inv else '', range)
        args = [xs_lst, ts_lst]
        if r1: args.append (start)
        if r2: args.append (stop)
        L().debug("sql: %s" % sql)
        L().debug("args: %r" % (args,))
        rs = db.query (dbconn, sql, tuple(args))
        L().info("read %d candidates from database" % len(rs))
        key = lambda x: (x.entr, x.sens, x.typ, x.ord)
        key = lambda x: x.entr
        for _, rows in itertools.groupby (rs, key=key):
            yield list(rows)

def choose_candidate (rows):
        L('choose_candidate').debug("received %d rows" % len(rows))
        if len(rows) == 1:
              # There is only one candidates row based on which we can decide
              # unambiguously among three possibilities: 1) there was no match,
              # 2) there were multiple matches, or 3) we found exactly one
              # match.
            v = rows[0]
            if v.tsrc is None:
                L('xref target not found').error(fs(v))
                return None
            if v.nentr==1:
                L('xref resolved (1)').info(fs(v))
                return v
            if rows[0].nentr>1:
                L('multiple candidates').error(fs(v))
                return None
          # If there were multiple candidates rows we need to look through
          # them all to find the best choice.  We will never choose a
          # candidates row that has .nentr>1 since that is definitionally
          # a match to multiple targets.  Also note the candidates must
          # already match the unresolved xref's reading or kanji or both
          # (if the xref specifies both).
        for v in rows:
               # If looking for a reading match, first choice is a match
               # to the first reading of an entry that has no kanji.
            if v.nentr == 1 and not v.ktxt and v.rdng==1 and v.nokanji:
                L('xref resolved (2)').info(fs(v))
                return v
        for v in rows:
               # Otherwise look for a candidate that matches on either the
               # first reading or first kanji.
            first = (v.rtxt and v.rdng==1) or (v.ktxt and v.kanj==1)
            if v.nentr == 1 and first:
                L('xref resolved (3)').info(fs(v))
                return v
        for v in rows:
               # And as last choice accept a candidate with a matching
               # reading and/or kanji regardless of the position of the
               # matches.
            if v.nentr == 1:
                L('xref resolved (4)').info(fs(v))
                return v
        L('multiple candidates').error(fs(v))
        return None

def wrxref (dbconn, xref, upsert, keep):
          # dbconn -- Open database connection.
          # xref -- (Xref) instance add to database.
          # upsert -- (bool) action to take if xref already in db.
          #   true: update it to match 'xref';
          #   false: raise duplicate key error.
          # keep -- (bool) if false, delete the unresolved xrefs from
          #   the xresolv table after each has successfully been resolved
          #   and added to the xref table.  If true, this is not done.

        x = xref    # For brevity.
        L('wrxref').debug("xref: entr=%s, sens=%s, xref=%s, typ=%s,"
                              " xentr=%s, xsens=%s, rdng=%s, kanj=%s,"
                              " nosens=%s, lowpri=%r" %
              (x.entr,x.sens,x.xref,x.typ,x.xentr,x.xsens,
               x.rdng or '',x.kanj or '',x.nosens,x.lowpri))

          # Write an xref to the "xref" database table.
          # We check for a duplicate key first.  If 'upsert' is true
          # then we just print an info message and do an upsert operation.
          # If upsert is not true then it is an error,
          # And if there is no preexisting entry we just do the upsert
          # which in this case devolves to a plain insert.
        pk = x.entr,x.sens,x.xref,x.xentr,x.xsens
        sql = "SELECT * FROM xref "\
              "WHERE entr=%s AND sens=%s AND xref=%s AND xentr=%s AND xsens=%s"
        existing = db.query (dbconn, sql, pk)
        if existing:
            e = existing[0]   # For brevity.
            if (e.typ,e.rdng,e.kanj,e.notes,e.nosens,e.lowpri) \
                    == (x.typ,x.rdng,x.kanj,x.notes,x.nosens,x.lowpri):
                L('update').info('no change needed')
                return xref
            else:
                lg = L('update').info if upsert else  L('update').error
                lg ("existing xref: %r" % e)
        if existing and not upsert: return None
        a = (x.typ,x.rdng,x.kanj,x.notes,x.nosens,x.lowpri)
          #FIXME: we have to explicitly give the name of the xref primary
          # key constraint below but currently in entrobj.sql the name is
          # asssigned by default; we should explicitly define it there too.
        sql = "INSERT INTO xref(entr,sens,xref,xentr,xsens,"\
                               "typ,rdng,kanj,notes,nosens,lowpri) "\
              "VALUES(%s,%s,%s,%s,%s, %s,%s,%s,%s,%s,%s) "
        args = pk + a
        if upsert:
            sql += \
              "ON CONFLICT ON CONSTRAINT xref_pkey DO UPDATE "\
              "SET typ=%s,rdng=%s,kanj=%s,notes=%s,nosens=%s,lowpri=%s"
            args += a
        L('wrxref.sql').debug("sql: %s" % sql)
        L('wrxref.sql').debug("args: %r" % (args,))
        db.ex (dbconn, sql, args)
        return x

def del_xresolv (dbconn, xref): 
        x = xref    # For brevity.
        sql = "DELETE FROM xresolv"\
              " WHERE entr=%s AND sens=%s AND typ=%s AND ord=%s"
          # CAUTION: we assume here that xref.xref has the same value
          #  as xresolv.ord and thus we can use xref.xref to delete 
          #  the corresponding xresolv row.  That is currently true but
          #  has not been true in past and could change in the future.
        args = x.entr, x.sens, x.typ, x.xref
        L('del_xresolv.sql').debug("sql: %s" % sql)
        L('del_xresolv.sql').debug("args: %r" % (args,))
        db.ex (dbconn, sql, args)
        return xref

def mkxref (v):
          # If there is no tsens, generate an xref to only the first
          # sense.  Rationale: Revs prior to ~2018-06-07 we generated
          # xrefs to all senses in this scenario.  When there were a
          # lot of reverse xrefs to a word from the Example sentences,
          # every sense of the target word would have them all repeated.
          # However unless there is only one target sense, we can be
          # sure we are wrong: if the senses were so similar to be
          # interchangable they wouldn't be separate senses.  Since
          # we'll be wrong either way and someone will need to manually
          # correct it later, choose the way that produces the least
          # amount of clutter in the entry.  Also, in many cases the
          # first *will* be the right sense.
        nosens = False
        if not v.tsens:
            if v.nsens != 1:
                L('multiple senses').warning("using sense 1: %s" % (fs(v)))
                nosens = True
            v.tsens = 1
        if v.tsens > v.nsens:
            L('sense number too big').error(fs(v))
            return None
        xref = jdb.Obj (entr=v.entr, sens=v.sens, xref=v.ord, typ=v.typ,
                        xentr=v.targ, xsens=v.tsens, rdng=v.rdng, kanj=v.kanj,
                        notes=v.notes, nosens=nosens, lowpri=not v.prio)
        return xref

def read_krmap (dbconn, infn, targ_src):
        if not infn: return None
        fin = open (infn, "r", encoding="utf8_sig")

        krmap = {}
        for lnnum, line in enumerate (fin):
            if line.isspace() or re.search (r'^\s*\#', line): continue
            rtxt, ktxt, seq = line.split ('\t', 3)
            try: seq = int (seq)
            except ValueError:
                raise ValueError ("Bad seq# at line %d in '%s'" % (lnnum, infn))
            entrs = get_entries (dbconn.cursor(), targ_src, rtxt, ktxt, seq)
            if not entrs:
                raise ValueError ("Entry seq not found, or kana/kanji"
                                  " mismatch at line %d in '%s'" % (lnnum, infn))
            krmap[(ktxt,rtxt)] = entrs[0]
        return krmap

def lookup_krmap (krmap, rtxt, ktxt):
        key = ((ktxt or ""),(rtxt or ""))
        return krmap[key]

def fs (v):
          # Format unresolved xref 'v' in a standard way for messages.
        s = "%s.%d (%d,%d,%d) %s:" \
           % (jdb.KW.SRC[v.src].kw,v.seq, v.entr,v.sens,v.ord,
              fmt_jitem(v.ktxt, v.rtxt, [v.tsens] if v.tsens else []))
        return s

def fmt_jitem (ktxt, rtxt, slist):
          # FIXME: move this function into one of the formatting
          # modules (e.g. fmt.py or fmtjel.py).
        jitem = (ktxt or "") + ('・' if ktxt and rtxt else '') + (rtxt or "")
        if slist: jitem += '[' + ','.join ([str(s) for s in slist]) + ']'
        return jitem

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

def parse_mlist (mlist, thresh):
        regexes = []
        for regex in mlist:
            neg = False
            if regex.startswith ('!'): regex, neg = regex[1:], True
            regexes.append ((neg, regex))
        filter = lambda x: logmsg_filter (x, regexes, thresh)
        return filter

def logmsg_filter (logrec, regexes, thresh=30):
        for neg, regex in regexes:
            if not re.search(regex,logrec.name): continue
              # The last regex matched.  For a regular match (ie, no "!"
              # was given and 'inverted' is False) return True to print
              # the log message.  If "!" was given, 'inverted' is True
              # and we return False to suppress the message.
            return not neg
        return logrec.levelno >= thresh

def loglevel (thresh):
        try:
            try: lvl = int(thresh)
            except (ValueError, TypeError):
                lvl = {'e':40, 'w':30, 'i':20, 'd':10}.get (thresh[0].lower())
        except (ValueError, TypeError, IndexError):
            raise ValueError ("Bad 'level' option: %s" % thresh)
        return lvl

#-----------------------------------------------------------------------

from optparse import OptionParser
from pylib.optparse_formatters import IndentedHelpFormatterWithNL

def parse_cmdline ():
        u = \
"""\n\t%prog [options]

%prog will convert textual xrefs in table "xresolv", to actual
entr.id xrefs and write them to database table "xref".

Arguments: none"""

import argparse, textwrap
from pylib.argparse_formatters import ParagraphFormatterML
def parse_cmdline (cmdln_args):
        p = argparse.ArgumentParser (prog=cmdln_args[0],
            formatter_class=ParagraphFormatterML,
            description="Resolve a set of unresolved xrefs by identifying "
                "one specific target entry for each one and creating "
                "xrefs to them.")

        p.add_argument ("-n", "--noaction", default=False,
            action="store_true",
            help="Resolve xrefs and generate log file but don't make "
                "any changes to database. (This implies --keep.)")

        p.add_argument ("-i", "--ignore-nonactive", default=False,
            action="store_true",
            help="Ignore unresolved xrefs belonging to entries with a"
                "status of deleted or rejected or which are unapproved ")

        p.add_argument ("-s", "--source-corpus", default=None,
            metavar='CORPORA',
            help="Limit to xrefs occuring in entries of CORPORA (a comma-"
                "separated list of corpus names or id numbers).  If preceeded "
                "by a \"-\", all corpora will be included except those listed.")

        p.add_argument ("-t", "--target-corpus", default=None,
            metavar='CORPORA',
            help="Limit to xrefs that resolve to targets in CORPORA (a comma-"
                "separated list of corpus names or id numbers).  If preceeded "
                "by a \"-\", all corpora will be included except those listed.")

        p.add_argument ("--start", default=None,
            help="Starting entry id number to process.")

        p.add_argument ("--stop", default=None,
            help="One greater than the last entry id number to process.")

        p.add_argument ("--krmap", default=None,
            help="Name of a file containing kanji/reading to seq# map.")

        p.add_argument ("-k", "--keep", default=False, action="store_true",
            help="Do not delete unresolved xrefs after they are resolved.  "
                "This is primarily to aid in debugging.")

#        p.add_argument ("--partial", default=False, action="store_true",
#            help="Create xrefs for an entry even if some of them can't be "
#                "created.  Default behavior without this option is not "
#                "to create any xrefs for an entry if any of them can't "
#                "be created.  "
#                "This option can be useful when performing incremental "
#                "updates.")
#
#        p.add_argument ("--preserve", default=False, action="store_true",
#            help="Do not delete existing xrefs for an entry prior to "
#                "resolving unresolved xrefs.  If an unresolved xref "
#                "resolves to the same key as a preexisting one, the "
#                "preexisting one will be updated to match the new one.  "
#                "Default behavior without this option is to delete any "
#                "preexisting xrefs for an entry prior to resolving xrefs "
#                "for that entry.  "
#                "This option can be useful when performing incremental "
#                "updates.")

        p.add_argument ("-l", "--logfile", default=None,
            help="Name of file log messages will be written to."
                "If not given messages will be written to stderr.")

        p.add_argument ("-v", "--level", default='warn',
            help="Logging level, one of: "
                "'error', 'warning', 'info', 'debug'.  "
                "May be abbreviated to a single letter.  Log messages at "
                "or above this level will be printed sans the exceptions"
                "specified by any --messages options given.")

        p.add_argument ("-m", "--messages", default=[], action="append",
            help="Allows finer-grained control of logging messages than "
                "provided by --level.  The value of this option is a "
                "a regular expression, optionally prefixed with a \"!\" "
                "character.  Multiple --message options may be given.  "
                "When a logging message is generated the message's source "
                "string (aka logger name) is matched against each --message "
                "regex in turn; if it matches and no \"!\" was given, the "
                "log message is printed.  If no \"!\" was given the message "
                "is not printed.  In either case no further --message regexes "
                "are checked for that log message.  If there was no match, "
                "the next regex is checked.  If no regexes match, the result "
                "is determined by the --level option.")

        p.add_argument ("-d", "--database", default="jmdict",
            help="URI for the database to use.")
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
and reading and creates an xref record using the target
entry's id number.  The matching process is more involved
than doing a simple search because a kanji xref may match
several entries, and our job is to find the right one.
This is currently done by a fast but inaccurate method
that does not take into account restr, stagr, and stag
restrictions which limit certain reading-kanji combinations
and thus would make unabiguous some xrefs that this program
considers ambiguous.  See the comments in sub choose_entry()
for a description of the algorithm.

When an xref text is not found, or multiple candidate
entries still exist after applying the selection
algorithm, the fact is reported and that xref skipped.

Error and other messages refer to unresolved xrefs using
the format: "corpus.seq# (entr-id, sens#, ord#) where
all except ord# refer to the entry the xref is from.
Error (E) messages indicate no resolved xref was generated.
Warning (W) messages indicate an xref was produced but
might not be what was wanted.  Info (I) messages report
sucessful completion of an action.  There are also
a number of debug (D) messages that can be optionally
enabled.
."""

        args = p.parse_args (cmdln_args[1:])
        return args

if __name__ == '__main__': main (sys.argv)


##  For reference this is the SQL for the "rslv" query used in the
##  get_candidates() function above.
##
##  ----------------------------------------------------------------------------
##  -- This view is used by xresolv.py for finding entries that could
##  -- possibly be the intended targets of unresolved xrefs in table
##  -- "xresolv".  
##  -- It joins the rows in xresolve to entries based on a common reading
##  -- text, kanji text, or both.  Because the joins vary depending on the
##  -- join column there are three separate SELECTs, one for each case,
##  -- UNIONed together.
##  -- There may be multiple (or no) entries that have kanji or a reading
##  -- matching an xresolv row so a particular xresolv row may result in
##  -- 0 or multiple rows returned.  This view provides data in additional
##  -- columns that is intended to allow for a reasonable guess at which
##  -- entry is the intended target (or that no reasonable guess is justified)
##  -- in the case of multiple matches.
##
##CREATE OR REPLACE VIEW rslv AS (
##    -- Query for xresolv with both 'rtxt' and 'ktxt'  (~30s 250K rows)
##    SELECT v.seq, v.src, v.entr, v.sens, v.typ, v.ord,
##           v.rtxt, v.ktxt, v.tsens, v.notes, v.prio,
##           c.src AS tsrc, count(*) AS nentr, min(c.id) AS targ,
##           c.rdng, c.kanj, FALSE AS nokanji,
##           max(c.nsens) AS nsens
##    FROM (SELECT z.*,seq,src FROM xresolv z JOIN entr e ON e.id=z.entr
##          WHERE ktxt IS NOT NULL AND rtxt IS NOT NULL
##            AND e.stat=2 AND NOT e.unap)
##          AS v
##    LEFT JOIN rkv c ON v.rtxt=c.rtxt AND v.ktxt=c.ktxt
##    GROUP BY v.seq,v.src,v.entr,v.sens,v.typ,v.ord,v.rtxt,v.ktxt,
##             v.tsens,v.notes,v.prio, c.src,c.rdng,c.kanj
##    UNION
##
##    -- Query for xresolv with only rtxt (~3m 1500K rows)
##    SELECT v.seq, v.src, v.entr, v.sens, v.typ, v.ord,
##           v.rtxt, v.ktxt, v.tsens, v.notes, v.prio,
##           c.src AS tsrc, count(*) AS nentr, min(c.id) AS targ,
##           c.rdng, NULL AS kanj, nokanji, max(c.nsens) AS nsens
##    FROM
##       (SELECT z.*,seq,src FROM xresolv z JOIN entr e ON e.id=z.entr
##        WHERE ktxt IS NULL AND rtxt IS NOT NULL )
##        AS v
##    LEFT JOIN
##       (SELECT e.id,e.src,r.txt as rtxt,r.rdng,
##                 -- The "not exists..." clause below is true if there
##                 -- are no kanj table rows for the entry.
##               (NOT EXISTS (SELECT 1 FROM kanj k WHERE k.entr=e.id))
##                 -- This cause is true if this reading is tagged <nokanji>.
##                 OR j.rdng IS NOT NULL AS nokanji,
##               (SELECT count(*) FROM sens s WHERE s.entr=e.id) AS nsens
##        FROM entr e JOIN rdng r ON r.entr=e.id
##        LEFT JOIN re_nokanji j ON j.id=e.id AND j.rdng=r.rdng
##        WHERE e.stat=2 AND NOT e.unap) 
##        AS c ON (v.rtxt=c.rtxt)
##    GROUP BY v.seq,v.src,v.entr,v.sens,v.typ,v.ord,v.rtxt,v.ktxt,
##             v.tsens,v.notes,v.prio, c.src,c.rdng,c.nokanji
##    UNION
##
##    -- Query for xresolv with only ktxt (~1m, 500K rows)
##    SELECT v.seq, v.src, v.entr, v.sens, v.typ, v.ord,
##           v.rtxt, v.ktxt, v.tsens, v.notes, v.prio,
##           c.src AS tsrc, count(*) AS nentr, min(c.id) AS targ,
##           NULL AS rdng, c.kanj, NULL AS nokanji, max(c.nsens) AS nsens
##    FROM
##       (SELECT z.*,seq,src FROM xresolv z JOIN entr e ON e.id=z.entr
##        WHERE rtxt IS NULL AND ktxt IS NOT NULL )
##        AS v
##    LEFT JOIN 
##       (SELECT e.id,e.src,k.txt as ktxt,k.kanj,
##               (SELECT count(*) FROM sens s WHERE s.entr=e.id) AS nsens
##        FROM entr e JOIN kanj k ON k.entr=e.id
##        WHERE e.stat=2 AND NOT e.unap) 
##        AS c ON (v.ktxt=c.ktxt)
##    GROUP BY v.seq,v.src,v.entr,v.sens,v.typ,v.ord,v.rtxt,v.ktxt,
##             v.tsens,v.notes,v.prio, c.src,c.kanj);
