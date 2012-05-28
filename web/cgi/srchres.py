#!/usr/bin/env python
#######################################################################
#  This file is part of JMdictDB. 
#  Copyright (c) 2006-2010 Stuart McGraw 
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
	       '$Date$'[7:-11])

import sys, cgi, copy, time
sys.path.extend (['../lib','../../python/lib','../python/lib'])
import cgitbx; cgitbx.enable()
import jdb, jmcgi, serialize, jelparse

def main( args, opts ):
	errs = []; so = None; stats = {}
	try: form, svc, host, cur, sid, sess, parms, cfg = jmcgi.parseform()
	except StandardError as e: jmcgi.err_page ([unicode (e)])

	cfg_web = d2o (cfg['web'])
	cfg_srch = d2o (cfg['search'])
	fv = form.getfirst; fl = form.getlist
	dbg = fv ('d'); meth = fv ('meth')
	force_srchres = fv('srchres')  # Force display of srchres page even if only one result.
	sqlp = (fv ('sql') or '').decode ('utf-8')
	soj = (fv ('soj') or '').decode ('utf-8')
	pgoffset = int(fv('p1') or 0)
	pgtotal = int(fv('pt') or -1)
	entrs_per_page = min (max (int(fv('ps') or cfg_web.DEF_ENTRIES_PER_PAGE),
			   cfg_web.MIN_ENTRIES_PER_PAGE), cfg_web.MAX_ENTRIES_PER_PAGE)
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
	    so.pos   = fl('pos');   so.misc  = fl('misc');  
	    so.fld   = fl('fld');   so.dial  = fl('dial');
	    so.rinf  = fl('rinf');  so.kinf  = fl('kinf');  so.freq = fl('freq')
	    so.grp   = grpsparse (fv('grp'))
	    so.src   = fl('src');   so.stat  = fl('stat');  so.unap = fl('appr')
	    so.nfval = fv('nfval'); so.nfcmp = fv('nfcmp')
	    so.gaval = fv('gaval'); so.gacmp = fv('gacmp')
	      #FIXME? use selection boxes for dates?  Or a JS calendar control?
	    so.ts = dateparse (fv('ts0'), 0, errs), dateparse (fv('ts1'), 1, errs)
	    so.smtr = (fv('smtr') or '').decode('utf-8'), fv('smtrm')
	    so.mt = fv('mt')
	      # Pack up all the search criteria in a json string that will 
	      # be given to the srchres form, which will in turn give it back
	      # to us if the user want to display the "next page".  
	    soj = serialize.so2js (so)

	elif soj:
	      # 'soj' is a json string that encodes the so object (containing
	      # the search criteria) that were used in previous invocation
	      # of this script, which displayed the previous page.
	    so = serialize.js2so (soj)

	elif sqlp:
	      # 'sqlp' is a SQL statement string that allows an arbitrary search.
	      # Because it can also do other things such as delete the database,
	      # it should only be run as a user with read-only access to the
	      # database and it is the job of jmcgi.adv_srch_allowed() to check
	      # that.
	    if not jmcgi.adv_srch_allowed (cfg, sess):
		jmcgi.err_page (["'sql' parameter is disallowed."])
	    sql = sqlp.strip()
	    if sql.endswith (';'): sql = sql[:-1]
	    sql_args = []

	if so:
	    try: condlist = jmcgi.so2conds (so)
	    except ValueError as e:
		errs.append (unicode (e))
	      # FIXME: [IS-115] Following will prevent kanjidic entries from
	      #  appearing in results.  Obviously hardwiring id=4 is a hack.
	    else:
	        #condlist.append (('entr e', 'e.src!=4', []))
	        sql, sql_args = jdb.build_search_sql (condlist)

	if errs: jmcgi.err_page (errs)

	orderby = "ORDER BY __wrap__.kanj,__wrap__.rdng,__wrap__.seq,__wrap__.id"
        page = "OFFSET %s LIMIT %s" % (pgoffset, entrs_per_page)
	sql2 = "SELECT __wrap__.* FROM esum __wrap__ " \
		 "JOIN (%s) AS __user__ ON __user__.id=__wrap__.id %s %s" \
		  % (sql, orderby, page)
	stats['sql']=sql; stats['args']=sql_args; stats['orderby']=orderby
	if cfg_srch.MAX_QUERY_COST > 0:
	    try:
	        cost = jdb.get_query_cost (cur, sql2, sql_args);
	    except StandardError as e:
		jmcgi.err_page (["Database error (%s):<pre> %s </pre></body></html>" 
			   % (e.__class__.__name__, str(e))])
	    stats['cost']=cost;
	    if cost > cfg_srch.MAX_QUERY_COST: 
		jmcgi.err_page (
		       ["The search request you made will likely take too long to execute. "
			"Please use your browser's \"back\" button to return to the search "
			"page and add more criteria to restrict your search more narrowly. "
			"(The estimated cost was %.1f, max allowed is %d.)" 
			% (cost, cfg_srch.MAX_QUERY_COST)])
	t0 = time.time()
	try: rs = jdb.dbread (cur, sql2, sql_args)
	except Exception as e:		#FIXME, what exception value(s)?
	    jmcgi.err_page (["Database error (%s):<pre> %s </pre></body></html>" 
		       % (e.__class__.__name__, str(e))])
	stats['dbtime'] = time.time() - t0
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
	    svcstr = ("svc=%s&sid=%s&" % (svc,sid)) if svc else ''
	    print ("Location: entr.py?%se=%d\n" % (svcstr, rs[0].id))
	else:
	    if not meth: meth = 'get' if dbg else 'post'
	    jmcgi.gen_page ("tmpl/srchres.tal", macros='tmpl/macros.tal', 
			    results=rs, pt=pgtotal, p0=pgoffset, method=meth,
			    p1=pgoffset+reccnt, soj=soj, sql=sqlp, parms=parms,
			    svc=svc, host=host, sid=sid, session=sess, cfg=cfg,
			    stats=stats, output=sys.stdout, this_page='srchres.py')

def d2o (dict_):
	# Copy the key/value items in a dict to attributes on an 
	# object, converting numbers to ints when possible.
	# FIXME: What about floats, bools, datetimes, lists, ...?
	#  Should we consider JSON as an ini file format?
	o = jdb.Obj()
	for k,v in dict_.items():
	    try: v = int (v)
	    except (ValueError,TypeError): pass
	    setattr (o, k, v)
	return o

def grpsparse (grpsstr):
	if not grpsstr: return []
	return grpsstr.split()

def dateparse (dstr, upper, errs): 
	if not dstr: return None 
	dstr = dstr.strip();  dt = None
	if not dstr: return None 
	  # Add a time if it wasn't given.
	if len(dstr) < 11: dstr += " 23:59" if upper else " 00:00"
	  # Note: we use time.strptime() to parse because it returns 
	  # struct easily converted into a 9-tuple, which in turn is 
	  # easily JSONized, unlike a datetime.datetime object. 
	try: dt = time.strptime (dstr, "%Y/%m/%d %H:%M")
	except ValueError:
	    try: dt = time.strptime (dstr, "%Y-%m-%d %H:%M")
	    except ValueError: 
		errs.append ("Unable to parse date/time string '%s'." % cgi.escape(dstr))
	if dt: return time.mktime (dt)
	return None

if __name__ == '__main__': 
	args, opts = jmcgi.args()
	main (args, opts)
