#!/usr/bin/env python
#######################################################################
#  This file is part of JMdictDB. 
#  Copyright (c) 2009 Stuart McGraw 
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
from __future__ import print_function

__version__ = ('$Revision$'[11:-2],
	       '$Date$'[7:-11]);

import sys, cgi
sys.path.extend (['../lib','../../python/lib','../python/lib'])
import cgitbx; cgitbx.enable()
import jdb, jmcgi

def main( args, opts ):
	try: form, svc, host, cur, sid, sess, parms, cfg = jmcgi.parseform()
	except StandardError as e: jmcgi.err_page ([unicode (e)])

	fv = form.getfirst; fl = form.getlist
	dbg = fv ('d'); meth = fv ('meth')
	#qs = jmcgi.form2qs (form)
	adv_srch_allowed = jmcgi.adv_srch_allowed (cfg, sess)
	if not meth: meth = 'get' if dbg else 'post'
	jmcgi.gen_page ("tmpl/srchsql.tal", macros='tmpl/macros.tal', 
			svc=svc, host=host, sid=sid, session=sess, cfg=cfg, 
			adv_srch_allowed = adv_srch_allowed, parms=parms,
			method=meth, output=sys.stdout, this_page='srchsql.py')

if __name__ == '__main__': 
	args, opts = jmcgi.args()
	main (args, opts)
