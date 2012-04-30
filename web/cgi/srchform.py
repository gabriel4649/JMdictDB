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

__version__ = ('$Revision$'[11:-2],
	       '$Date$'[7:-11]);

import sys, cgi
sys.path.extend (['../lib','../../python/lib','../python/lib'])
import cgitbx; cgitbx.enable()
import jdb, jmcgi

class Kwfreq (object): 
    def __init__ (self, kw, descr):
	self.kw, self.descr = kw, descr

def main( args, opts ):
	try: form, svc, host, cur, sid, sess, parms, cfg = jmcgi.parseform()
	except StandardError, e: jmcgi.err_page ([unicode (e)])

	qs = jmcgi.form2qs (form)
	  # reshapes()'s last argument is the maximum number of checkboxes
	  # to put on a line, and is ajusted empirically to make the total
	  # widths for all the sections approximately equal. 
	pos =  reshape (sorted (jdb.KW.recs('POS'),  key=lambda x:x.kw.lower()), 10)
	misc = reshape (sorted (jdb.KW.recs('MISC'), key=lambda x:x.kw.lower()), 8)
	stat = reshape (sorted (jdb.KW.recs('STAT'), key=lambda x:x.kw.lower()), 10)
	fld =  reshape (sorted (jdb.KW.recs('FLD'),  key=lambda x:x.kw.lower()), 10)
	dial = reshape (sorted (jdb.KW.recs('DIAL'), key=lambda x:x.kw.lower()), 12)
	kinf = reshape (sorted (jdb.KW.recs('KINF'), key=lambda x:x.kw.lower()), 5)
	  # FIXME: restricting 'rinf' kwds to values less that 100 causes
	  #  the searchj form not to show the the kanjidic-related ones.
	  #  This is really too hackish.  See IS-190 for fix.
	rinf = reshape (sorted ([x for x in jdb.KW.recs('RINF') if x.id < 100],
						     key=lambda x:x.kw.lower()), 5)
	  # FIXME: Filter out the kanjidic corpus for now.  Will figure
	  #  out how to integrate it later.  This too is pre- IS-190 hack.
	corp = reshape (sorted ([x for x in jdb.KW.recs('SRC') if x.kw!='xxkanjidic'] , 
						     key=lambda x:x.kw.lower()), 10)
	freq = []
	for x in sorted (jdb.KW.recs('FREQ'), key=lambda x:x.kw.lower()):
	     # Build list of Kwfreq keywords for populating the webpage Freq
	     # checkboxes.  Since the 'kwfreq' table does not include the
	     # values (the "1", "2", in "ichi1" etc), we create the expanded 
	     # values here.  We also supply the "descr" value which will provide
	     # tool tips on web page.
	   if x.kw!='nf' and x.kw!='gA': freq.extend ([Kwfreq(x.kw+'1', x.descr), 
						       Kwfreq(x.kw+'2', x.descr)])

	jmcgi.gen_page ("tmpl/srchform.tal", macros='tmpl/macros.tal', KW=jdb.KW,
			pos=pos, misc=misc, stat=stat, src=corp, freq=freq,
			fld=fld, kinf=kinf, rinf=rinf, dial=dial, parms=parms,
			svc=svc, host=host, sid=sid, session=sess, cfg=cfg, 
			method='get', output=sys.stdout, this_page='srchform.py')

def reshape (array, ncols, default=None):
	result = []
	for i in range(0, len(array), ncols):
	    result.append (array[i:i+ncols])
	if len(result[-1]) < ncols:
	    result[-1].extend ([default]*(ncols - len(result[-1])))
	return result

if __name__ == '__main__': 
	args, opts = jmcgi.args()
	main (args, opts)
