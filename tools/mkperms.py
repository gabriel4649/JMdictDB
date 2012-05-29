#!/usr/bin/env python
#######################################################################
#  This file is part of JMdictDB. 
#  Copyright (c) 2009 Stuart McGraw 
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
#
# Generate a set SQL commands to properly set table permissions
# in a JmdictDB database during creation of a new database.
# Provide the pg/mktables.sql file on stdin.  Output written to 
# stdout should be saved in file pg/mkperms.sql.
#
from __future__ import print_function, absolute_import, division
from future_builtins import ascii, filter, hex, map, oct, zip 

__version__ = ("$Revision$"[11:-2],
	       "$Date$"[7:-11])

import sys, re, datetime

def main (args, opts):
	tables = [    # Hardwire these seq names since they're
		      # hard to pull out of mktables.sql.
		  'entr_id_seq',
		  'kwgrp_id_seq',
		  'snd_id_seq',
		  'sndfile_id_seq',
		  'sndvol_id_seq']
	for filename in args:
	    tables.extend (extract_object_names (filename))
	tlist = ','.join (tables)
	print ("GRANT ALL ON %s TO jmdictdb;"     % tlist)
	print ("GRANT SELECT ON %s TO jmdictdbv;" % tlist)

def extract_object_names (filename):
	tables = []
	pattern = r'\s*CREATE\s+((TABLE)|((OR\s+REPLACE\s+)?VIEW))\s+([A-Za-z0-9_]+)'
	fl = open (filename)
	for ln in fl:
	    mo = re.match (pattern, ln, re.IGNORECASE)
	    if mo: tables.append (mo.group(5))
	return tables

if __name__ == '__main__': 
	args, opts = sys.argv[1:], None
	sys.argv[0] = sys.argv[0].split('\\')[-1].split('/')[-1]
	main (args, opts)
