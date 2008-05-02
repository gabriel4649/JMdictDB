#!/usr/bin/env python
#######################################################################
#  This file is part of JMdictDB. 
#  Copyright (c) 2006,2008 Stuart McGraw 
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
sys.path.extend (['../../python/lib','../python/lib'])
import jdb, jmcgi

def main (args, opts):
	form = cgi.FieldStorage()
	errs = []
	svc = form.getfirst ('svc')
	try: svc = jmcgi.safe (svc)
	except ValueError: errs.append ('svc=' + svc)
	if not errs:
	    cur = jmcgi.dbOpenSvc (svc)
	    entries = jmcgi.get_entrs (cur, form.getlist ('e'),
					    form.getlist ('q'), errs)
	    for e in entries:
		for s in e._sens:
		    if hasattr (s, '_xref'): jdb.augment_xrefs (cur, s._xref)
		    if hasattr (s, '_xrer'): jdb.augment_xrefs (cur, s._xrer, 1)
	    cur.close()
	if not errs:
	    jmcgi.fmt_p (entries)
	    jmcgi.fmt_restr (entries)
	    jmcgi.fmt_stag (entries)
	    jmcgi.set_audio_flag (entries)
	    jmcgi.set_editable_flag (entries)
	    jmcgi.gen_page ('tmpl/entr.tal', output=sys.stdout, entries=entries, svc=svc)
	else:
	    jmcgi.gen_page ('tmpl/url_errors.tal', output=sys.stdout, errs=errs)

if __name__ == '__main__': 
	args, opts = jmcgi.args()
	main (args, opts)
