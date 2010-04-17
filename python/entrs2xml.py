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

# Read entries from database and write to XML file.  Run with 
# --help option for details.

import sys, time, pdb
import jdb, fmt, fmtxml

def main (args, opts):
	debug = opts.debug
	  # Open the database.  jdb.dbopts() extracts the db-related
	  # options from the command line options in 'opts'.
	cur = jdb.dbOpen (opts.database, **jdb.dbopts (opts))

	  # If no "--root" option was supplied, choose a default based
	  # on the value of the "--compat" option.
	if not opts.root:
	    if opts.compat == 'jmnedict': opts.root = 'JMnedict'
	    else: opts.root = 'JMdict'

	outf = None
	if not opts.nodtd:
	      # Choose a dtd to use based on the "--compat" option.
	      # The dtd file is expected to be located somewhere in the
	      # pythonpath (sys.path) directories. 
	    if opts.compat == 'jmdict': dtd = "dtd-jmdict.xml"
	    elif opts.compat == 'jmnedict': dtd = "dtd-jmnedict.xml"
	    else: dtd = "dtd-jmdict-ex.xml"
	    dir = jdb.find_in_syspath (dtd)
	    dtdfn = dir + "/" + dtd		# Fully qualified dtd file name.

	      # jdb.get_dtd() reads the dtd text, and replaces the root
	      # element name name and encoding with the values supplied 
	      # in the arguments.
	    dtdtxt= jdb.get_dtd (dtdfn, opts.root, opts.encoding)
	    if len (args) == 0: outf = sys.stdout
	    else: outf = open (args[0], "w")
	    outf.write (dtdtxt.encode (opts.encoding))

	  # Turn the "--corpus" option value into a string that can be 
	  # and'ed into a SQL WHERE clause to restrict the results to 
	  # the specified corpora.
	corp_terms = parse_corpus_opt (opts.corpus, 'e.src')

	    # If the output file was not opened in the dtd section
	    # above, open it now.  We postpose opening it until the
	    # last possible moment to avoid creating it and then
	    # bombing because there was a typo in the input or dtd
	    # filename, etc.
	    # FIXME: Should do a "write" function that opens the 
	    #  file just before writing.
	if not outf:
	    if len (args) == 0: outf = sys.stdout
	    else: outf = open (args[0], "w")

	if opts.begin:
	      # If a "--begin" sequence number was given, we need to read
	      # the entr record so we can get the src id number.  Complain
	      # and exit if not found.  Complain if more than one entry 
	      # with the requested seq number exists.  More than one may be
	      # found since the same sequence number may exist in different
	      # corpora, or in the same corpus if an entry was edited.
	      # 
	      # FIXME: no way to select from multiple entries with same seq
	      #   number.  Might want just the stat="A" entries for example.
	    sql = "SELECT id,seq,src FROM entr e WHERE seq=%s%s ORDER BY src" \
		    % (int(opts.begin), corp_terms)
	    if debug: print >>sys.stderr, sql
	    start = time.time()
	    rs = jdb.dbread (cur, sql)
	    if debug: print >>sys.stderr, "Time: %s (init read)" % (time.time()-start)
	    if not rs:
		print >>sys.stderr, "No entry with seq '%s' found" \
				     % opts.begin;  sys.exit (1)
	    if len(rs) > 1:
		print >>sys.stderr, "Multiple entries having seq '%s' found, results " \
		                    "may not be as expected.  Consider using -s to " \
				    "restrict to a single corpus." % (opts.begin)
	else: 
	      # If no "--begin" option, remove the " AND" from the front of
	      # the 'corp_terms' string.  Read the first entry (by seq number)
	      # in the requested corpora.
	    cc = corp_terms[4:] if corp_terms else 'True'
	      # If compat (jmdict or jmnedict), restrict the xml to Active
	      # entries only.
	    astat = " AND stat="+str(jdb.KW.STAT['A'].id) if opt.compat else "" 
	    sql = "SELECT id,seq,src FROM entr e WHERE %s%s ORDER BY src,seq LIMIT 1" % (cc, astat)
	    start = time.time()
	    if debug: print >>sys.stderr, sql
	    rs = jdb.dbread (cur, sql)
	    if debug: print >>sys.stderr, "Time: %s (init read)" % (time.time()-start)

	lastsrc, lastseq, lastid = rs[0].src, rs[0].seq, rs[0].id  
	count = opts.count; done = 0; blksize = opts.blocksize; corpora = set()
	if not opts.nodtd: outf.write ('<%s>\n' % opts.root)

	while count is None or count > 0:

	      # In this loop we read blocks of 'blksize' entries.  Each 
	      # block read is ordered by entr src (i.e. corpus), seq, and
	      # id.  The block to read is specified in WHERE clause which
	      # is effectively:
	      #   WHERE ((e.src=lastsrc AND e.seq=lastseq AND e.id>=lastid+1)
	      #		  OR (e.src=lastsrc AND e.seq>=lastseq)
	      #		  OR e.src>lastsrc)
	      # and (lastsrc, lastseq, lastid) are from the last entry in 
	      # the last block read.

	    whr = "WHERE ((e.src=%%s AND e.seq=%%s AND e.id>=%%s) " \
			  "OR (e.src=%%s AND e.seq>%%s) " \
			  "OR e.src>%%s) %s" % (corp_terms)
	    sql = "SELECT e.id FROM entr e" \
		  " %s ORDER BY src,seq,id LIMIT %d" \
		   % (whr, blksize if count is None else min (blksize, count))

	      # The following args will be substituted for the "%%s" in
	      # the sql above, in jbd.findEntr().
	    sql_args = [lastsrc, lastseq, lastid, lastsrc, lastseq, lastsrc]

	      # Create a temporary table of id numbers and give that to
	      # jdb.entrList().  This is an order of magnitude faster than
	      # giving the above sql directly to entrList().
	    if debug: print >>sys.stderr, sql, sql_args
	    start = time.time()
	    tmptbl = jdb.entrFind (cur, sql, sql_args)
	    mid = time.time()
	    entrs, raw = jdb.entrList (cur, tmptbl, None, ord="src,seq,id", ret_tuple=True)
	    end = time.time()
	    if debug: print >>sys.stderr, "read %d entries" % len(entrs)
	    if debug: print >>sys.stderr, "Time: %s (entrFind), %s (entrList)" % (mid-start, end-mid)
	    if not entrs : break

	      # To format xrefs in xml, they must be augmented so that the 
	      # the target reading and kanji text will be available.
	    jdb.augment_xrefs (cur, raw['xref'])

	      # Generate xml for each entry and write it to the output file.
	    start = time.time()
	    for e in entrs:
		if not opts.compat:
		    if e.src not in corpora:
			txt = '\n'.join (fmtxml.corpus ([e.src]))
			outf.write (txt.encode (opts.encoding) + "\n")
			corpora.add (e.src)
		    grp = getattr (e, '_grp', [])
		    for g in grp:
			gob = jdb.KW.GRP[g.kw]
			if not hasattr (gob, 'written'):
			    gob.written = True
			    txt = '\n'.join (fmtxml.grpdef (gob))
			    outf.write (txt.encode (opts.encoding) + "\n")
		txt = fmtxml.entr (e, compat=opts.compat, genhists=True)
		outf.write (txt.encode (opts.encoding) + "\n")
	    if debug: print >>sys.stderr, "Time: %s (fmt)" % (time.time()-start)

	      # Update the 'last*' variables for the next time through
	      # the loop.  Also, decrement 'count', if we are counting.
	    lastsrc = entrs[-1].src;  lastseq = entrs[-1].seq;  lastid = entrs[-1].id + 1 
	    if count is not None: count -= blksize
	    done += len (entrs)
	    if not debug: sys.stderr.write ('.')
	    else: print >>sys.stderr, "%d entries written" % done
	if not opts.nodtd: outf.writelines ('</%s>\n' % opts.root)
	if not debug: sys.stderr.write ('\n')
	print >>sys.stderr, "Wrote %d entries" % done

def parse_corpus_opt (s, src_col):
	if not s: return ''
	in_srcs = [];  other_srcs = []; terms = []
	terms = s.split(',')
	for t in terms:
	    t1, x, t2 = t.partition (':')
	    if t1 and not t1.isdigit(): t1 = jdb.KW.SRC[t1].id
	    if t2 and not t2.isdigit(): t2 = jdb.KW.SRC[t2].id
	    if not x: in_srcs.append (str(int(t1)))
	    else:
		if not t2: other_srcs.append ("%s>=%d" % (src_col, int(t1)))
		elif not t1: other_srcs.append ("%s<=%d" % (src_col, int(t2)))
		else: other_srcs.append ("%s BETWEEN %d AND %d" % (src_col, int(t1),int(t2)))
	if in_srcs: 
	    if len (in_srcs) == 1: other_srcs.append ("%s=%s" % (src_col, in_srcs[0]))
	    else: other_srcs.append ("%s IN(%s)" % (src_col, ",".join (in_srcs)))
	clause = " AND ".join (other_srcs)
	if clause: clause = " AND " + clause
	return clause

from optparse import OptionParser, OptionGroup
from pylib.optparse_formatters import IndentedHelpFormatterWithNL

def parse_cmdline ():
	u = \
"""\n\t%prog [options] [outfile]

%prog will read entries from a jmdictdb database and write them 
in XML form to a file.

Arguments: 
	outfile -- Name of the output XML file.  If not given output
		is written to stdout."""

	v = sys.argv[0][max (0,sys.argv[0].rfind('\\')+1):] \
	        + " Rev %s (%s)" % __version__
	p = OptionParser (usage=u, version=v, add_help_option=False, 
		formatter=IndentedHelpFormatterWithNL())

	p.add_option ("--help",
            action="help", help="Print this help message.")

	p.add_option ("-b", "--begin", default=0,
            type="int", metavar="SEQNUM",
            help="Sequence number of first entry to process.  If not "
		"given or 0, processing will start with the first entry.")

	p.add_option ("-c", "--count", default=None,
            type="int", metavar="NUM",
            help="Number of entries to process.  If not given, "
		"all entries in the file will be processed.")

	p.add_option ("-s", "--corpus", default=None,
            help="""Restrict extracted entries to those belonging to the 
		corpora defined by this option.  The format is a list of
		comma separated specifiers.  Each specifier is either a 
		corpus id number, corpus name, or a range.  A range is a
		corpus id number or corpus name followed by a colon, a
		colon followed by a corpus id number or corpus name, or a
		corpus id number or corpus name followed by a colon followed
		by a corpus id number or corpus name.  

	        Examples:

		    -s 2         Restrict to corpus id 2 (jmnedict).

		    -s jmnedict  Restrict to corpus id 2 (jmnedict).

		    -s 3,26,27   Restrict to the corpora 3, 26, or 27.

		    -s 10:13     Restrict to corpora 10, 11, 12, or 13.

		    -s test:	 Restrict to corpora with an id greater
				 or equal to the id of corpus "test".

		    -s jmdict-examples,test
				 Restrict to corpora with id numbers 
				 between "jmdict" and "examples", or equal 
				 to the id of corpus "test".

		Default is all corpora.""")

	p.add_option ("--compat", default=None,
            help="""If given, must have a value of either 'jmdict' or
		'jmnedict', and will cause the generation of a file that
		uses a DTD compatible with the standard Monash JMdict or
		JMnedict XML files.  Information not representable in the
		DTD will not be included in the XML and thus will lost if
		the database is reloaded from the XML.
		Without this option, an extended DTD is used that will 
		preserve all information in the database entries.""")

	p.add_option ("-r", "--root", 
            help="""Name to use as the root element in the output XML file. 
		If 'compat' is None or "jmdict", default is "JMdict",
		otherwise ('compat' is "jmnedict") default is "JMnedict".""")

	p.add_option ("--nodtd", default=None,
            action="store_true",
            help="Do not write a DTD or root element. If this option "
	        "is given, --root is ignored.")

	p.add_option ("-B", "--blocksize", default=1000,
	    type="int", metavar="NUM", 
            help="Read and write entries in blocks of NUM entries.  "
		"Default is 1000.")

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

	p.add_option ("-D", "--debug", default="0",
            dest="debug", type="int",
            help="If given a value greater than 0, print debugging information "
		"while executing.  See source code for details.")

	opts, args = p.parse_args ()
	if len (args) > 1: p.error ("%d arguments given, expected at most one.")
	if opts.compat and opts.compat!='jmdict' and  opts.compat!='jmnedict':
	    p.error ('--compat option value must be either "jmdict" or "jmnedict".')
	return args, opts

if __name__ == '__main__': 
	args, opts = parse_cmdline()
	main (args, opts)
