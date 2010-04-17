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
#  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA
#######################################################################

__version__ = ('$Revision$'[11:-2],
	       '$Date$'[7:-11]);

"""
Functions for generating XML descriptions of entries.

"""
import re, difflib
from xml.sax.saxutils import escape as esc, quoteattr as esca
import jdb, xmlkw

global XKW, KW
XKW = None

def entr (entr, compat=None, genhists=False, genxrefs=True, wantlist=False,
		implicit_pos=True):
	'''
	Generate an XML description of entry 'entr'.
	Parameters:
	  entr -- An entry object (such as return by entrList()).
	  compat -- If false, generate XML that completely 
		describes the entry using an enhanced version
		of the jmdict DTD.
		If "jmdict", generate XML that uses the standard
		JMdict DTD but looses information that is not
		representable with that DTD.
		If "jmnedict", generate XML that uses the standard
		JMnedict DTD but looses information that is not
		representable with that DTD.
	  genhists -- If true, generate	<audit> elements in the XML. 
		Otherwise, don't. 
	  genxrefs -- If true generate <xref> elements.  If false
		don't.  In order to generate xrefs the 'entr' 
		object must have augmented xrefs.  If it doesn't
		a exception will be thrown.
	  wantlist -- If false, return the xml as a single string.
		with embedded newline characters.  If true, return a 
		list of strings, one line per string, with no embedded
		newlines.
	  implicit_pos -- Boolean: if true, a sense's <pos> 
		elements will not be added to sense if they exactly 
		match (in number, values, and order) the previous 
		sense's <pos> elements.  Does not extend across 
		entry boundries.  This is the rule used in the 
		Monash JMdict XML file.  If false, each sense will 
		be generated with <pos> elements explictly expressed.
	'''
	  #FIXME: Need to generate an kwid->xml-entity mapping
	  # idependent of the KW table.  See comments in jmxml.py
	  # but note the mapping used here needs to also support
	  # the enhanced DTD.
	global XKW, KW; KW = jdb.KW; 
	if not XKW: XKW = xmlkw.make (KW)

	fmt= entrhdr (entr, compat)

	kanjs = getattr (entr, '_kanj', [])
	for k in kanjs: fmt.extend (kanj (k))

	rdngs = getattr (entr, '_rdng', [])
	for r in rdngs: fmt.extend (rdng (r, kanjs, compat))

	fmt.extend (info (entr, compat, genhists))

	senss = getattr (entr, '_sens', [])
	if compat == 'jmnedict':
	    for x in senss: fmt.extend (trans (x))
	else:
	    last_pos = [] if implicit_pos else None
	    for x in senss: 
		fmt.extend (sens (x, kanjs, rdngs, compat, entr.src, genxrefs, last_pos))

	if not compat: fmt.extend (audio (entr))
	if not compat: fmt.extend (grps (entr))
	fmt.append ('</entry>')
	if wantlist: return fmt
	return '\n'.join (fmt)

def kanj (k):
	fmt = []
	fmt.append ('<k_ele>')
	fmt.append ('<keb>%s</keb>' % k.txt)
	fmt.extend (kwds (k, '_inf', 'KINF', 'ke_inf', sort=True))
	fmt.extend (['<ke_pri>%s</ke_pri>' %s 
		     for s in jdb.freq2txts (getattr (k,'_freq',[]))])
	fmt.append ('</k_ele>')
	return fmt

def rdng (r, k, compat):
	fmt = []
	fmt.append ('<r_ele>')
	fmt.append ('<reb>%s</reb>' % r.txt)
	fmt.extend (restrs (r, k))
	fmt.extend (kwds (r, '_inf', 'RINF', 're_inf', sort=True))
	fmt.extend (['<re_pri>%s</re_pri>' %s 
		     for s in jdb.freq2txts (getattr (r,'_freq',[]))])
	if not compat: fmt.extend (audio (r))
	fmt.append ('</r_ele>')
	return fmt

def restrs (rdng, kanjs, attr='_restr'):
	# Generate xml lines for reading-kanji (or sense-reading, or 
	# sense-kanji) restrictions.  This function does the necessary
	# inversion between the "dis-allowed" form of restrictions used
	# in the database and API, and the "allowed" form used in the 
	# XML.  It also properly generates "re_nokanji" elements when
	# appropriate for reading-kanji restrictions.  It does not 
	# require or use Rdng.rdng, Kanj.kanj, or Sens.sens attributes.
	#
	# rdng -- A Rdng (or Sens) object.
	# kanjs -- A list of Kanj (or Rdng) objects.
	# attr -- Name of the attribute on the 'rdng' or 'kanj' object(s)
	#   that contains the restriction list.

	fmt = []; invrestr = []
	invdkanjs = jdb.restrs2ext (rdng, kanjs, attr)
	if invdkanjs is None: 
	    if attr != '_restr': raise RuntimeError ()
	    fmt.append ('<re_nokanji/>')
	elif invdkanjs:
	    tag = "re_"+attr[1:] if attr=='_restr' else attr[1:]
	    fmt.extend (['<%s>%s</%s>' % (tag, x.txt, tag) for x in invdkanjs])
	return fmt

def sens (s, kanj, rdng, compat, src, genxrefs=True, prev_pos=None):
	"""
	Format a sense.
	fmt -- A list to which formatted text lines will be appended.
	s -- The sense object to format.
	kanj -- The kanji object of the entry that 's' belongs to.
	rdng -- The reading object of the entry that 's' belongs to.
	compat -- See function entr().  We assume in sens() that if
	    compat is not None it is =='jmdict', that is, if it is 
	    'jmnedict', trans() would have been called rather than
	    sens().
	src -- If 'compat' is None, this should be the value of the
	    entry's .src attribute.  It is passed to the xref() func
	    which needs it when formatting enhanced xml xrefs.  If 
	    'compat' is not None, this parameter is ignored.
	genxrefs -- If false, do not attempt to format xrefs.  This
	    will prevent an exception if the entry has only ordinary
	    xrefs rather than augmented xrefs.
	prev_pos -- If not None, should be set to the pos list of
	    the previous sense, or an empty list if this is the 
	    first sense of an entry.  This function will mutate 
	    'prev_pos' (if not None) to the current pos list before
	    returning so that usually, sens() will be called with
	    with an empty list on the first sense of an entry, and
	    te same list on subsequent calls.  It is used to suppress
	    pos values when they are the same as in the prevuious 
	    sense per the JMdict DTD.
	    If None, an explict pos will be generated in each sense.

	We attempt to produce the elements in the same order as seen
	in the EDRDG JMdict XML file of 2009-03-01.
	"""
	fmt = []
	fmt.append ('<sense>')

	fmt.extend (restrs (s, kanj, '_stagk'))
	fmt.extend (restrs (s, rdng, '_stagr'))

	this_pos = [x.kw for x in getattr (s, '_pos', [])]
	if not prev_pos or prev_pos != this_pos:
	    fmt.extend (kwds (s, '_pos', 'POS', 'pos'))
	    if prev_pos is not None: prev_pos[:] = this_pos

	xrfs = getattr (s, '_xref', None)
	if xrfs and genxrefs:
	    fmt.extend (xrefs (xrfs, (not compat) and src))
	xrfs = getattr (s, '_xrslv', None)
	if xrfs and genxrefs:
	    fmt.extend (xrslvs (xrfs, (not compat) and src))

	fmt.extend (kwds (s, '_fld', 'FLD', 'field'))
	fmt.extend (kwds (s, '_misc', 'MISC', 'misc'))

	notes = getattr (s, 'notes', None)
	if notes: fmt.append ('<s_inf>%s</s_inf>' % esc (notes))

	lsource = getattr (s, '_lsrc', None)
	if lsource: 
	    for x in lsource: fmt.extend (lsrc (x))

	fmt.extend (kwds (s, '_dial', 'DIAL', 'dial'))

	for x in s._gloss: fmt.extend (gloss (x, compat))

	fmt.append ('</sense>')
	return fmt

def trans (s):
	"""Format a jmnedict trans element.
	s -- A sense object."""

	fmt = []
	nlist = getattr (s, '_misc', [])
	kwtab = getattr (XKW, 'NAME_TYPE')
	fmt.extend (['<name_type>&%s;</name_type>' % kwtab[x.kw].kw
		     for x in nlist])
	eng_id = KW.LANG['eng'].id
	for g in getattr (s, '_gloss', []):
	    lang = getattr (g, 'g_lang', eng_id)
	    lang_attr = (' xml:lang="%s"' % XKW.LANG[lang].kw) if lang != eng_id else ''
	    fmt.append ('<trans_det%s>%s</trans_det>' % (lang_attr, g.txt))
	if fmt: 
	    fmt.insert (0, '<trans>')
	    fmt.append ('</trans>')
	return fmt
	   
def gloss (g, compat=None):
	fmt = []
	attrs = []
	if g.lang != XKW.LANG['eng'].id:
	    attrs.append ('xml:lang="%s"' % XKW.LANG[g.lang].kw)
	  # If 'compat' is not None, we generate all glosses as "equ"
	  # glosses.  There is no way to regenerate the original gloss
	  # for non-"equ" glosses since the were parsed out of some 
	  # other gloss but we no longer have any information about 
	  # which one. 
	if not compat and g.ginf != XKW.GINF['equ'].id:
	    attrs.append ('g_type="%s"' % XKW.GINF[g.ginf].kw)
	attr = (' ' if attrs else '') + ' '.join (attrs)
	fmt.append ("<gloss%s>%s</gloss>" % (attr, esc(g.txt)))
	return fmt

def kwds (parent, attr, domain, elem_name, sort=False):
	nlist = getattr (parent, attr, [])
	if not nlist: return nlist
	kwtab = getattr (XKW, domain)
	kwlist = ['<%s>&%s;</%s>' % (elem_name, kwtab[x.kw].kw, elem_name)
		  for x in nlist]
	if sort: kwlist.sort()
	return kwlist

def lsrc (x):
	fmt = [];  attrs = []
	if x.lang != XKW.LANG['eng'].id or not x.wasei: 
	    attrs.append ('xml:lang="%s"' % XKW.LANG[x.lang].kw)
	if x.part: attrs.append ('ls_type="part"')
	if x.wasei: attrs.append ('ls_wasei="y"')
	attr = (' ' if attrs else '') + ' '.join (attrs)
	if not x.txt: fmt.append ('<lsource%s/>' % attr)
	else: fmt.append ('<lsource%s>%s</lsource>' % (attr, esc(x.txt)))
	return fmt

def xrefs (xrefs, src):
	# Generate xml for xrefs.  If there is an xref to every 
	# sense of a target entry, then we generate a single 
	# xref element without a sense number.  Otherwise we
	# generate an xref element with sense number for each 
	# target sense.
	# 
	# xrefs -- A list of xref objects to be formatted.  The
	#   xrefs must have an augmented target attribute (as
	#   produced by calling augment_xrefs()) or an error 
	#   will be raised (in function xref).
	# 
	# src -- Corpus id number of the entry that contains
	#   the target 'xref' of the xrefs.
	#   If 'src' is true, enhanced XML will be generated.  
	#   If not, legacy JMdict XML will be generated.

	fmt = []
	  # Mark each xref that differs only by .xsens value with
	  # a ._xsens attribute that will be a list of all .xsens 
	  # values on the first such xref, and an emply list on 
	  # subsequent such xrefs.
	jdb.add_xsens_lists (xrefs)

	for x in xrefs:
	      # If ._xsens is empty, this xref can we ignored since 
	      # we already formatted a preceeding matching xref that
	      # contained a list of all .xsens values.
	    if not x._xsens: continue

	      # Check that augment_xrefs() was called on this
	      # xref.  The target object is needed because we
	      # it has the actual kanji and reading texts that
	      # will be used in the xml xref, as well and the
	      # the number of senses, which we also need.
	    try: targ = x.TARG
	    except AttributeError:
		raise AttributeError ("xref missing TARG attribute.  Did you forget to call augmented_xrefs()?")

	      # Format the xref into xml text.
	    fmtdxref = xref (x, src)

	      # We can assume that, since the database RI constraints
	      # won't allow two xrefs in the same source to point to
	      # the same target and sense, if the number of xsens values 
	      # in the .xsens list equals the number of target senses,
	      # there is one xref pointing to each sense.  
	    if len(targ._sens) != len(x._xsens):
		  # There is not an xref for each target sense, so we
		  # want to generate xrefs with explicit target senses.
		for s in x._xsens:
		      # The string returned by xref() has a "%s"
		      # placeholder for the sense number.  Generate
		      # an xref element with sense for each xref in
		      # the group.  \u30FB is mid-height dot.
		    fmt.append (fmtdxref % u'\u30FB%d' % s)
	    else:
		  # There is an xref for each target sense so we want
		  # to supress the target sense numbers.
		fmt.append (fmtdxref % '')
	return fmt

def xref (xref, src):
	"""
	Generate a formatter xml string for a single xref.  

	xref -- The xref object to be formatted.  The xref must
	  have an augmented target attribute (as produced by calling
	  augment_xrefs()), since that infomation is require to 
	  generate the kanji and reading texts, and an error will
	  be raised if not.

	src -- Corpus id number of the entry that contains 'xref'.
	  If 'src' is true, enhanced XML will be generated.  
	  If not, legacy JMdict XML will be generated.

	The returned xref string will have a "%s" where the target
	sense number would go, which the caller	is expected to 
	replace with the sense number or not, as desired.
	"""
	targobj = xref.TARG
	k = r = ''
	if getattr (xref, 'kanj', None):
	    k = targobj._kanj[xref.kanj-1].txt
	if getattr (xref, 'rdng', None):
	    r = targobj._rdng[xref.rdng-1].txt
	if k and r: target = k + u'\u30FB' + r  # \u30FB is mid-height dot.
	else: target = k or r

	tag = 'xref'; attrs = []
	if src:
	    attrs.append ('type="%s"' % XKW.XREF[xref.typ].kw)
	    attrs.append ('seq="%s"' % targobj.seq)
	    if targobj.src != src:
		attrs.append ('corp="%s"' % jdb.KW.SRC[targobj.src].kw)
	    if getattr (xref, 'notes', None): 
		attrs.append ('note="%s"' % esc(xref.notes))
	else:
	    if xref.typ == XKW.XREF['ant'].id: tag = 'ant'

	attr = (' ' if attrs else '') + ' '.join (attrs)
	return '<%s%s>%s%%s</%s>' % (tag, attr, target, tag)

def xrslvs (xrslvs, src):
	# Generate a list of <xref> elements based on the list
	# Xrslv objects, 'xrlvs'.  If 'compat' is false, extended
	# xml will be produced which will use <xref> elements with
	# "type" attributes for all xrefs.
	# If 'compat' is true, plain <xref> and <ant> elements
	# compatible to EDRDG JMdict XML will be produced.
	# Xref items with a type other than "see" or "ant" will
	# be ignored.
	# 
	# xrslvs -- List of unresolved xrefs as Xrslv objects.
	# src -- Corpus id number of the entry that contains 'xref'.
	#   If 'src' is true, enhanced XML will be generated.  
	#   If not, legacy JMdict XML will be generated.

	fmt = []
	for x in xrslvs:
	    v = []; elname = "xref"
	    if src:
		attrs = ' type="%s"' % KW.XREF[x.typ].kw
		  # FIXME: Can't generate seq and corp attributes because
		  #  that info is not available from Xrslv objects. See
		  #  IS-150.
	    else:
		if x.typ == KW.XREF['see'].id: elname = 'xref'
		elif x.typ == KW.XREF['ant'].id: elname = 'ant'
		else: continue
		attrs = ''
	    if getattr (x, 'ktxt',  None): v.append (x.ktxt)
	    if getattr (x, 'rtxt',  None): v.append (x.rtxt)
	    if getattr (x, 'tsens', None): v.append (str(x.tsens))
	    xreftxt = u'\u30FB'.join (v)	# U+30FB is middot.
	    fmt.append ("<%s%s>%s</%s>" % (elname, attrs, xreftxt, elname))
	return fmt

def info (entr, compat=None, genhists=False):
	fmt = [] 
	if not compat:
	    x = getattr (entr, 'srcnote', None)
	    if x: fmt.append ('<srcnote>%s</srcnote>' % esc(entr.srcnote))
	    x = getattr (entr, 'notes', None)
	    if x: fmt.append ('<notes>%s</notes>' % esc(entr.notes))
	if genhists:
	    for x in getattr (entr, '_hist', []):
		fmt.extend (audit (x, compat))
	if fmt: 
	    fmt.insert (0, '<info>')
	    fmt.append ('</info>')
	return fmt

def audit (h, compat=None):
	global XKW
	fmt = []
	fmt.append ('<audit>')
	fmt.append ('<upd_date>%s</upd_date>' % h.dt.date().isoformat())
	if getattr (h, 'notes', None): fmt.append ('<upd_detl>%s</upd_detl>'   % esc(h.notes))
	if not compat:
	    if getattr (h, 'stat', None):  fmt.append ('<upd_stat>%s</upd_stat>'   % XKW.STAT[h.stat].kw)
	    if getattr (h, 'unap', None):  fmt.append ('<upd_unap/>')
	    if getattr (h, 'email', None): fmt.append ('<upd_email>%s</upd_email>' % esc(h.email))
	    if getattr (h, 'name', None):  fmt.append ('<upd_name>%s</upd_name>'   % esc(h.name))
	    if getattr (h, 'refs', None):  fmt.append ('<upd_refs>%s</upd_refs>'   % esc(h.refs))
	    if getattr (h, 'diff', None):  fmt.append ('<upd_diff>%s</upd_diff>'   % esc(h.diff))
	fmt.append ('</audit>')
	return fmt

def grps (entr):
	global XKW
	fmt = []
	for x in getattr (entr, '_grp', []):
	    ord = (' ord="%d"' % x.ord) if x.ord is not None else ''
	    fmt.append ('<group%s>%s</group>' % (ord, XKW.GRP[x.kw].kw))
	return fmt

def grpdef (kwgrp_obj):
	fmt = []
	fmt.append ('<grpdef id="%d">' % kwgrp_obj.id)
	fmt.append ('<gd_name>%s</gd_name>' % kwgrp_obj.kw)
	fmt.append ('<gd_descr>%s</gd_descr>' % kwgrp_obj.descr)
	fmt.append ('</grpdef>')
	return fmt

def audio (entr_or_rdng):
	a = getattr (entr_or_rdng, '_snd', [])
	if not a: return []
	return ['<audio clipid="c%d"/>' % x.snd for x in a]

def entrhdr (entr, compat=None):
	global XKW
	if not compat:
	    id = getattr (entr, 'id', None)
	    idattr = (' id="%d"' % id) if id else ""
	    stat = getattr (entr, 'stat', None)
	    statattr = (' stat="%s"' % XKW.STAT[stat].kw) if stat else ""
	    apprattr = ' appr="n"' if entr.unap else ""
	    dfrm = getattr (entr, 'dfrm', None)
	    dfrmattr = (' dfrm="%d"' % entr.dfrm) if dfrm else ""
	    fmt = ["<entry%s%s%s%s>" % (idattr, statattr, apprattr, dfrmattr)]
	else: fmt = ['<entry>']
	if getattr (entr, 'seq', None):
	    seq = fmt.append ('<ent_seq>%d</ent_seq>' % entr.seq)
	if getattr (entr, 'src', None):
	    src = jdb.KW.SRC[entr.src].kw
	    if not compat: fmt.append ('<ent_corp>%s</ent_corp>' % src)
	return fmt

def sndvols (vols):
	if not vols: return []
	fmt = []
	for v in vols:
	    idstr = ' id="v%s"' % str (v.id)
	    fmt.append ('<avol%s>' % idstr)
	    if getattr (v, 'loc',   None) is not None: fmt.append ('<av_loc>%s</av_loc>'     % v.loc)
	    if getattr (v, 'type',  None) is not None: fmt.append ('<av_type>%s</av_type>'   % v.type)
	    if getattr (v, 'title', None) is not None: fmt.append ('<av_title>%s</av_title>' % v.title)
	    if getattr (v, 'idstr', None) is not None: fmt.append ('<av_idstr>%s</av_idstr>' % v.idstr)
	    if getattr (v, 'corp',  None) is not None: fmt.append ('<av_corpus>%s</av_corpus>' % v.corp)
	    if getattr (v, 'notes', None) is not None: fmt.append ('<av_notes>%s</av_notes>' % v.notes)
	    fmt.append ('</avol>')
	return fmt

def sndsels (sels):
	if not sels: return []
	fmt = []
	for s in sels:
	    idstr = ' id="s%s"' % str (s.id)
	    volstr = ' vol="v%s"' % str (s.vol)
	    fmt.append ('<asel%s%s>' % (idstr, volstr))
	    if getattr (s, 'loc',   None) is not None: fmt.append ('<as_loc>%s</as_loc>'     % s.loc)
	    if getattr (s, 'type',  None) is not None: fmt.append ('<as_type>%s</as_type>'   % s.type)
	    if getattr (s, 'title', None) is not None: fmt.append ('<as_title>%s</as_title>' % s.title)
	    if getattr (s, 'notes', None) is not None: fmt.append ('<as_notes>%s</as_notes>' % s.notes)
	    fmt.append ('</asel>')
	return fmt

def sndclips (clips):
	if not clips: return []
	fmt = []
	for c in clips:
	    idstr = ' id="c%s"' % str (c.id)
	    selstr = ' sel="s%s"' % str (c.file)
	    fmt.append ('<aclip%s%s>' % (idstr,selstr))
	    if getattr (c, 'strt',  None) is not None: fmt.append ('<ac_strt>%s</ac_strt>'   % c.strt)
	    if getattr (c, 'leng',  None): fmt.append ('<ac_leng>%s</ac_leng>'   % c.leng)
	    if getattr (c, 'trns',  None): fmt.append ('<ac_trns>%s</ac_trns>'   % c.trns)
	    if getattr (c, 'notes', None): fmt.append ('<ac_notes>%s</ac_notes>' % c.notes)
	    fmt.append ('</aclip>')
	return fmt

def corpus (corpora):
	KW = jdb.KW;  fmt = []
	for c in corpora:
	    kwo = KW.SRC[c]
	    fmt.append ('<corpus id="%d">' % kwo.id)
	    fmt.append ('<co_name>%s</co_name>' % kwo.kw)
	    if getattr (kwo, 'descr', None): fmt.append ('<co_descr>%s</co_descr>' % esc(KW.SRC[c].descr))
	    if getattr (kwo, 'dt',    None): fmt.append ('<co_date>%s</co_date>'   % KW.SRC[c].dt)
	    if getattr (kwo, 'notes', None): fmt.append ('<co_notes>%s</co_notes>' % esc(KW.SRC[c].notes))
	    if getattr (kwo, 'seq',   None): fmt.append ('<co_sname>%s</co_sname>' % esc(KW.SRC[c].seq))
	    if getattr (kwo, 'sinc',  None): fmt.append ('<co_sinc>%d</co_sinc>'   % KW.SRC[c].sinc)
	    if getattr (kwo, 'smin',  None): fmt.append ('<co_smin>%d</co_smin>'   % KW.SRC[c].smin)
	    if getattr (kwo, 'smax',  None): fmt.append ('<co_smax>%d</co_smax>'   % KW.SRC[c].smax)
	    fmt.append ('</corpus>')
	return fmt


def entr_diff (eold, enew, n=2):
	# 'eold' and/or 'enew' can be either Entr objects or
	# XML strings of Entr objects.

	if isinstance (eold, (str, unicode)): eoldxml = eold.splitlines(False)
	else: eoldxml = entr (eold, wantlist=1, implicit_pos=0)
	if isinstance (enew, (str, unicode)): enewxml = enew.splitlines(False)
	else: enewxml = entr (enew, wantlist=1, implicit_pos=0)
	  # Generate diff and remove trailing whitespace, including newlines.
	  # Also, skip the <entry> line since they will always differ.
	rawdiff = difflib.unified_diff (eoldxml, enewxml, n=n)
	diffs = [x.rstrip() for x in rawdiff
		 if not (x[1:].startswith ('<entry') or x.startswith ('@@ -1,1 +1,1 @@')) ]
	  # Remove the intial "---", "+++" lines.
	if len(diffs) >= 2: diffs = diffs[2:]
	diffstr = '\n'.join (diffs)
	return diffstr

def _main (args, opts):
	cur = jdb.dbOpen ('jmdict')
	while True:
	    try: id = raw_input ("Id number? ")
	    except EOFError: id = None
	    if not id: break
	    e, raw = jdb.entrList (cur, [int(id)], ret_tuple=True)
	    jdb.augment_xrefs (cur, raw['xref'])
	    if not e:
		print "Entry id %d not found" % id
	    else:
		txt = entr (e[0], compat=None)
		print txt

if __name__ == '__main__':
	_main (None, None)
