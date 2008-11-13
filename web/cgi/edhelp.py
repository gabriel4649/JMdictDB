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
import jdb, jmcgi

def main (args, opts):
	form = cgi.FieldStorage()
	svc = jmcgi.safe (form.getvalue ('svc'))
	cur = jmcgi.dbOpenSvc (svc)
	cur.close()
	kwlist = []; kwhash = {}
	for t in 'RINF KINF FREQ MISC POS FLD DIAL LANG GINF SRC STAT XREF'.split():
	    kw = jdb.KW.recs (t)
	    kwset = [t.capitalize(), sorted (kw, key=lambda x:x.kw)]
	    kwlist.append (kwset)
	    kwhash[t] = kwset[1]
	jmcgi.gen_page ("tmpl/edhelp.tal", macros='tmpl/macros.tal', 
			kwlist=kwlist, kwhash=kwhash, svc=svc,
			output=sys.stdout)

if __name__ == '__main__': 
	args, opts = jmcgi.args()
	main (args, opts)
