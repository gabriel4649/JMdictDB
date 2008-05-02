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
	       '$Date$'[7:-11]);

import sys, cgi
sys.path.extend (['../../python/lib','../python/lib'])
import jdb, jmcgi

def main( args, opts ):
	form = cgi.FieldStorage()
	errs = []
	svc = jmcgi.safe (form.getfirst ('svc'))
	cur = jmcgi.dbOpenSvc (svc)

	pos =  reshape (sorted (jdb.KW.recs('POS'),  key=lambda x:x.kw), 10)
	misc = reshape (sorted (jdb.KW.recs('MISC'), key=lambda x:x.kw), 10)
	stat = reshape (sorted (jdb.KW.recs('STAT'), key=lambda x:x.kw), 10)
	fld =  reshape (sorted (jdb.KW.recs('FLD'),  key=lambda x:x.kw), 10)
	kinf = reshape (sorted (jdb.KW.recs('KINF'), key=lambda x:x.kw), 5)
	  # FIXME: restricting 'rinf' kwds to values less that 100 causes
	  #  the searchj form not to show the the kanjidic-related ones.
	  #  This is really too hackish. 
	rinf = reshape (sorted ([x for x in jdb.KW.recs('RINF') if x.id < 100],
						     key=lambda x:x.kw), 5)
	  # FIXME: Filter out the kanjidic corpus for now.  Will figure
	  #  out how to itegrate it later.  This too is obviously a hack.
	corp = reshape (sorted ([x for x in jdb.KW.recs('SRC') if x.kw!='kanjdic'] , 
						     key=lambda x:x.kw), 10)
	freq = []
	for x in sorted (jdb.KW.recs('FREQ'), key=lambda x:x.kw):
	   if x.kw!='nf' and x.kw!='gA': freq.extend ([x.kw+'1', x.kw+'2'])

	jmcgi.gen_page ("tmpl/srchform.tal", output=sys.stdout, svc=svc,
			pos=pos, misc=misc, stat=stat, src=corp, freq=freq,
			fld=fld, kinf=kinf, rinf=rinf)

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

