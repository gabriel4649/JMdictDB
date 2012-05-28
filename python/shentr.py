#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Simple command line tool to find and display entries
# in the JMdict database.

from __future__ import print_function

_VERSION_ = ("$Revision$"[11:-2], "$Date$"[7:-11])

import sys, os, inspect, pdb
_ = os.path.abspath(os.path.split(inspect.getfile(inspect.currentframe()))[0])
_ = os.path.join (os.path.dirname(_), 'python', 'lib')
if _ not in sys.path: sys.path.insert(0, _) 

import re
import jdb, fmt, fmtjel

global KW, Enc

def main (args, opts):
	global Enc

	  # The following call creates a database "cursor" that will
	  # be used for subsequent database operations.  It also, as 
	  # a side-effect, create a global variable in module 'jdb'
	  # named 'KW' which contains data read from all the keyword
	  # database tables (tables with names matchingthe pattern 
	  # "kw*".  We read this data once at program startup to avoid
	  # multiple hi-cost trips to the database later.  
	try: cur = jdb.dbOpen (opts.database, **jdb.dbopts(opts))
	except jdb.dbapi.OperationalError as e:
	    print ("Error, unable to connect to database, do you need -u or -p?\n", str(e), file=sys.stderr);  
	    sys.exit(1)
	Enc = opts.encoding or sys.stdout.encoding or 'utf-8'

	  # Get the command line options and convert them into a sql
	  # statement that will find the desired entries.
	sql, sqlargs = opts2sql (args, opts)
	if opts.debug: 
	    print (("%s  %s" % (sql, repr(sqlargs))).encode(Enc, 'replace'))

	  # Retrieve the entries from the database.  'entrs' will be
	  # set to a list on entry objects.  'raw' is set to dictionary, 
	  # keyed by table name, and with values consisting of all the
	  # rows retrieved from that table.  
	entrs, raw = jdb.entrList (cur, sql, sqlargs, ret_tuple=True)

	  # Any xrefs in the retrieved entry objects contain contain only 
	  # the entry id numbers of the referenced entries.  We want to be
	  # able to show the refernced entriy's kanji, glosses, etc so we
	  # call "augment_xrefs" to get this extra information.  Same for
	  # any reverse refrerences.
	jdb.augment_xrefs (cur, raw['xref'])
	jdb.augment_xrefs (cur, raw['xrer'], rev=1)
	jdb.add_xsens_lists (raw['xref'])
	jdb.mark_seq_xrefs (cur, raw['xref'])

	  # Now all we have to do is print the entries.
	first = True
	for e in entrs: 
	      # Format the entry for printing, according to the 
	      # kind of out put the user requested.
	    if opts.jel: txt = fmtjel.entr (e)
	    else:        txt = fmt.entr (e)

	      # Print the formatted entry using the requested encoding
	      # and inserting a blank line between entries.
	    if not first: print ()
	    print (txt.encode (Enc, "replace"))
	    first = False

	if len(entrs) == 0: print ("No entries found")

def opts2sql (args, opts):
	conds = []
	for x in args:
	    if x.isdigit(): appendto (opts, 'id', x)
	    else: appendto (opts, '_is', x)
	if opts.char:      conds.extend (char2cond (opts.char))
	if opts._is:       conds.extend (jdb.autocond (x.decode(Enc), 1, 1) for x in opts._is)
	if opts.starts:    conds.extend (jdb.autocond (x.decode(Enc), 2, 1) for x in opts.starts)
	if opts.contains:  conds.extend (jdb.autocond (x.decode(Enc), 3, 1) for x in opts.contains)
	if opts.ends:      conds.extend (jdb.autocond (x.decode(Enc), 4, 1) for x in opts.ends)

	if opts.kis:       conds.extend (jdb.autocond (x.decode(Enc), 1, 2) for x in opts.kis)
	if opts.kstarts:   conds.extend (jdb.autocond (x.decode(Enc), 2, 2) for x in opts.kstarts)
	if opts.kcontains: conds.extend (jdb.autocond (x.decode(Enc), 3, 2) for x in opts.kcontains)
	if opts.kends:     conds.extend (jdb.autocond (x.decode(Enc), 4, 2) for x in opts.kends)

	if opts.ris:       conds.extend (jdb.autocond (x.decode(Enc), 1, 3) for x in opts.ris)
	if opts.rstarts:   conds.extend (jdb.autocond (x.decode(Enc), 2, 3) for x in opts.rstarts)
	if opts.rcontains: conds.extend (jdb.autocond (x.decode(Enc), 3, 3) for x in opts.rcontains)
	if opts.rends:     conds.extend (jdb.autocond (x.decode(Enc), 4, 3) for x in opts.rends)

	if opts.gis:       conds.extend (jdb.autocond (x.decode(Enc), 1, 4) for x in opts.gis)
	if opts.gstarts:   conds.extend (jdb.autocond (x.decode(Enc), 2, 4) for x in opts.gstarts)
	if opts.gcontains: conds.extend (jdb.autocond (x.decode(Enc), 3, 4) for x in opts.gcontains)
	if opts.gends:     conds.extend (jdb.autocond (x.decode(Enc), 4, 4) for x in opts.gends)

	if opts.id:	   conds.append (('entr',
					  "id IN(%s)" % (','.join(('%s',)*len(opts.id))),
					  tuple((int(x) for x in opts.id),) ))
	if opts.seq:       conds.append (('entr',
					  "seq IN(%s)" % (','.join(('%s',)*len(opts.seq))),
					  tuple((int(x) for x in opts.seq),) ))
	sql, sqlargs = jdb.build_search_sql (conds, disjunct=True)
	if opts.corp:
	    corp, inv = jdb.kwnorm ('SRC', opts.corp)
	    s1, s2 = sql.split (' WHERE ')
	    sql = "%s WHERE src %sIN (%s) AND (%s)" % (s1, inv, jdb.pmarks(corp), s2)
	    sqlargs[0:0] = corp
	return sql, sqlargs

def char2cond (opts_char):
	conds = []; char_list = [];  ucs_list = []
	for ch in opts_char:
	    ch = ch.decode(Enc)
	    if len (ch) == 1: char_list.append (ch)
	    else:
		try: ucs_list.append (int (ch, 16))
		except ValueError: 
		    print ("--char value must be unicode value in hex or single character.", file=sys.stderr)
		    sys.exit (1)
	if char_list:
	     conds.append (('chr', 
			    'chr IN (%s)' % ','.join(('%s',)*len(char_list)), 
			    char_list))
	if ucs_list:
	    conds.append (('chr',
			   'ascii(chr) IN (%s)' % ','.join(('%s',)*len(ucs_list)),
		    	   ucs_list))
	return conds

def appendto (obj, attr, val):
	try: getattr(obj,attr).append (val)
	except AttributeError: setattr (obj, attr, [val])

#---------------------------------------------------------------------

from optparse import OptionParser, Option


class MyOption (Option):
    ACTIONS = Option.ACTIONS + ('extend',)
    STORE_ACTIONS = Option.STORE_ACTIONS + ('extend',)
    TYPED_ACTIONS = Option.TYPED_ACTIONS + ('extend',)
    ALWAYS_TYPED_ACTIONS = Option.ALWAYS_TYPED_ACTIONS + ('extend',)

    def take_action(self, action, dest, opt, value, values, parser):
        if action == 'extend':
            lvalues = value.split( ',' )
            values.ensure_value( dest, [] ).extend( x.strip() for x in lvalues )
        else:
            Option.take_action( self, action, dest, opt, value, values, parser )

def parse_cmdline ():
	u = \
"""\n\t%prog [-d database][-u user][-p passwd] [-m host]

  %prog will do very simple searches of the jdb database and
  print the found entries.  

arguments:  [text | number]...
	An arbitrary number of numbers or text strings.  Numbers are
	presumed to be entry id numbers and will be treated as though 
	they were  preceeded by a "--id" option.  Text consisting of
	of characters other than [0-9] will be taken as a text string 
	to search for as though it had been preceeded by a "--is" 
	option.
	"""

	v = sys.argv[0][max (0,sys.argv[0].rfind('\\')+1):] \
	        + " Rev %s (%s)" % _VERSION_
	p = OptionParser (usage=u, version=v, add_help_option=False,
			  option_class=MyOption)

	p.add_option ("--id", "-i", action="append", dest="id",
	    help="Find the entry with id number ID.")
	p.add_option ("--seq", "-q", action="append", dest="seq",
	    help="Find entries with seq number SEQ.")
	p.add_option ("--corpus", "-s", action="extend", dest="corp",
	    help=u"Restrict the search to the given corpora.  Each corpus "
		"is specified by its keyword.  If more than one, they must "
		" be comma separated. If the first comma separated word is "
		"\"NOT\" rather than a corpus keyword, then all corpora "
		"other than those listed will be searched. Example: "
		" '%prog -c NOT,examples ...' will search in all corpora "
		"other than the \"example\" corpus.  "
		"Specifying --corpus with --id is not usually useful since "
		"id numbers uniquely identify an entry regardless of the "
		"corpus it occurs in.")

	p.add_option ("--char", action="append", dest="char",
	    help="Find character CHAR 'chr' table.  CHAR may by a single character "
		"string, of a four or more character string giving the character's "
		"unicode code-point in hexadecimal.")

	p.add_option ("--is", action="append", dest="_is", metavar='TXT',
	    help="Search for and entry with text that exactly matches TXT.  "
		"If TXT contains any kanji characters, it is looked for  "
		"only in the kanji table.  Otherwise, if it contains hiragana "
		"or katakana characters, it will be searched for in the "
		"readings table.  Otherwise it will be searched for in the "
		"gloss table (case insensitively).  ")
	p.add_option ("--starts", action="append", dest="starts", metavar='TXT',
	    help="Search for an entry that starts with or exactly matches "
		"TXT.  The search is otherwise done as described for \"--is\".")
	p.add_option ("--contains", action="append", dest="contains", metavar='TXT',
	    help="Search for an entry that contains or exactly matches TXT.  "
		"The search is otherwise done as described for \"--is\".  ")
	p.add_option ("--ends", action="append", dest="ends", metavar='TXT',
	    help="Search for an entry that ends with or exactly matches TXT.  "
		"The search is otherwise done as described for \"--is\".  " )

	p.add_option ("--kis", action="append", dest="kis", metavar='TXT',
	    help="Search in the kanji table for an entry that exactly matches "
		"TXT.  The search is otherwise done as described for \"--is\".")
	p.add_option ("--kstarts", action="append", dest="kstarts", metavar='TXT',
	    help="Search in the kanji for an entry that starts with or exactly "
		"matches TXT.  The search is otherwise done as described for "
		"\"--starts\".")
	p.add_option ("--kcontains", action="append", dest="kcontains", metavar='TXT',
	    help="Search in the kanj for an entry that contains or exactly "
		"matches TXT.  The search is otherwise done as described for "
		"\"--contains\".  ")
	p.add_option ("--kends", action="append", dest="kends", metavar='TXT',
	    help="Search in the kanji table for an entry that ends with or "
		"exactly matches TXT.  The search is otherwise done as described "
		"for \"--ends\".  " )

	p.add_option ("--ris", action="append", dest="ris", metavar='TXT',
	    help="Search in the readings table for an entry that exactly matches "
		"TXT.  The search is otherwise done as described for \"--is\".")
	p.add_option ("--rstarts", action="append", dest="rstarts", metavar='TXT',
	    help="Search in the readings for an entry that starts with or exactly "
		"matches TXT.  The search is otherwise done as described for "
		"\"--starts\".")
	p.add_option ("--rcontains", action="append", dest="rcontains", metavar='TXT',
	    help="Search in the readings for an entry that contains or exactly "
		"matches TXT.  The search is otherwise done as described for "
		"\"--contains\".  ")
	p.add_option ("--rends", action="append", dest="rends", metavar='TXT',
	    help="Search in the readings table for an entry that ends with or "
		"exactly matches TXT.  The search is otherwise done as described "
		"for \"--ends\".  " )

	p.add_option ("--gis", action="append", dest="gis", metavar='TXT',
	    help="Search in the gloss table for an entry that exactly matches "
		"TXT.  The search is otherwise done as described for \"--is\".")
	p.add_option ("--gstarts", action="append", dest="gstarts", metavar='TXT',
	    help="Search in the gloss for an entry that starts with or exactly "
		"matches TXT.  The search is otherwise done as described for "
		"\"--starts\".")
	p.add_option ("--gcontains", action="append", dest="gcontains", metavar='TXT',
	    help="Search in the gloss for an entry that contains or exactly "
		"matches TXT.  The search is otherwise done as described for "
		"\"--contains\".  ")
	p.add_option ("--gends", action="append", dest="gends", metavar='TXT',
	    help="Search in the gloss table for an entry that ends with or "
		"exactly matches TXT.  The search is otherwise done as described "
		"for \"--ends\".  " )

	p.add_option ("-j", "--jel",
            action="store_true", dest="jel", default=False,
            help="Write output in JEL (JMdict Edit language) format.")

	p.add_option ("-d", "--database", default="jmdict",
            type="str",
            help="Name of the database to load.")
	p.add_option ("-h", "--host",
            type="str", 
            help="Name host machine database resides on.")
	p.add_option ("-u", "--user",
            type="str",  
            help="Connect to database with this username.")
	p.add_option ("-e", "--encoding", default=None,
            type="str",  
            help="Encoding for output (typically \"sjis\", \"utf8\", "
	      "or \"euc-jp\"")
	p.add_option ("-p", "--password",
            type="str", 
            help="Connect to database with this password.")
	p.add_option ("--help",
            action="help", help="Print this help message.")

	p.add_option ("-D", "--debug", default=0,
	    type="int", 
	    help="""If non-zero, print debugging info.""")

	opts, args = p.parse_args ()

	return args, opts

if __name__ == '__main__': 
	args, opts = parse_cmdline ()
	main (args, opts)

