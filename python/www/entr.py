#!/usr/bin/env python
# -*- coding: utf-8 -*-

_VERSION_=("$Revision$"[11:-2],"$Date$"[7:-11])
_AUTHOR_ = "Stuart McGraw <smcgraw@frii.com>"
# Copyright (c) 2006, Stuart McGraw 

# Simple cgi script to display entries in the JMdict database.
# Use url's like:
#   http://server/cgi-bin/htmlentr.py?e=nnnn&e=...
# Where &e=nnnn will display the entry with id=nnnn
# and &q=nnnn will display the entry with ent_seq nnnn.
# You can give as many &e= and &q= parameters as you wish.

import sys, os, cgi, cgitb
sys.path.append (r"c:\stuart\develop\jdb\jb")
import db, jbdb
from tables import *
from simpleTalHelper import mktemplate, serialize

global KW

def main (args, opts):
	global KW

	try: pt = os.environ['PATH_TRANSLATED'].replace('\\', '/')
	except KeyError: base = "."
	else: base = pt[:pt.rfind('/')]

	print "Content-type: text/html\n"
	if len(args)==0 or args[0]=="": cgitb.enable()

	# open the database...
	cursor = db.dbOpen (user="postgres", password="satomi", database="jb")

	# Read in all the keyword tables...
	KW = jbdb.Kwds (cursor)

	if len(args)==0 or args[0]=="":
	    frm = cgi.FieldStorage()
	    idlist = ["e"+x for x in frm.getlist("e")] \
	    	   + ["q"+x for x in frm.getlist("q")] \
		   + ["s"+x for x in frm.getlist("s")]
	else: idlist = args
	elist = get_entries (cursor, idlist)
	display_entries (elist, base)
	
def display_entries (elist, base):
	for e in elist:
	    for s in e.sens:
		s.tal_xrefs = [x[1] for x in s.xref if x.typ==KW.XREF.see.id]
		s.tal_ants = [x[1] for x in s.xref if x.typ==KW.XREF.ant.id]

	tmpl = mktemplate(base+"/templates/entr.tal")
	serialize (tmpl, sys.stdout, KW=KW, elist=elist)

def get_entries (cursor, idlist):
	elist = [get_entry (cursor, int(x[1:]), x[0]) for x in idlist]
	elist = [x for x in elist if x.id is not None]  # Temporary hack.
	#elist.sort (key=lambda x: x.id)
	return elist 

def get_entry (cursor, id, typ):
	eid = get_entryid (cursor, id, typ)
	e = Entr()._read(cursor, eid)

	  # Do a little preprocessing on the restr, stagr, and stagk
	  # data to make them easier to deal with inside the html
	  # display template...

	for s in e.sens: 
	      # If there are any sense restrictions, invert and resolve
	      # them, i.e. change them from list of invalid combinations
	      # to list of valid combinations, and replace the restriction
	      # objects (Stagr or Stagk) with references to the actual
	      # Kana or Kanj objects that the restriction objects referred
	      # to.
	    if hasattr(s, "stagr") and s.stagr: 
		s.stagr = jbdb.listdiff (e.kana, s.stagr, lambda a,b:a[0]!=b[1])
	    if hasattr(s, "stagk") and s.stagk: 
		s.stagk = jbdb.listdiff (e.kanj, s.stagk, lambda a,b:a[0]!=b[1])

	  # Create an e.restr attribute that will be false if the entry
	  # has no reading restrictions, or true otherwise.  The template
	  # will use this to decide how to display the kanji and readings.  
	e.restr = False
	for r in e.kana:
	    if hasattr(r, "restr") and r.restr: e.restr = True

	  # If there are any reading restrictions, invert and resolve 
	  # them that same way as for the Stagr and Stagk restrictions
	  # above.  They are attached to the reading elements they 
	  # apply to.
	if e.restr:
	    for r in e.kana:
		r.restr = jbdb.listdiff (e.kanj, r.restr, lambda a,b:a[0]!=b[1])
	return e

def get_entryid (cursor, id, typ='e'): 
	if typ == 'q': 
	    sql = "SELECT e.id FROM entr e WHERE seq=%%s AND src=%d" \
		  % KW.SRC["jmdict"].id
	    cursor.execute (sql, (id,))
	    if cursor.rowcount != 1: return None
	    eid = cursor.fetchone()[0]
	elif typ == 's':
	    sql = "SELECT e.id FROM entr e JOIN sens s ON s.entr=e.id WHERE s.id=%s"
	    cursor.execute (sql, (id,))
	    if cursor.rowcount != 1: return None
	    eid = cursor.fetchone()[0]
	elif typ == 'e': eid = id
	else: raise ValueError ("Bad 'typ' parameter")
	return eid

#---------------------------------------------------------------------
def exit(message=None, stat=2):
	import sys
	if stat <= 0: f=sys.stderr
	else: f=sys.stdout
	if message: print >>f, message
	if stat >= 0: sys.exit(stat)
	
def exceptionHandler(type, value, tb):
	if not (sys.stderr.isatty() and sys.stdin.isatty()) or type==SyntaxError: 
	    sys.__excepthook__(type, value, tb)
	else: # Not in interactive mode, print the exception...
	    import traceback, pdb
	    traceback.print_exception(type, value, tb)
	    print;  pdb.pm()

if __name__ == '__main__': 
	import getopt
	try: opts, args = getopt.getopt(sys.argv[1:], "D")
	except getopt.GetoptError: exit("Bad command line")
	opts = dict(opts)
	if ('-D' in opts):
	    import pdb, traceback
	    sys.excepthook = exceptionHandler
	    pdb.set_trace()
	main(args, opts)



