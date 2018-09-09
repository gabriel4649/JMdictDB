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

# Read sound clips from database and write to an XML file.
# Currently, quite incomplete.
# To-do:
# * Add command line args and options output encoding.
#   dtd file selection, xml roor name, sound clips subset, etc.

import sys, os, inspect, pdb
_ = os.path.abspath(os.path.split(inspect.getfile(inspect.currentframe()))[0])
_ = os.path.join (os.path.dirname(_), 'python', 'lib')
if _ not in sys.path: sys.path.insert(0, _)

import jdb, fmtxml

def main (args, opts):
        jdb.reset_encoding (sys.stdout, opts.encoding)
        dir = jdb.find_in_syspath ("dtd-audio.xml")
        dtd = jdb.get_dtd (dir + "/" + "dtd-audio.xml", "JMaudio", opts.encoding)
        print (dtd); print ("<JMaudio>")
        cur = jdb.dbOpen (opts.database, **jdb.dbopts (opts))
        vols = jdb.dbread (cur, "SELECT * FROM sndvol")
        for v in vols:
            print ("\n".join (fmtxml.sndvols ([v])))
            sels = jdb.dbread (cur, "SELECT * FROM sndfile s WHERE s.vol=%s", [v.id])
            for s in sels:
                print ("\n".join (fmtxml.sndsels ([s])))
                clips = jdb.dbread (cur, "SELECT * FROM snd c WHERE c.file=%s", [s.id])
                for c in clips:
                    print ("\n".join (fmtxml.sndclips ([c])))
        print ('</JMaudio>')


from optparse import OptionParser, OptionGroup
from pylib.optparse_formatters import IndentedHelpFormatterWithNL

def parse_cmdline ():
        u = \
"""\n\t%prog [options]

%prog will read audio clip data from a jmdictdb database and write
them in XML form to stdout.

Arguments: none"""

        p = OptionParser (usage=u, add_help_option=False,
                formatter=IndentedHelpFormatterWithNL())

        p.add_option ("--help",
            action="help", help="Print this help message.")
        p.add_option ("-e", "--encoding", default="utf-8",
            help="Encoding for the output XML file.  Default is \"utf-8\".")

        g = OptionGroup (p, "Database access options",
                """The following options are used to connect to a
                database in order to read the entries.

                Caution: On many systems, command line option contents
                may be visible to other users on the system.  For that
                reason, you should avoid using the "--user" and "--password"
                options below and use a .pgpass file (see the Postgresql
                docs) instead. """)

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
        if len (args) != 0: p.error ("%d arguments given, expected at most one" % len(args))
        return args, opts

if __name__ == '__main__':
        args, opts = parse_cmdline()
        main (args, opts)
