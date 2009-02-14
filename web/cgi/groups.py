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

__version__ = ('$Revision$'[11:-2],
	       '$Date$'[7:-11])

import sys, cgi
sys.path.extend (['../lib','../../python/lib','../python/lib'])
import jdb, jmcgi

def main( args, opts ):
	errs = []
	try: form, svc, host, cur, sid, sess, parms = jmcgi.parseform()
	except Exception, e: errs = [str (e)]
	if errs:
	    jmcgi.gen_page ('tmpl/url_errors.tal', output=sys.stdout, errs=errs)
	    return 
	fv = form.getfirst; fl = form.getlist
	orderby = "k.id,s.kw,e.src"
	sql = "SELECT k.id, k.kw, k.descr, s.kw AS corpus, count(*) AS cnt " \
		"FROM kwgrp k " \
		"LEFT JOIN grp g ON g.kw=k.id " \
		"LEFT JOIN entr e ON e.id=g.entr " \
		"LEFT JOIN kwsrc s ON s.id=e.src " \
		"GROUP BY k.id, k.kw, k.descr, s.kw " \
		"ORDER BY %s" % orderby
		
	rs = jdb.dbread (cur, sql)
	jmcgi.gen_page ("tmpl/groups.tal", macros='tmpl/macros.tal', 
			 results=rs, 
			 svc=svc, host=host, sid=sid, session=sess, parms=parms,
			 output=sys.stdout, this_page='goups.py')

if __name__ == '__main__': 
	args, opts = jmcgi.args()
	main (args, opts)