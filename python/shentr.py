#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Simple command line tool to find and display entries
# in the JMdict database.

_VERSION_ = ("$Revision$"[11:-2], "$Date$"[7:-11])
import sys, os, re
import jdb, fmt, fmtjel

global KW, Enc

def main (args, opts):
	global Enc

	try: cur = jdb.dbOpen (opts.database, **jdb.dbopts(opts))
	except jdb.dbapi.OperationalError, e:
	    print >>sys.stderr, "Error, unable to connect to database, do you need -u or -p?\n", str(e);  
	    sys.exit(1)
	Enc = opts.encoding or sys.stdout.encoding or 'utf-8'
	  # The following call will create a global (aka module-level) 
	  # variable in jdb named KW which contains data from all
	  # the static keyword database tables.  We read this data once
	  # at program startup to avoid multiple hi-cost trips to the 
	  # database later.  The data is stored in a jdb.Kwds instance.
	  # Since many library functions need it they look for a global
	  # variable jdb.KW, which is easier than passing the the
	  # data as a function argument.  jdb.KWglobal() is
	  # simple helper function that saves repeating the same two
	  # or three lines of boilerplate code in every program.

	sql, sqlargs = opts2sql (args, opts)
	entrs, raw = jdb.entrList (cur, sql, sqlargs, ret_tuple=True)
	jdb.augment_xrefs (cur, raw['xref'])
	jdb.augment_xrefs (cur, raw['xrer'], rev=1)
	first = True
	for e in entrs: 
	    if opts.jel: txt = fmtjel.entr (e)
	    else:        txt = fmt.entr (e)
	    if not first: print
	    print txt.encode (Enc, "replace")
	    first = False
	if len(entrs) == 0: print "No entries found"

def opts2sql (args, opts):
	conds = []
	for x in args:
	    if x.isdigit(): appendto (opts, 'id', x)
	    else: appendto (opts, '_is', x)
	if opts._is:      conds.extend (jdb.autocond (x.decode(Enc), 1, 1) for x in opts._is)
	if opts.starts:   conds.extend (jdb.autocond (x.decode(Enc), 2, 1) for x in opts.starts)
	if opts.contains: conds.extend (jdb.autocond (x.decode(Enc), 3, 1) for x in opts.contains)
	if opts.ends:     conds.extend (jdb.autocond (x.decode(Enc), 4, 1) for x in opts.ends)

	if opts.kis:       conds.extend (jdb.autocond (x.decode(Enc), 1, 2) for x in opts.kis)
	if opts.kstarts:   conds.extend (jdb.autocond (x.decode(Enc), 2, 2) for x in opts.kstarts)
	if opts.kcontains: conds.extend (jdb.autocond (x.decode(Enc), 3, 2) for x in opts.kcontains)
	if opts.kends:     conds.extend (jdb.autocond (x.decode(Enc), 4, 2) for x in opts.kends)

	if opts.id:	  conds.append (('entr',
				         "id IN(%s)" % (','.join(('%s',)*len(opts.id))),
					 tuple((int(x) for x in opts.id),) ))
	if opts.seq:      conds.append (('entr',
					 "seq IN(%s)" % (','.join(('%s',)*len(opts.seq))),
					 tuple((int(x) for x in opts.seq),) ))
	sql, sqlargs = jdb.build_search_sql (conds, disjunct=True)
	if opts.corp:
	    corp, inv = jdb.kwnorm ('SRC', opts.corp)
	    s1, s2 = sql.split (' WHERE ')
	    sql = "%s WHERE src %sIN (%s) AND (%s)" % (s1, inv, jdb.pmarks(corp), s2)
	    sqlargs[0:0] = corp
	return sql, sqlargs

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
	p.add_option ("--corpus", "-c", action="extend", dest="corp",
	    help=u"Restrict the search to the given corpuses.  Each corpus "
		"is specified by its keyword.  If more than one, they must "
		" be comma separated. If the first comma separated word is "
		"\"NOT\" rather than a corpus keyword, then all corpuses "
		"other than those listed will be searched. Example: "
		" '%prog -c NOT,examples ...' will search in all corpuses "
		"other than the \"example\" corpus.  "
		"Specifying --corpus with --id is not usually useful since "
		"id numbers uniquely identify an entry regardless of the "
		"corpus it occurs in.")

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
		"\"--is\".")
	p.add_option ("--kcontains", action="append", dest="kcontains", metavar='TXT',
	    help="Search in the kanj for an entry that contains or exactly "
		"matches TXT.  The search is otherwise done as described for "
		"\"--is\".  ")
	p.add_option ("--kends", action="append", dest="kends", metavar='TXT',
	    help="Search in the kanji table for an entry that ends with or "
		"exactly matches TXT.  The search is otherwise done as described "
		"for \"--is\".  " )

	p.add_option ("--ris", action="append", dest="ris", metavar='TXT',
	    help="Search in the readings table for an entry that exactly matches "
		"TXT.  The search is otherwise done as described for \"--is\".")
	p.add_option ("--rstarts", action="append", dest="rstarts", metavar='TXT',
	    help="Search in the readings for an entry that starts with or exactly "
		"matches TXT.  The search is otherwise done as described for "
		"\"--is\".")
	p.add_option ("--rcontains", action="append", dest="rcontains", metavar='TXT',
	    help="Search in the readings for an entry that contains or exactly "
		"matches TXT.  The search is otherwise done as described for "
		"\"--is\".  ")
	p.add_option ("--rends", action="append", dest="rends", metavar='TXT',
	    help="Search in the readings table for an entry that ends with or "
		"exactly matches TXT.  The search is otherwise done as described "
		"for \"--is\".  " )

	p.add_option ("-j", "--jel",
            action="store_true", dest="jel", default=False,
            help="Write output in JEL (JMdict Edit language) format.")

	p.add_option ("-d", "--database",
            type="str", dest="database", default="jmdict",
            help="Name of the database to load.")
	p.add_option ("-h", "--host",
            type="str", dest="host",
            help="Name host machine database resides on.")
	p.add_option ("-u", "--user",
            type="str", dest="user", 
            help="Connect to database with this username.")
	p.add_option ("-e", "--encoding", default=None,
            type="str", dest="encoding", 
            help="Encoding for output (typically \"sjis\", \"utf8\", "
	      "or \"euc-jp\"")
	p.add_option ("-p", "--password",
            type="str", dest="password",
            help="Connect to database with this password.")
	p.add_option ("--help",
            action="help", help="Print this help message.")

	opts, args = p.parse_args ()

	return args, opts

if __name__ == '__main__': 
	args, opts = parse_cmdline ()
	main (args, opts)

