#!/usr/bin/env python
#######################################################################
#  This file is part of JMdictDB. 
#  Copyright (c) 2008-2009 Stuart McGraw 
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

# This page accepts the following url parameters:
#   e=n -- Zero or more entry id numbers.
#   q=n -- Zero or more entry seq numbers.
#   q=n.c -- Zero or more entry seq numbers with corpus.
#   f=1 -- Do not give non-editor users a choice of corpus for
#	new entries.  This parameter will be ignored if 'c' not
#	also given.
#   c=c -- Default corpus for any q entries.  q entries without 
#	a corpus will be limited to this corpus.  Value may be  
#	the corpus id number, or corpus name.
#   a=1 -- Restrict q entries to active/approved, or new, entries.
#	If not given all entries with a matching seq number will 
#	be displayed regardless of status or approval state.
#   Standard parameters: svc, sid.

import sys, cgi
sys.path.extend (['../lib','../../python/lib','../python/lib'])
import cgitbx; cgitbx.enable()
import jdb, jmcgi, fmtjel

def main (args, opts):
	errs = []
	try: form, svc, host, cur, sid, sess, parms, cfg = jmcgi.parseform()
	except Exception, e: errs = [str (e)]
	is_editor = jmcgi.is_editor (sess)
	def_corp = form.getfirst ('c')		# Default corpus for new entries.
	force_corp = form.getfirst ('f')	# Force default corpus for new entries.
	active = form.getfirst ('a')		# Limit q entries to active/appr or new..
	if not errs:
	    elist = form.getlist ('e')	# Entry id numbers.
	    qlist = form.getlist ('q')  # Seq.corpus identifiers.
	    if elist or qlist:
	        entrs = jmcgi.get_entrs (cur, elist, qlist, errs, 
					 active=active, corpus=def_corp)
	    else: entrs = []
	    cur.close()
	if not errs:
	    srcs = sorted (jdb.KW.recs('SRC'), key=lambda x: x.kw)
	    #srcs.insert (0, jdb.Obj (id=0, kw='', descr=''))
	    for entr in entrs:
		if not is_editor: remove_freqs (entr)
		entr.ISDELETE = (entr.stat == jdb.KW.STAT['D'].id) or None
	    if not entrs:
		  # This is a new entry.
		defcorpid = None
		if def_corp:
		    try: def_corp = int (def_corp)
		    except ValueError: pass
		    try: defcorpid = jdb.KW.SRC[def_corp].id
		    except KeyError: errs.append ("Bad url parameter: c=%s" % def_corp)
	        if not errs:
		      # The following dummy entry will produce the default
		      # text for new entries: no kanji, no reading, and sense
		      # text "[1][n]".
		    entr = jdb.Entr(_sens=[jdb.Sens(_pos=[jdb.Pos(kw=jdb.KW.POS['n'].id)])])
		      # Provide a default corpus.
		    entr.src = defcorpid
		    entr.ISDELETE = False
		    entr.NOCORPOPT = force_corp  
		    entrs = [entr]
	if not errs:
	    jmcgi.gen_page ('tmpl/edform.tal', macros='tmpl/macros.tal', parms=parms,
			     entrs=entrs, srcs=srcs, is_editor=is_editor, 
			     svc=svc, host=host, sid=sid, session=sess, cfg=cfg, 
			     method='get', output=sys.stdout, this_page='edform.py')
	else:
	    jmcgi.gen_page ('tmpl/url_errors.tal', output=sys.stdout, errs=errs)

def remove_freqs (entr):
	for r in getattr (entr, '_rdng', []): r._freq = []
	for k in getattr (entr, '_kanj', []): k._freq = []

if __name__ == '__main__': 
	args, opts = jmcgi.args()
	main (args, opts)
