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

"""
Functions for generating XML descriptions of entries.

"""

import jdb

global XKW

def entr (entr, enhanced=True, genhists=False, genxrefs=True, wantlist=False):
	'''
	Generate an XML description of entry 'entr'.
	Parameters:
	  entr -- An entry object (such as return by entrList()).
	  enhanced -- If true, generate XML that completely 
		describes the entry using an enhanced version
		of the jmdict DTD.
		If false, generate XML that uses the standard
		jmdict DTD (currently rev 1.06) but looses infor-
		mation that is not representable with that DTD.
	  genhists -- If true (and enhanced is also true), generate
		<hist> elements in the XML.  If false, don't. 
	  genxrefs -- If true generate <xref> elements.  If false
		don't.  In order to generate xrefs the 'entr' 
		object must have augmented xrefs.  If it doesn't
		a exception will be thrown.
	'''
	  #FIXME: Need to generate an kwid->xml-entity mapping
	  # idependent of the KW table.  See comments in jmxml.py
	  # but note the mapping used here needs to also support
	  # the enhanced DTD.
	global XKW; XKW = jdb.KW

	fmt = ['<entry>']
	fmt.extend (entrhdr (entr, enhanced))
	if enhanced:
	    x = getattr (entr, 'srcnote', None)
	    if x: fmt.append ('<srcnote>%s</srcnote>' % entr.srcnote)
	    x = getattr (entr, 'notes', None)
	    if x: fmt.append ('<notes>%s</notes>' % entr.notes)

	kanjs = getattr (entr, '_kanj', [])
	for k in kanjs: fmt.extend (kanj (k))

	rdngs = getattr (entr, '_rdng', [])
	for r in rdngs: fmt.extend (rdng (r, kanjs))

	if enhanced: 
	    if genhists: fmt.extend (hists (entr, '_hist'))
	else: fmt.extend (audit (entr, '_hist'))

	senss = getattr (entr, '_sens', [])
	src = entr.src if enhanced else None
	for x in senss: fmt.extend (sens (x, kanjs, rdngs, src, genxrefs))

	fmt.append ('</entry>')
	if wantlist: return fmt
	return '\n'.join (fmt)

def kanj (k):
	fmt = []
	fmt.append ('<k_ele>')
	fmt.append ('<keb>%s</keb>' % k.txt)
	fmt.extend (kwds (k, '_inf', 'KINF', 'ke_inf'))
	fmt.extend (freqs (k, '_freq', 'ke_pri'))
	fmt.append ('</k_ele>')
	return fmt

def rdng (r, k):
	fmt = []
	fmt.append ('<r_ele>')
	fmt.append ('<reb>%s</reb>' % r.txt)
	fmt.extend (restrs (r, k))
	fmt.extend (kwds (r, '_inf', 'RINF', 're_inf'))
	fmt.extend (freqs (r, '_freq', 're_pri'))
	fmt.append ('</r_ele>')
	return fmt

def restrs (r, kanj):
	fmt = []
	restr = getattr (r, '_restr', None)
	if restr: 
	    if len(restr) == len(kanj):
		fmt.append ('<re_nokanji/>')
	    else:
	        re = jdb.filt (kanj, ['kanj'], restr, ['kanj'])
	        fmt.extend (['<re_restr>' + x.txt + '</re_restr>' for x in re])
	return fmt

def sens (s, kanj, rdng, src, genxrefs=True):
	"""
	Format a sense.
	fmt -- A list to which formatted text lines will be appended.
	s -- The sense object to format.
	kanj -- The kanji object of the entry that 's' belongs to.
	rdng -- The reading object of the entry that 's' belongs to.
	src -- If None, non-enhanced format will be generated.  If
	    not None, it should be the value of the entry's .src
	    attribute.  It is passed to the xref() func which needs
	    it when formatting enhanced xml xrefs.  
	genxrefs -- If false, do not attempt to format xrefs.  This
	    will prevent an exception if the entry has only ordinary
	    xrefs rather than augmented xrefs.
	"""
	fmt = []
	enhanced = src
	fmt.append ('<sense>')

	stagk = getattr (s, '_stagk', None)
	if stagk: 
	    sk = jdb.filt (kanj, ['kanj'], stagk, ['kanj'])
	    fmt.extend (['<stagk>' + x.txt + '</stagk>' for x in sk])

	stagr = getattr (s, '_stagr', None)
	if stagr: 
	    sr = jdb.filt (rdng, ['rdng'], stagr, ['rdng'])
	    fmt.extend (['<stagr>' + x.txt + '</stagr>' for x in sr])

	fmt.extend (kwds (s, '_pos', 'POS', 'pos'))

	xrefs = getattr (s, '_xref', None)
	if xrefs and genxrefs:
	    for x in xrefs: fmt.extend (xref (x, src))

	fmt.extend (kwds (s, '_fld', 'FLD', 'field'))

	fmt.extend (kwds (s, '_misc', 'MISC', 'misc'))

	notes = getattr (s, 'notes', None)
	if notes: fmt.append ('<s_inf>%s</s_inf>' % notes)

	lsource = getattr (s, '_lsrc')
	if lsource: 
	    for x in lsource: fmt.extend (lsrc (x, enhanced))

	fmt.extend (kwds (s, '_dial', 'DIAL', 'dial'))

	for x in s._gloss: fmt.extend (gloss (x, enhanced))

	fmt.append ('</sense>')
	return fmt
	   
def gloss (g, enhanced=True):
	fmt = []
	attrs = []
	if g.lang != XKW.LANG['eng'].id:
	    attrs.append ('xml:lang="%s"' % XKW.LANG[g.lang].kw)
	if enhanced and g.ginf != XKW.GINF['equ'].id:
	    attrs.append ('g_type="%s"' % XKW.GINF[g.ginf].kw)
	attr = (' ' if attrs else '') + ' '.join (attrs)
	fmt.append ("<gloss%s>%s</gloss>" % (attr, g.txt))
	return fmt

def kwds (parent, attr, domain, elem_name):
	nlist = getattr (parent, attr, [])
	if not nlist: return nlist
	kwtab = getattr (XKW, domain)
	kwlist = ['<%s>&%s;</%s>' % (elem_name, kwtab[x.kw].kw, elem_name)
		  for x in nlist]
	return kwlist

def freqs (parent, attr, rk):
	kwds = getattr (parent, attr, [])
	if not kwds: return []
	tmp = [(XKW.FREQ[x.kw].kw, x.value) for x in kwds]
	tmp.sort()
	return [('<%s>%s%02d</%s>' if x[0]=='nf' else '<%s>%s%d</%s>') 
		  % (rk, x[0], x[1], rk) 
		for x in tmp]

def lsrc (x, enhanced=True):
	fmt = [];  attrs = []
	if x.lang != XKW.LANG['eng'].id:
	    attrs.append ('xml:lang="%s"' % XKW.LANG[x.lang].kw)
	if x.part: attrs.append ('ls_type="part"')
	if enhanced:
	    if x.wasei: attrs.append ('ls_type="wasei"')
	attr = (' ' if attrs else '') + ' '.join (attrs)
	if not x.txt: fmt.append ('<lsource%s/>' % attr)
	else: fmt.append ('<lsource%s>%s</lsource>' % (attr, x.txt))
	return fmt

def xref (xref, src):
	fmt = []
	try: targobj = xref.TARG
	except AttributeError:
	    raise AttributeError ("Expected 'TARG' attribute on xref")

	k = r = ''
	if getattr (xref, 'kanj', None):
	    k = targobj._kanj[xref.kanj-1].txt
	if getattr (xref, 'rdng', None):
	    r = targobj._rdng[xref.rdng-1].txt
	if k and r: target = k + u'\uFF1D' + r 
	else: target = k or r
	#target += '(%d)' % xref.xsens

	attrs = []
	if src:
	    tag = 'xref'
	    attrs.append ('x_type="%s"' % XKW.XREF[xref.typ].kw)
	    if targobj.src == src: targseq = targobj.seq
	    else: targseq = "%s.%s" % (targobj.seq, jd.KW.SRC[targobj.src].kw)
	    attrs.append ('x_seq="%s"' % targseq)
	    if getattr (xref, 'notes', None): 
		attrs.append ('x_note="%s"' % xref.notes)
	else:
	    if xref.typ == XKW.XREF['ant']: tag = 'ant'
	    else : tag = 'xref'

	attr = (' ' if attrs else '') + ' '.join (attrs)
	fmt.append ('<%s%s>%s</%s>' % (tag, attr, target, tag))
	return fmt

def hists (parent):
	hlist = getattr (parent, '_hist', [])
	return [hist (x) for x in hlist]

def hist (h):
	fmt = []; attrs = []
	attrs.append ('date="%s"' % h.date)
	attrs.append ('name="%s"' % h.name)
	attrs.append ('email="%s"' % h.email)
	attr = (' ' if attrs else '') + ' '.join (attrs)
	fmt.append ('<hist%s>' % attr)
	diff = getattr (h, 'diff', None)
	if diff: fmt.append ('<h_diff>%s</h_diff>' % diff)
	notes = getattr (h, 'notes', None)
	if notes: fmt.append ('<h_notes>%s</h_notes>' % notes)
	refs = getattr (h, 'refs', None)
	if refs: fmt.append ('<h_refs>%s</h_refs>' % refs)

def audit (parent, attr):
	fmt = []
	hlist = getattr (parent, attr, [])
	if not hlist: return []
	key = 'From JMdict <upd_detl>: '
	h = hlist[0] 
	if hasattr (h, 'notes') and h.notes.startswith (key):
	    fmt.extend (['<info>','<audit>'])
	    fmt.append ('<upd_date>%s</upd_date>' % h.dt.date().isoformat())
	    fmt.append ('<upd_detl>%s</upd_detl>' % h.notes[len(key):])
	    fmt.extend (['</audit>','</info>'])
	return fmt

def entrhdr (entr, enhanced=True):
	fmt = []
	id = getattr (entr, 'id',   '')
	src = jdb.KW.SRC[entr.src].kw
	if enhanced: fmt.append ('<corpus>%s</corpus>' % src)
	seq = fmt.append ('<ent_seq>%d</ent_seq>' % entr.seq)
	if enhanced:
	    stat = getattr (entr, 'stat', '')
	    if stat: 
		fmt.append ('<status>%s</status>' % jdb.KW.STAT[stat].kw)
	    if getattr (entr, 'unap', False):
		fmt.append ('<unapproved/>')
	return fmt

def _main (args, opts):
	cur = jdb.dbOpen ('jmnew')
	while True:
	    id = raw_input ("Id number? ")
	    if not id: break
	    e, raw = jdb.entrList (cur, [int(id)], ret_tuple=True)
	    jdb.augment_xrefs (cur, raw['xref'])
	    if not e:
		print "Entry id %d not found" % id
	    else:
		txt = entr (e[0], enhanced=False)
		print txt

if __name__ == '__main__':
	_main (None, None)