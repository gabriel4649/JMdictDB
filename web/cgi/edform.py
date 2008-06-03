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

import sys, cgi
sys.path.extend (['../lib','../../python/lib','../python/lib'])
import jdb, jmcgi, fmtjel

def main (args, opts):
	form = cgi.FieldStorage()
	errs = []
	is_editor = 1
	svc = form.getfirst ('svc')
	try: svc = jmcgi.safe (svc)
	except ValueError: 
	    errs.append ('svc=' + svc)
	if not errs:
	    elist = form.getlist ('e')
	    qlist = form.getlist ('q')
	    cur = jmcgi.dbOpenSvc (svc)
	    if elist or qlist:
	        entrs = jmcgi.get_entrs (cur, elist, qlist, errs)
	    else: entrs = []
	    cur.close()
	if not errs:
	    if len (entrs) > 1: 
	        errs.append ("Can\'t edit more than one entry at a time<br>\n"
			 "Note: q=... url parameters may need to qualified<br/>\n"
			 "by a specific corpus, e.g. q=1037440.jmdict")
	if not errs:
	    srcs = sorted (jdb.KW.recs('SRC'), key=lambda x: x.kw)
	    srcs.insert (0, jdb.Obj (id=0, kw='', descr=''))
	    if entrs:
		entr = entrs[0]
		ktxt = fmtjel.kanjs (entr._kanj)
		rtxt = fmtjel.rdngs (entr._rdng, entr._kanj)
		stxt = fmtjel.senss (entr._sens, entr._kanj, entr._rdng)
		isdelete = (entr.stat == jdb.KW.STAT['D'].id) or None
	    else:
		entr = None; isdelete = None
		ktxt = rtxt = ''
		stxt = "[1][n]"
	    jmcgi.gen_page ('tmpl/edform.tal', output=sys.stdout, e=entr, 
			     ktxt=ktxt, rtxt=rtxt, stxt=stxt,
			     srcs=srcs, is_editor=is_editor, isdelete=isdelete,
			     svc=svc, method='get')
	else:
	    jmcgi.gen_page ('tmpl/url_errors.tal', output=sys.stdout, errs=errs)

if __name__ == '__main__': 
	args, opts = jmcgi.args()
	main (args, opts)
