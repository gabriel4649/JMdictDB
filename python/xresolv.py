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

import re, itertools
import jdb
import logging, logger; from logger import L

#-----------------------------------------------------------------------

def main (cmdln_args):
        args = parse_cmdline (cmdln_args)
        level = loglevel (args.level)
        logger.log_config (level=1 if args.messages else level)
        if args.messages:
            try: filter = parse_mlist (args.messages, level)
            except ValueError as e: sys.exit("Bad -m option: '%s'" % str (e))
            L().handlers[0].addFilter (filter)

        global Args;  Args = args

        try:
            dbopts = jdb.parse_pguri(args.database) 
            dbh = jdb.dbOpen (dbopts['database'], **dbopts)
        except jdb.dbapi.OperationalError as e:
            sys.exit ("Error, unable to connect to database, "
                      "do you need -u or -p?\n" % str(e))
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
        #krmap = read_krmap (dbh, args.krmap, targ_src)
        krmap = {}

        blksz = 1000
        for rows in get_xresolv_set (dbh, xref_src, blksz):
            do_entr_set (dbh, list (rows), targ_src, krmap,
                         args.partial, args.preserve)
        if args.noaction:
            L('trans').info("ROLLBACK");  dbh.connection.rollback()
        else:
            L('trans').info("COMMIT");  dbh.connection.commit()
        dbh.close()

def do_entr_set (dbh, vrows, targ_src, krmap, partial=False, preserve=False):
          # Attempt to resolve a set of xresolve rows associated with a
          # a single entry.
          #
          # vrows -- a block of xresolv rows with a common .entr attribute
          #   value and sorted by (.sens, .typ, .ord).
          # targ_src -- (list) Only entries with these .src values will
          #   be candidates for resolution targets.
          # kmap -- Not currently used.
          # partial --Allow partial resolutions of full entr set.
          #   If false a failure to resolve any xresolv row will fail the
          #   entire set of xresolv rows with the same .entr value and no
          #   xrefs will be generated for any of the xresolve rows.
          #   It true, only the failing xresolve rows will fail to generate
          #   xrefs; the non-failing rows will.
          # preserve -- if true, do not replace all preexisting xrefs with
          #   the newly resolved ones.  Instead replace only those that
          #   match one of the newly resolved ones.

          # Skip this set of xresolv rows if the "--ignore-nonactive"
          # option was given and the entry is not active (i.e. is deleted
          # or rejected) or is unapproved.  Unapproved entries will
          # be checked during approval submission and unresolved
          # xrefs in rejected/deleted entries are usually moot.
        if Args.ignore_nonactive and (vrows[0].stat != jdb.KW.STAT['A'].id
                                      or vrows[0].unap):
            L('invalid').info("skipping inactive or unapproved entry %d"
                               % vrows[0].entr)
            return

        dbh.execute ("SAVEPOINT sp2")
        try:
            if not preserve:
                entrid = vrows[0].entr
                L('entr_set').info("deleting old xrefs for entr=%s" % entrid)
                dbh.execute ("DELETE FROM xref WHERE entr=%s", (entrid,))
            xrefs = []
            for v in vrows:
                xref = resolv (dbh, v, targ_src, krmap)
                if xref:
                    err = not wrxref (dbh, xref, upsert=partial)
                    if not err: xrefs.append (xref)

              # 'xrefs' now contains an Xref instance for every 'vrows'
              # item that was successfully resolved.  If 'partial' is not
              # true, we require every 'vrows' item to have been resolved;
              # if not the case then rollback all the newly created
              # database xrefs.
              # We don't abort on the first error because we want to
              # gererate error messages for all the failing vrows' items.
            if len(vrows) == len(xrefs):
                L('results').info("entr %d: all %d items resolved"
                                   % (vrows[0].entr, len(vrows)))
            else:
                L('results').info("entry %d: %d items not resolved"
                                  % (vrows[0].entr, len(vrows)-len(xrefs)))
                if not partial:
                    L('results').error("skipping entry %d due to errors"
                                      % (vrows[0].entr,))
                    dbh.execute ("ROLLBACK TO sp2")
                    xrefs = []
        finally: dbh.execute ("RELEASE sp2")
        if not Args.keep:
            sql = "DELETE FROM xresolv "\
                  "WHERE entr=%s AND sens=%s AND typ=%s AND ord=%s"
            for x in xrefs:
                  # x is xref row, not x.resolv row, hence x.xref, not x.ord.
                dbh.execute (sql, (x.entr, x.sens, x.typ, x.xref))

def resolv (dbh, xresolv_row, targ_src, krmap):
        v = xresolv_row     # For brevity.
        L('resolving').debug("entr=%s, sens=%s, typ=%s, ord=%s, "
                          "tsens=%s, prio=%s, rtxt=%s, ktxt=%s"
            % (v.entr,v.sens,v.typ,v.ord,v.tsens,v.prio,v.rtxt,v.ktxt))
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
              # care of generating an error message and returns a false
              # value.
            e = choose_target (v, entries)
            if not e: return None

          # Check that the chosen target entry isn't the same as the
          # referring entry.

        if e[0] == v.entr:
            L('self-referential').error("skipped %s %s" % (fs(v), kr(v)))
            return None # i.e., failed.

          # Now that we know the target entry, we can create the actual
          # db xref records.  There may be more than one if the target
          # entry has multiple senses and no explicit sense was given
          # in the xresolv record.
        xref = mkxref (v, e)
        if xref:
            L('resolved').info("%s -> xref %r" % (fs(v), xref))
        return xref

def wrxref (dbh, xref, upsert=False):
          # dbh -- Open database connection.
          # xref -- (Xref) instance add to database.
          # upsert -- (bool) action to take if xref already in db.
          #   true: update it to match 'xref';
          #   false: raise duplicate key error.

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
        existing = jdb.dbread (dbh, sql, pk)
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

          #FIXME: we have to explicitly give the name of the xref primary
          # key constraint below but currently in entrobj.sql the name is
          # asssigned by default; we should explicitly define it there too.
        sql = "INSERT INTO xref(entr,sens,xref,xentr,xsens,"\
                               "typ,rdng,kanj,notes,nosens,lowpri) "\
              "VALUES(%s,%s,%s,%s,%s, %s,%s,%s,%s,%s,%s)"\
              "ON CONFLICT ON CONSTRAINT xref_pkey DO UPDATE "\
              "SET typ=%s,rdng=%s,kanj=%s,notes=%s,nosens=%s,lowpri=%s"
        a = (x.typ,x.rdng,x.kanj,x.notes,x.nosens,x.lowpri)
        args = pk + a + a
        L('wrxref.sql').debug("sql: %s" % sql)
        L('wrxref.sql').debug("args: %r" % (args,))
        dbh.execute (sql, args)
        return xref

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
            raise ValueError ("get_entries(): 'rtxt' and 'ktxt' args "
                              "are are both empty.")
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
            L('not found').error("%s %s" % (fs(v), kr(v)))
            return None
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
        L('multiple targets').error("%s %s" % (fs(v), kr(v)))
        return None

def mkxref (v, e):
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
            if e[6] != 1:
                L('multiple senses').warning("using sense 1: %s %s"
                                             % (fs(v), kr(v)))
                nosens = True
            v.tsens = 1
        if v.tsens > e[6]:
            L('sense number too big').error("%s %s" % (fs(v), kr(v)))
            return None
        xref = jdb.Obj (entr=v.entr, sens=v.sens, xref=v.ord, typ=v.typ,
                        xentr=e[0], xsens=v.tsens, rdng=e[2], kanj=e[3],
                        notes=v.notes, nosens=nosens, lowpri=not v.prio)
        return xref

def get_xresolv_set (dbh, xref_src, blksz):
          # Yield sequential blocks (lists of xresolv rows) where all rows
          # in the block have the same .entr value and are ordered on
          # sens,typ,ord.  We expect get_xresolv_row() to supply rows
          # in .entr,.sens,.typ,.ord order.
        reader = get_xresolv_row (dbh, xref_src, blksz)
        keyfunc = lambda x: x.entr
        for key, group in itertools.groupby (reader, keyfunc):
            yield group

def get_xresolv_row (dbh, xref_src, blksz, read_xrefs=False):
          # Read blocks of xresolv rows from the database and yield
          # one row at a time.  Rows are ordered on entr,sens,typ,ord.
        for blk in get_xresolv_block (dbh, xref_src, blksz):
            for row in blk: yield row

def get_xresolv_block (dbh, xref_src, blksz, read_xrefs=False):
        # Read and yield sucessive blocks of 'blksz' rows from table "xresolv"
        # (or, despite our name, table "xref" if 'read_xrefs' is true).  Rows
        # are ordered by (target) entr id, sens, xref type and xref ord (or
        # xref.xref for table "xref") and limited to entries having a .src
        # attribute of 'xref_src'.  None is returned when no more rows are
        # available.
        table = "xref" if read_xrefs else "xresolv"
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
            sql = "SELECT v.*,e.src,e.seq,e.stat,e.unap "\
                  "FROM %s v JOIN entr e ON v.entr=e.id "\
                  "WHERE %s (v.entr>%%s OR (v.entr=%%s "\
                     "AND (v.sens>%%s OR (v.sens=%%s "\
                     "AND (v.typ>%%s OR (v.typ=%%s "\
                     "AND (v.ord>%%s))))))) "\
                   "ORDER BY v.entr,v.sens,v.typ,v.ord "\
                   "LIMIT %s" % (table, src_condition, blksz)
            if read_xrefs:
                  # If reading the xref rather than the xresolv table make some
                  # adjustments:
                  #   The "ord" field is named "xref".
                sql = sql.replace ('.ord', '.xref')
                  #   The typ and xref (aka ord) fields are swapped
                  #   in xref rows.
                t0, o0 = o0, t0
            sql_args.extend ([e0,e0,s0,s0,t0,t0,o0])
            L('get_xresolv_block').debug("sql: %s" % sql_args)
            L('get_xresolv_block').debug("args: %r" % (sql_args,))
            rs = jdb.dbread (dbh, sql, sql_args)
            if len (rs) == 0: return
            L('get_xresolv_block').debug("Read %d %s rows from %s"
                                         % (len(rs), table, lastpos))
              # Slicing doesn't seem to currently work on DbRow objects or
              #  we could write "lastpos = rs[-1][0:4]" below.
            lastpos = rs[-1][0], rs[-1][1], rs[-1][2], rs[-1][3]
            yield rs
        assert True, "Unexpected break from loop"
        return

def read_krmap (dbh, infn, targ_src):
        if not infn: return None
        fin = open (infn, "r", encoding="utf8_sig")

        krmap = {}
        for lnnum, line in enumerate (fin):
            if line.isspace() or re.search (r'^\s*\#', line): continue
            rtxt, ktxt, seq = line.split ('\t', 3)
            try: seq = int (seq)
            except ValueError:
                raise ValueError ("Bad seq# at line %d in '%s'" % (lnnum, infn))
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
          # Format unresolved xref 'v' in a standard way for messages.
        s = "%s.%d (%d,%d,%d):" \
           % (jdb.KW.SRC[v.src].kw, v.seq,v.entr,v.sens,v.ord)
        return s

def fmt_jitem (ktxt, rtxt, slist):
          # FIXME: move this function into one of the formatting
          # modules (e.g. fmt.py or fmtjel.py).
        jitem = (ktxt or "") + ('/' if ktxt and rtxt else '') + (rtxt or "")
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

        p.add_argument ("--krmap", default=None,
            help="Name of a file containing kanji/reading to seq# map.")

        p.add_argument ("-k", "--keep", default=False, action="store_true",
            help="Do not delete unresolved xrefs after they are resolved.  "
                "This is primarily to aid in debugging.")

        p.add_argument ("--partial", default=False, action="store_true",
            help="Create xrefs for an entry even if some of them can't be "
                "created.  Default behavior without this option is not "
                "to create any xrefs for an entry if any of them can't "
                "be created.  "
                "This option can be useful when performing incremental "
                "updates.")

        p.add_argument ("--preserve", default=False, action="store_true",
            help="Do not delete existing xrefs for an entry prior to "
                "resolving unresolved xrefs.  If an unresolved xref "
                "resolves to the same key as a preexisting one, the "
                "preexisting one will be updated to match the new one.  "
                "Default behavior without this option is to delete any "
                "preexisting xrefs for an entry prior to resolving xrefs "
                "for that entry.  "
                "This option can be useful when performing incremental "
                "updates.")

        #p.add_argument ("-l", "--logfile", default=None,
        #    help="Name of file log messages will be written to."
        #        "If not given messages will be written to stderr.")

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
