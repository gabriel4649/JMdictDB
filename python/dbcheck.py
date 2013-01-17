#!/usr/bin/env python
# -*- coding: utf-8 -*-
#######################################################################
#  This file is part of JMdictDB.
#  Copyright (c) 2010 Stuart McGraw
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

# This run some checks on the data in a jmdictdb database.

__version__ = ("$Revision$"[11:-2],
               "$Date$"[7:-11])
import sys, os, re
import jdb

LIMIT = 30      # Max number of results top retreive.

def main (args, opts):
        global Opts;  Opts = opts
        cur = jdb.dbOpen (opts.database, **jdb.dbopts(opts))

        checks = [
            #------ 1 -- Approved but edit of another entry.
            ("The following entries are \"approved\" (entr.unap is FALSE) \n"\
             "but are listed as being edits of another entry (entr.dfrm \n"\
             "is non-NULL):",

            "SELECT e.id "\
                "FROM entr e "\
                "WHERE NOT e.unap AND e.dfrm IS NOT NULL "\
                "ORDER BY e.id LIMIT %s" % LIMIT),

            #------ 2 -- Dfrm cycle.
            ("The following entries are part of a dfrm cycle:",

            "WITH RECURSIVE wt (id, dfrm, depth, path, cycle) AS ("\
                   "SELECT e.id, e.dfrm, 1, ARRAY[e.id], false "\
                   "FROM entr e "\
                     "UNION ALL "\
                   "SELECT e.id, e.dfrm, wt.depth+1, path||e.id, e.id=ANY(path) "\
                   "FROM entr e, wt "\
                   "WHERE e.id = wt.dfrm AND NOT cycle) "\
                "SELECT DISTINCT wt.id FROM wt WHERE cycle LIMIT %s" % LIMIT),

            #------ 3 -- Multiple A entries in seqset.
            ("More that one \"A\" (approved and active) entry is a \n"\
             "seqset.  Following are the src,seq numbers:",

                # FIXME: We have to exclude the Examples corpus (see IS-157)
                #  but there is no guarantee the its 'src' number is 3.
            "SELECT src, seq FROM entr e WHERE NOT unap and stat=2 AND src!=3 "\
                "GROUP BY src, seq HAVING count(*)>1 "\
                "ORDER BY src,seq  LIMIT %s" % LIMIT),

            #------ 4 -- Multiple src/seq in editset.
            ("Entry id's in editsets where some entries have different \n"\
             "corpus or seq# than others:",

            "SELECT e1.id, e2.id "\
                "FROM entr e1 "\
                "JOIN entr e2 ON e2.dfrm=e1.id "\
                "WHERE e1.src!=e2.src OR e1.seq!=e2.seq "\
                "ORDER BY e1.id,e2.id LIMIT %s" % LIMIT),

            #------ 5 -- JIS semicolon in gloss.
            ("Entries with a JIS semicolon in a gloss:",

                # Hex string is unicode codepoint of JIS semicolon.
            u"SELECT entr FROM gloss WHERE txt LIKE '%%\uFF1B%%' "\
                "ORDER BY entr LIMIT %s" % LIMIT),

            #------ 6 -- JIS space in gloss.
            ("Entries with a JIS space in a gloss:",

                # Hex string is unicode codepoint of JIS space.
            u"SELECT entr FROM gloss WHERE txt LIKE '%%\u3000%%' "\
                "ORDER BY entr LIMIT %s" % LIMIT),

            #------ 7 -- No readings.
            ("Entries with no readings:",

                # FIXME: We have to exclude the Examples corpus (since none of
                #  its entries have readings) but there is no guarantee that its
                #  'src' number is 3.
                # Don't bother reporting deleted or rejected entries.
            "SELECT e.id FROM entr e WHERE src!=3 AND stat=2 AND NOT EXISTS "\
                "(SELECT 1 FROM rdng r WHERE r.entr=e.id) "\
                "ORDER BY e.id LIMIT %s" % LIMIT),

            #------ 8 -- No senses.
            ("Entries with no senses:",

            "SELECT e.id FROM entr e WHERE NOT EXISTS "\
                "(SELECT 1 FROM sens s WHERE s.entr=e.id) "\
                "ORDER BY e.id LIMIT %s" % LIMIT),

            #------ 9 -- No glosses.
            ("Entries with glossless senses:",

            "SELECT e.id,s.sens FROM entr e JOIN sens s ON s.entr=e.id WHERE NOT EXISTS "\
                "(SELECT 1 FROM gloss g WHERE g.entr=s.entr AND g.sens=s.sens) "\
                "ORDER BY e.id,s.sens LIMIT %s" % LIMIT),

            #------ 10 -- No PoS.
            ("Entries with senses that have no PoS:",

                # FIXME: Poslessness is a bad thing only in jmdict corpora but
                #  but there is no way to identify such.  We'll take a guess that
                #  there is only one and its 'src' is 1.
            "SELECT e.id,s.sens FROM entr e JOIN sens s ON s.entr=e.id WHERE src=1 AND NOT EXISTS "\
                "(SELECT 1 FROM pos p WHERE p.entr=s.entr AND p.sens=s.sens) "\
                "ORDER BY e.id,s.sens LIMIT %s" % LIMIT),

            #------ 11 -- Non-sequential kanj numbers.
            ("Entries with kanj.kanj numbers that are not sequential or do "\
             "not start at one.",

            "SELECT entr FROM kanj "\
                "GROUP BY entr HAVING MIN(kanj)!=1 OR COUNT(*)!=MAX(kanj) "\
                "ORDER by entr LIMIT %s" % LIMIT),

            #------ 12 -- Non-sequential rdng numbers.
            ("Entries with rdng.rdng numbers that are not sequential or do "\
             "not start at one.",

            "SELECT entr FROM rdng "\
                "GROUP BY entr HAVING MIN(rdng)!=1 OR COUNT(*)!=MAX(rdng) "\
                "ORDER by entr LIMIT %s" % LIMIT),

            #------ 13 -- Non-sequential sens numbers.
            ("Entries with sens.sens numbers that are not sequential or do "\
             "not start at one.",

            "SELECT entr FROM sens "\
                "GROUP BY entr HAVING MIN(sens)!=1 OR COUNT(*)!=MAX(sens) "\
                "ORDER by entr LIMIT %s" % LIMIT),

            #------ 14 -- Non-sequential gloss numbers.
            ("Entries with gloss.gloss numbers that are not sequential or do "\
             "not start at one.",

            "SELECT entr,sens FROM gloss "\
                "GROUP BY entr,sens HAVING MIN(gloss)!=1 OR COUNT(*)!=MAX(gloss) "\
                "ORDER by entr,sens LIMIT %s" % LIMIT),

            #------ 15 -- Deleted or rejected without history.
            ("Deleted or rejected entries with no history.  These will not be "\
             "expunged by the usual maintenance scripts because with no history, "\
             "they have no \"age\".",

            "SELECT e.id FROM entr e WHERE stat IN (4,6)"\
                "AND NOT EXISTS (SELECT 1 FROM hist h WHERE h.entr=e.id) "\
                "ORDER by e.id LIMIT %s" % LIMIT),
            ]

        errs = ok = 0
        for n, (msg, sql) in enumerate (checks):
            if args and n+1 not in args: continue
            sqlargs = None   # See the comments in jb.dbread().
            bad = run_check (cur, "Check %d"%(n+1), msg, sql, sqlargs)
            if bad: errs += 1
            else: ok += 1
        if Opts.verbose: print "%d ok" % ok
        if Opts.verbose and errs: print "%d errors" % errs
        if errs: sys.exit(1)

def run_check (cur, name, msg, sql, sqlargs):
        cur.execute (sql, sqlargs)
        rs = cur.fetchall()
        if rs:
            print >>sys.stderr, "\nFailed: %s\n--------" % name
            print >>sys.stderr, msg
            print >>sys.stderr, ', '.join ([str(r) for r in rs]
                             + ['more...' if len(rs) >= LIMIT else ''])
            return 1

        elif Opts.verbose:
            print >>sys.stderr, "\nPassed: %s" % name
            return 0

#=====================================================================

from optparse import OptionParser, Option

def parse_cmdline ():
        u = \
"""\n\t%prog [options] [check-num [check-num [...]]]

Run a number of checks on the database that look for data
problems.  If no errors are found, no output is produced
(if -v not given) and %prog will exit with a status of 0.
If there are errors messages will be written to stderr and
%prog will exit will a status of 1.

Arguments -- List of check numbers to run.  If none given,
    all checks will be run."""

        v = sys.argv[0][max (0,sys.argv[0].rfind('\\')+1):] \
                + " Rev %s (%s)" % __version__
        p = OptionParser (usage=u, version=v, add_help_option=False)

        p.add_option ("-v", "--verbose", default=False, action='store_true',
            help="Note successful checks as well a failed ones in output.")

        p.add_option ("-d", "--database", default="jmdict",
            help="Name of the database to load.")
        p.add_option ("-h", "--host",
            help="Name host machine database resides on.")
        p.add_option ("-u", "--user",
            help="Connect to database with this username.")
        p.add_option ("-p", "--password",
            help="Connect to database with this password.")
        p.add_option ("--help",
            action="help", help="Print this help message.")

        opts, args = p.parse_args ()
        for i in range (len(args)):
            try: args[i] = int (args[i])
            except ValueError: p.error ('Argument "%s" is not an integer' % args[i])

        return args, opts

if __name__ == '__main__':
        args, opts = parse_cmdline ()
        main (args, opts)

