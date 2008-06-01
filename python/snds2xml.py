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

# Read sound clips from database and write to an XML file.
# To-do:
# * Add command line parse and options for database access, output
#   encoding. dtd file selection, sound clips subset.

import sys
import jdb, fmtxml

def main (args, opts):
	enc = 'utf-8'
	pout = lambda x:sys.stdout.write (x.encode(enc) + '\n')
	dir = jdb.find_in_syspath ("dtd-audio.xml")
	dtd = jdb.get_dtd (dir + "/" + "dtd-audio.xml", "JMaudio", enc)
	pout (dtd.read())
	dtd.close()

	pout ("<JMaudio>")
	cur = jdb.dbOpen ('jmdict')
	vols = jdb.dbread (cur, "SELECT * FROM sndvol")
	for v in vols:
	    pout ("\n".join (fmtxml.sndvols ([v])))
	    sels = jdb.dbread (cur, "SELECT * FROM sndfile s WHERE s.vol=%s", [v.id])
	    for s in sels:
		pout ("\n".join (fmtxml.sndsels ([s])))
		clips = jdb.dbread (cur, "SELECT * FROM snd c WHERE c.file=%s", [s.id])
		for c in clips:
		    pout ("\n".join (fmtxml.sndclips ([c])))
	pout ('</JMaudio>')

if __name__ == '__main__': 
	args, opts = None, None #parse_cmdline()
	main (args, opts)
