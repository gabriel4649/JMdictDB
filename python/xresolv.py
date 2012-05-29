#!/usr/bin/env python
#######################################################################
#  This file is part of JMdictDB. 
#  Copyright (c) 2008,2010 Stuart McGraw 
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
#  51 Franklin Street, Fifth Floor, Boston, MA  02110#1301, USA
#######################################################################
from __future__ import print_function, absolute_import, division
from future_builtins import ascii, filter, hex, map, oct, zip 

__version__ = ('$Revision$'[11:-2],
	       '$Date$'[7:-11]);

# This program creates rows in table "xref" based on the 
# textual (kanji and kana) xref information saved in table
# "xresolv".  xresolv contains "unresolved" xrefs -- that
# is, xrefs defined only by a kanji/kana text(s) which for
# which there may be zero or multiple target entries..
#
# Each xresolv row contains the entr id and sens number 
# of the entry that contained the xref, the type of xref,
# and the xref target entry kanji and or reading, and
# optionally, sense number. 
#
# This program searchs for an entry matching the kanji
# and reading and creates one or more xref records using
# the target entry's id number.  The matching process is
# more involved than doing a simple search because a kanji
# xref may match several entries, and our job is to find 
# the right one.  This is currently done by a fast but 
# inaccurate method that does not take into account restr,
# stagr, and stag restrictions which limit certain reading-
# kanji combinations and thus would make unabiguous some
# xrefs that this program considers ambiguous.  See the
# comments in sub choose_entry() for a description of
# the algorithm. 
#
# When an xref text is not found, or multiple candidate
# entries still exist after applying the selection
# algorithm, the fact is reported and that xref skipped.

import sys, os, inspect, pdb
_ = os.path.abspath(os.path.split(inspect.getfile(inspect.currentframe()))[0])
_ = os.path.join (os.path.dirname(_), 'python', 'lib')
if _ not in sys.path: sys.path.insert(0, _) 

import re
from collections import defaultdict
import jdb

#-----------------------------------------------------------------------

def main (args, opts):
	global Opts
	Opts = opts
	  # Debugging flags:
	  #  1 -- Print generated xref records.
	  #  2 -- Print executed sql.
	  #  4 -- Print info about read xresolve records.
	if opts.debug & 0x02: Debug.prtsql = True

	try: dbh = jdb.dbOpen (opts.database, **jdb.dbopts(opts))
	except jdb.dbapi.OperationalError as e:
	    prnt (sys.stderr, "Error, unable to connect to database, do you need -u or -p?\n" % str(e))  
	    sys.exit(1)

	xref_src = opts.source_corpus or KW.SRC['jmdict'].id
	targ_src = opts.target_corpus or KW.SRC['jmdict'].id

	krmap = read_krmap (dbh, opts.filename, targ_src)

	lastpos = [0,0,0,0]; blksz = 1000
	while 1:
	    if not opts.noaction and lastpos != [0,0,0,0]:
		dbh.connection.commit()
		if opts.verbose: print ("Commit") 
	    lastpos = resolv (dbh, lastpos, blksz, 
			      xref_src, targ_src, krmap) 
	    if lastpos is None: break 
	dbh.close()

#-----------------------------------------------------------------------

def resolv (dbh, lastpos, blksz, xref_src, targ_src, krmap):
	e0, s0, t0, o0 = lastpos
	  # Following sql will read 'blksz' xresolv rows, starting
	  # at 'lastpos' (which is given as a 4-tuple of xresolv.entr,
	  # .sens, .typ and .ord).  Note that the result set must be
	  # ordered on exactly this same set of values in order to 
	  # step through them block-wise.
	sql = "SELECT v.*,e.seq,e.stat,e.unap FROM xresolv v JOIN entr e ON v.entr=e.id " \
		        "WHERE e.src=%%s " \
			  "AND (v.entr>%%s OR (v.entr=%%s " \
			   "AND (v.sens>%%s OR (v.sens=%%s " \
			    "AND (v.typ>%%s OR (v.typ=%%s " \
			     "AND (v.ord>%%s))))))) " \
			"ORDER BY v.entr,v.sens,v.typ,v.ord " \
			"LIMIT %s" % blksz
	rs = jdb.dbread (dbh, sql, [xref_src, e0,e0,s0,s0,t0,t0,o0])
	if len (rs) == 0: return None
	if Opts.debug & 0x04: 
	    print ("Read %d xresolv rows" % (len(rs),), file=sys.stderr) 
	for v in rs:

	      # Skip this xref if the "ignore-nonactive" option was 
	      # given and the entry is not active (i.e. is deleted or
	      # rejected) or is unapproved.  Unapproved entries will
	      # be checked during approval submission and unresolved 
	      # xrefs in rejected/deleted entries are often moot. 

	    if Opts.ignore_nonactive and \
		(v.stat != jdb.KW.STAT['A'].id or v.unap): continue

	    e = None
	    if krmap: 

		  # If we have a user supplied map, lookup the xresolv
		  # reading and kanji in it first.

		e = krlookup (krmap, v.rtxt, v.ktxt)

	    if not e:

		  # If there was no map, or the xresolv reading/kanji 
		  # was not found in it, look in the database for them.
		  # get_entries() will return an abbreviated entry 
		  # summary record for each entry that has a matching 
		  # reading-kanji pair (if the xresolv rec specifies 
		  # both), reading or kanji (if the xresolv rec specifies
		  # one).

	        entries = get_entries (dbh, targ_src, v.rtxt, v.ktxt, None)

		  # If we didn't find anything, and we did not have both
		  # a reading and a kanji, try again but search for reading
		  # in kanj table or kanji in rdng table because our idea
		  # of when a string is kanji and when it is a reading still
		  # still does not agree with JMdict's in all casee (IS-26).
		  # This hack will be removed when IS-26 is resolved.

	        if not entries and (not v.rtxt or not v.ktxt):
		    entries = get_entries (dbh, targ_src, v.ktxt, v.rtxt, None)

		  # Choose_target() will examine the entries and determine if
		  # if it can narrow the target down to a single entry, which
		  # it will return as a 7-element array (see get_entries() for
		  # description).  If it can't find a unique entry, it takes
		  # care of generating an error message and returns a false value. 
		e = choose_target (v, entries)
	        if not e: continue

	      # Check that the chosen target entry isn't the same as the
	      # referring entry.

	    if e[0] == v.entr:
		msg (fs(v), "self-referential", kr(v))
		continue

	      # Now that we know the target entry, we can create the actual
	      # db xref records.  There may be more than one of the target 
	      # entry has multiple senses and no explicit sense was given
	      # in the xresolv record.

	    xrefs = mkxrefs (v, e)

	    if Opts.verbose and xrefs: prnt (sys.stdout,
	        "%s resolved to %d xrefs: %s" % (fs(v),len(xrefs),kr(v)))

	      # Write each xref record to the database...
	    for x in xrefs:
		if not Opts.noaction:
		    if Opts.debug & 0x01: 
	 		prnt (sys.stderr, "not yet"
			)#	"(x.entr,x.sens,x.xref,x.typ,x.xentr"
			#	    .  "x.xsens}," . (x.rdng}||"") . "," . (x.kanj}||"")
			#	    . ",x.notes})\n")
		    jdb.dbinsert (dbh, "xref", 
			          ["entr","sens","xref","typ","xentr",
				   "xsens","rdng","kanj","notes"],
				  x)
	    if not Opts.keep:
	        dbh.execute ("DELETE FROM xresolv "
			     "WHERE entr=%s AND sens=%s AND typ=%s AND ord=%s",
			     (v.entr,v.sens,v.typ,v.ord))
	r = rs[-1]
	return r.entr, r.sens, r.typ, r.ord

class Memoize:
    def __init__( self, func ):
	self.func = func
	self.cache = {}
    def __call__( self, *args ):
        if not args in self.cache:
            self.cache[args] = self.func( *args )
        return self.cache[args]

@Memoize
def get_entries (dbh, targ_src, rtxt, ktxt, seq):

	# Find all entries in the corpus targ_src that have a
	# reading and kanji that match rtxt and ktxt.  If seq
	# is given, then the matched entries must also have a
	# as sequence number tyhat is the same.  Matches are 
	# restricted to entries with stat=2 ("active");
	#
	# The records in the entry list are lists, and are
	# indexed as follows:
	#
	#	0 -- entr.id
	#	1 -- entr.seq
	#	2 -- rdng.rdng
	#	3 -- kanj.kanj
	#	4 -- total number of readings in entry.
	#	5 -- total number of kanji in entry.
	#	6 -- total number of senses in entry.

	KW = jdb.KW
	if not ktxt and not rtxt:
	    raise ValueError ("get_entries(): 'rtxt' and 'ktxt' args are are both empty.")
	args = [];  cond = [];
	args.append (targ_src); cond.append ("src=%s");
	if seq:
	    args.append (seq); cond.append ("seq=%s")
	if rtxt:
	    args.append (rtxt); cond.append ("r.txt=%s")
	if ktxt:
	    args.append (ktxt); cond.append ("k.txt=%s")
	sql = "SELECT DISTINCT id,seq," \
		+ ("r.rdng," if rtxt else "NULL AS rdng,") \
		+ ("k.kanj," if ktxt else "NULL AS kanj,") \
		+ "(SELECT COUNT(*) FROM rdng WHERE entr=id) AS rcnt," \
		  "(SELECT COUNT(*) FROM kanj WHERE entr=id) AS kcnt," \
		  "(SELECT COUNT(*) FROM sens WHERE entr=id) AS scnt" \
		" FROM entr e " \
		+ ("JOIN rdng r ON r.entr=e.id " if rtxt else "") \
		+ ("JOIN kanj k ON k.entr=e.id " if ktxt else "") \
		+ "WHERE stat=%s AND %s" \
		% (KW.STAT['A'].id, " AND ".join (cond))
	dbh.execute (sql, args)
	rs = dbh.fetchall()
	return rs

def choose_target (v, entries):
	# From that candidate target entries in entries,
	# choose the one we will use for xref target for
	# the xresolv record in v.
	#
	# The current algorithm is what was intended to be 
	# implemented by the former xresolv.sql script.
	# Like that script, it does not take into account
	# any of the restr, stagk, stagr information.
	# Ideally, if we find a single match based on the
	# first valid (considering those restrictions)
	# reading/kanji we should use that as a target.
	# The best way to do that is under review.
	#
	# The list of entries we received are those that 
	# have a matching reading and kanji (in any positions)
	# if the xresolv record had both reading and kanji,
	# or a matching reading or kani (in any position)
	# if the xresolv record had only a reading or kanji.

	rtxt = v.rtxt;  ktxt = v.ktxt

	  # If there is only a single entry that matched,
	  # that must be the target.
	if 1 == len (entries): return entries[0]

	  # And if there were no matching entries at all...
	if 0 == len (entries):
	    msg (fs(v), "not found", kr(v)); return None

	if not ktxt:
	      # If there is only one entry that has the 
	      # given reading as the first reading, and no
	      # kanji, that's it.
	    candidates = [x for x in entries if x[5]==0 and x[2]==1]
	    if 1 == len (candidates): return candidates[0]

	      # If there is only one entry that has the 
	      # given reading and no kanji, that's it.
	    candidates = [x for x in entries if x[5]==0]
	    if 1 == len (candidates): return candidates[0]

	      # Is there is only one entry with reading 
	      # as the first reading?
	    candidates = [x for x in entries if x[2]==1]
	    if 1 == len (candidates): return candidates[0]

	elif not rtxt:
	      # Is there only one entry whose 1st kanji matches?
	    candidates = [x for x in entries if x[3]==1]
	    if 1 == len (candidates): return candidates[0]

	  # At this point we either failed to resolve in one 
	  # of the above suites, or we had both a reading and 
	  # kanji with multiple matches -- either way we give up.
	msg (fs(v), "multiple targets", kr(v))
	return None

Prev = None

def mkxrefs (v, e):
	global Prev
	cntr = 1 + (Prev.xref if Prev else 0)
	xrefs = []
	for s in range (1, e[6]+1):

	      # If there was a sense number given in the xresolv 
	      # record (field "tsens") then step through the
	      # senses until we get to that one and generate
	      # an xref only for it.  If there is no tsens, 
	      # generate an xref for every sense.
	    if v.tsens and v.tsens != s: continue

	      # The db xref records use column "xref" as a order
	      # number and to distinguish between multiple xrefs
	      # in the same entr/sens.  We use cntr to maintain
	      # its value, and it is reset to 1 here whenever we
	      # see an xref record with a new entr or sens value.
	    if not Prev or Prev.entr != v.entr \
			or Prev.sens != v.sens: cntr = 1
	    xref = jdb.Obj (entr=v.entr, sens=v.sens, xref=cntr, typ=v.typ, 
			    xentr=e[0], xsens=s, rdng=e[2], kanj=e[3])
	    cntr += 1;  Prev = xref
	    xrefs.append (xref)

	if not xrefs:
	    if v.tsens: msg (fs(v), "Sense not found", kr(v))
	    else: raise ValueError ("No senses in retrieved entry!")

	return xrefs

def read_krmap (dbh, infn, targ_src):
	if not infn: return None
	FIN = codecs.open (infn, "r", "utf8_sig")

	krmap = {}
	for lnnum, line in enumberate (FIN):
	    if line.isspace() or re.search (r'^\s*\#', line): continue
	    rtxt, ktxt, seq = line.split ('\t', 3)
	    try: seq = int (seq)
	    except ValueError: raise ValueError ("Bad seq# at line %d in '%s'" % (lnnum, infn))
	    entrs = get_entries (dbh, targ_src, rtxt, ktxt, seq)
	    if not entrs:
	        raise ValueError ("Entry seq not found, or kana/kanji"
				  " mismatch at line %d in '%s'" % (lnnum, infn))
	    krmap[(ktxt,rtxt)] = entrs[0]
	return krmap

def lookup_krmap (krmap, rtxt, ktxt):
	key = ((ktxt or ""),(rtxt or ""))
	return krmap[key]

def kr (v):
	s = fmt_jitem (v.ktxt, v.rtxt, [v.tsens] if v.tsens else [])
	return s

def fs (v):
	s = "Seq %d (%d,%d):" % (v.seq,v.sens,v.ord)
	return s

def fmt_jitem (ktxt, rtxt, slist):
	  # FIXME: move this function into one of the formatting
	  # modules (e.g. fmt.py or fmtjel.py).
	jitem = (ktxt or "") + (u'/' if ktxt and rtxt else '') + (rtxt or "") 
	if slist: jitem += '[' + ','.join ([str(s) for s in slist]) + ']'
	return jitem	    

def msg (source, msg, arg):
	if not Opts.quiet:
	    print (("%s %s: %s" % (source,msg,arg)).encode (
		Opts.encoding or sys.stdout.encoding or getdefaultencoding()))

def prnt (f, msg):
	print (msg.encode (
		Opts.encoding or sys.stdout.encoding or getdefaultencoding()), file=f)

#-----------------------------------------------------------------------

from optparse import OptionParser
from pylib.optparse_formatters import IndentedHelpFormatterWithNL

def parse_cmdline ():
	u = \
"""\n\t%prog [options]

%prog will convert textual xrefs in table "xresolv", to actual 
entr.id xrefs and write them to database table "xref".

Arguments: none"""

	v = sys.argv[0][max (0,sys.argv[0].rfind('\\')+1):] \
	        + " Rev %s (%s)" % __version__
	p = OptionParser (usage=u, version=v, add_help_option=False,
		          formatter=IndentedHelpFormatterWithNL())

	p.add_option ("--help",
            action="help", help="Print this help message.")

	p.add_option ("-n", "--noaction", default=False,
	    action="store_true",
	    help="Resolve xrefs and generate log file but don't make "
	        "any changes to database. (This implies --keep.)")

	p.add_option ("-v", "--verbose", default=False,
	    action="store_true",
	    help="Print a message for every successfully resolved xref.")

	p.add_option ("-q", "--quiet", default=False,
	    action="store_true",
	    help="Do not print a warning for each unresolvable xref.")

	p.add_option ("-f", "--filename", default=None,
	    help="Name of a file containing kanji/reading to seq# map.")

	p.add_option ("-k", "--keep", default=False, action="store_true",
	    help="Do not delete unresolved xrefs after they are resolved.")

	p.add_option ("-i", "--ignore-nonactive", default=False,
	    action="store_true",
	    help="Ignore unresolved xrefs belonging to entries with a"
		"status of deleted or rejected or which are unapproved ")  

	p.add_option ("-s", "--source-corpus", default=1,
	    type="int", metavar="NUM",
	    help="Limit to xrefs occuring in entries of corpus id "
		"NUM.  Default = 1 (jmdict).")

	p.add_option ("-t", "--target-corpus", default=1,
	    type="int",  metavar="NUM",
	    help="Limit to xrefs that resolve to targets in corpus "
		"NUM.  Default = 1 (jmdict).")

	p.add_option ("-e", "--encoding", default="utf-8",
            type="str", dest="encoding", 
            help="Encoding for output (typically \"sjis\", \"utf8\", "
	      "or \"euc-jp\"")

	p.add_option ("-d", "--database",
            type="str", dest="database", default="jmdict",
            help="Name of the database to load.")
	p.add_option ("-h", "--host", default=None,
            type="str", dest="host",
            help="Name host machine database resides on.")
	p.add_option ("-u", "--user", default=None,
            type="str", dest="user", 
            help="Connect to database with this username.")
	p.add_option ("-p", "--password", default=None,
            type="str", dest="password",
            help="Connect to database with this password.")

	p.add_option ("-D", "--debug", default=0,
	    type="int", metavar="NUM",
	    help="Print debugging output to stderr.  The number NUM "
		"controls what is printed.  See source code.")

	p.epilog = """\
When a program such as jmparse.py of exparse.py parses
a corpus file, any xrefs in that file are in textual
form (often a kanji and/or kana text string that identifies
the target of the xref).  The database stores xrefs using
the actual entry id number of the target entry but the
textual form canot be resolved into the id form at parse
time since the target entry may not even be in the database 
yet. Instead, the parser programs save the textual form of 
the xref in a table, 'xresolv', and it is the job of this 
program, when run later, to convert the textual 'xresolv' 
table xrefs into the id form of xrefs and load them into
table 'xref'.

Each xresolv row contains the entr id and sens number 
of the entry that contained the xref, the type of xref,
and the xref target entry kanji and/or reading, and
optionally, sense number. 

This program searches for an entry matching the kanji
and reading and creates one or more xref records using
the target entry's id number.  The matching process is
more involved than doing a simple search because a kanji
xref may match several entries, and our job is to find 
the right one.  This is currently done by a fast but 
inaccurate method that does not take into account restr,
stagr, and stag restrictions which limit certain reading-
kanji combinations and thus would make unabiguous some
xrefs that this program considers ambiguous.  See the
comments in sub choose_entry() for a description of
the algorithm. 

When an xref text is not found, or multiple candidate
entries still exist after applying the selection
algorithm, the fact is reported (unless the -q option 
was given) and that xref skipped.  

Before the program exits, it prints a summary of all
unresolvable xrefs, grouped by reason and xref text.
Following the xref text, in parenthesis, is the number 
of xresolv xrefs that included that unresolvable text.
All normal (non-fatal) messages (other than debug 
messages generated via the -D option) are written to 
stdout.  Fatal errors and debug messages are written 
to stderr."""

	opts, args = p.parse_args ()
	return args, opts

if __name__ == '__main__': 
	args, opts = parse_cmdline()
	main (args, opts)

