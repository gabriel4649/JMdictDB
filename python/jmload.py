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

# This program will adjust the entr id numbers (both entr.id number
# and references to them in other tables) in a Postgresql dump file
# of a jmdict database, so that the file can be loaded into a database
# with existing entries and not conflict with those entries.

import sys, os, inspect, pdb
_ = os.path.abspath(os.path.split(inspect.getfile(inspect.currentframe()))[0])
_ = os.path.join (os.path.dirname(_), 'python', 'lib')
if _ not in sys.path: sys.path.insert(0, _) 

import re, codecs
import jdb, warns

def main (args, opts):
	eid = opts.starting_id
	if not eid:
	      # Get the starting value of $::eid from the
	      # max values of entr.id found in the database.
	      # If that database id number changes between the time we
	      # read it, and our output file is loaded, the result will
	      # probably be duplicate key errors.
	      # FIXME: should be able to explicitly give these values 
	      #   on the commandline.
	    eid = get_max_ids (opts)
	try: eid = int (eid)
	except ValueError:
	    raise ValueError ("Invalid valid entr.id value '%s', please check -i" % eid)
	rmin = opts.minimum_id; rmax = opts.maximum_id
	eiddelt = eid - rmin;
	print ("Rebasing %d to %d." % (rmin, eid), file=sys.stderr)
	srcid = opts.srcid

	fin  = open (args[0])
	fout = open (opts.output, 'w')

	  # This hash identifies the database tables that have a foreign
	  # reference to entr.id (or primary key in the case of table "entr"),
	  # and the column(s) (by number) of each such.
	offtbl = {
	    'entr'    : [0],    'rdng'    : [0],    'rinf'    : [0],    'kanj'    : [0],
	    'kinf'    : [0],    'sens'    : [0],    'gloss'   : [0],    'misc'    : [0],
	    'pos'     : [0],    'fld'     : [0],    'hist'    : [0],    'dial'    : [0],
	    'lsrc'    : [0],    'ginf'    : [0],    'restr'   : [0],    'stagr'   : [0],
	    'stagk'   : [0],    'xref'    : [0,2],  'xresolv' : [0],    'entrsnd' : [0],
	    'rdngsnd' : [0],    'chr'     : [0],    'cinf'    : [0],    'kresolv' : [0],
	    'freq'    : [0],	'grp'	  : [0],
	    }
	  # Column numbers of id and kw in kwsrc, and src in entr tables.
	KWSRC_ID=0;  KWSRC_KW=1; ENTR_SRC=1

	delt=0;  reading_table_data=False;  updtd=[]

	for line in fin:
	    line = line.rstrip()
	    if reading_table_data:
		if line.startswith (r'\.'):
		    reading_table_data = False
		    delt = 0
		elif delt or srccol >= 0:
		    a = line.split ("\t")
		    if delt:
			for col in cols:
			    v = int(a[col])
			    if v >= rmin and (not rmax or v<rmax): 
				a[col] = str (v + delt)
		    if srccol >= 0:
			a[srccol] = str (srcid)
		    if kwcol >= 0:
			a[KWSRC_KW] = opts.srckw
		    line = "\t".join (a)
	    else:
		mo = re.search (r'^[\\]?COPY\s+([^\s(]+)', line)
		if mo:
		    reading_table_data = True
		    tblnm = mo.group(1)
		    try: cols = offtbl[tblnm]
		    except KeyError: pass
		    else:
			delt = eiddelt;
			updtd.append (tblnm)
		    srccol = kwcol = -1
		    if srcid:
			if tblnm == 'entr':  srccol = ENTR_SRC
		        if tblnm == 'kwsrc': 
			    srccol = KWSRC_ID
			    kwcol  = KWSRC_KW
	    fout.write (line + "\n")

	if updtd and eiddelt != 0:
	    print ("Rebased tables: " + ",".join (updtd), file=sys.stderr)
	else: print ("No changes made", file=sys.stderr)

def get_max_ids (opts):
	  # Get and return 1 + the max values of entr.id found in the
	  # database defined by the connection parameters we were called
	  # with.
	dbh = jdb.dbOpen (opts.database, **jdb.dbopts (opts))
	sql = "SELECT 1+COALESCE((SELECT MAX(id) FROM entr),0) AS entr";
	dbh.execute (sql)
	rs = dbh.fetchall()
	dbh.close()
	return rs[0][0]


#-----------------------------------------------------------------------

from optparse import OptionParser, OptionGroup
from pylib.optparse_formatters import IndentedHelpFormatterWithNL

def parse_cmdline ():
	u = """\

        %prog -o output-filename [-i starting-id-value] 
                  [-m minimum-id] [-x maximum-id]
		  [-s src-adjust-amount]
                  [-u username] [-p password] [-d database] 
                  [-r host] [-e encoding] 
              pgi-filename 

%prog reads a postgresql dump file such as produced by jmparse.py
and adjusts the entr.id numbers in it.  This allows jmparse.py and 
other loader programs to generate entr.id numbers starting at 1, and 
rely on this program to adjust the numbers prior to loading into a 
database to avoid duplicate id numbers when the database already 
contains other entries.  It can also adjust the kwsrc.id and entr.src
numbers to avoid conflict when loading a second copy of the data.

It also allows entries to be extracted from a database with the 
Postgresql 'copy' command and loaded into another database by re-
basing the entr.id numbers and adjusting the kwsrc.id and entr.src
numbers.

Arguments:
	pgi-filename -- Name of input dump file.  Default is 
	    "jmdict.pgi"."""

	v = sys.argv[0][max (0,sys.argv[0].rfind('\\')+1):] \
	        + " Rev %s (%s)" % __version__
	p = OptionParser (usage=u, version=v, add_help_option=False,
		          formatter=IndentedHelpFormatterWithNL())

	p.add_option ("--help",
            action="help", help="Print this help message.")

	p.add_option ("-o", "--output", default=None,
	    dest="output", metavar="FILENAME",
	    help="Name of output postgresql dump file.  "
		"By convention this is usually given the suffix \".dmp\".")

	p.add_option ("-i", "--starting-id", default=0,
	    type="int",
	    help="""Value that the minimum entr id (given 
		by the -m option) will be adjusted to in order to 
		prevent entry id conflicts with existing database entries 
		when these data are loaded.  
		It not given or 0, jmload.py will connect to the database 
		(using the database access options below) to read the max
		id number from the database and use that number plus one.""")

	p.add_option ("-m", "--minimum-id", default=1,
	    type="int", 
	    help="""Only entr id's equal or greater than this will 
		be modified.  This option is useful to avoid changing
		entry id's in things like xref records that may refer
		to entries outside those within the input file.""")

	p.add_option ("-x", "--maximum-id", default=0,
	    type="int",
	    help="""Only entr id's less than this will be
		modified.  If not given or 0, no maximum will apply.  
		This option is useful to avoid changing
		entry id's in things like xref records that may refer
		to entries outside those within the input file.""")

	p.add_option ("-c", "--corpus", default=None,
	    help="""Arg format is "xxx.n" where 'xxx' will be used as the 
		corpus keyword (kwsrc.kw) and 'n' (a number) will be 
		used as the corpus id (kwsrc.id).  All entr.src values 
		will also be adjusted to match 'n'.""")

	p.add_option ("-e", "--encoding", default="utf-8",
            dest="encoding", 
            help="Encoding for output (typically \"sjis\", \"utf8\", "
	      "or \"euc-jp\"")

	g = OptionGroup (p, "Database access options",
		"""If -i was not given, the following options will be used  
		to connect to a database in order to read the max entr.id 
      		value.  If the dump file is loaded into a different database, 
		or if the max entr.id value changes between load_jmdict.pl's 
		read and loading the dump file, it is likely duplicate key  
		errors will occur.""")
	g.add_option ("-d", "--database", default="jmdict",
            help="Name of the database to load.")
	g.add_option ("-h", "--host", default=None,
            help="Name host machine database resides on.")
	g.add_option ("-u", "--user", default=None,
            help="Connect to database with this username.")
	g.add_option ("-p", "--password", default=None,
            help="Connect to database with this password.")
	p.add_option_group (g)

	p.add_option ("-D", "--debug", default=0,
	    type="int", metavar="NUM",
	    help="Print debugging output to stderr.  The number NUM "
		"controls what is printed.  See source code.")

	opts, args = p.parse_args ()
	if len (args) > 1: p.error ("Too many arguments, expected only one.")
	if len (args) < 1: p.error ("Not enough arguments, expected one.")
	if not opts.output: p.error ("--output (-o) option is required.")
	opts.srcid = None
	if opts.corpus:
	    cname, x, cid = opts.corpus.partition(".")
	    if not cname or not cid: 
		p.error ('Bad format for --corpus argument, "%s"' % opts.corpus)
	    opts.srckw = cname
	    try: opts.srcid = int(cid)
	    except ValueError: p_error ('Bad format for --corpus argument, "%s"' % opts.corpus)
	return args, opts

if __name__ == '__main__': 
	args, opts = parse_cmdline()
	main (args, opts)


