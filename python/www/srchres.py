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

import sys, os, re, cgi, cgitb
sys.path.append (r"c:\stuart\develop\jdb\jb")
import db, jbdb
from tables import *
from simpleTalHelper import mktemplate, serialize
from impfile import impfile
impfile (r"c:\stuart\develop\python\lib\topsort.py", ("topsort",))

global KW

def main (args, opts):
	global KW

	if len(args)==0 or args[0]=="": 
	    cgitb.enable()
	    try: pt = os.environ['PATH_TRANSLATED'].replace('\\', '/')
	    except KeyError: base = "."
	    else: base = pt[:pt.rfind('/')]
	    env = os.environ
	else:
	    env = dict()
	    env["QUERY_STRING"] = args[0]
	    base = "."

	# open the database...
	cursor = db.dbOpen (user="postgres", password="satomi", database="jb")

	# Read in all the keyword tables...
	KW = jbdb.Kwds (cursor)

	t = [None,None,None]; s = [None,None,None]; y = [None,None,None]  
	frm = cgi.FieldStorage(environ=env)
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
		if t[i]: condlist.append (str_match_clause (s[i],y[i],t[i].decode("utf-8"),i))
	    if pos: condlist.append (("pos",getsel("pos.kw",pos),()))
	    if misc: condlist.append (("misc",getsel("misc.kw",misc),()))
	    if src: condlist.append (("entr",getsel("entr.src",src),()))
	    if freq: condlist.extend (freq_srch_clause (freq, nfval, nfcmp))
	    sql, sql_args = jbdb.build_search_sql (condlist)

	sql = "SELECT q.* FROM entr_summary q JOIN (%s) AS i ON i.id=q.id" % sql
	#print "Content-type: text/html\n\n%s\n%s" % (sql,str(sql_args))
	cursor.execute (sql, sql_args)
	rs = cursor.fetchall ()
	if len(rs) == 1:
	    print "Location: entr.py?e=%d\n" % rs[0][0]
	else:
	    print "Content-type: text/html\n"
	    display_entries (base, rs, sql)
	
def display_entries (base, rs, sql=None):
	tmpl = mktemplate(base+"/templates/srchres.tal")
	serialize (tmpl, sys.stdout, results=rs, sql=sql)

def freq_srch_clause (freq, nfval, nfcmp):
	x = {}; whr = []
	for f in freq:
	    domain,value = re.findall("^(\D+)(\d*)$", f)[0]
	    if domain == "nf": continue
	    x.setdefault(domain,[]).append(value)
	for k,v in x.items():
	    kwid = KW.FREQ[k].id
	    if len(v)==2 or k=="spec": whr.append (
		"(kfreq.kw=%s OR rfreq.kw=%s)" % (kwid,kwid))
		# Above assumes only values possible are 1 and 2.
	    elif len(v) == 1: whr.append (
		"((kfreq.kw=%s AND kfreq.value=%s) OR (rfreq.kw=%s AND rfreq.value=%s))" 
		% (kwid, v[0], kwid, v[0]))
	    elif len(v) > 2: whr.append (
		"((kfreq.kw=%s AND kfreq.value IN (%s)) OR (rfreq.kw=%s AND rfreq.value IN (%s)))" 
		% (k, ",".join(v), k, ",".join(v)))
	    else: raise ValueError
	if "nf" in freq and nfval is not None:
	    kwid = KW.FREQ['nf'].id
	    whr.append ("((kfreq.kw=%s AND kfreq.value%s%s)" 
			" OR (rfreq.kw=%s AND rfreq.value%s%s))"
		% (kwid, nfcmp, nfval,  kwid, nfcmp, nfval))
	whr = "(" + " OR ".join(whr) + ")"
	if not whr: return ()
	return ("*rfreq","",()),("*kfreq",whr,())

def str_match_clause (srchin, srchtyp, srchfor, idx):
	if srchin == "auto":
	    x = jbdb.jstr_classify (srchfor)
	    if x & jbdb.KANJI: table = "kanj"
	    elif x & jbdb.KANA: table = "kana"
	    else: table = "gloss"
	else: table = srchin
	alias = {"kanj":"j", "kana":"r", "gloss":"g"}[table] + str(idx)
	srchtyp = srchtyp.lower()
	if srchtyp == "is":         whr = "%s.txt=%%s" % alias
	else:                       whr = "%s.txt LIKE(%%s)" % alias
	if srchtyp == "is":         args = (srchfor,) 
	elif srchtyp == "starts":   args = (srchfor+"%",)
	elif srchtyp == "contains": args = ("%"+srchfor+"%",)
	elif srchtyp == "ends":     args = ("%"+srchfor,)
	else: raise ValueError ("srchtyp = %s" % srchtyp)
	return "%s %s" % (table,alias),whr,args

def getsel (fqcol, itms):
	s = "%s IN (%s)" % (fqcol, ",".join([str(x) for x in itms]))
	#s = " AND ".join(["%s=%s" % (fqcol,x) for x in itms])
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



