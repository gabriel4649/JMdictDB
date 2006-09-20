# Loads the JMdict files in a jbdb database.

_VERSION_ = ("$Revision$"[11:-2], "$Date$"[7:-11])

import sys, os, re
import jbdb, MySQLdb
from tables import *

global KW

def main (args, opts):
	global KW, KWx

	# open the database...
	try: cursor = jbdb.dbOpen (user=opts.u, pw=opts.p, db=opts.d)
	except MySQLdb.OperationalError, e:
	    if e[0] == 1045: 
		print "Error, unable to connect to database, do you need -u or -p?\n", e[1];  sys.exit(1)
	    else: raise

	# Read in all the keyword tables...
	KW = jbdb.Kwds (cursor)

	print """
This program will repeatedly prompt you for a number and display
data for a matching jmdict entry.  If the number is less than
1000000 then it is interpreted as an entry id number.  Otherwise
it is interpreted as an entry sequence number.

To exit type a return, or EOF (usually ^d on Unix, ^z on Windows)."""

	while True:
	    try: s = raw_input( "\nId or seq number? ").strip()
	    except EOFError: break
	    if not s: break
	    try: s = int(s)
	    except: print "Not a number"
	    else:
		entr = get_entr (cursor, s)
		if not entr: print "Entry not found"
		else: display_entr (entr)

def display_entr (entr):

	  # Print basic entry information 

	print "\nseq: %s, lang=(%s), dial=(%s), id=%d\n" % (entr.seq, 
	    ",".join([KW.LANG[x.kw].descr for x in entr.lang]), 
	    ",".join([KW.DIAL[x.kw].descr for x in entr.dial]), entr.id)
	
	  # Print the entry's kanji text.
 
	klist = []
	for k in entr.kanj:
	    kwds = ";".join([KW.KINF[x.kw].kw for x in k.inf] \
		   + [KW.FREQ[x.kw].kw+str(x.value) for x in k.freq])
	    if kwds: klist.append (k.txt + "/" + kwds)
	    else: klist.append (k.txt)
	if klist: print "; ".join (klist)
	
	  # And the readings.  The "max(...) > 0" expression is 
	  # true if a restriction exists on any of the readings 
	  # in which case we call display_restr() instead of just 
	  # printing the readings.  We don't display r_inf or 
	  # r_rfreq for for simplicity -- method is same as for
	  # kanji.

	if max([len(r.restr) for r in entr.read]) > 0:
	    display_restr (entr.read, entr.kanj)
	else:
	    print ", ".join([x.txt for x in entr.read])

	  # Print the sense information.

	for n,s in enumerate (entr.sens):

	      # Part-of-speech, misc keywords, field...
	    pos = ";".join([KW.POS[p.kw].kw for p in s.pos])
	    if pos: pos = "[" + pos + "]"
	    misc = ";".join([KW.MISC[p.kw].kw for p in s.misc])
	    if misc: misc = "[" + misc + "]"
	    fld = ", ".join([KW.FLD[p.kw].descr for p in s.fld])

	      # Restrictions... 
	    if not s.stagr: sr = []
	    else: sr = filt ([x.kana for x in s.stagr], entr.read)
	    if not s.stagk: sk = []
	    else: sk = filt ([x.kanj for x in s.stagk], entr.kanj)
	    stag = ""
	    if sr or sk: 
		stag = " (%s only)" % ", ".join([x.txt for x in sk+sr])

	    print "\n  %d. %s%s%s" % (n+1, pos, misc, stag)
	    if fld: print "     Field(s): " + fld

	      # Now print the glosses...
	    for g in s.gloss:
		lang = KW.LANG[g.lang].kw
		if lang: lang += ": "
	        print "     %s%s" % (lang, g.txt)

	      # Print the number of xrefs than this sense references,
	      # and the numbers of other senses that reference this
	      # one.

	    if len(s.xref) > 0: print "     [%d xrefs from this sense.]" % len(s.xref)
	    if len(s.xrex) > 0: print "     [%d xrefs to this sense.]" % len(s.xrex)

def display_restr (rlist, klist):
	s = []
	for r in rlist:
	    valid = filt ([x.kanj for x in r.restr], klist)
	    if not valid: s.append (r.txt)
	    else: s.append (r.txt + u" (" + ", ".join([j.txt for j in valid]) + u")")
	print "; ".join(s)

def get_entr (cursor, id):
	if id < 1000000:
	    e = load (Entr, cursor, "select * from entr where id=%s", (id,))
	else:
	    e = load (Entr, cursor, "select * from entr where seq=%s", (str(id),))
	if len(e) < 1: return None
	e = e[0]; id = e.id
	e.lang = load (Lang, cursor, "select * from lang where entr=%s", (id,))
	e.dial = load (Dial, cursor, "select * from dial where entr=%s", (id,))
	e.read = load (Read, cursor, "select * from kana where entr=%s order by ord", (id,))
	e.kanj = load (Kanj, cursor, "select * from kanj where entr=%s order by ord", (id,))
	e.sens = load (Sens, cursor, "select * from sens where entr=%s order by ord", (id,))
	for s in e.sens:
	    s.gloss = load (Gloss, cursor, "select * from gloss where sens=%s order by ord", (s.id,))
	    s.pos = load (Pos, cursor, "select * from pos where sens=%s", (s.id,))
	    s.misc = load (Misc, cursor, "select * from misc where sens=%s", (s.id,))
	    s.fld = load (Fld, cursor, "select * from fld where sens=%s", (s.id,))
	    s.xref = load (Xref, cursor, "select * from xref where sens=%s", (s.id,))
	    s.xrex = load (Xref, cursor, "select * from xref where xref=%s", (s.id,))
	    s.stagr = load (Stagr, cursor, "select * from stagr where sens=%s", (s.id,))
	    s.stagk = load (Stagk, cursor, "select * from stagk where sens=%s", (s.id,))

	for j in e.kanj:
	    j.inf = load (Kinf, cursor, "select * from kinf where kanj=%s", (j.id,))
	    j.freq = load (Kfreq, cursor, "select * from kfreq where kanj=%s", (j.id,))
	for k in e.read:
	    k.inf = load (Kinf, cursor, "select * from rinf where kana=%s", (k.id,))
	    k.freq = load (Kfreq, cursor, "select * from rfreq where kana=%s", (k.id,))
	    k.restr = load (Restr, cursor, "select * from restr where kana=%s", (k.id,))
	return e

def load (cls, cursor, sql, sqlargs):
	cursor.execute (sql, sqlargs)
	rs = cursor.fetchall ()
	return [cls (x) for x in rs]

def filt (exclude, xlist):
	# returns a list containing those items of <xlist>
	# that do not have an id number that is in the list
	# of numbers in <exclude>.
	return [x for x in xlist if x.id not in exclude]

# Following stuff is boilerplate code...
#---------------------------------------------------------------------

from optparse import OptionParser

def parse_cmdline ():
	u = \
"""\n\t%prog [-d database][-u user][-p passwd] 

  %prog is a simple-minded program to illustrate extracting
  and displaying data from the jb database.  Options can be
  used to give information necessary for connecting to the
  database.  The program runs in a loop, prompting for an
  entry id or sequence number number, and displaying that
  entry.

  To exit, type a returnm or enter ^Z on MS Windows or ^D
  on Unix. 

arguments:  None"""

	v = sys.argv[0][max (0,sys.argv[0].rfind('\\')+1):] \
	        + " Rev %s (%s)" % _VERSION_
	p = OptionParser (usage=u, version=v)
	p.add_option ("-d", "--database",
             type="str", dest="d", default="jb",
             help="Name of the database to load.  Default is \"jb\".")
	p.add_option ("-u", "--user",
             type="str", dest="u", default="root", 
             help="Connect to Mysql with this username.  " \
                      "Deafult is \"root\"")
	p.add_option ("-p", "--passwd",
             type="str", dest="p", default="",
             help="Connect to Mysql with this password.")
	p.add_option ("-D", "--debug",
             action="store_true", dest="D", 
             help="Startup in Python pdb debugger.")
	opts, args = p.parse_args ()
	if len(args) > 0: p.error("Error, no arguments expected.  " 
				"Use --help for more info")
	return args, opts

def exceptionHandler (type, value, tb):
	if not (sys.stderr.isatty() and sys.stdin.isatty()) or type==SyntaxError: 
	    sys.__excepthook__(type, value, tb)
	else: # Not in interactive mode, print the exception...
	    import traceback, pdb
	    traceback.print_exception(type, value, tb)
	    print;  pdb.pm()

if __name__ == '__main__': 
	args, opts = parse_cmdline ()
	if (opts.D):
	    import pdb, traceback
	    sys.excepthook = exceptionHandler
	    pdb.set_trace ()
	main (args, opts)


