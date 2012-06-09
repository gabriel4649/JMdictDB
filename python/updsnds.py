#!/usr/bin/env python3
#######################################################################
#  This file is part of JMdictDB.
#  Copyright (c) 2008 Stuart McGraw
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
#  51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
#######################################################################


__version__ = ('$Revision$'[11:-2],
               '$Date$'[7:-11]);

# This program will read a label file produced by Audacity,
# attempt to find matching sounds already in the database,
# and update the strt and leng parameters of the existing
# sounds from data in the label file.

import sys, os, inspect, pdb
_ = os.path.abspath(os.path.split(inspect.getfile(inspect.currentframe()))[0])
_ = os.path.join (os.path.dirname(_), 'python', 'lib')
if _ not in sys.path: sys.path.insert(0, _)

import os.path
import jdb

def main (args, opts):
          # Open the database.  jdb.dbopts() extracts the db-related
          # options from the command line options in 'opts'.
        if sys.stdout.encoding != opts.encoding:
            sys.stdout = open (sys.stdout.fileno(), 'w', encoding=opts.encoding)
        cur = jdb.dbOpen (opts.database, **jdb.dbopts (opts))
        fidnum = args[0]
        lbls = args[1]
        xx, rsb = labels_from_db (cur, fidnum)
        rsa = labels_from_file (lbls)
        update, nomatch = align (rsa, rsb, opts.quiet)
        updated = added = None
        ans = ask_action()
        if ans == 'i':   updated, added = do_interactive (cur, fidnum, update, nomatch)
        elif ans == 'u': updated, added = do_noninteractive (cur, fidnum, update, nomatch)
        if updated is not None:
            pout ("%d sound records updated" % updated)
        if added is not None:
            pout ("%d sound records added" % added)
            for a in nomatch:
                if hasattr (a, 'id'):
                    pout ("Added: %d:(%d,%d,%s)" % (a.id, a.strt, a.leng, a.trns))

def ask_action():
        prompt = "update and add non-matched (u), interactive (i), quit (q)? "
        while True:
            try: ans = input (prompt).strip()
            except IOError: return
            if ans not in ('uiq'): print ('Answer the bloody question')
            else: break
        return ans

def labels_from_db (cur, filenum):
        sql = "SELECT v.loc AS vloc, f.loc AS floc " \
                "FROM sndfile f JOIN sndvol v ON f.vol=v.id " \
                "WHERE f.id=%s"
        rs = jdb.dbread (cur, sql, [filenum])
        if not rs: return None, None
        if len (rs) > 1: raise RuntimeError
        fname = os.path.join (rs[0].vloc, rs[0].floc)

        sql = "SELECT * FROM snd s WHERE s.file=%s ORDER BY strt,leng"
        rs = jdb.dbread (cur, sql, [filenum])
        return fname, rs

def labels_from_file (fname):
        rs = []
        f = open (fname, 'r', encoding='utf_8_sig')
        for line in f:
            s, e, trns = line.split('\t')
            strt = int (float (s) * 100)
            end = int (float (e) * 100)
            rs.append (jdb.Obj (strt=strt, leng=end-strt, trns=trns.strip()))
        f.close()
        return rs

def align (rsa, rsb, quiet):
        for a in rsa:
            a._ov = (None, 0)
            for b in rsb:
                ol = overlap (a, b)
                if ol: match (a, b, ol)
        update = [];  nomatch = []
        for a in rsa:
            b, ov = a._ov
            if not b:
                pout ("No match found for (%d,%d,%s)"  % (a.strt,a.leng,a.trns))
                nomatch.append (a)
            else:
                if a.strt==b.strt and a.leng==b.leng and a.trns==b.trns:
                    action = 'Skip'
                else:
                    action = 'Update'
                    update.append (a)
                if not quiet or action != 'Skip' :
                    pout ("%s%s %d:(%d,%d,%s) to (%d,%d,%s) [ov=%f]" %
                          ('*' if b.trns != a.trns else '', action,
                          b.id,b.strt,b.leng,b.trns,a.strt,a.leng,a.trns,ov))
        if not quiet:
            b_changed = [a._ov[0] for a in rsa]
            b_unchanged = [b for b in rsb if b not in b_changed]
            for b in b_unchanged:
                pout ("No change: %d:(%d,%d,%s)" % (b.id,b.strt,b.leng,b.trns))
        return update, nomatch

def match (a, b, ol):
        ov = min (ol / float(a.leng), ol / float(b.leng))
        xb, xov = a._ov
        if ov > xov:
            if xb: pout ("Discarding previous match %d:(%d,%d,%s,%f) on (%d,%d,%s)" % \
                                (xb.id,xb.strt,xb.leng,xb.trns,xov,a.strt,a.leng,a.trns))
            a._ov = (b, ov)

def overlap (a, b):
        sa = a.strt; ea = sa + a.leng
        sb = b.strt; eb = sb + b.leng;
        if ea <= sb or sa > eb: return 0
          # Calculate overlap
        sx = max (sa, sb);  ex = min (ea, eb)
        return ex - sx

def pout (s):
        print (s.encode ('sjis'))

def do_noninteractive (cur, sndfilenum, update, nomatch):
        updated = added = 0
        sql = "UPDATE snd SET strt=%s,leng=%s,trns=%s WHERE id=%s"
        for a in update:
            args = (a.strt, a.leng, a.trns, a._ov[0].id)
            ##pout ("%s (%s)" % (sql, ",".join([unicode(x) for x in args])))
            cur.execute (sql, args)
            updated += cur.rowcount
        sql = "INSERT INTO snd(file,strt,leng,trns) VALUES(%s,%s,%s,%s) RETURNING id"
        for a in nomatch:
            args = args = (sndfilenum, a.strt, a.leng, a.trns)
            ##pout ("%s (%s)" % (sql, ",".join([unicode(x) for x in args])))
            cur.execute (sql, args)
            added += cur.rowcount
            rs = cur.fetchall()
            a.id = rs[0][0]; a.file = sndfilenum
        cur.connection.commit()
        return updated, added

from optparse import OptionParser, OptionGroup
from pylib.optparse_formatters import IndentedHelpFormatterWithNL

def parse_cmdline ():
        u = \
"""\n\t%prog [options] sndfile-num [sndfile-num [...]]

%prog will generate an Audacity label file for each sndfile
entry in the database whose id number is given as an argument.


Arguments:
        outfile -- Name of the output XML file.  If not given output
                is written to stdout."""

        v = sys.argv[0][max (0,sys.argv[0].rfind('\\')+1):] \
                + " Rev %s (%s)" % __version__
        p = OptionParser (usage=u, version=v, add_help_option=False,
                formatter=IndentedHelpFormatterWithNL())

        p.add_option ("--help",
            action="help", help="Print this help message.")

        p.add_option ("-e", "--encoding", default="utf-8",
            help="Encoding for the output.  Default is \"utf-8\".")

        p.add_option ("-q", "--quiet", default=False,
            action="store_true",
            help='Supress the "No change" and "Skip" messages.')

        g = OptionGroup (p, "Database access options",
                """The following options are used to connect to a
                database in order to read the entries.  """)
        g.add_option ("-d", "--database", default="jmdict",
            help="Name of the database to load.  Default is \"jmdict\".")
        g.add_option ("-h", "--host", default=None,
            help="Name host machine database resides on.")
        g.add_option ("-u", "--user", default=None,
            help="Connect to database with this username.")
        g.add_option ("-p", "--password", default=None,
            help="Connect to database with this password.")
        p.add_option_group (g)

        opts, args = p.parse_args ()
        if len (args) < 1: p.error ("No arguments given, expected at least one.")
        return args, opts

if __name__ == '__main__':
        args, opts = parse_cmdline()
        main (args, opts)
