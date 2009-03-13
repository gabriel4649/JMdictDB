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

import sys, cgi, re, datetime
sys.path.extend (['../lib','../../python/lib','../python/lib'])
import cgitbx; cgitbx.enable()
import jdb, jmcgi, jelparse, jellex, serialize

def main (args, opts):
	errs = []; chklist = {}
	try: form, svc, host, cur, sid, sess, parms, cfg = jmcgi.parseform()
	except Exception, e: errs = [str (e)]
	fv = form.getfirst; fl = form.getlist
	dbg = fv ('d'); meth = fv ('meth')
	KW = jdb.KW

	  # 'eid' will be an integer if we are editing an existing 
	  # entry, or undefined if this is a new entry.
	pentr = None
	eid = url_int ('id', form, errs)
	if eid: 
	    pentr = jdb.entrList (cur, None, [eid])
	      # FIXME: Need a better message with more explanation.
	    if not pentr: errs.append ("The entry you are editing has been deleted.")
	    else: 
		pentr = pentr[0]
		xrefs = jdb.collect_xrefs ([pentr])
		if xrefs: jdb.augment_xrefs (cur, xrefs)

	  # Desired disposition: 'a':approve, 'r':reject, undef:submit.
	disp = url_str ('disp', form)
	if disp!='a' and disp!='r' and disp !='' and disp is not None: 
	    errs.append ("Invalid 'disp' parameter: '%s'" % disp)

	  # New status is A for edit of existing or new entry, D for
	  # deletion of existing entry.
	delete = fv ('delete');  makecopy = fv ('makecopy')
	if delete and makecopy: errs.append ("The 'delete' and 'treat as new'"
	   " checkboxes are mutually exclusive; please select only one.")
	if makecopy: eid = None
	  # FIXME: we need to disallow new entries with corp.seq 
	  # that matches an existing A, A*, R*, D*, D? entry.
	  # Do same check in submit.py.

	seq = url_int ('seq', form, errs)
	src = url_int ('src', form, errs)
	notes = url_str ('notes', form)
	srcnote = url_str ('srcnote', form)

	  # These are the JEL (JMdict Edit Language) texts which
	  # we will concatenate into a string that is fed to the
	  # JEL parser which will create an Entr object.
	kanj = url_str ('kanj', form).replace('\n', ' ')
	rdng = url_str ('rdng', form).replace('\n', ' ')
	sens = url_str ('sens', form)
	intxt = "\n".join ((kanj, rdng, sens))

	  # Get the meta-edit info which will go into the history
	  # record for this change.
	comment = url_str ('comment', form)
	refs    = url_str ('reference', form)
	name    = url_str ('name', form)
	email   = url_str ('email', form)

	  # Parse the entry data.  Problems will be reported
	  # by messages in 'perrs'.  We do the parse even if 
	  # the request is to delete the entry (is this right
	  # thing to do???) since on the edconf page we want
	  # to display what the entry was.  The edsubmit page
	  # will do the actual deletion. 

	entr, perrs = parse (intxt)
	errs.extend (perrs)

	if entr and not errs:
	    entr.dfrm = eid;
	    entr.unap = not disp

	    if delete:
		  # Ignore any content changes made by the submitter by 
		  # restoring original values to the new entry.
	        entr.seq = pentr.seq;	entr.src = pentr.src;
		entr.stat = KW.STAT['D'].id
		entr.notes = pentr.notes;  entr.srcnote = pentr.srcnote; 
		entr._kanj = getattr (pentr, '_kanj', []); 
		entr._rdng = getattr (pentr, '_rdng', []); 
		entr._sens = getattr (pentr, '_sens', []); 
		entr._snd  = getattr (pentr, '_snd',  []); 
		entr._grp  = getattr (pentr, '_grp',  []); 
		entr._cinf = getattr (pentr, '_cinf', []); 
	    else:
	          # Migrate the entr details to the new entr object
	          # which to this point has only the kanj/rdng/sens
	          # info provided by jbparser.  
		entr.seq = seq;   entr.src = src;   
		entr.stat = KW.STAT['A'].id
		entr.notes = notes;  entr.srcnote = srcnote; 

	          # Copy (shallowly since we won't be changing the copied
		  # content) content from the original entry to the new
		  # entry since JEL currently provides no way to specify
	          # these items.
		if pentr: 
		    if not jmcgi.is_editor (sess): 
			jdb.copy_freqs (pentr, entr)
		    if hasattr (pentr, '_grp'): entr._grp = pentr._grp
		    if hasattr (pentr, '_cinf'): entr._cinf = pentr._cinf
		    copy_snd (pentr, entr)

	          # Add sound details so confirm page will look the same as the 
	          # original entry page.  Otherwise, the confirm page will display
	          # only the sounf clip id(s).
	        snds = []
	        for s in getattr (entr, '_snd', []): snds.append (s)
	        for r in getattr (entr, '_rdng', []):
		    for s in getattr (r, '_snd', []): snds.append (s)
	        if snds: jdb.augment_snds (cur, snds)

	          # If any xrefs were given, resolve them to actual entries
	          # here since that is the form used to store them in the 
	          # database.  If any are unresolvable, an approriate error 
	          # is saved and will reported later.

	        rslv_errs = jelparse.resolv_xrefs (cur, entr)
	        if rslv_errs: chklist['xrslv'] = rslv_errs

	if entr and not errs:
	      # Append a new hist record details this edit.
	    if not hasattr (entr, '_hist'): entr._hist = []
	    entr = jdb.add_hist (entr, pentr, sess.userid if sess else None, 
				 name, email, comment, refs, 
				 entr.stat==KW.STAT['D'].id)
	    chkentr (entr, errs)

	      # If this is a new entry, look for other entries that
	      # have the same kanji or reading.  These will be shown
	      # as cautions at the top of the confirmation form in
	      # hopes of reducing submissions of words already in 
	      # the database.
	    if not eid and not delete:
		dups = find_similar (cur, getattr (entr,'_kanj',[]),
					getattr (entr,'_rdng',[]), entr.src)
	        if dups: chklist['dups'] = dups
		  # FIXME: Should pass list of the kanj/rdng text rather than
		  #   a pre-joined string so that page can present the list as
		  #   it wishes.
		chklist['invkebs'] = ", ".join ([k.txt for k in getattr (entr,'_kanj',[])
				                       if not jdb.jstr_keb (k.txt)])
		chklist['invrebs'] = ", ".join ([r.txt for r in getattr (entr,'_rdng',[])
				                       if not jdb.jstr_reb (r.txt)])
	    entrs = [entr]

	if not errs:
	    if not meth: meth = 'get' if dbg else 'post'
	    serialized = serialize.serialize (entrs)
	    jmcgi.htmlprep (entrs)
	    jmcgi.gen_page ("tmpl/edconf.tal", macros='tmpl/macros.tal',
			    entries=entrs, serialized=serialized,
			    chklist=chklist, disp=disp, parms=parms,
			    svc=svc, host=host, sid=sid, session=sess, cfg=cfg, 
			    method=meth, output=sys.stdout, this_page='edconf.py')
	else: jmcgi.gen_page ("tmpl/url_errors.tal", output=sys.stdout, errs=errs)
	cur.close() 

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
	if v: v = v.decode ('utf-8').strip(u'\n\r \t\u3000')
	return v or ''

def copy_snd (fromentr, toentr, replace=False):
	# Copy the snd items (both Entrsnd and Rdngsnd objects) from
	# 'fromentr' to 'toentr'.  
	# If 'replace' is false, the copied freqs will be appended
	# to any freqs already on 'toentr'.  If true, all existing
	# freqs on 'toentr' will be deleted before copying the freqs.
	# CAUTION: The Entrsnd and Rdngsnd objects themselves are not
	#  duplicated, the same objects are referred to from both the
	#  'fromentr' and the 'toentr'.

	if replace: 
	    if hasattr (toentr, '_snd'): toentr._snd = []
	    for r in getattr (toentr, '_rdng', []):
		if hasattr (r, '_snd'): r._snd = []
	if hasattr (fromentr, '_snd'): toentr._snd.extend (fromentr._snd)
	  # FIXME: How to migrate if new readings are different 
	  # than old readings (in attr '.txt', in order, or in number)?
	if hasattr (fromentr, '_rdng') and hasattr (toentr, '_rdng'):
	    for rto, rfrom in zip (getattr (toentr,'_rdng',[]),
				   getattr (fromentr,'_rdng',[])):
		 if hasattr (rfrom, '_snd'): rto._snd.extend (rfrom._snd)

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
	entr = None; errs = []
	lexer, tokens = jellex.create_lexer ()
        parser = jelparse.create_parser (lexer, tokens, module=jelparse,
					 tabmodule='jelparse_tab',
					 write_tables=0, optimize=1, debug=1)
        jellex.lexreset (lexer, krstext)
        try: 
	    entr = parser.parse (krstext, lexer=lexer, tracking=True)
	except jelparse.ParseError, e:
	    if not e.loc: msg = e.args[0]
	    else: msg = "%s\n<pre>\n%s\n</pre>" % (e.args[0], e.loc)
	    errs.append (msg)
	return entr, errs

if __name__ == '__main__': 
	args, opts = jmcgi.args()
	main (args, opts)
