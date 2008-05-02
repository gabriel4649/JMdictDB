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

def main( args, opts ):
	form = cgi.FieldStorage(); fv = form.getfirst; fl = form.getlist
	svc = jmcgi.safe (form.getvalue ('svc'))
	cur = jmcgi.dbOpenSvc (svc)

	so = jmcgi.SearchItems()
	so.idnum=fv('idval');  so.idtyp=fv('idtyp')
	tl = []
	for i in (1,2,3):
	    txt = (fv('t'+str(i)) or '').decode('utf-8')
	    if txt: tl.append (jmcgi.SearchItemsTexts (
				 srchtxt = txt, 
				 srchin  = fv('s'+str(i)),
				 srchtyp = fv('y'+str(i)) ))
	if tl: so.txts = tl
	so.pos   = fl('pos');   so.misc  = fl('misc');  so.fld  = fl('fld')
	so.rinf  = fl('rinf');  so.kinf  = fl('kinf');  so.freq = fl('freq')
	so.src   = fl('src');   so.stat  = fl('stat');  so.unap = fl('appr')
	so.nfval = fv('nfval'); so.nfcmp = fv('nfcmp')
	so.gaval = fv('gaval'); so.gacmp = fv('gacmp')
	force_srchres = 1  #fv('srchres')  # Force display of srchres page even if only one result.

	condlist = jmcgi.so2conds (so)
	  # FIXME: [IS-115] Following will prevent kanjidic entries from
	  #  appearing in results.  Obviously hardwiring id=4 is a hack.
	condlist.append (('entr e', 'e.src!=4', []))
	sql, sql_args = jdb.build_search_sql (condlist)

	#  $::Debug->{'Search sql'} = $sql;  $::Debug->{'Search args'} = join(",", @$sql_args);
	sql2 = "SELECT q.* FROM esum q JOIN (%s) AS i ON i.id=q.id" % sql
	#  my $start = time();
	try: rs = jdb.dbread (cur, sql2, sql_args)
	#  $::Debug->{'Search time'} = time() - $start;
	except Exception, e:		#FIXME, what exception value(s)?
	    print "<pre> %s </pre>\n<pre>%s</pre>\n<pre>%s</pre></body></html>" \
		% (str(e), sql2, ", ".join(sql_args))
	    return
	if len(rs) == 1 and not force_srchres:
	    svcstr = ("svc=%s&" % svc) if svc else ''
	    print "Location: entr.py?%se=%d\n" % (svcstr, rs[0].id)
	else:
	    jmcgi.gen_page ("tmpl/srchres.tal", output=sys.stdout, results=rs, svc=svc)

if __name__ == '__main__': 
	args, opts = jmcgi.args()
	main (args, opts)
