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

__version__ = ('$Revision$'[11:-2],
	       '$Date$'[7:-11])

import sys, cgi, cgitb, re, datetime
sys.path.extend (['../lib','../../python/lib','../python/lib'])
import jdb, jmcgi, jelparse, jellex, json

def main (args, opts):
	#cgitb.enable()
	errs = []; form = cgi.FieldStorage()
	fv = form.getfirst; fl = form.getlist
	svc = fv ('svc')
	try: svc = jmcgi.safe (svc)
	except ValueError: 
	    jmcgi.gen_page ('tmpl/url_errors.tal', output=sys.stdout, errs=['svc=svc'])
	    return
	cur = jmcgi.dbOpenSvc (svc)
	KW = jdb.KW

	  # $eid will be an integer if we are editing an existing 
	  # entry, or undefined if this is a new entry.
	eid = url_int ('id', form, errs)

	  # Desired disposition: 'a':approve, 'r':reject, undef:submit.
	disp = url_str ('disp', form)

	  # New status is A for edit of existing entry, N for new 
	  # entry, D for deletion of existing entry.
	delete = fv ('delete')
	stat = (KW.STAT['D'].id if delete else KW.STAT['A'].id) \
		if eid else KW.STAT['N'].id

	  # These will only have values when editing an entry. 
	seq = url_int ('seq', form, errs)
	src = url_int ('src', form, errs)
	notes = url_str ('notes', form)
	srcnote = url_str ('srcnote', form)

	  # These are the JEL (JMdict Edit Language) texts which
	  # we will concatenate into a string that is fed to the
	  # JEL parser which will create an entry object.
	kanj = url_str ('kanj', form) or ''
	rdng = url_str ('rdng', form) or ''
	sens = url_str ('sens', form) or ''
	intxt = "\n".join ((kanj, rdng, sens))

	  # Get the meta-edit info which will go into the history
	  # record for this change.
	comment = url_str ('comment', form)   or ''
	refs    = url_str ('reference', form) or ''
	name    = url_str ('name', form)      or ''
	email   = url_str ('email', form)     or ''
	if not email: errs.append ("Missing email address")
	else:
	    mo = re.search (r'^[A-Z0-9._%-]+@(?:[A-Z0-9-]+\.)+[A-Z]{2,4}$', email, re.I)
	    if not mo:
		errs.append ("Invalid email address: %s" % email)

	  # Parse the entry data.  Problems will be reported
	  # by messages in @$perrs.  We do the parse even if 
	  # the request is to delete the entry (is this right
	  # thing to do???) since on the edconf page we want
	  # to display what the entry was.  The edsubmit page
	  # will do the actual deletion. 
	entr, perrs = parse (intxt)
	errs.extend (perrs)

	  # The code in the "if" below assumes we have a valid entr
	  # object from jbparser.  If there were parse errors that's
	  # not true so we don't go there.
	if entr and not errs:

	      # If any xrefs were given, resolve them to actual entries
	      # here since that is the form used to store them in the 
	      # database.  If any are unresolvable, an approriate error 
	      # is saved and will reported later.
	    perrs = jelparse.resolv_xrefs (cur, entr)

	      # Migrate the entr details to the new entr object
	      # which to this point had only the kanj/rdng/sens
	      # info provided by jbparser.  
	    entr.dfrm = eid;  entr.seq = seq;      entr.stat = stat; 
	    entr.src = src;   entr.notes = notes;  entr.srcnote = srcnote; 
	    entr.unap = 1

	      # Append a new hist record details this edit.
	    if not hasattr (entr, '_hist'): entr._hist = []
	    entr._hist.append (newhist (entr, stat, comment, refs,
					 name, email, errs))
	    chkentr (entr, errs)

	      # If this is a new entry, look for other entries that
	      # have the same kanji or reading.  These will be shown
	      # as cautions at the top of the confirmation form in
	      # hopes of reducing submissions of words already in 
	      # the database.
	    if not eid and not delete:
		chklist = find_similar (cur, getattr (entr,'_kanj',[]),
					getattr (entr,'_rdng',[]), entr.src)
	    else: chklist = []
	    entrs = [entr]

	if not errs:
	    serialized = json.serialize ([entr])
	    jmcgi.fmt_p (entrs)
	    jmcgi.fmt_restr (entrs)
	    jmcgi.fmt_stag (entrs)
	    jmcgi.set_audio_flag (entrs)
	    jmcgi.gen_page ("tmpl/edconf.tal", output=sys.stdout, entries=entrs,
			    chklist=chklist, is_editor=1, svc=svc, disp=disp,
			    method="get", serialized=serialized)
	else: jmcgi.gen_page ("tmpl/url_errors.tal", output=sys.stdout, errs=errs)
	cur.close() 

def newhist (entr, stat, comment, refs, name, email, errs):
	  # Create a history record for display.  A real record 
	  # will be recreated when the entry is actually committed
	  # to the database.
	now = datetime.datetime.utcnow().replace(microsecond=0)
	hist = jdb.Obj (hist=1, dt=now, stat=stat, name=name, 
		        email=email, diff='', refs=refs, notes=comment)
	return hist

def find_similar (dbh, kanj, rdng, src):
	# Find all entries that have a kanj in the set @$kanj,
	# or a reading in the set @$rdng, and return a list of
	# esum view records of such entries.  Either $kanj or
	# $rdng, but not both, may be undefined or empty.
	# If $src is given, search will be limited to entries
	# with that entr.src id number.
	
	rwhr = " OR ".join (["txt=%s"] * len(rdng))
	kwhr = " OR ".join (["txt=%s"] * len(kanj))
	args = [src]
	args.extend ([x.txt for x in rdng+kanj])

	sql = "SELECT DISTINCT e.* " \
		+ "FROM esum e " \
		+ "WHERE e.src=%s AND e.stat<4 AND e.id IN (" \
  		+ (("SELECT entr FROM rdng WHERE %s " % rwhr)    if rwhr          else "") \
		+ ("UNION "                                      if rwhr and kwhr else "") \
		+ (("SELECT entr FROM kanj WHERE %s " % kwhr)    if kwhr          else "") \
		+ ")"
	rs = jdb.dbread (dbh, sql, args)
	return rs

def url_int (name, form, errs):
	v = form.getfirst (name)
	if not v: return v
	try: n = int (v)
	except ValueError: 
	      # FIXME: escape v
	    errs.append ("name=" + v)
	return n
	
def url_str (name, form):
	v = form.getfirst (name)
	if v: v = v.decode ('utf-8') 
	return v

def chkentr (e, errs):
	# Do some validation of the entry.  This is nowhere near complete 
	# Yhe database integrity rules will in principle catch all serious
	# problems but catching db errors and back translating them to a
	# user-actionable message is difficult so we try to catch the obvious
	# stuff here.

	if not getattr (e,'src',None):
	    errs.append ("No Corpus specified.  Please select the corpus "
			 "that this entry will be added to.")
	if not getattr (e,'_rdng',None) and not getattr (e,'_kanj'):
	    errs.append ("Both the Kanji and Reading boxes are empty.  "
			 "You must provide at least one of them.")
	if not getattr (e,'_sens',None):
	    errs.append ("No senses given.  You must provide at least one sense.")
	for n, s in enumerate (e._sens):
	    if not getattr (s, '_gloss'):
		errs.append ("Sense %d has no glosses.  Every sense must have at least "
			     "one regular gloss, or a [lit=...] or [expl=...] tag." % n)

def parse (krstext):
	errs = []
	lexer, tokens = jellex.create_lexer ()
        parser = jelparse.create_parser (tokens, debug=0)
        jellex.lexreset (lexer, krstext)
        try: e = parser.parse (krstext, lexer=lexer)
	except StandardError, e: errs.append (str(e))
	return e, errs

if __name__ == '__main__': 
	args, opts = jmcgi.args()
	main (args, opts)
