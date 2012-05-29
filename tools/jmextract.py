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
from __future__ import print_function, absolute_import, division
from future_builtins import ascii, filter, hex, map, oct, zip

__version__ = ('$Revision$'[11:-2],
               '$Date$'[7:-11]);

# This program will read a JMdict XML file and extract selected entries.

import sys, os, inspect, pdb
_ = os.path.abspath(os.path.split(inspect.getfile(inspect.currentframe()))[0])
_ = os.path.join (os.path.dirname(_), 'python', 'lib')
if _ not in sys.path: sys.path.insert(0, _)

import re, codecs
import jdb, jmxml

def main (args, opts):
        jdb.KW = KW = jdb.Kwds (jdb.std_csv_dir())
        seqlist = []; first = True
        infn = args.pop (0)
        if opts.seqfile:
            seqlist = parse_seqfile (opts.seqfile)
        else:
            for arg in args:
                seq, x, cnt = arg.partition (',')
                seqlist.append ((int (seq), int (cnt or 1)))
        fin = codecs.open (infn, "r", "utf_8_sig")
        if seqlist:
            for seq,entr in jmxml.extract (fin, seqlist, opts.dtd, opts.all):
                print (seq, file=sys.stderr)
                if opts.dtd and first:
                    toplev, dtd = seq, entr
                    print (('\n'.join (dtd)).encode (opts.encoding, 'backslashreplace'))
                    print (("<%s>" % toplev))
                    first = False;  continue
                print (('\n'.join (entr)).encode (opts.encoding, 'backslashreplace'))
            if opts.dtd: print (("</%s>" % toplev))
        else: print ("No seq numbers!", file=sys.stderr)

def parse_seqfile (fname):
        seqlist = []
        f = open (fname)
        for lnnum, ln in enumerate (f):
            if ln.isspace() or re.search (r'^\s*#', ln): continue
            lnx = re.sub (r'\s*#.*', '', ln)
            lnx = re.sub (r'\s+', ' ', lnx).strip()
            seq, dummy, count = lnx.partition (' ')
            try: seqlist.append ((int (seq), int (count or 1)))
            except ValueError:
                print ("Line %d, bad format: %s" % (lnnum+1, ln.rstrip()), file=sys.stderr)
        return seqlist

#######################################################################

from optparse import OptionParser
from pylib.optparse_formatters import IndentedHelpFormatterWithNL

def parse_cmdline ():
        u = \
"""\
Usage:
  %prog [options] filename seqnum[,count] [...]
  %prog [options] -s seqfile filename

  Extracts entries from a JMdict or JMnedict XML file 'filename'.
  The extracted entry(s), prepended with the files's DTD (unless
  -d was given), is written to stdout.  The arguments give the
  sequence numbers of the entries to be written.  Each can optionally
  be followed by a comma and a second number that is a count of
  the number successive entries to be extracted (including the
  first.  I.e., 1000320,3 will extract entry 1000320 and the next
  two entries.)

  The Monash JMnedict file does not contain sequence numbers.  In
  this case the 'seq' arguments are interpreted as ordinal entry
  numbers (starting from one).

  %prof assumes the entries in the input file are ordered by seq
  number and it will stop scanning for entries after a seq number
  greater than the largest seq number in the argument list is seen.
  The can be disabled, resulting is a full scan of the input file,
  with the -f option.

Arguments:
        filename -- Name of input JMdict or JMnedict xml file.
        seqnum,count -- Seq number (or ordinal number in the
            case of JMnedict) of an entry to extract optionally
            followed by a comma and count of sucessive entries
            (including 'seq') to extract."""

        v = sys.argv[0][max (0,sys.argv[0].rfind('\\')+1):] \
                + " Rev %s (%s)" % __version__
        p = OptionParser (usage=u, version=v, add_help_option=False,
                formatter=IndentedHelpFormatterWithNL())

        p.add_option ("--help",
            action="help", help="Print this help message.")

        p.add_option ("-s", "--seqfile", default=None,
            help="""Name of a file containing seq number and
           count pairs, one pair per line with the count being
           optional, but if present, separated by whitespace.
           Comments start with "#" and are ignored as are blank
           lines.""")

        p.add_option ("-d", "--dtd", default=True,
            action="store_false",
            help="Don't prepend the DTD extracted from the input "
                "file to the output.")

        p.add_option ("-a", "--all", default=False,
            action="store_true",
            help="""Scan the whole file looking for entries.  Normally
            %prog stops scanning after a sequence number greater than
            the largest seq number in arguments is seen, since it assumes
            sequence numbers are in increasing order.""")

        p.add_option ("-e", "--encoding", default='utf-8',
            type="str", dest="encoding",
            help="Encoding for output and error messages.  Note that "
                "this does not change the encoding declaration in the "
                "output DTD (if any).  It is intended to facilitate "
                "viewing output when directed to an interactive screen.")

        opts, args = p.parse_args ()
        if opts.seqfile:
            if len (args) < 1: p.error ("Not enough arguments, expected input filename.")
            if len (args) > 1: p.error ("Too many arguments, only input filename allowed when -w given.")
        else:
            if len (args) < 2: p.error ("Not enough arguments, expected at least two.")
        return args, opts

if __name__ == '__main__':
        args, opts = parse_cmdline()
        main (args, opts)
