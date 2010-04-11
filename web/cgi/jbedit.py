#!/usr/bin/env python
#######################################################################
#  This file is part of JMdictDB. 
#  Copyright (c) 2010 Stuart McGraw 
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


import sys, cgi, re, os
sys.path.extend (['../lib','../../python/lib','../python/lib'])
import cgitbx; cgitbx.enable()
import jdb, jmcgi, fmtjel, edparse
from serialize import unserialize

Enc = 'utf-8'

def main (args, opts):
	errs = []
	try: form, svc, host, cur, sid, sess, parms, cfg = jmcgi.parseform()
	except Exception, e: errs = [str (e)]
	if errs: err_page (errs)

	  # The filesystem path of the directory containing editdata files.
	filesdir = cfg['web']['EDITDATA_DIR']
	  # The URL for the directory containing editdata files.
	httpdir  = cfg['web']['EDITDATA_URL']

	fv = lambda x:(form.getfirst(x) or '').decode(Enc)
	is_editor = jmcgi.is_editor (sess)
	dbg = fv ('d'); meth = fv ('meth')
	srcs = sorted (jdb.KW.recs('SRC'), key=lambda x: x.kw)

	# Get the filename url parameter, and validate it.
	fn = fv ('fn')
	if not re.search (r'[0-9]{5}\.dat$', fn) or '/' in fn:
	    err_page (["Bad 'fn' url parameter"])
	fullname = os.path.join (filesdir, fn)
	# Open the file, get the data.
	s = open (fullname).read()
	try: e, ref, comment, name, email = unserialize (s)
	except StandardError, e:
	    err_page (["Bad file data, unable to unserialize: %s" % unicode(e)])
	extra = {'ref':ref, 'comment':comment, 'name':name, 'email':email}
	e.NOCORPOPT = ''  # This seems to be required by template, see edform.py
	if not meth: meth = 'get' if dbg else 'post'
	jmcgi.gen_page ('tmpl/edform.tal', macros='tmpl/macros.tal', parms=parms,
			entrs=[e], extra=extra, srcs=srcs, is_editor=is_editor,
			svc=svc, host=host, sid=sid, session=sess, cfg=cfg, 
			 method=meth, output=sys.stdout, this_page='jbedit.py')

def err_page (errs):
	jmcgi.gen_page ('tmpl/url_errors.tal', output=sys.stdout, errs=errs)
	sys.exit()

if __name__ == '__main__': 
	args, opts = jmcgi.args()
	main (args, opts)
