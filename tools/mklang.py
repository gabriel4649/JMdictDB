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
#  51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
#######################################################################


__version__ = ('$Revision$'[11:-2],
               '$Date$'[7:-11]);

import sys

def main (args, opts):
        f = open (args[0], 'r', 'utf_8_sig')
        for n,ln in enumerate (f):
            if (opts.format):
                id, part2b, part2t, part1, scope, type, ref_name = ln.split('\t')
                ref_name = ref_name.rstrip()
                lang = part2b or id
            else:
                id, part2b, part2t, ref_name, other = ln.split ('|')
                if id == 'qaa-qtz': continue
                lang = id
            if n == 0: out (opts.style, 1, 'eng', 'English')
            else:
                if lang != 'eng': out (opts.style, n+1, lang, ref_name)

def out (style, n, lang, descr):
        if style == 'csv':
            print (('%d\t%s\t%s' % (n, lang, descr)).encode('utf-8'))
        elif style == 'perl':
            print (("\t    '%s' => %d,\t# %s" % (lang, n, descr)).encode('utf-8'))
        else:
            raise ValueError ("Invalid 'style' parameter: '%s'" % style)


from optparse import OptionParser

def parse_cmdline ():
        u = \
"""\n\t%prog [-s [csv|perl]] iso-639-file

  This program will read a ISO 639 dataset file containing the complete
  ISO 639 (-2 or -3) standard language codes dataset and generate,
  depending on the command line options given, a tab-delimited csv table
  suitable for use as the pg/data/kwlang.csv file, or a snippent of perl
  code suitable for inclusion in perl/lib/jmdictxml.pm.  Note that the
  -2 and -3 standards are quite different and will produce different output
  from this program.
  Output is written to stdout and is utf-8 encoded.

  The ISO 639-2 dataset file is available from (use the utf-8 version):
    http://www.loc.gov/standards/iso639-2/ascii_8bits.html
  The ISO 639-3 dataset file is available from:
    http://www.sil.org/iso639-3/download.asp

Arguments:
        iso-639-file -- Name of the file containing the iso-639 data."""

        v = sys.argv[0][max (0,sys.argv[0].rfind('\\')+1):] \
                + " Rev %s (%s)" % __version__
        p = OptionParser (usage=u, version=v, add_help_option=False)
        p.add_option ("-2", "--iso239-2",
            action="store_false", dest="format",
            help="Input file is a \"|\" delimited ISO-639-2 file. ")
        p.add_option ("-3", "--iso239-3",
            action="store_true", dest="format", default=True,
            help="Input file is a tab delimited ISO-639-3 file. ")
        p.add_option ("-s", "--style", default='csv',
            type="str", dest="style",
            help="Output style.  Must be either \"csv\" or \"perl\".")
        p.add_option ("--help",
            action="help", help="Print this help message.")
        opts, args = p.parse_args ()
        if len(args) != 1: p.error("Expected one command line argument.")
        return args, opts

if __name__ == '__main__':
        args, opts = parse_cmdline()
        main (args, opts)
