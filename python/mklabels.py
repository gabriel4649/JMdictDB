#!/usr/bin/env python
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
#  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA
#######################################################################


__version__ = ('$Revision$'[11:-2],
               '$Date$'[7:-11]);

# Write an Audacity label track for the sound clips in a
# sound file.  Run with --help option for details.

import sys, os, inspect, pdb
_ = os.path.abspath(os.path.split(inspect.getfile(inspect.currentframe()))[0])
_ = os.path.join (os.path.dirname(_), 'python', 'lib')
if _ not in sys.path: sys.path.insert(0, _)

import os.path
import jdb

def main (args, opts):
          # Open the database.  jdb.dbopts() extracts the db-related
          # options from the command line options in 'opts'.
        cur = jdb.dbOpen (opts.database, **jdb.dbopts (opts))
        for f in args:
            fname, ldata = getlabels (cur, f)
            if not fname: print ("No data for sound file '%s'" % str(f), file=sys.stderr)
            else:
                print (fname)
                for r in ldata:
                    strt = r.strt/100.0
                    print ("%f\t%f\t%s" % (strt, strt + r.leng/100.0,
                                          r.trns.encode(opts.encoding)))

def getlabels (cur, filenum):
        sql = "SELECT v.loc AS vloc, f.loc AS floc " \
                "FROM sndfile f JOIN sndvol v ON f.vol=v.id " \
                "WHERE f.id=%s"
        rs = jdb.dbread (cur, sql, [filenum])
        if not rs: return None, None
        if len (rs) > 1: raise RuntimeError
        fname = os.path.join (rs[0].vloc, rs[0].floc)

        sql = "SELECT strt,leng,trns,notes FROM snd s WHERE s.file=%s ORDER BY strt,leng"
        rs = jdb.dbread (cur, sql, [filenum])
        return fname, rs

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
