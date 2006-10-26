#!/usr/bin/env python
# -*- coding: utf-8 -*-

_VERSION_=("$Revision$"[11:-2],"$Date$"[7:-11])
_AUTHOR_ = "Stuart McGraw <smcgraw@frii.com>"
# Copyright (c) 2006, Stuart McGraw 

import sys, os, cgi, cgitb
sys.path.append (r"c:\stuart\develop\jdb\jb")
import db, jbdb
from tables import *
from simpleTalHelper import mktemplate, serialize

global KW

def main (args, opts):
	global KW
	print "Content-type: text/html\n"

	try: pt = os.environ['PATH_TRANSLATED'].replace('\\', '/')
	except KeyError: base = "."
	else: base = pt[:pt.rfind('/')]

	if len(args)==0 or args[0]=="": 
	    cgitb.enable()
	    sys.stderr = file(base+"srchfrm.log","w")

	# open the database...
	try: cursor = db.dbOpen (user="postgres", password="satomi", database="jb")
	except db.dbapi.OperationalError, e:
	    print "Error, unable to connect to database:", unicode(e);  sys.exit(1)
	# Read in all the keyword tables...
	KW = jbdb.Kwds (cursor)
	src =   sorted ([v for k,v in KW.SRC.items()  if isinstance(k,int)], key=lambda v: v.kw)
	pos =   sorted ([v for k,v in KW.POS.items()  if isinstance(k,int)], key=lambda v: v.kw)
	misc =  sorted ([v for k,v in KW.MISC.items() if isinstance(k,int)], key=lambda v: v.kw)
	frq =  sorted ([v for k,v in KW.FREQ.items() if isinstance(k,int)], key=lambda v: v.kw)
	freq = []
	for x in frq:
	    for v in '1','2':
		if not (x.kw=="nf" or (x.kw=="spec" and v=="2")): freq.append (x.kw+v)

	tmpl = mktemplate(base+"/templates/srchfrm.tal")
	serialize (tmpl, sys.stdout, src=src, pos=pos, misc=misc, freq=freq)

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



