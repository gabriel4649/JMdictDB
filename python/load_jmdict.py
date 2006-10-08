#!/usr/bin/env python

# Loads the JMdict files in a jbdb database.

_VERSION_ = ("$Revision$"[11:-2], "$Date$"[7:-11])

import sys, os, re, locale
import MySQLdb as dbapi
import jbdb, tables
if sys.version_info[1] < 5: import cElementTree as ElementTree
else: import xml.etree.cElementTree as ElementTree

global KW, KWx, Xrefs, Seq, Def_enc
Xrefs = []

def main (args, opts):
	global KW, KWx, Def_enc

	Def_enc = locale.getdefaultlocale()[1]

	# open the database...
	try: cursor = jbdb.dbOpen (user=opts.u, pw=opts.p, db=opts.d)
	except dbapi.OperationalError, e:
	    print "Error, unable to connect to database:", unicode(e);  sys.exit(1)

	# Read in all the keyword tables...
	KW = jbdb.Kwds (cursor)

	# Build an inverted map for mapping jmdict entity and
	# element strings to kw id's...
	KWx = mk_xemap (KW)

	# Parse the jmdict file and write to the database...
	parse_xmlfile (cursor, args[0], KW.SRC.jmdict.id, opts)

class LnFile:
    # Wrap a standard file object so as to keep track
    # of the current line number.

    def __init__(self, source):
	self.source = source;  self.lineno = 0
    def read(self, bytes):
	s = self.source.readline();  self.lineno += 1
	return s

def parse_xmlfile (cursor, filename, srcid, opts): 
	global Xrefs

	# Use the ElementTree module to parse the jmdict 
	# xml file.  This function keeps track of where
	# we are and for each parsed <entry> element, calls
	# do_entry() to actually build a runtime representation
	# of the entry, and then write_entry() to do the actual
	# writing to the database.

        inpf = LnFile(open(filename))
	context = iter(ElementTree.iterparse( inpf, ("start","end")))
	event, root = context.next()
	if opts.b and opts.b>1: print "Skipping initial entries..."
	elist = [];  cntr = 0;  cnt0 = 0
	for event, elem in context:

	    # We get here every time a tag is opened (event 
	    # will be "start") or closed (event will be "end")
	    # "elem" is an object containg the element which 
	    # will be empty when event is "start" and will contain
	    # all the element's attributes and child elements
	    # when event is "end".  elem.tag is the name of the
	    # tag.

	    if elem.tag == "entry" and event == "start":

		# When we encounter a <entry> tag, save the line
		# number, and increment the entry counter "cntr".
		# Break if we've gone past the line number given
		# in the -e option.

		lineno = inpf.lineno
	        if lineno > opts.e: break
	        cntr += 1

		# If we are skipping entries, cnt0 will be 0.
		# Otherwise, break if we have processed the 
		# the number of entries requested in the -c 
		# option.

		if cnt0 > 0 and cntr - cnt0 >= opts.c: break


	    # Otherwise we are precessing entries so we want
	    # to handle the <entry> "end" events but we are 
	    # not interested in anything else.

	    if elem.tag != "entry" or event != "end": continue

	    # If we haven't reached that starting line number 
	    # (given by the -b option) yet, then don't process
	    # this entry, but we still need to clear the parsed
	    # entry bofore continuing in order to avoid excessive
	    # memory consumption.

	    if lineno >= opts.b: 

		# If this is the first entry processed (cnt0==0) 
		# save the current entry counter value.
 
		if cnt0 == 0: 
		    cnt0 = cntr
		    x = " and loading database"
		    if opts.n: x = ""
		    print "Parsing%s..." % x
		    if not opts.n: cursor.execute ("BEGIN")

		# Process and write this entry.

		entr = do_entry (elem, srcid, lineno)
		if not opts.n: write_entr (cursor, entr)

		# A progress bar.  The modulo number is picked
		# to provide slightly less that 80 dots for a full
		# jmdict file.

		if (cntr - cnt0 + 1) % 1325 == 0: sys.stderr.write (".")

		# Only commit after a batch of entries.  Number is trade-
		# off between faster speed (high number) and not having 
		# to redo entries in case of error (low number).
 
		if (cntr - cnt0 + 1) % 3975 == 0: 
		    if not opts.n: cursor.execute ("COMMIT")

	    # We no longer need the parsed xml info for this
	    # item so dump it to reduce memory consumption.

	    root.clear()

	if not opts.n: cursor.execute ("COMMIT")
	print "\nParsed xml to line %d in %s" % (inpf.lineno, filename)

	if not opts.n: 
	    print "Resolving %d xrefs and antonyms..." \
		% sum ([len(x[2]) for x in Xrefs])
	    do_xrefs (cursor, Xrefs)
	print "Done!"

def write_entr (cursor, entr):
	# Insert an entry into the database.  entr's _insert()
	# method will call the _insert() methods for all child
	# items recursively.

	entr._insert (cursor)

	# Now that all the sens, kanj, and kana objects have been
	# written, they all have valid id numbers and we can write
	# the restriction table rows.

	for o in entr.restr: o._insert (cursor)
	for o in entr.stagk: o._insert (cursor)
	for o in entr.stagr: o._insert (cursor)

	# We can't write xrefs because referenced entry
	# may not be in database yet.  So save this entries 
	# xref in a list for processing at end of program.
	# We have to do this after the entry was written 
	# because we need to save the actual sens.id used
	# in the database.

	for s in entr.sens:
	    if s.xrefs: Xrefs.append ((s.id, entr.seq, s.xrefs))

def do_entry (elem, srcid, lineno):
	# Process an <entry> element.  The element has been
	# parse by the xml ElementTree parse and is in "elem".
	# when the entry data is written to the database and
	# identifies where this entry came from (JMdict, 
	# JMnedict, examples, etc).  "lineno" is the source
	# file line number.

	seq = int(elem.find('ent_seq').text)
	global Seq;  Seq = seq
	entr =  tables.Entr ((0, srcid, seq, str(lineno)))

	# Build lists of any <lang> and <dial> elements.
	
	entr.lang = [tables.Lang((0,KWx.LANG[x.text]))
		     for x in elem.findall('info/lang')]

	entr.dial = [tables.Dial((0,KWx.DIAL[x.text]))
		     for x in elem.findall('info/dial')]

	entr.audit = [mk_audit(x) 
		      for x in elem.findall('info/audit')]

	# Process the <r_ele>, <k_ele> and <sense>
	# elements by caling one of the do_*() functions
	# to process that element and all the enclosed
	# elements.  The value returned by each is an
	# object of the appropriate type (e.g. a Sens 
	# object for do_sense()) and all are concatenated
	# into a list and attached to an attribute on entr.
	# "ord" is used to maintain the same order of items
	# in the database as they occur in jmdict.

	entr.read = [];  ord = 10
	for x in elem.findall('r_ele'):
	    entr.read.append (do_r_ele(x, ord))
	    ord += 10

	entr.kanj = [];  ord = 10
	for x in elem.findall('k_ele'):
	    entr.kanj.append (do_k_ele(x, ord))
	    ord += 10

	entr.sens = [];  ord = 10
	for x in elem.findall('sense'):
	    entr.sens.append (do_sense(x, ord))
	    ord += 10

	# Fix up the restrictions.  They are stored in the 
	# .restr attribute of the Read, Kanj, and Sens objects
	# and consist of a list of the text strings given in
	# the xml.  Here we do two things:
	# 1. Convert the strings to references to the actual
	#   objects containing the text.
	# 2. Invert the sense: in Jmdict, the restr elements
	#   identify valid combinations, except that the lack 
	#   of the element which would logically mean "no valid
	#   combinations" actually means "all cominations are 
	#   valid.  To straighten that out for storage in the 
	#   db, we store only invalid combinations.  Thus if 
	#   an entry has 3 kanji (K1,K2,K3), 2 readings (R1,R2), 
	#   and a restriction on R1 of K1,K2 we will store
	#   (R1,K3) in the restr table.  If R2 has a restriction
	#   of K3, then we store (R2,K1)(R2,K2).  This more
	#   consistent representation allows generating the 
	#   valid K,R combination in a SQL statement by taking
	#   the set difference between the cross product of K 
	#   and R, and the restriction set.  Otherwise one really
	#   needs to handle it with a conditional in application
	#   code.

	entr.restr = [tables.Restr(x) for r in entr.read
		      for x in mk_restr (r, r.restr, entr.kanj)]
	entr.stagk = [tables.Stagk(x) for s in entr.sens
		      for x in mk_restr (s, s.stagk, entr.kanj)]
	entr.stagr = [tables.Stagr(x) for s in entr.sens
		      for x in mk_restr (s, s.stagr, entr.read)]
	return entr

def do_r_ele (elem, ord):
	# Process a <re_ele> element...

	txt = elem.find('reb').text
	r = tables.Read ((0, 0, ord, txt))

	r.inf = [tables.Rinf((0,KWx.RINF[fixup(x.text)]))
		    for x in elem.findall('re_inf')]

	# Split the <re_pri> tag into a freq scale keyword and a 
	# numeric value.  "news1" and "news2" are ignored because 
	# they are redundent with the "nfxx" tags.

	r.freq = [tables.Rfreq(decd_pri(x.text, KW))
		    for x in elem.findall('re_pri') 
		    if x.text != "news1" and x.text != "news2"]
	
	# Need the following hack because some jmdict entries 
	# (as of 2006.09.18) have multiple "nfxx" tag in the same
	# re_ele and ke_ele's.
	r.freq = remove_dup_freq_tags (r.freq)

	# Save the reading restictions.  We don't have access to
	# the kanji text here, and can't resolve the restriction
	# texts to Kanj objects, so we save it as-is and resolve 
	# later.  We will always create a .restr attribute and 
	# it will encode three conditions:
	#   [non-empty list] -- Kanji texts with this reading.
	#   [] -- Empty list: No kanji have this reading.
	#   None -- All kanji have this reading (i.e no restr).

	r.restr = [x.text for x in elem.findall('re_restr')]
	if not r.restr: r.restr = None  # All kanji have this reading.
	if elem.find('re_nokanji') is not None: 
	    r.restr = []		# No kanji have this reading.
  	return r

def do_k_ele (elem, ord):
	# Process a <re_ele> element...

	txt = elem.find('keb').text
	k = tables.Kanj ((0, 0, ord, txt))

	k.inf = [tables.Kinf((0,KWx.KINF[fixup(x.text)]))
		    for x in elem.findall('ke_inf')]

	# See comments in do_r_ele() re *_pri handling.  ke_pri
	# is handled identically.

	k.freq = [tables.Kfreq(decd_pri(x.text, KW))
		    for x in elem.findall('ke_pri')
		    if x.text != "news1" and x.text != "news2"]

	# Need the following hack because some jmdict entries 
	# (as of 2006.09.18) have multiple "nfxx" tag in the same
	# re_ele and ke_ele's.
	k.freq = remove_dup_freq_tags (k.freq)

	return k

def do_sense (elem, ord):
	# Process a <re_ele> element... 

	s = tables.Sens ((0, 0, ord, None))

	# Build lists of keyword tags for any <field>, <pos>,
	# or <misc> elements.  fixup() removes any extraneous
	# trainling spaces.
 
	s.fld =  [tables.Fld((0,KWx.FLD[fixup(x.text)])) 
		  for x in elem.findall('field')]
	s.pos =  [tables.Pos((0,KWx.POS[fixup(x.text)])) 
		  for x in elem.findall('pos')]
	s.misc = [tables.Misc((0,KWx.MISC[fixup(x.text)])) 
		  for x in elem.findall('misc')]

	s.note = "\n".join ([x .text for x in elem.findall('s_inf')])
	s.xrefs = [("x", x.text) for x in elem.findall('xref')]
	s.xrefs.extend ([("a", x.text) for x in elem.findall('ant')])

	# See comments in do_re_ele() re handling of restrictions.
	# It is identical here except there is no analogue of
	# of <nokanji> hence no need to use an empty restriction 
	# list.

	s.stagk = [x.text for x in elem.findall('stagk')]
	if not s.stagk: s.stagk = None
	s.stagr = [x.text for x in elem.findall('stagr')]
	if not s.stagr: s.stagr = None

	# Process the <gloss> elements in do_gloss().  The 
	# resulting list of Gloss objects is stored in the
	# Sens .gloss attribute.

	s.gloss = [];  ord = 10
	for x in elem.findall('gloss'):
	    s.gloss.append (do_gloss(x, ord))
	    ord += 10
	return s
	
def do_gloss (elem, ord):
	# Process a <gloss> element by setting the appropriate
	# values in a Gloss object.

	lang = KWx.LANG[elem.get ('g_lang', None)]
	g = tables.Gloss ((0, 0, ord, lang, elem.text, None))
	return g

def mk_audit (elem):
	# Process audit entries
	# We assume that it has only one each of upd_detl and
	# upd_date elements.
	dt = elem.find('upd_date').text
	if elem.find('upd_detl').text != "Entry created":
	    raise RuntimeError ("Unexpected <upd_detl> contents")
	a = tables.Audit((0,0,KW.AUDIT.a.id,dt,"JMdict loader",None))
	return a

def do_xrefs (cursor, xreflist):
	# Process the deferred xrefs.  xreflist is a list of 
	# 2-tuples.  Each 2-tuple consists of the id number
	# for the sense the xref occured in, and a list of 
	# text strings, which may by kanji or readings.
	# Hopefully they will indentify a single entry 
	# but will will generate db xrefs for every sense
	# in every entry found. 
	# The xreflist will look something like this:
	# [(S1,Q1,[("x","text"),("x,"text"),("a","text"),...]),
	#  (S2,Q2,[("x","text"),...]),
	#  ...]
	# Each item is a 3-tuple cosisting of a sense id 
	# number (Sn), the sequence number of that sense's
	# entry (Qn), and a list.  The list consists of 
	# 2-tuples representing the actual xref's and ant's
	# that were in Sn.  The first item of each 2-tuple
	# is an "x" if the tuple is an xref, or an "a" if
	# an ant.  The sencond item is the xref or ant's 
	# text string as it was in jmdict.  

	cursor.execute ("BEGIN")
	for sid,seq,xlst in xreflist:
	    for typ,txt in xlst:
		xids = find_xref_targets (cursor, txt)
		if not xids:
		    print "Warning, no entry found that matches " \
			  "xref \"%s\" from entry %s" % (txt, seq)
		for n,x in enumerate (xids):
		    if typ=="x": xtyp = KW.XREF.see.id
		    elif typ=="a": xtyp = KW.XREF.ant.id
		    else: raise RuntimeError ("Bad xref type code")
		    xref = tables.Xref ((sid, x, xtyp, "JMdict")) 
		    try: xref._insert (cursor)
		    except dbapi.IntegrityError, err:
			estr = str(err).lower()
			if "duplicate key" not in estr \
			    and "duplicate entry" not in estr: raise
			print "Note: Multiple xref resolved to same entry (%s)" % seq
			cursor.execute ("ROLLBACK")
		    else: 
			cursor.execute ("COMMIT")

def find_xref_targets (cursor, txt):
	# Return a list of all the sense id's for entries 
	# in the database that have a kanj.txt or kana.txt 
	# that matches "txt".

	if jbdb.KANJI & jbdb.jstr_classify (txt):
	    sql = "SELECT s.id FROM ((entr e " \
		"INNER JOIN sens s ON s.entr=e.id) " \
		"INNER JOIN kanj j ON j.entr=e.id) " \
		"WHERE j.txt=%s"
	else:
	    sql = "SELECT s.id FROM ((entr e " \
		"INNER JOIN sens s ON s.entr=e.id) " \
		"INNER JOIN kana k ON k.entr=e.id) " \
		"WHERE k.txt=%s"
	cursor.execute (sql, (txt,))
	return [r[0] for r in cursor.fetchall()]

def fixup (s):
	return s.rstrip ()

def decd_pri (s, kwds, parent=0):
	# Splits a ke_pri or re_pri string (e.g. "ichi1" or "nf27") 
	# into alpha and numeric parts.  The former is looked up 
	# in the kwfreq table to get the kwid number, the latter 
	# is the frequency value and is converted to a number. 
	# The pair (kwid, freqval) is returned.

	if s[-1].isdigit():
	    if s[-2].isdigit(): i = -2
	    else: i = -1
	    t = s[:i];  n = int(s[i:])
	else: 
	    t = s;  n = 0
	id = kwds.FREQ[t].id 
	return parent,id,n

def mk_restr (obj, restr, targs):
	"""
	obj -- The object which is a Read (for restr) or Sens (for
		stagr, stagk) that contains the restrictions.
	restr -- List of text strings that occur in the txt of targ's.
		This comes from the contents of the <restr>,<stagk>,
		<stakr> elements.
	targs -- List of Kanj objects (for restr or stagk) or Kana
		objects (for stagr) for the entry.  Any text string
		in "restr" are expected to be found in one of there
		objects.
	"""
	if restr is None: return []  # No invalid k/r pairs.
	restr_pairs = []
	for o in targs:
	    for txt in restr:
		if txt == o.txt: break  # Found kanj in restr.
	    else: # Come here only if no break executed above.
	        restr_pairs.append ((obj, o)) # This kanji *not* in restr.
	return restr_pairs

def mk_xemap (kwds):
	"""
	Create a data structure for mapping from entity and 
	other constant string in jmdict, to id numbers in the
	kw* tables.  The structure is an object with attributes
	that derived from the kw* tables's names by removing
	the "kw" part and capitalizing the rest.  Thus the data
	from table kwfld is store in attribute .FLD; for kwkinf
	in KINF, and so on.

	The thing stored in each attribute is a dictionary that
	maps the strings as they appear in the parsed jmdict
	elements, to the id numbers of the correspond rows in
	the kw* table.

	The ElementTree xml parser we use will expand entities
	to their long forms so that for tables that represent
	entities, the dictionary key will be these long strings
	which are in the kw table's "descr" column.
	Other element like <dial> don't use entities and thus
	the dict keys must be the short form from the kw table's
	"kw" column. 

	Finally the kwlang table is used for both <lang> elements
	and <gloss> g_lang" attributes.  In jmdict the former have
	":" suffixed but the latter do not.  Thus in the .LANG
	dictionary we store both forms.

	Typical use:

	cursor = <data base specific object or function>
	KW = jbdb.Kwds (cursor)   # Get keyword table data.
	KWx = mk_xemap (KW)	  # Create inverse mapping.

	print KWx.KINF['irregular okurigana usage']
	2
	print KWx.RFREQ['jdd']
	3
	print KWx.LANG['fr']
	8
	print KWx.LANG['fr:']
	8

	(Id values printed will vary of course depending on the 
	values in the kw* tables.)

	"""
	class Xemap (object): pass
	ents = ["FLD","KINF","MISC","POS","RINF"]  # xml expanded entities
	xemap = Xemap()
	for k in dir(kwds):
	    if not k.isupper(): continue 
	    p = dict()
	    setattr (xemap, k, p)
	    for j,w in (getattr (kwds, k)).items():
		if isinstance (j, int): 
		    if k in ents: p[w.descr] = j
		    else:
			if k == "LANG" or k == "DIAL": 
			    # <lang> and <dial> values have colons
			    p[w.kw+":"] = j 
		    	p[w.kw] = j
	return xemap

def remove_dup_freq_tags (flist):
	# Temporary (I hope!) hack to remove duplicate enties
	# in r.freq and k.freq lists.  If dups in the list will
	# cause a duplicate pk error when list is written to 
	# database.

	global Seq
	result = [];  seen = {}
	for x in flist:
	    if seen.get (x.kw):
		pass # Warnings are to noisy, surpresss for now.
		#print "Warning, multiple \"%s\" pri values " \
		#	"in entry %s" % (KW.FREQ[x.kw].kw, str(Seq))
	    else:
		seen[x.kw] = True
		result.append (x)
	return result

#---------------------------------------------------------------------

from optparse import OptionParser

def parse_cmdline ():
	u = \
"""\n\t%prog [-d dbfile] xmlfile
	
  %prog will extract the data from <xmlfile> (which is a JMdict
  or JMnedict file) and will load it into a database. The new
  data will be added without erasing any data already present
  in the database.

arguments:
  xmlfile          Filename of a JMdict XML file."""

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
	p.add_option ("-b", "--begin",
             type="int", dest="b", default=0,
             help="Begin processing at first entry that occurs "
		"at or after line number B.")
	p.add_option ("-e", "--end",
             type="int", dest="e", default=99999999,
             help="Stop processing at (just before) " 
	     "line number E.  If both -c and -e are given processing "
		"will stop as soon as either condition is met.")
	p.add_option ("-c", "--count", 
             type="int", dest="c", default=9999999,
             help="Stop after processing C entries."
		"If both -c and -e are given processing will stop "
		"as soon as either condition is met.")
	p.add_option ("-n", "--noaction",
             action="store_true", dest="n", default=False,
             help="Process the xml file but do not make " 
		"any database updates.  This is useful for " 
		"checking the validity of the xml file.")
	p.add_option ("-D", "--debug",
             action="store_true", dest="D", 
             help="Startup in Python pdb debugger.")
	opts, args = p.parse_args ()
	if len(args) < 1: p.error("Too few arguments, jmdict filename expected" 
				"\nUse --help for more info")
	if len(args) > 1: p.error("Too many arguments, expected only jmdict filename " 
				"\nUse --help for more info")
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
