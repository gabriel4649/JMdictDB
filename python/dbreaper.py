#!/usr/bin/env python
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

__version__ = ('$Revision$'[11:-2],
               '$Date$'[7:-11]);

# Delete old deleted or rejected entries from the database after
# logging them to a file.

import sys, datetime, pdb
import jdb, fmtxml, edfmt

def main (args, opts):
          # Open the database.  jdb.dbopts() extracts the db-related
          # options from the command line options in 'opts'.
        cur = jdb.dbOpen (opts.database, **jdb.dbopts (opts))
        stats = [jdb.KW.STAT['D'].id] if opts.deleted else []
        if opts.rejected: stats.append (jdb.KW.STAT['R'].id)
        entries, tmptbl = find_entries (cur, stats, opts.corpus, str(opts.age)+' days')
        if opts.outfile:
            outf = open_outfile (opts.outfile)
            write_log (entries, outf)
        if opts.verbose:
            for e in entries:
                ts = e._hist[-1].dt.isoformat(' ')[:10]
                  # FIXME: Want seq number in output, but edfmt.entr() should
                  #  provide it like wwwjdic, following the last gloss, not us.
                print >>sys.stderr, "[%s,%s] %s %s" % (e.src, e.id, ts, edfmt.entr (e))
        cur.execute ("BEGIN")
        delcnt = del_entries (cur, tmptbl)
        if opts.noaction: cur.execute ("ROLLBACK")
        else: cur.execute ("COMMIT")
        if opts.verbose:
            print >>sys.stderr, "%d entries read, %d entries deleted"\
                                 % (len(entries), delcnt)
            if opts.noaction:
                print >>sys.stderr, "%d deleted rolled back" % delcnt

def find_entries (cur, stat, sopts='', interval='30 days'):
        # cur -- An open psycopg2 cursor to a JMdictDB database.
        # stat -- A sequence of kwstat.id numbers.  Only entries with one
        #       of these values in its 'stat' column will be processed.
        #       4 is "deleted", 6 is "rejected".
        # interval -- A string giving a Postgresql interval spec.
        # sopts -- A string, described in the help for --corpus,
        #       giving the corpra to be processed.

        sclause = parse_corpus_opt (sopts, 'e.src')
        sql = "SELECT e.id "\
                "FROM entr e "\
                "JOIN hist h ON h.entr=e.id "\
                "WHERE e.stat IN %%s AND NOT e.unap %s "\
                  "AND NOT EXISTS (SELECT 1 FROM entr WHERE dfrm=e.id) "\
                "GROUP BY e.id "\
                "HAVING MAX(dt)<(CURRENT_TIMESTAMP AT TIME ZONE 'utc'-%%s::INTERVAL) "\
                "ORDER BY id" % sclause
          # 'stat' needs to be a tuple when used as the argument for an IN
          # clause in pysgopg2.  psycopg2 will convert a list to a Postgresql
          # array which won't work.
        tmptbl = jdb.entrFind (cur, sql, (tuple(stat), interval))
        entrs, raw = jdb.entrList (cur, tmptbl, None, ord="src,seq,id", ret_tuple=True)
        jdb.augment_xrefs (cur, raw['xref'])
        return entrs, tmptbl

def write_log (entrs, outf):
          # FIXME: this code is similar to code in extrs2xml.py,
          #  should factor out into a common library.
        corpora = set()
          # Generate xml for each entry and write it to the output file.
        for e in entrs:
            if e.src not in corpora:
                txt = '\n'.join (fmtxml.corpus ([e.src]))
                outf.write (txt.encode ('utf-8') + "\n")
                corpora.add (e.src)
            grp = getattr (e, '_grp', [])
            for g in grp:
                gob = jdb.KW.GRP[g.kw]
                if not hasattr (gob, 'written'):
                    gob.written = True
                    txt = '\n'.join (fmtxml.grpdef (gob))
                    outf.write (txt.encode ('utf-8') + "\n")
            txt = fmtxml.entr (e, compat=None, genhists=True)
            outf.write (txt.encode ('utf-8') + "\n")

def del_entries (cur, tmptbl):
        sql = "DELETE FROM entr WHERE id in (SELECT id FROM %s)" % tmptbl.name
        cur.execute (sql, None)
        return cur.rowcount

def open_outfile (outfname):
        if outfname is '-': outf = sys.stdout
        else: outf = open (outfname, "at")
        ts = datetime.datetime.now().isoformat(' ')
        print >>outf, "\n<!-- %s: reaper.py -->" % (ts,)
        return outf

def parse_corpus_opt (s, src_col):
          # FIXME: this code is similar to code in extrs2xml.py,
          #  should factor out into a common library.
        if not s: return ''
        in_srcs = [];  other_srcs = []; terms = []
        terms = s.split(',')
        for t in terms:
            t1, x, t2 = t.partition (':')
            if t1 and not t1.isdigit(): t1 = jdb.KW.SRC[t1].id
            if t2 and not t2.isdigit(): t2 = jdb.KW.SRC[t2].id
            if not x: in_srcs.append (str(int(t1)))
            else:
                if not t2: other_srcs.append ("%s>=%d" % (src_col, int(t1)))
                elif not t1: other_srcs.append ("%s<=%d" % (src_col, int(t2)))
                else: other_srcs.append ("%s BETWEEN %d AND %d" % (src_col, int(t1),int(t2)))
        if in_srcs:
            if len (in_srcs) == 1: other_srcs.append ("%s=%s" % (src_col, in_srcs[0]))
            else: other_srcs.append ("%s IN(%s)" % (src_col, ",".join (in_srcs)))
        clause = " AND ".join (other_srcs)
        if clause: clause = " AND " + clause
        return clause

from optparse import OptionParser, OptionGroup
from pylib.optparse_formatters import IndentedHelpFormatterWithNL

def parse_cmdline ():
        u = \
"""\n\t%prog [options] [outfile]

%prog will remove old deleted and rejected entries from a jmdictdb
database after first writing them in as a series of XML <entry>
elements to a file.  Options control whether entries that are deleted,
rejected or both are processed as well as what corpus they are in
and their minumium age.  Entries that are edits referenced by other
entries (via the 'dfrm' field) are never touched.

Arguments: none"""

        v = sys.argv[0][max (0,sys.argv[0].rfind('\\')+1):] \
                + " Rev %s (%s)" % __version__
        p = OptionParser (usage=u, version=v, add_help_option=False,
                formatter=IndentedHelpFormatterWithNL())

        p.add_option ("--help",
            action="help", help="Print this help message.")

        p.add_option ("-o", "--outfile", default=None,
            help="Name of file to write XML output to.  The output file "
                "will always be opened in append mode.  If not given, no "
                "XML output will be produced.  If \"-\", output is written "
                "to stdout.  Note that a complete XML file is not produced; "
                "there is no DTD and no root element in the output, just a "
                "series of extended-JMdict entry elements.")

        p.add_option ("-d", "--deleted", default=False, action='store_true',
            help="Process deleted entries.  At least one of -d or -r is required.")

        p.add_option ("-r", "--rejected", default=False, action='store_true',
            help="Process rejected entries.  At least one of -r or -d is required.")

        p.add_option ("-a", "--age", type="int", default="30",
            help="Gives the minimum age in days for an entry to be expunged.  "
                "An entry's age is based on the timestamp of its most recent "
                "history record.  Default is 30 days.")

        p.add_option ("-s", "--corpus", default=None,
            help="""Restrict processed entries to those belonging to the
                corpora defined by this option.  The format is a list of
                comma separated specifiers.  Each specifier is either a
                corpus id number, corpus name, or a range.  A range is a
                corpus id number or corpus name followed by a colon, a
                colon followed by a corpus id number or corpus name, or a
                corpus id number or corpus name followed by a colon followed
                by a corpus id number or corpus name.

                Examples:

                    -s 2         Restrict to corpus id 2 (jmnedict).

                    -s jmnedict  Restrict to corpus id 2 (jmnedict).

                    -s 3,26,27   Restrict to the corpora 3, 26, or 27.

                    -s 10:13     Restrict to corpora 10, 11, 12, or 13.

                    -s test:     Restrict to corpora with an id greater
                                 or equal to the id of corpus "test".

                    -s jmdict-examples,test
                                 Restrict to corpora with id numbers
                                 between "jmdict" and "examples", or equal
                                 to the id of corpus "test".

                Default is all corpora.""")

        p.add_option ("-n", "--noaction", default=False, action='store_true',
                help="Go through the motions, including finding the outdated "
                    "entries, writing the log file and attempting the deletions "
                    "but rollback the transaction at the end so that no changes "
                    "are actually made to the database.")

        p.add_option ("-v", "--verbose", default=False, action='store_true',
                help="Print some summary info to stderr before exit."),

        g = OptionGroup (p, "Database access options",
                """The following options are used to connect to a
                database in order to read the entries.

                Caution: On many systems, command line option contents
                may be visible to other users on the system.  For that
                reason, you should avoid using the "--user" and "--password"
                options below and use a .pgpass file (see the Postgresql
                docs) instead. """)

        g.add_option ("-D", "--database", default="jmdict",
            help="Name of the database to load.  Default is \"jmdict\".")
        g.add_option ("-H", "--host", default=None,
            help="Name host machine database resides on.")
        g.add_option ("-U", "--user", default=None,
            help="Connect to database with this username.")
        g.add_option ("-P", "--password", default=None,
            help="Connect to database with this password.")
        p.add_option_group (g)

        opts, args = p.parse_args ()
        if len (args) > 0: p.error ("No arguments expected.")
        if not opts.deleted and not opts.rejected:
            p.error ('At least one of --deleted or --rejected must be given.')
        return args, opts

if __name__ == '__main__':
        args, opts = parse_cmdline()
        main (args, opts)
