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

# Read sound clips from XML file and generate a Postgresql loadable
# dump file.

import sys, os, inspect, pdb
_ = os.path.abspath(os.path.split(inspect.getfile(inspect.currentframe()))[0])
_ = os.path.join (os.path.dirname(_), 'python', 'lib')
if _ not in sys.path: sys.path.insert(0, _) 

import jdb, jmxml, pgi

def main (args, opts):
	m = {'vol':'sndvol', 'sel':'sndfile', 'clip':'snd'}
        inpf = jmxml.JmdictFile( open( args[0] ))
	workfiles = pgi.initialize (opts.tempdir)
	snd_iter = jmxml.parse_sndfile (inpf)
	for obj, typ, lineno in snd_iter:
	    pgi._wrrow (obj, workfiles[m[typ]])
	pgi.finalize (workfiles, args[1], delfiles=(not opts.keep), transaction=True)

from optparse import OptionParser, OptionGroup

def parse_cmdline ():
	u = """\

        %prog xml-filename pgi-filename

%prog reads an XML file containing JMdict audio data and will 
write a loadable Postgresql dump file.

Arguments:
	xml-filename -- Name of input XML file.
	pgi-filename -- Name of output postgresql dump file (typically
			given a .pgi suffix)."""

	v = sys.argv[0][max (0,sys.argv[0].rfind('\\')+1):] \
	        + " Rev %s (%s)" % __version__
	p = OptionParser (usage=u, version=v, add_help_option=False)

	p.add_option ("-k", "--keep", default=False,
            dest="keep", action="store_true",
            help="Do not delete temporary files after program exits.")

	p.add_option ("-t", "--tempdir", default=".",
            dest="tempdir", metavar="DIRPATH",
            help="Directory in which to create temporary files.")

	p.add_option ("--help",
            action="help", help="Print this help message.")

	opts, args = p.parse_args ()
	if len (args) != 2: p.error ("%d arguments given, expected two" % len(args))

	return args, opts


if __name__ == '__main__': 
	args, opts = parse_cmdline()
	main (args, opts)
