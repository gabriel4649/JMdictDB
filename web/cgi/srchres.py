#!/usr/bin/env python
#######################################################################
#  This file is part of JMdictDB. 
#  Copyright (c) 2006,2009 Stuart McGraw 
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

import sys, cgi, copy
sys.path.extend (['../lib','../../python/lib','../python/lib'])
import jdb, jmcgi, serialize

MAX_ENTRIES_PER_PAGE = 1000
MIN_ENTRIES_PER_PAGE = 1
DEF_ENTRIES_PER_PAGE = 100
MAX_QUERY_COST = 200000

def main( args, opts ):
	errs = []; so = None
	try: form, svc, host, cur, sid, sess, parms = jmcgi.parseform ()
	except Exception, e: errs = [str (e)]
	if errs:
	    jmcgi.gen_page ('tmpl/url_errors.tal', output=sys.stdout, errs=errs)
	    return 
	fv = form.getfirst; fl = form.getlist
	force_srchres = fv('srchres')  # Force display of srchres page even if only one result.
	sqlp = None #fv ('sql')
	soj = fv ('soj')
	pgoffset = int(fv('p1') or 0)
	pgtotal = int(fv('pt') or -1)
	entrs_per_page = min (max (int(fv('ps') or DEF_ENTRIES_PER_PAGE),
			   MIN_ENTRIES_PER_PAGE), MAX_ENTRIES_PER_PAGE)
	if not sqlp and not soj:
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
	    so.grp   = fl('grp')
	    so.src   = fl('src');   so.stat  = fl('stat');  so.unap = fl('appr')
	    so.nfval = fv('nfval'); so.nfcmp = fv('nfcmp')
	    so.gaval = fv('gaval'); so.gacmp = fv('gacmp')
	      # Pack up all the search criteria in a json string that will 
	      # be given to the srchres form, which will in turn give it back
	      # to us if the user want to display the "next page".  
	    soj = serialize.so2js (so)

	elif soj:
	      # 'soj' is a json string that encodes the so object (containing
	      # the search criteria) that were used in previous invocation
	      # of this script, which displayed the previous page.
	    so = serialize.js2so (soj)

	  # Disabled for now until database security issues worked out.
	elif sqlp:
	    if not jmcgi.is_editor(sess):
		errs = ["'sql' parameter only accepted from logged in editors."]
		jmcgi.gen_page ('tmpl/url_errors.tal', output=sys.stdout, errs=errs)
		return
	    sql = sqlp.strip()
	    if sql.endswith (';'): sql = sql[:-1]
	    sql_args = []

	if so:
	    condlist = jmcgi.so2conds (so)
	      # FIXME: [IS-115] Following will prevent kanjidic entries from
	      #  appearing in results.  Obviously hardwiring id=4 is a hack.
	    condlist.append (('entr e', 'e.src!=4', []))
	    sql, sql_args = jdb.build_search_sql (condlist)

	sql2 = "SELECT q.* FROM esum q JOIN (%s) AS i ON i.id=q.id " \
		 "ORDER BY q.seq,q.id OFFSET %s LIMIT %s" % (sql, pgoffset, entrs_per_page)
	if MAX_QUERY_COST > 0:
	    cost = jdb.get_query_cost (cur, sql2, sql_args);
	    if cost > MAX_QUERY_COST: 
		errs = ["The search request you made will likely take too long to execute. "
			"Please use your browser's \"back\" button to return to the search "
			"page and add more criteria to restrict your search more narrowly. "
			"(The estimated cost was %.1f, max allowed is %d.)" 
			% (cost,MAX_QUERY_COST)]
		jmcgi.gen_page ('tmpl/url_errors.tal', output=sys.stdout, errs=errs)
		return 

	try: rs = jdb.dbread (cur, sql2, sql_args)
	except Exception, e:		#FIXME, what exception value(s)?
	    print "<pre> %s </pre>\n<pre>%s</pre>\n<pre>%s</pre></body></html>" \
		% (str(e), sql2, ", ".join(sql_args))
	    return
	reccnt = len(rs)
	if pgtotal < 0:
	    if reccnt >= entrs_per_page:
	      # If there may be more than one page of entries (because
	      # 'reccnt' is greater than the page size, 'entrs_per_page',
	      # then run another query to get the actual number of entries.
	      # We only do this on the first page of results ('pgtotal' is
	      # less then 0) and subsequently pass the value between pages
	      # for performace reasons, even though the number of entries
	      # may change before the user gets to the last page.
	        sql3 = "SELECT COUNT(*) AS cnt FROM (%s) AS i " % sql
	        cntrec = jdb.dbread (cur, sql3, sql_args)
	        pgtotal = cntrec[0][0]	# Total number of entries.
	    else: pgtotal = reccnt
	if reccnt == 1 and pgtotal == 1 and not force_srchres:
	      # If there is only one entry, display it rather than a search
	      # results page.  'force_srchres' allows supressing this behavior
	      # for debugging.
	    svcstr = ("svc=%s&" % svc) if svc else ''
	    print "Location: entr.py?%se=%d\n" % (svcstr, rs[0].id)
	else:
	    jmcgi.gen_page ("tmpl/srchres.tal", macros='tmpl/macros.tal', 
			    results=rs, pt=pgtotal, p0=pgoffset,
			    p1=pgoffset+reccnt, soj=soj, sql=sqlp,
			    svc=svc, host=host, sid=sid, session=sess, parms=parms,
			    output=sys.stdout, this_page='srchres.py')

if __name__ == '__main__': 
	args, opts = jmcgi.args()
	main (args, opts)
