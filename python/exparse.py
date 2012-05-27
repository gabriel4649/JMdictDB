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
from __future__ import print_function

__version__ = ('$Revision$'[11:-2],
	       '$Date$'[7:-11]);

# This program will read an Examples file and create
# an output file containing postgresql data COPY commands.
# The file can be loaded into a Postgresql jmdict database
# after subsequent processing with jmload.pl.
#
# The Example file "A" lines create database entries with 
# a entr.src=3 which identifies them as from the Examples
# files.  These entries will have an single kanji, single
# sense, and single gloss.  They may have a misc tag and 
# sense note if there was a parsable "[...]" comment on the
# line.
#
# "B" line items create database xref table rows.  However,
# like jmparse, we do not create the xrefs directly from 
# within this program, but instead write pseudo-xref records
# that contain the target reading and kanji text, to the 
# xrslv table, and generate the resolved xrefs later by
# running insert queries based on joins of xrslv and the
# jmdict entries.  All the pseudo-xref genereated by this
# program will have a typ=6.

import sys, os, inspect, pdb
_ = os.path.abspath(os.path.split(inspect.getfile(inspect.currentframe()))[0])
_ = os.path.join (os.path.dirname(_), 'python', 'lib')
if _ not in sys.path: sys.path.insert(0, _) 

import re, datetime
from collections import defaultdict

import jdb, pgi, warns
from warns import warn

Msgs = defaultdict (list)
Seq = None
Lnnum = None
Opts = None

# The following is used to map tags that occur in square brackets
# immediately preceeding the #ID field to MISC id numbers.
EX2ID = {
	'aphorism'		: [82],
	'bible'			: [83,"Biblical"],
	'f'			: [9],
	'idiom'			: [13],
	'm'			: [15],
	'nelson at trafalgar.'	: [83,"Nelson at Trafalgar"],
	'prov'			: [81],
	'proverb. shakespeare'	: [81,'Shakespeare'],
	'proverb'		: [81],
	'psalm 26'		: [83,"Biblical"],
	'quotation'		: [83],
	'bible quote'		: [83,"Biblical"],
	'from song lyrics'	: [83,"Song lyrics"],
	'senryuu'		: [83,"Senryuu"],
        'xxx'			: [1],}

class ParseError (StandardError): pass

def main (args, opts):
	global Opts; Opts = opts
	global KW; jdb.KW = KW = jdb.Kwds (jdb.std_csv_dir())

	if opts.logfile: warns.Logfile = open (opts.logfile, "w")
	if opts.encoding: warns.Encoding = opts.encoding
	fin = ABPairReader (args[0])
	  # FIXME: following gives localtime, change to utc or lt+tz.
	mtime = datetime.date.fromtimestamp(os.stat(args[0])[8])
	corpid, corprec \
	    = pgi.parse_corpus_opt (opts.corpus, "examples", mtime)
	tmpfiles = pgi.initialize (opts.tempdir)
	if not opts.noaction: 
	    tmpfiles = pgi.initialize (opts.tempdir)
	    if corprec: pgi.wrcorp (corprec, tmpfiles)
	for eid, entr in enumerate (parse_ex (fin, opts.begin)):
	    if not opts.noaction:
		entr.src = corpid
		jdb.setkeys (entr, eid+1)
		pgi.wrentr (entr, tmpfiles)
	    if not (eid % 2000): 
		sys.stdout.write ('.'); sys.stdout.flush()
	    if opts.count and eid+1 >= opts.count: break
	sys.stdout.write ('\n')
	if not opts.noaction: pgi.finalize (tmpfiles, opts.output, not opts.keep)

def parse_ex (fin, begin):
	# This is a generator function that will process one (A and B) pair
	# of lines from open file object 'fin' each time it is called.
	#
	# fin -- An open Examples file. 
	# begin -- Line number at which to begin processing.  Lines 
	#    before that are skipped.

	seq_cache = set()
	for aln, bln in fin:
	    global Lnnum, Seq
	    if fin.lineno < begin: continue
	    Lnnum = fin.lineno
	    mo = re.search (r'(\s*#\s*ID\s*=\s*(\d+)_(\d+)\s*)$', aln)
	    if mo:
		aln = aln[:mo.start(1)]
		  # The ID number is of the form "nnnn_mmmm" where "nnnn" is the
		  # Tatoeba English sentence id number, and "mmmm" is the Japanese
		  # id number.  Generate a seq number by combining them.
		  # FIXME: the following assumes that the english sentence id
		  #  number will never be greater than 1E6, which is probably
		  #  not wise given that some are already in the 400K range. 
		id1, id0 = int(mo.group(2)), int(mo.group(3))
		if id0 >= 1000000: msg ("Warning, ID#%s_%s, 2nd half exceeds limit" % (id1, id0))
		Seq = id1 * 1000000 + id0
	    else: 
		msg ("No ID number found"); continue
	    try: 
		jtxt, etxt, kwds = parsea (aln)
		idxlist = parseb (bln, jtxt)
	    except ParseError, e:
		msg (e.args[0]); continue
	    if not idxlist: continue
	      # Turns out some of the entries in the examples file are duplicates
	      # (including the ID#) so we check the seq# 
	    if Seq in seq_cache: 
		msg ("Duplicate id#: %s_%s" % (id1, id0))
		continue
	    seq_cache.add (Seq)
	    entr = mkentr (jtxt, etxt, kwds)
	    entr.seq = Seq
	    entr._sens[0]._xrslv = mkxrslv (idxlist)
	    yield entr

def parsea (aln):
	  # When we're called, 'aln' has had the "A: " stripped from
	  # its start, and the ID field stripped from it's end.
	mo = re.search (r'^\s*(.+)\t(.+?)\s*(\[.+\])?\s*$', aln) 
	if not mo: raise ParseError ('"A" line parse error') 
	jp, en, ntxt = mo.group (1,2,3)
	kws = []
	if ntxt:
	    ntxt = ntxt.replace (']', '[') 
	    ntxts = ntxt.split ('[') 
	    for nt in ntxts[1:]:
		if not nt or nt.isspace(): continue
		try: kws.append (EX2ID[nt.lower()])
		except KeyError: msg ("Unknown 'A' line note: '%s'" % nt)
	return jp, en, kws

def parseb (bln, jtxt):
	parts = bln.split()
	res = []
	for n,x in enumerate (parts):
	    try: res.append (parsebitem (x, n, jtxt))
	    except ParseError, e: msg (e.args[0])
	return res

def parsebitem (s, n, jtxt):
	mo = re.search (r'^([^([{]+)(\((\S+)\))?(\[\d+\])*(\{(\S+)\})?(~)?\s*$', s)
	if not mo:
	    raise ParseError ("\"B\" line parse error in item %d: '%s'" % (n, s))
	
	ktxt,rtxt,sens,atxt,prio = mo.group (1,3,4,6,7)
	 
	if rtxt and not jdb.jstr_reb (rtxt): 
	    raise ParseError ("Expected kana in item %d: '%s'" % (n, rtxt))
	if kana_only (ktxt):
	    if rtxt: raise ParseError ("Double kana in item %d: '%s', '%s'" % (n, ktxt, rtxt))
	    rtxt = ktxt;  ktxt = None
	if sens: 
	    sens = sens.replace(']', '')
	    sens = [x for x in sens.split ('[') if len(x)>0]

	if atxt and jtxt.find (atxt) < 0:
	    raise ParseError ("\{%s\} not in A line in item %d" % (atxt, n)) 
	return ktxt, rtxt, sens, atxt, not not prio

def hw (ktxt, rtxt):
	if ktxt and rtxt: return "%s(%s)" % (ktxt,rtxt)
	return ktxt or rtxt

def mkentr (jtxt, etxt, kwds):
	  # Create an entry object to represent the "A" line text of the 
	  # example sentence.
	e = jdb.Obj (stat=KW.STAT_A, unap=False)
	e.srcnote = str (Lnnum)
	  # Each @$kwds item is a 2-array consisting of the kw
	  # id number and optionally a note string.
	kws = [x[0] for x in kwds]
	sens_note = "; ".join ([x[1] for x in kwds if len(x)>1]) or None
	if jdb.jstr_reb (jtxt): e._rdng = [jdb.Obj (txt=jtxt)]
	else: 			e._kanj = [jdb.Obj (txt=jtxt)]
	e._sens = [jdb.Obj (notes=sens_note,
		    _gloss=[jdb.Obj (lang=KW.LANG_eng, 
				     ginf=KW.GINF_equ, txt=etxt)],
		    _misc=[jdb.Obj (kw=x) for x in kws])]
	return e

def mkxrslv (idxlist):
	# Convert the $@indexlist that was created by bparse() into a 
	# list of database xrslv table records.  The fk fields "entr"
	# and "sens" are not set in the xrslv records; they are set
	# by setids() just prior to writing to the database.

	res = []
	for ktxt, rtxt, senslst, note, prio in idxlist:
	    if senslst:
		  # A list of explicit sens were give in the B line, 
		  # create an xrslv record for each.
	    	res.extend ([jdb.Obj (ktxt=ktxt, rtxt=rtxt, tsens=s,
				      typ=KW.XREF_uses, notes=note, prio=prio)
				for s in senslst])
	    else:
		  # This is not list of senses so this cross-ref will 
		  # apply to all the target's senses.  Don't set a "sens"
		  # field in the xrslv record will will result in a NULL
		  # in the database record.
		res.append (jdb.Obj (ktxt=ktxt, rtxt=rtxt,
			    typ=KW.XREF_uses, notes=note, prio=prio))
	for n,r in enumerate (res): r.ord = n + 1
	return res

def kana_only (txt): 
	v = jdb.jstr_reb (txt)
	return (v & jdb.KANA) and not (v & jdb.KANJI)

def msg (msg):
	global Opts, Seq, Lnnum
	if Opts.verbose: warns.warn ("Seq %d (line %s): %s" % (Seq, Lnnum, msg))
	Msgs[msg] = Lnnum

class ABPairReader (file):
    def __init__ (self, *args, **kwds):
	file.__init__ (self, *args, **kwds)
	self.lineno = 0
    def readpair( self ):
	aline = self.getline ('A: ')
	bline = self.getline ('B: ')
	return aline, bline
    def getline( self, key ):
	didmsg = False
	while 1:
	    line = self.readline().decode('utf-8'); self.lineno += 1
	    if not line: return None
	    if line.startswith (key) \
		    or (line[1:].startswith(key) and line[0]==u'\uFEFF'): 
		if didmsg: 
		    warns.warn ("Line %d: resyncronised." % self.lineno)
		    didmsg = False
		return line[len(key):].strip()
	    else:
		if not didmsg:
		    warns.warn ("Line %d: expected '%s' line not found, resyncronising..." 
			   % (self.lineno, key.strip()))
		    didmsg = True
    def next( self ):
	a, b = self.readpair()
	if not a: raise StopIteration
	return a, b


from optparse import OptionParser

def parse_cmdline ():
	u = \
"""\n\t%prog [options] [filename]

%prog will read a file containing Tanaka corpus example sentence pairs
(as described at http://www.edrdg.org/wiki/index.php/Tanaka_Corpus) and
create a data file that can be subsequently loaded into a jmdict Postgresql 
database (usually after pre-processing by jmload.pl).

Arguments: 
	filename -- Name of input examples file.  Default is
	"examples.txt"."""

	v = sys.argv[0][max (0,sys.argv[0].rfind('\\')+1):] \
	        + " Rev %s (%s)" % __version__
	p = OptionParser (usage=u, version=v, add_help_option=False)

	p.add_option ("--help",
            action="help", help="Print this help message.")

	p.add_option ("-o", "--output", default="examples.pgi",
	    dest="output", metavar="FILENAME",
	    help="Name of output postgresql rebasable dump file.  "
		"By convention this is usually given the suffix \".pgi\".")

	p.add_option ("-b", "--begin", default=0,
            dest="begin", type="int", metavar="SEQNUM",
            help="Line number of first entry to process.  If not "
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
	'descr' and 'notes' but exparse.py provides no means for setting 
	their values.  They can be updated in the database table after  
	kwsrc is loaded, using standard Postgresql tools like "psql".]

	Unless only 'id' is given in the CORPUS string, a corpus record 
	will be written to the output .pgi file.  A record with this 'id'
	number or 'kw' must not exist in the database when the output
	file is later loaded.

	If only 'id' is given in CORPUS, a new corpus record will not 
	be created; rather, all enties will be assigned the given corpus 
	id number and it will be assumed that a corpus record with that
	id number already exists when the output file is later loaded.

	If this option is not given at all, exparse.py will use "3", 
	"examples", and "examples_seq", and the last-modified date of
	the input file (or null if not available) for 'id', 'kw', and
	'seq', and 'dt' respectively.""")

	p.add_option ("-k", "--keep", default=False,
            dest="keep", action="store_true",
            help="Do not delete temporary files after program exits.")

	p.add_option ("-l", "--logfile", default="exparse.log",
            dest="logfile", metavar="FILENAME",
            help="Name of file to write log messages to.")

	p.add_option ("-t", "--tempdir", default=".",
            dest="tempdir", metavar="DIRPATH",
            help="Directory in which to create temporary files.")

	p.add_option ("-e", "--encoding", default='utf-8',
            type="str", dest="encoding", 
            help="Encoding for error and logfile messages (typically "
		"\"sjis\", \"utf8\", or \"euc-jp\").  This does not "
		"affect the output .pgi file or the temp files which "
		"are always written with utf-8 encoding.")

	p.add_option ("-n", "--noaction", default=False,
            dest="noaction", action="store_true",
            help="Parse only, no database access used: do not resolve "
		"index words from it.")

	p.add_option ("-v", "--verbose", default=False,
            dest="verbose", action="store_true",
            help="Print messages to stderr as irregularies "
		"are encountered.  With or without this option, the "
		"program will print a full accounting of irregularies "
		"(in a more convenient form) to stdout before it exits.")

	opts, args = p.parse_args ()
	if len (args) > 1: print ("%d arguments given, expected at most one", file=sys.stderr)
	if len (args) < 1: args = ["examples.txt"]
	return args, opts

if __name__ == '__main__': 
	args, opts = parse_cmdline()
	main (args, opts)

