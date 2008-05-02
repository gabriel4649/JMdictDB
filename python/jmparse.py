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

import jdb, jmxml, pgi, warns, kwstatic
jdb.KW = kwstatic.KW
import fmt

def main (args, opts):
	global Logfile

	  #FIXME: need to come up with a framework for managing
	  #  dicrepencies between database kw* table 'kw' codes,
	  #  and entity code used in xml.  Currently there are
	  #  no such discrepencies but should be prepared,
	  #  Don't want to maintain a full set independently as 
	  #  we did in Perl (jmdictxml.pm); maybe just a list of
	  #  exceptions. 
	jmxml.XKW = jmxml.xml_lookup_table (kwstatic.KW)
	jdb.KW = kwstatic.KW

	xlang = None
	if opts.lang:
	    xlang = [KW.LANG[x].id for x in opts.lang.split(',')]

        inpf = jmxml.JmdictFile( open( args[0] ))
	tmpfiles = pgi.initialize (opts.tempdir)
	if opts.logfile: warns.Logfile = open (opts.logfile, "w")
	if opts.encoding: warns.Encoding = opts.encoding

	first = True;  eid = 0
	for eid,entr in enumerate (jmxml.parse_xmlfile (inpf, opts.begin, opts.count,
							opts.extract, xlang, toptag=True)):
	    if first: 
		  # Note that 'entr' here is actually the tag name of the
		  # top-level element in the xml file, typically either
		  # "JMdict" or "JMnedict".
		corpid, corprec \
		    = pgi.parse_corpus_opt (opts.corpus, entr, inpf.created)
		if corprec: pgi.wrcorp (corprec, tmpfiles)
		first = False
		continue
	    #print fmt.entr (entr)
	    if not ((eid - 1) % 1550): 
		sys.stdout.write ('.'); sys.stdout.flush()
		warns.Logfile.flush()
	    entr.src = corpid
	    jdb.setkeys (entr, eid)
	    pgi.wrentr (entr, tmpfiles)
	sys.stdout.write ('\n')
	pgi.finalize (tmpfiles, opts.output, not opts.keep)


from optparse import OptionParser
from pylib.optparse_formatters import IndentedHelpFormatterWithNL

def parse_cmdline ():
	u = \
"""\n\t%prog [options] [filename]

%prog will read a jmdict XML file such as JMdict or JMnedict and
create a file that can be subsequently loaded into a jmdict Postgresql 
database (usually after pre-processing by jmload.pl).

Arguments: 
	filename -- Name of input jmdict xml file.  Default is
	"JMdict"."""

	v = sys.argv[0][max (0,sys.argv[0].rfind('\\')+1):] \
	        + " Rev %s (%s)" % __version__
	p = OptionParser (usage=u, version=v, add_help_option=False, 
		formatter=IndentedHelpFormatterWithNL())

	p.add_option ("--help",
            action="help", help="Print this help message.")

	p.add_option ("-o", "--output", default="JMdict.pgi",
	    dest="output", metavar="FILENAME",
	    help="Name of output postgresql rebasable dump file.  "
		"By convention this is usually given the suffix \".pgi\".")

	p.add_option ("-b", "--begin", default=0,
            dest="begin", type="int", metavar="SEQNUM",
            help="Sequence number of first entry to process.  If not "
		"given or 0, processing will start with the first entry.")

	p.add_option ("-c", "--count", default=0,
            dest="count", type="int", metavar="NUM",
            help="Number of entries to process.  If not given or 0, "
		"all entries in the file will be processed.")

	p.add_option ("-s", "--corpus",
            dest="corpus", default=None,
            help="""\
	CORPUS defines a corpus record (in table kwsrc) to which all 
	entries in the input file will be assigned.  It is set of one
	to four comma separated items.  Spaces are not permitted within
	the string.

	The CORPUS items are:

	  id -- Id number of the corpus record.

          kw -- A short string used as an identifier for the corpus. 
	     Must start with a lowercase letter followed by zero or
	     more lowercase letters, digits, or underscore ("_") 
	     characters.  Must not already be used in the database.

	  dt -- The corpus' date in the form: "yyyy-mm-dd".

	  seq -- The name of a Postgresql sequence that will be used 
	     to assign sequence numbers of entries of this corpus when
	     those entries have no explicit sequence number.  Note that 
	     this does not affect entries loaded by jmdict which always
	     assigns explicit seq numbers to entries it generates.
	     There are five predefined sequences:
		jmdict_seq, jmnedict_seq, examples_seq, test_seq, seq.  
	     You can create additional sequences if required.

	[N.B. that the corpus table ("kwsrc") also has two other columns, 
	'descr' and 'notes' but jmparse provides no means for setting 
	their values.  They can be updated in the database table after  
	kwsrc is loaded, using standard Postgresql tools like "psql".]

	Unless only 'id' is given in the CORPUS string, a corpus record 
	will be written to the output .pgi file.  A record with this 'id'
	number or 'kw' must not exist in the database when the entries
	are later loaded.

	If only 'id' is given in CORPUS, a new corpus record will not 
	be created; rather, all enties will be assigned the given corpus 
	id number and it will be assumed that a corpus record with that
	id number already exists when the entries are later loaded.

	If this option is not given at all, jmparse will examine the
	name of the top-level element in the input file.  If it is
	"JMdict", jmparse will use "1", "jmdict", and "jmdict_seq"
	for 'id', 'kw', and 'seq' respectively.  If it is "JMnedict",
	jmparse will use "2", "jmnedict", and "jmnedict_seq" for 'id',
	'kw', and 'seq' respectively.  In both cases it will use the
	date extracted from the "date comment" in the input XML file
	if available for 'dt'.  
	If the top-level element name is neither "JMdict" or "JMnedict"
	an error will be reported.

	Examples:

	    <no option>

		Will create a new corpus record based on information
		extracted from the XML input file as described above.
		This is the usual choice when processing the JMdict 
		or jmnedict files downloaded from Monash.

	    -s 6,jmdict_2,2008-03-15,jmdict_seq

		Will create a new corpus (kwsrc table) record with
		an id of 6, and name of "jmdict_2", a date of "2008-
		03-15.  It will use the same sequence generator as
		the jmdict corpus (should that also be loaded).

	    -s 15,,,myseq

		Will create a new corpus (kwsrc table) record with
		an id of 15.  The name will be taken from the top-
`		level element in the input file, and the date from
		the date comment in the file if it exists.  The corpus
		record will specify sequence "myseq" (which you must
		create sometime before later attempting to add an entry 
		with no	sequence number). 

	    -s 5

		Will give all entries produced by this execution
		of jmparse.py a corpus id (entr.src value) of 5 but
		will not generate any kwsrc record in the output
		.pgi file.  When these entries are loaded into the 
		database a kwsrc table record with id=5 must already
		exist or an integrity error will occur.""")

	p.add_option ("-g", "--lang", default=None, 
            dest="lang",
            help="Include only gloss tag with language code LANG.  "
		"If not given default is to include all glosses regardless "
		"of language.")

	p.add_option ("-y", "--extract", default=False, 
            dest="extract", action="store_true",
            help="Extract literal and trans information from glosses.")

	p.add_option ("-k", "--keep", default=False,
            dest="keep", action="store_true",
            help="Do not delete temporary files after program exits.")

	p.add_option ("-l", "--logfile", default="jmparse.log",
            dest="logfile", metavar="FILENAME",
            help="Name of file to write log messages to.")

	p.add_option ("-t", "--tempdir", default=".",
            dest="tempdir", metavar="DIRPATH",
            help="Directory in which to create temporary files.")

	p.add_option ("-e", "--encoding", default="utf-8",
            type="str", dest="encoding", 
            help="Encoding for error and logfile messages (typically "
		"\"sjis\", \"utf8\", or \"euc-jp\").  This does not "
		"affect the output .pgi file or the temp files which "
		"are always written with utf-8 encoding.")

	opts, args = p.parse_args ()
	if len (args) > 1: print >>sys.stderr, "%d arguments given, expected at most one"
	if len (args) < 1: args = ["JMdict"]
	return args, opts

if __name__ == '__main__': 
	args, opts = parse_cmdline()
	main (args, opts)

