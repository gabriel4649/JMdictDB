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
from impfile import impfile
impfile (r"c:\stuart\develop\python\lib\topsort.py", ("topsort",))

global KW

def main (args, opts):
	global KW

	#sys.stdout = BufferedOutput (sys.stdout)
	if len(args)==0 or args[0]=="": cgitb.enable()

	try: pt = os.environ['PATH_TRANSLATED'].replace('\\', '/')
	except KeyError: base = "."
	else: base = pt[:pt.rfind('/')]

	# open the database...
	cursor = db.dbOpen (user="postgres", password="satomi", database="jb")

	# Read in all the keyword tables...
	KW = jbdb.Kwds (cursor)

	t = [None,None,None]; s = [None,None,None]; y = [None,None,None]  
	if len(args)==0 or args[0]=="":
	    frm = cgi.FieldStorage()
	    s[0]=frm.getvalue("s1"); y[0]=frm.getvalue("y1"); t[0]=frm.getvalue("t1")
	    s[1]=frm.getvalue("s2"); y[1]=frm.getvalue("y2"); t[1]=frm.getvalue("t2")
	    s[2]=frm.getvalue("s3"); y[2]=frm.getvalue("y3"); t[2]=frm.getvalue("t3")
	    pos=frm.getlist("pos");  misc=frm.getlist("misc")
	    src=frm.getlist("src");  freq=frm.getlist("freq")
	    nfval=frm.getvalue("nfval"); nfcmp=frm.getvalue("nfcmp")

	    idval=frm.getvalue("idval"); idtbl=frm.getvalue("idtyp")

	    if idval: 
		if idtbl != "seqnum":  col = "id"
		else: idtbl, col = "entr", "seq"
		sql, sql_args = jbdb.build_search_sql (
			[(idtbl, "%s.%s=%%s" % (idtbl,col), (idval,))])
	    else: 
		condlist = []
		for i in 0,1,2:
	            if t[i]: condlist.append (str_match_clause (s[i],y[i],t[i].decode("utf-8")))
		if pos: condlist.append (("pos",getsel("pos",pos),()))
		if misc: condlist.append (("misc",getsel("misc",misc),()))
		if src: condlist.append (("src",getsel("src",src),()))
		sql, sql_args = jbdb.build_search_sql (condlist)

	sql = "SELECT q.* FROM entr_summary q JOIN (%s) AS i ON i.id=q.id" % sql
	cursor.execute (sql, sql_args)
	rs = cursor.fetchall ()
	if len(rs) == 1:
	    print "Location: entr.py?e=%d\n" % rs[0][0]
	else:
	    print "Content-type: text/html\n"
	    display_entries (base, rs)
	
def display_entries (base, rs):
	tmpl = mktemplate(base+"/templates/srchres.tal")
	serialize (tmpl, sys.stdout, results=rs)

def str_match_clause (srchin, srchtyp, srchfor):
	if srchin == "auto":
	    x = jbdb.jstr_classify (srchfor)
	    if x & jbdb.KANJI: table = "kanj"
	    elif x & jbdb.KANA: table = "kana"
	    else: table = "gloss"
	else: table = srchin
	srchtyp = srchtyp.lower()
	if srchtyp == "is":         whr = "%s.txt=%%s" % table
	else:                       whr = "%s.txt LIKE(%%s)" % table
	if srchtyp == "is":         args = (srchfor,) 
	elif srchtyp == "starts":   args = (srchfor+"%",)
	elif srchtyp == "contains": args = ("%"+srchfor+"%",)
	elif srchtyp == "ends":     args = ("%"+srchfor,)
	else: raise ValueError ("srchtyp = %s" % srchtyp)
	return table,whr,args

def getsel (name, itms):
	s = "%s IN (%s)" % (name, ",".join([str(x) for x in itms]))
	return s

#---------------------------------------------------------------------
def exit(message=None, stat=2):
	import sys
	if stat > 0: f=sys.stderr
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



