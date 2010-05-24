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


import sys, cgi, re, os, json, itertools
sys.path.extend (['../lib','../../python/lib','../python/lib'])
import cgitbx; cgitbx.enable()
import jdb, jmcgi, fmtjel, edparse

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
	try: e, ref, comment, name, email = read_editdata (cur, fullname)
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

def read_editdata (cursor, fullname):
	# Read the edit data in file "fullname" and convert it into 
	# an Entr object, geting additional information from the
	# database in the case of amendments to an existing entry.
	# Note that there's a risk that the entry was changed after 
	# the time the submitter submitted his changes and now,
	# resulting in an inconsistent or regressionary change,
	# but we hope that the human editor will notice such cases.

	with open (fullname) as f: s = f.read()
	parsed = json.loads (s)
	entr = create_entr (cursor, parsed)
	entrdata = [entr, parsed.get('reference'),
			  parsed.get('comment'),
			  parsed.get('name'),
			  parsed.get('email')]
	#--- debug
	#print "submission %s" % fullname
	#print "ktxt:", entr.ktxt
	#print "rtxt:", entr.rtxt
	#print "stxt:", entr.stxt
	#---

	return entrdata

def create_entr (cursor, parsed):
	# From the dictionary of wwwjdict submission values in 
	# 'parsed' we create the same kind of data that cgi/edform.py
	# creates internally to send to the edform.tal template: an 
	# Entr object with some attached extra data.  This object is
	# returned to caller (who will serialize it and write it to
	# a file).

	if parsed['subtype'] == 'new':
	    entr = jdb.Entr()
	    entr.src = jdb.KW.SRC['jmdict'].id
	else:	# == 'amend'
	    seqnum = parsed['seqnum']
	    errs = []
	      # FIXME: following assumes seqnum is an entry in jmdict.
	    entrs = jmcgi.get_entrs (cursor, None, [seqnum], errs,
				     active=True, corpus='jmdict')
	    if errs: print '\n'.join (errs)
	    if entrs: entr = entrs[0]
	    else: raise ParseError ("Unable to get entry seq# %s from database" % seqnum)

	kanj = [];  rdng = []; gloss = []
	for x in parsed.get ('headw', []):
	    if jdb.jstr_reb (x): rdng.append (x)
	    else: kanj.append (x)
	rdng.extend (parsed.get ('kana', []))
	ktxt = ';'.join (kanj)
	rtxt = ';'.join (rdng)
	stxt = ' / '.join (parsed.get ('english', []))
	pos = ','.join (parsed.get ('pos', []))
	misc = ','.join (parsed.get ('misc', []))
	xref = ','.join (parsed.get ('crossref', []))
	  #FIXME: Note that including pos, xref. et.al. can break
	  # a sense parse that would otherwise be ok.  Maybe if the
	  # parse fails, we should try again without this stuff, 
	  # and if that works, append this stuff as "unparsable"-
	  # tagged extra text.
	  # However, senses other than the first may have this
	  # information embedded in the text and it seems a bit
	  # much to try pulling it out... 
	stxt = (('('+pos+')') if pos else '') \
		+ (('(See '+xref+')') if xref else '') \
		+ (('('+misc+')') if misc else '') \
		+ (' ' if pos or misc or xref else '') + stxt 

	  #FIXME:  What do about 'date', 'entlangnam' fields? 
	  # I don't think we care about 'sendNotJS'.

	ktxt, rtxt, stxt = reformat (ktxt, rtxt, stxt, entr)
	entr.ktxt, entr.rtxt, entr.stxt = ktxt, rtxt, stxt
	return entr

def reformat (ktxt, rtxt, stxt, entr):
	# Given edict2-formatted kanji, reading, and sense
	# strings, try to convert them into jmdictdb objects, 
	# and then format them back to JEL-formatted strings
	# which are returned.  If unable to parse an input
	# string, return the unparsed string prefixed with
        # "!unparsed!" instead of the JEL-formatted string.
        # If matching kanji or reading items exist on 'entr'
        # have and kinf, rinf, freq, or restrs, those items
        # are added to the JEL-formated string.

	failed = False;  kanjs = rdngs = senss = None;  fmap = {}

	  # Assume the worst and overwrite the following if  
	  # things work ok...
	jktxt = "!unparsed!\n" + ktxt
	jrtxt = "!unparsed!\n" + rtxt
	jstxt = "!unparsed!\n" + stxt

	try: 
	    kanjs = edparse.parse_krpart (ktxt, fmap) 
	except eParseError, excep: 
	    try: print "reformat kanj failed: %s" % (unicode(excep))
	    except UnicodeError: "reformat kanj failed: (unprintable exception)"

	if kanjs is not None:    # kanjs is None if kanji parse failed in
	    try:                 #  which case we can't parse readings or senses.
		rdngs = edparse.parse_krpart (rtxt, fmap, kanjs)
	    except eParseError, excep: 
		try: print "reformat rdng failed: %s" % (unicode(excep))
		except UnicodeError: "reformat rdng failed: (unprintable exception)"

        if rdngs is not None:    # rdngs is None if reading parse failed in 
	    if entr:             #  which case we can't parse senses.
		  # The wwwjdic submission data does not apparently
		  # include tags from the orignal entry so we copy 
		  # them here. 
		copy_tags (entr._rdng, entr._kanj, rdngs, kanjs)
	    e = jdb.Entr(_rdng=rdngs, _kanj=kanjs)
	    try: 
	        edparse.parse_spart (stxt, e, fmap) 
	        senss = e._sens
	        jktxt = fmtjel.kanjs (kanjs)
                jrtxt = fmtjel.rdngs (rdngs, kanjs)
	        jstxt = fmtjel.senss (senss, kanjs, rdngs)
	    except eParseError, excep:
		try: print "reformat sens failed: %s" % (unicode(excep))
		except UnicodeError: "reformat sens failed: (unprintable exception)"

	return jktxt, jrtxt, jstxt

def copy_tags (rdngs, kanjs, new_rdngs, new_kanjs):
	# It appears that the wwwjdic forms do not send any info
	# about the tags (kinf, rinf, or freq) or kr restrictions 
        # on the kana or kanji of an amended entry.  This function
        # will attempt to restore the tags that are on the original
        # entry to the edit entry to save the reviewer the effort of
        # manually re-adding them.
	#
	# CAUTION: this function is not intended for general-purpose
	# use...see comments below.

	  # Build a lookup dict for reading text -> Rng obj for
	  #  only Rdng objects that have Freq or Rinf tags.
	rmap = dict(((r.txt, r) for r in rdngs if r._freq or r._inf))

	  # Same for Kanj objects.
	kmap = dict(((k.txt, k) for k in kanjs if k._freq or k._inf))

	  # Build a lookup set for kanji,reading text pairs ->
	  #  Kanj, Rdng object pairs for only pairs that have
	  #  a common Restr object on their ._restr lists.
	krset = set(((k.txt, r.txt) 
		  for k, r in itertools.product (kanjs, rdngs)
		  if has_restr (k, r)))

	  # "Copy" the Freq and [KR]inf references from the 
	  # old entry Rdngs and Kanj to the new ones.  Note 
	  # that we do not copy the Freq or [KR]inf objects
	  # them selfselves but only the references to them.  
	  # Thus the objects are shared between the old and 
	  # new entries.  We get away with this because this
	  # function is not intended foe general-purpose use
	  # and we know that we are going to throw away both
	  # objects after they have been used to generate a
	  # textual representation.  We copy to the new Rdng
	  # or Kanj that has the same text as the old one so
	  # a change in position will not prevent the copy.
	  # Note that if there are already tag on the object,
	  # they will remain.  We do not check for duplicates.

	for r in new_rdngs:
	    if r.txt in rmap:
		r._freq.extend (rmap[r.txt]._freq)
		r._inf.extend (rmap[r.txt]._inf)
	for k in new_kanjs:
	    if k.txt in kmap: 
		k._freq.extend (kmap[k.txt]._freq)
		k._inf.extend (kmap[k.txt]._inf)

	  # To copy the Restr object, the new object must have
	  # both the same reading and kanji that were restricted 
	  # in the old entry.  'krmap' lists those pairs (by
	  # text) for the old entr.  itertools.product() will 
	  # give all combinations or Rdng and Kanj for the new
	  # object.  If the text pair exists in 'krmap', and
	  # if there is not already a restriction, then create 
	  # a new one.  Contrary to the caution above, this
	  # part of the code *does* create an independent copy,
	  # and avoids duplication.

	for k, r in itertools.product (new_kanjs, new_rdngs):
	    if (k.txt, r.txt) in krset: 
		if not has_restr (k, r): 
		    x = jdb.Restr()
		    k._restr.append (x)
		    r._restr.append (x)
		
def has_restr (k, r):
	# If Kanj object k and Rdng object r are linked via
	# a Restr object, return a reference to that object.
	# Otherwise return None.
	# FIXME: this probably belongs in jdb.

	if not k._restr or not r._restr: return None
	for kx in k._restr:
	    for rx in r._restr:
		if kx is rx: return kx

if __name__ == '__main__': 
	args, opts = jmcgi.args()
	main (args, opts)
