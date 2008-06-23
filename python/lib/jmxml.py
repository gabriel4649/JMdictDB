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
Functions for parsing XML descriptions of entries into
entry objects.

"""

import sys, os, re, datetime
from collections import defaultdict
#import lxml.etree as ElementTree
import xml.etree.cElementTree as ElementTree
import jdb, warns, kwstatic

# This module calls function warns.warn() (from inside local
# function warn()) to log non-fatal warning messages.  By default,
# that function will write it's messages to sys.stderr using the
# system default encoding.  The caller of this module (jmxml.py)
# can change these defaults be setting warns.Logfile and
# warns.Encoding.

Seq = None

class ParseError (RuntimeError): pass
class NotFoundError (RuntimeError): pass

def xml_lookup_table (KW):
	"""
	This function generates jdb.Kwds -like structure used for
	mapping JMdict entities to the kw* table id numbers used
	to represent the corresponding information in jmdictdb.

	For the most part, jmdictdb uses the textual value of the 
	JMdict XML entities as keywords.  (For example, if "&adj-na;"
	is used to denote and na-adjective in JMdict, jmdictdb will 
	use "na-adj" the the "kw" value of the na-adjective row in 
	table kwpos.

	But we don't want to be forced into this convention, so
	we use this function to generate an independent set of mapping
	tables (rather than just using jdb.KW), which is functionally
	a copy of jdb.KW but allows the introduction of exceptions 
	should we ever need to do that.
	"""
	for attr in 'DIAL FLD KINF MISC POS RINF'.split():
	    kwdict = getattr (KW, attr)
	return KW

class JmdictFile:
    # Wrap a standard file object and preprocess the lines being
    # read (expectedly by an XML parser) for three purposes: 
    #   1. Keep track of the file line number (for error messages).
    #   2. Since the XML parser doesn't seem to be able to extract
    #      the JMdict creation date comment (because it is outside
    #      of the root element), we do it here.
    #   3. Replace entities with non-entity strings of the same 
    #      textual value.  It is more convinient to work with the
    #      entity string values than their expanded text values.

    def __init__(self, source):
	self.source = source;  self.lineno = 0
	self.name = None; self.created=None
    def read(self, bytes):
	s = self.source.readline();  self.lineno += 1
	if self.lineno == 1: 
	    if s[:3] == '\xef\xbb\xbf': s = s[3:]
	    if s[0] == u'\uFEFF': s = s[1:]
	s = re.sub (r'&([a-zA-Z0-9-]+);', r'\1', s)
	if self.created is None and self.lineno < 400:
	    mo = re.search (r'<!-- ([a-zA-Z]+) created: (\d{4})-(\d{2})-(\d{2}) -->', s)
	    if mo:
		self.name = mo.group(1)
		self.created = datetime.date (*map(int, mo.group(2,3,4)))
	return s

def parse_entry (txt, dtd=None):
	# Convert an XML text string into entry objects.
	# 
	# @param txt Text string containing a piece of XML defining
	#            one of more entry elements.
	# @param dtd (optional) A text string providing a DTD to be
	#            prepended to 'txt'.  If not provide no DTD will 
	#            be prepended.
	# @returns An list of entry objects. 

	if dtd: txt = dtd + txt
	else: txt = re.sub ('&([a-zA-Z0-9-]+);', r'\1', txt)
	xo = ElementTree.XML (txt)
	if xo is None:
	    print "No parse results"
	    return []
	e = do_entr (xo, None)
	return [e]

def parse_xmlfile (
	inpf, 		# (file) An open jmdict/jmnedict XML file..
	startseq=None, 	# (int) Skip until this entry seen, or None
			#   to start at first entry.
	elimit=None, 	# (int) Maximum number of entries to process.
	xlit=False, 	# (bool) Extract "lit" info from glosses.
	xlang=None,	# (list) List of lang id's to limit extracted
			#   glosses to.
	corp_dict=None,	# (dict) A mapping that contains corpus (aka
			#   "src") records indexed by id number and 
			#   name.  <ent_corp> elements will be looked
			#   up in this dict.  If not supplied, it is 
			#   expected that <corpus> elements will occur
			#   in the XML that define corpuses before they
			#   are referenced by <ent_corp> elements.
	toptag=False):	# (bool) Make first item retuned by iterator 
			#   a string giving the name of the top-level
			#   element.

	global Seq
	etiter = iter(ElementTree.iterparse( inpf, ("start","end")))
	event, root = etiter.next()
	if toptag: yield 'root', root.tag
	if corp_dict is None: corp_dict = {}
	elist=[];  count=0;  entrnum=0
	for event, elem in etiter:
	    if elem.tag != "entry" and elem.tag != 'corpus': continue
	    if event == "start": 
		lineno = getattr (inpf, 'lineno', None)
		  # Only jmdict has "ent_seq" elements so if parsing jmnedici
		  # we will use the the ordinal position of the entry in the
		  # file, which we maintain by counting entries with 'entrnum',
		  # as the seq number.
		if elem.tag == 'entry': entrnum += 1
		continue
	      # At this point elem.tag must be either 'entry' or 'corpus'
	      # and event is 'end'.
	    if elem.tag == 'corpus':
		corp = do_corpus (elem)
		corp_dict[corp.id] = corp_dict[corp.kw] = corp
		yield "corpus", corp
		continue
	    prevseq = Seq
	    Seq = seq = int (elem.findtext ('ent_seq') or entrnum)
	    if prevseq and seq <= prevseq: 
		warn (" (line %d): Sequence less than preceeding sequence" % lineno)
	    if not startseq or seq >= startseq:
		startseq = None
		try: entr = do_entr (elem, seq, xlit, xlang, corp_dict)
		except ParseError, e:
		    warn (" (line %d): %s" % (lineno, e))
		else: yield "entry", entr
	        count += 1
		if elimit and count >= elimit: break
	    root.clear()

def do_corpus (elem):
	o = jdb.Obj (id=int(elem.get('id')), kw=elem.findtext ('name'))
	descr = elem.findtext ('descr')
	if descr: o.descr = descr
	dt = elem.findtext ('date')
	if dt: o.dt = dt
	notes = elem.findtext ('notes')
	if notes: o.notes = notes
	seq = elem.findtext ('seqname')
	if seq: o.seq = seq
	return o

def do_entr (elem, seq, xlit=False, xlang=None, corp_dict=None):
	"""
    Create an entr object from a parsed ElementTree entry
    element, 'elem'.  'lineno' is the source file line number
    of the "<entry>" line or None and is only used in error
    messages.

    Note that the entry object returned is different from one
    read from the database in the following respects:
    * The 'entr' record will have no .src (aka corpus) attribute
      if there is no <ent_corp> element in the entry.  In this
      case the .src attribute is expected to be added by the
      caller.  If there is a <ent_corp> element, it will be 
      used to find a corpus in 'corp_dict', which in turn will
      will provide an id number used in .src.
    * Items in sense's _xref list are unresolved xrefs, not 
      resolved xrefs as in a database entr object.  
      jdb.resolv_xref() or similar can be used to resolve the
      xrefs.
    * Attributes will be missing if the corresponding xml
      information is not present.  For example, if a particular 
      entry has no <ke_ele> elements, the entr object will not
      have a '._kanj' attribute.  In an entr object read from 
      the database, it will have a '._kanj' attribute with a 
      value of [].
    * The entr object does not have many of the foreign key 
      attributes: gloss.gloss, xref.xref, <anything>.entr, etc. 
      However, it does have rdng.rdng, kanj.kanj, and sens.sens
      attributes since these are required when adding restr,
      stagr, stagk, and freq objects.
	"""
	global XKW, KW

	entr = jdb.Obj ()

	if not seq:
	    elemseq = elem.find ('ent_seq')
	    if elemseq is None: raise ParseError ("No <ent_seq> element found")
	    try: seq = int (elemseq.text)
	    except ValueError: raise ParseError ("Invalid 'ent_seq' value, '%s'" % elem.text)
	if seq <= 0: raise ParseError ("Invalid 'ent_seq' value, '%s'" % elem.text)
	entr.seq = seq

	id = elem.get('id')
	if id is not None: entr.id = int (id)
	dfrm = elem.get('dfrm')
	if dfrm is not None: entr.dfrm = int (dfrm)
	stat = elem.get('status') or jdb.KW.STAT['A'].id
	try: stat = XKW.STAT[stat].id
	except KeyError: raise ParseError ("Invalid <status> element value, '%s'" % stat)
	entr.stat = stat
	entr.unap = elem.get('appr') == 'n'

	corpname = elem.findtext('ent_corp')
	if corpname is not None: entr.src = corp_dict[corpname].id
	fmap = defaultdict (lambda:([],[]))
	do_kanjs (elem.findall('k_ele'), entr, fmap)
	do_rdngs (elem.findall('r_ele'), entr, fmap)
	do_freq (fmap, entr)
	do_senss (elem.findall('sense'), entr, xlit, xlang)
	do_senss (elem.findall('trans'), entr, xlit, xlang)
	do_info  (elem.findall("info"), entr)
	do_audio (elem.findall("audio"), entr)
	return entr

def do_info (elems, entr):
	if not elems: return 
	elem = elems[0]	  # DTD allows only one "info" element.
	x = elem.findtext ('srcnote')
	if x: entr.srcnote = x
	x = elem.findtext ('notes')
	if x: entr.notes = x
	do_hist (elem.findall("audit"), entr)

def do_kanjs (elems, entr, fmap):
	if elems is None: return 
	kanjs = []; dupchk = {}
	for ord, elem in enumerate (elems):
	    txt = elem.find('keb').text
	    if not jdb.unique (txt, dupchk): 
		warn ("Duplicate keb text: '%s'" % txt); continue
	    if not (jdb.jstr_classify (txt) & jdb.KANJI):
		warn ("keb text '%s' not kanji." % txt)
	    kanj = jdb.Obj (kanj=ord+1, txt=txt)
	    do_kws (elem.findall('ke_inf'), kanj, '_inf', 'KINF')
	    for x in elem.findall ('ke_pri'): 
		q = fmap[x.text][0]
		if kanj not in q: q.append (kanj)
		else: freq_warn ("Duplicate", None, kanj, x.text)
	    kanjs.append (kanj)
	if kanjs: entr._kanj = kanjs

def do_rdngs (elems, entr, fmap):
	if elems is None: return
	rdngs = getattr (entr, '_rdng', [])
	kanjs = getattr (entr, '_kanj', [])
	rdngs = []; dupchk = {}
	for ord, elem in enumerate (elems):
	    txt = elem.find('reb').text
	    if not jdb.unique (txt, dupchk): 
		warn ("Duplicate reb text: '%s'" % txt); continue
	    t = jdb.jstr_classify (txt)
	    if (t & jdb.KANJI) or not (t & jdb.KANA):
		warn ("reb text '%s' not kana." % txt)
	    rdng = jdb.Obj (rdng=ord+1, txt=txt)
	    do_kws (elem.findall('re_inf'), rdng, '_inf', 'RINF')
	    for x in elem.findall ('re_pri'): 
		q = fmap[x.text][1]
		if rdng not in q: q.append (rdng)
		else: freq_warn ("Duplicate", rdng, None, x.text)
	    nokanji = elem.find ('re_nokanji')
	    do_restr (elem.findall('re_restr'), rdng, kanjs, 'rdng', 'kanj', '_restr', nokanji)
	    rdngs.append (rdng)
	if rdngs: entr._rdng = rdngs

def do_senss (elems, entr, xlit=False, xlang=None): 
	global XKW
	rdngs = getattr (entr, '_rdng', [])
	kanjs = getattr (entr, '_kanj', [])
	senss = [];  last_pos = None
	for ord, elem in enumerate (elems):
	    sens = jdb.Obj (sens=ord+1)
	    snotes = elem.find ('s_inf')
	    if snotes is not None and snotes.text: sens.notes = snotes.text

	    pelems = elem.findall('pos')
	    if pelems: 
		last_pos = do_kws (pelems, sens, '_pos', 'POS')
	    elif last_pos: 
		sens._pos = [jdb.Obj(kw=x.kw) for x in last_pos]

	    do_kws   (elem.findall('name_type'), sens, '_pos',  'POS')
	    do_kws   (elem.findall('misc'),      sens, '_misc', 'MISC')
	    do_kws   (elem.findall('field'),     sens, '_fld',  'FLD')
	    do_kws   (elem.findall('dial'),      sens, '_dial', 'DIAL')
	    do_lsrc  (elem.findall('lsource'),   sens,)
	    do_gloss (elem.findall('gloss'),     sens, xlit, xlang)
	    do_gloss (elem.findall('trans_det'), sens,)
	    do_restr (elem.findall('stagr'),     sens, rdngs, 'sens', 'rdng', '_stagr')
	    do_restr (elem.findall('stagk'),     sens, kanjs, 'sens', 'kanj', '_stagk')
	    do_xref  (elem.findall('xref'),      sens, jdb.KW.XREF['see'].id)
	    do_xref  (elem.findall('ant'),       sens, jdb.KW.XREF['ant'].id)

	    if not getattr (sens, '_gloss', None):
		warn ("Sense %d has no glosses." % (ord+1))
	    senss.append (sens)
	if senss: entr._sens = senss

def do_gloss (elems, sens, xlit=False, xlang=None):
	global XKW
	glosses=[]; lits=[]; lsrc=[]; dupchk={}
	for elem in elems:
	    lng = elem.get ('{http://www.w3.org/XML/1998/namespace}lang')
	    try: lang = XKW.LANG[lng].id if lng else XKW.LANG['eng'].id
	    except KeyError:
		warn ("Invalid gloss lang attribute: '%s'" % lng)
		continue
	    txt = elem.text
	    lit = []; trans = [];
	    if xlit and ('lit:' in txt):
		 txt, lit = extract_lit (txt)
	    if not jdb.unique ((lang,txt), dupchk):
		warn ("Duplicate lang/text in gloss '%s'/'%s'" % (lng, txt))
		continue
	    # (entr,sens,gloss,lang,txt)
	    if txt and (not xlang or lang in xlang):
	        glosses.append (jdb.Obj (lang=lang, ginf=XKW.GINF['equ'].id, txt=txt))
	    if lit:
	        lits.extend ([jdb.Obj (lang=lang, ginf=XKW.GINF['lit'].id, txt=x) for x in lit])
	if glosses or lits:
	    if not hasattr (sens, '_gloss'): sens._gloss = []
	    sens._gloss.extend (glosses + lits)

def do_lsrc (elems, sens): 
	lsrc = [];
	for elem in elems:
	    txt = elem.text or ''
	    lng = elem.get ('{http://www.w3.org/XML/1998/namespace}lang')
	    try: lang = XKW.LANG[lng].id if lng else XKW.LANG['eng'].id
	    except KeyError:
		warn ("Invalid lsource lang attribute: '%s'" % lng)
		continue
	    lstyp = elem.get ('ls_type')
	    if lstyp and lstyp != 'part':
		warn ("Invalid lsource type attribute: '%s'" % lstyp)
		continue
	    wasei = elem.get ('ls_wasei') is not None

	    if (lstyp or wasei) and  not txt: 
		attrs = ("ls_wasei" if wasei else '') \
			+ ',' if wasei and lstyp else '' \
			("ls_type" if lstyp else '')
		warn ("lsource has attribute(s) %s but no text" % msg)
	    lsrc.append (jdb.Obj (lang=lang, txt=txt, part=lstyp=='part', wasei=wasei))
	if lsrc: 
	    if not hasattr (sens, '_lsrc'): sens._lsrc = []
	    sens._lsrc.extend (lsrc)

def do_xref (elems, sens, xtypkw):
	  # Create a xresolv record for each xml <xref> element.  The xref 
	  # may contain a kanji string, kana string, or kanji.\x{30fb}kana.  
	  # (\x{30fb} is a mid-height dot.)  It may optionally be followed
	  # by a \x{30fb} and a sense number.
	  # Since jmdict words may also contain \x{30fb} as part of their
	  # kanji or reading text we try to handle that by ignoring the 
	  # \x{30fb} between two kana strings, two kanji strings, or a
	  # kana\x{30fb}kanji string.  Of course if a jmdict word is 
	  # kanji\x{30fb}kana then we're out of luck; it's ambiguous.

	xrefs = []
	for elem in elems:
	    txt = elem.text

	      # Split the xref text on the separator character.

	    frags = txt.split (u"\u30fb")

	      # Check for a sense number in the rightmost fragment.
	      # But don't treat it as a sense number if it is the 
	      # only fragment (which will leave us without any kana
	      # or kanji text which will fail when loading xresolv.
 
	    snum = None
	    if len (frags) > 0 and frags[-1].isdigit():
		snum = int (frags.pop())

	      # Go through all the fragments, from right to left.
	      # For each, if it has no kanji, push it on the @rlst 
	      # list.  If it has kanji, and every fragment thereafter
	      # regardless of its kana/kanji status, push on the @klst
	      # list.  $kflg is set to true when we see a kanji word
	      # to make that happen.
	      # We could do more checking here (that entries going
	      # into @rlst are kana for, example) but don't bother 
	      # since, as long as the data loads into xresolv ok, 
	      # wierd xrefs will be found later by being unresolvable.

	    klst=[];  rlst=[];  kflg=False
	    for frag in reversed (frags):
		if not kflg: jtyp = jdb.jstr_classify (frag)
		if kflg or jtyp & jdb.KANJI:
		    klst.append (frag)
		    kflg = True
		else: rlst.append (frag)

	      # Put the kanji and kana parts back together into
	      # strings, and write the xresolv resord.

	    ktxt = u"\u30fb".join (klst) or None
	    rtxt = u"\u30fb".join (rlst) or None

	    if ktxt or rtxt:
		xrefs.append (jdb.Obj (typ=xtypkw, ktxt=ktxt, rtxt=rtxt, tsens=snum))
	if xrefs: 
	    for n, x in enumerate (xrefs): x.ord = n + 1
	    if not hasattr (sens, '_xrslv'): sens._xrslv = []
	    sens._xrslv.extend (xrefs)

def do_hist (elems, entr):
	hists = []
	for elem in elems:
	    x = elem.findtext ("upd_date")
	    dt = datetime.datetime (*([int(z) for z in x.split ('-')] + [0, 0, 0]))
	    o = jdb.Obj (dt=dt, stat=kwstatic.KWSTAT_A)
	    notes = elem.findtext ("upd_detl")
	    name = elem.findtext ("upd_name")
	    email = elem.findtext ("upd_email")
	    diff = elem.findtext ("upd_diff")
	    refs = elem.findtext ("upd_refs")
	    if name: o.name = name
	    if email: o.email = email
	    if notes: o.notes = notes
	    if refs: o.refs = refs
	    if diff: o.diff = diff
	    hists.append (o)
	if hists: 
	    if not hasattr (entr, '_hist'): entr._hist = []
	    entr._hist.extend (hists)

def do_audio (elems, entr_or_rdng):
	snds = []
	for elem in elems:
	    v = elem.get ('clipid')
	    if not v: 
		warn ("Missing audio clipid attribute."); continue
	    try: clipid = int (v.lstrip('c'))
	    except (ValueError, TypeError): warn ("Invalid audio clipid attribute: %s" % v)
	    else: snds.append (jdb.Obj (snd=clipid))
	if snds:
	    if not hasattr (entr_or_rdng, '_snd'): entr_or_rdng._snd = []
	    entr_or_rdng._snd.extend (snds)

def do_kws (elems, obj, attr, kwtabname):
	"""
	Extract the keywords in the elementtree elements 'elems',
	resolve them in kw table 'kwtabname', and append them to
	the list attached to 'obj' named 'attr'.
	""" 
	global XKW
	if elems is None: return None
	kwtab = getattr (XKW, kwtabname)
	kwtxts, dups = jdb.rmdups ([x.text for x in elems])
	kwrecs = []
	for x in kwtxts:
	    try: kw = kwtab[x].id
	    except KeyError: 
		warn ("Unknown %s keyword '%s'" % (kwtabname,x))
	    else:
		kwrecs.append (jdb.Obj (kw=kw))
	dups, x = jdb.rmdups (dups)
	for x in dups:
	    warn ("Duplicate %s keyword '%s'" % (kwtabname, x))
	if kwrecs: 
	    if not hasattr (obj, attr): setattr (obj, attr, [])
	    getattr (obj, attr).extend (kwrecs)
	return kwrecs

def do_restr (elems, rdng, kanjs, rattr, kattr, pattr, nokanji=None):
	"""
	The function can be used to process stagr and stagk restrictions
        in addition to re_restr restrictions, but for simplicity, code
	comments and variable names assume re_restr processing.

	    rdng -- A rdng obj (must have a correct 'rdng' attribute').
	    elems -- A list of 're_restr' xml elements (may be empty).
	    nokanji -- True if the reading has a <no_kanji> element,
		    false otherwise.
	    kanjs -- A complete list of the entries kanj objects (with
		    correct 'kanj' attributes).

	To use for stagr restictions:

	    do_restrs (stagr_elems, sens, rdngs, 'sens', 'rdng', '_stagr', False)

	or stagk restrictions:

	    do_restrs (stagk_elems, sens, kanjs, 'sens', 'kanj', '_stagk', False)
	"""

	  # Warning, do not replace the 'nokanji is None' tests below
	  # with 'not nokanji'.  'nokanji' may be an elementtree element
	  # which can be False, even if not None.  (See the element tree
	  # docs.)

	if not elems and nokanji is None: return
	if elems and nokanji is not None:
	    warn ("Conflicting 'nokanji' and 're_restr' in reading %d." % rdng.rdng)
	if nokanji is not None: allowed_kanj = []
	else: 
	    allowed_kanj, dups = jdb.rmdups ([x.text for x in elems])
	    if dups:
		warn ("Duplicate %s item(s) %s in %s %d." 
			% (pattr[1:], "'"+"','".join([dups])+"'", 
			   rattr, getattr (rdng,rattr)))

	for kanj in kanjs:
	    if kanj.txt not in allowed_kanj:
		add_restr (rdng, rattr, kanj, kattr, pattr)

def add_restr (rdng, rattr, kanj, kattr, pattr):
	"""
	Create a restriction row object and link it to two items
	that constitute the restriction.

	To create a reading restr:
	    add_restr (rdng, 'rdng', kanj, 'kanj', '_restr')
	To create a stagr restr:
	    add_restr (sens, 'sens', rdng, 'rdng', '_stagr')
	To create a stagk restr:
	    add_restr (sens, 'sens', kanj, 'kanj', '_stagk')
	"""
	restr = jdb.Obj (); 
	setattr (restr, rattr, getattr (rdng, rattr))
	setattr (restr, kattr, getattr (kanj, kattr))
	if not hasattr (rdng, pattr): setattr (rdng, pattr, [])
	if not hasattr (kanj, pattr): setattr (kanj, pattr, [])
	getattr (rdng, pattr).append (restr)
	getattr (kanj, pattr).append (restr)

def do_freq (fmap, entr):
	"""
	Convert the freq information collected in 'fmap' into freq
	records attached to reading and kanji records in lists 'rdng'
	and 'kanj',
	"""
	  # 'fmap' is a dictionary, keyed by freq text ("ichi1", "gai2",
	  # etc).  Each value is a 2-tuple of lists.  The first list is
	  # all the rdng's having that freq, the second is a list of all
	  # the kanj's having that freq.  (In most cases the length of
	  # each list will be either 0 or 1).

	frecs = {}
	for freq, (kanjs, rdngs) in fmap.items():
	    kw, val = parse_freq (freq, '')
	    dups = []; repld = []
	    if not rdngs:
		for k in kanjs: 
		    freq_bin (None, k, kw, val, frecs, dups, repld)
	    elif not kanjs:
		for r in rdngs: 
		    freq_bin (r, None, kw, val, frecs, dups, repld)
	    else:
		for r,k in crossprod (rdngs, kanjs): 
		    freq_bin (r, k, kw, val, frecs, dups, repld)
	    if dups:
		  # We filter out dup pri's in do_rdng() and do_kanj()
		  # and thus should never see any here.
		raise RuntimeError ("Unexpected duplicates in do_freq()")
	    for r, k, kw, val in repld:
		freq_warn ("Conflicting", r, k, freq) 

	for (r, k, kw), val in frecs.items():
	    fo = jdb.Obj (rdng=getattr(r,'rdng',None), kanj=getattr(k,'kanj',None),
			  kw=kw, value=val)
	    if r:
		if not hasattr (r, '_freq'): r._freq = []
		r._freq.append (fo)
	    if k:
		if not hasattr (k, '_freq'): k._freq = []
		k._freq.append (fo)

	
def freq_bin (r, k, kw, val, freqs, dups, repld):
	"""
	This function takes a freq item (given in parsed form
	as 'kw', 'val') in the context of a specific reading/kanji
	pair (given as the rdng and kanj base-1 index numbers in an
	entry's reading and kanji lists) and puts it into one of
	three dicts: 'freqs' if the freq item will is selected to
	go into the database, 'dups' if the freq item in a duplicate
	of one selected to go into the database, and 'replcd' for 
	freq items that have the same domain as one going into the
	database but with a greater value (that is, given two freq
	items, "nf22", and "nf15", the "nf15" will go into 'freqs'
	and "nf22" in 'replcd' since they both have the same "nf" 
	domain and the later's value of "22" is greater than the 
	former's "15".)

	r -- The 1-based index position of the rdng object this freq
		item is acccosiated with.
	k -- The 1-based index position of the kanj object this freq
		item is acccosiated with.
	kw -- The id number in table kwfreq of the freq item.
	val -- The value of the freq item.
	freqs -- A dict that will receive freq items selected to go
		into the database.
	dups -- A dict that will receive freq items that are duplicates
		of ones selected to go into the database.
	replcd -- A dict that will receive freq items that are rejected
		becase they have the same domain but a higher value as
		one selected to go into the database.
	"""
	key = (r, k, kw)
	if key in freqs:
	    if val < freqs[key]:
		repld.append ((r, k, kw, freqs[key]))
	    elif val > freqs[key]:
		repld.append ((r, k, kw, val))
	    else:
		dups.append ((r, k, kw, val))
	else:
	    freqs[key] = val

def parse_freq (fstr, ptype):
	# Convert a re_pri or ke_pri element string (e.g "nf30") into
	# numeric (id,value) pair (like 4,30) (4 is the id number of 
	# keyword "nf" in the database table "kwfreq", and we get it 
	# by looking it up in JM2ID (from jmdictxml.pm). In addition 
	# to the id,value pair, we also return keyword string.
	# $ptype is a string used only in error or warning messages 
	# and is typically either "re_pri" or "ke_pri".

	global XKW
	mo = re.match (r'^([a-z]+)(\d+)$', fstr)
	if not mo: warn ("Invalid %s, '%s'" % (ptype, fstr))
	kwstr, val = mo.group (1,2)
	try: kw = XKW.FREQ[kwstr].id
	except KeyError: warn ("Unrecognised %s, '%s'" % (ptype, fstr))
	val = int (val)
	#FIXME -- check for invalid values in 'val'.
	return kw, val

def freq_warn (warn_type, r, k, kwstr):
	tmp = []
	if r: tmp.append ("reading %d" % r.rdng)
	if k: tmp.append ("kanji %d" % k.kanj)
	warn ("%s pri value '%s' in %s" 
		% (warn_type, kwstr, ', '.join (tmp)))

def extract_lit (txt):
	"""
	Extract literal gloss text from a gloss text string, 'txt'.   
	"""
	t = re.sub (r'^lit:\s*', '', txt)
	if len(t) != len(txt): return '', [t]
	  # The following regex will match substrings like "(lit: xxxx)".  
	  # The "xxxx" part may have parenthesised text but not nested. 
	  # Thus, "lit: foo (on you) dude" will be correctly parsed, but
	  # "lit: (foo (on you)) dude" won't.
	regex = r'\((lit):\s*((([^()]+)|(\([^)]+\)))+)\)'
        start = 0; gloss=[]; lit=[]
        for mo in re.finditer(regex, txt):
            gtyp, special = mo.group(1,2)
            brk, end = mo.span(0)
	    if brk - start > 0:   gloss.append (txt[start:brk].strip())
	    lit.append (special.strip())
	    start = end
	t = txt[start:len(txt)].strip()
	if t: gloss.append (t)
	gloss = ' '.join(gloss)
	return gloss, lit

def crossprod (*args):
	"""
	Return the cross product of an arbitrary number of lists.
	"""
	# From http://aspn.activestate.com/ASPN/Cookbook/Python/Recipe/159975
	result = [[]]
	for arg in args:
	    result = [x + [y] for x in result for y in arg]
	return result

def warn (msg):
	global Seq
	warns.warn ("Seq %d: %s" % (Seq, msg))

def extract (fin, seqs_wanted, dtd=False, fullscan=False, keepends=False):
	"""
	Returns an iterator that will return the text lines in 
	xml file 'fin' for the entries given in 'seqs_wanted'.

	Each call (of the iterator's next() method) will return
	a 2-tuple: the first item is the seq number of the entry
	and the second item is list of text lines the comprise
	the entry.  The lines are exactly as read from 'fin'
	(i.e. if 'fin'in a standard file object, the lines 
	will have the encoding of the file (typically utf-8)
	and contain line terminators ('\n').  Entries are returned
	in the order they are encountered in the input file, 
	regardless of the order given in 'seq_wanted'.  Comments 
	within an entry will returned as part of that entry, but 
	comments between entries are inaccessible.

	If the 'dtd' parameter is true, the first call will return 
	a 2-tuple whose first item is a string naming the root tag
	(typically "JMdict" or JMnedict"; it is needed by the caller 
	so that a correct closing tag can be written), and a list 
	of the lines of the input file's DTD.  

	Note that this function does *not* actually parse the xml; 
	it relies on the lexical characteristics of the jmdict and
	jmnedict files (an entry tag occurs alone on a line, that 
	an ent_seq element is on a single line, etc) for speed.
	If the format of the jmdict files changes, it is likely
	that this will fail or return erroneous results.

	TO-DO: document those assumtions.

	If a requested seq number is not found, a NotFoundError will
	be raised after all the found entries have been returned.

	fin -- Open file object for the xml file to use.
 	
	seq_wanted -- A list of intermixed jmdict seq numbers or 
	    seq number/count pairs (tuple or list).  The seq number 
	    value indentifies the entry to return.  The count value 
	    gives the number of successive entries including seq 
	    number to return.  If the count is not given, 1 is 
	    assumed.  Entries  will be returned in the order found, 
	    not the order they occur in 'seq-wanted'.  

	dtd -- If true, the first returned value will be a 2-tuple.  
	    The first item in it will be a list containng the text 
	    lines of the DTD in the input file (if any).  The second 
	    item is a single text string that is the line containing
	    the root element (will be "<JMdict>\n" for a standard 
	    JMdict file, or "<JMnedict>\n" to the entries extracted.

	fullscan -- Normally this function assumes the input file 
	   entries are in ascending seq number order, and after it  
	   sees a sequence number greater that the highest seq number  
	   in 'seq_wanted', it will stop scanning and report any 
	   unfound seq numbers.  If the input file entries are not 
	   ordered, it may be necessary to use 'fullscan' to force 
	   scanning to the end of the file to find all the requested 
	   entries. This can take a long time for large files.
	"""

	  # Break the seqs_wanted listed into two lists: a list of
	  # the sequence numbers, sorted in ascending order, and a
	  # equal length list of the corresponding counts.  The
	  # try/except below is to catch the failure of "len(s)"
	  # which will happen if 's' is a seq number rather than
	  # a (seq-number, count) pair.
	tmp = []
	for s in seqs_wanted:
	    try: 
		if len(s) == 2:  sv, sc = s
		elif len(s) == 1: sv, sc = s[0], 1
		else: raise ValueError (s)
	    except TypeError:
		sv, sc = int(s), 1
	    tmp.append ((sv, sc))
	tmp.sort (key=lambda x:x[0])
	seqs = [x[0] for x in tmp];  counts = [x[1] for x in tmp]

	scanning='in_dtd';  seq=0;  lastseq=None;  toplev=None;  
	rettxt = [];  count=0;
	for line in fin:

	      # The following "if" clauses are in order of frequency
	      # of being true for efficiency.

	    if scanning == 'copy' or  scanning == 'nocopy':
		if scanning == 'copy': 
		    if keepends: rettxt.append (line.strip())
		    else: rettxt.append (line.rstrip())
		if line.lstrip().startswith ('</entry>'):
		    if count <= 0 and (not seqs or (seqs[-1] < seq and not fullscan)): break
		    if count > 0: 
			yield seq, rettxt;  rettxt = []
		    scanning = 'between_entries'
		    lastseq = seq 

	    elif scanning == 'between_entries':
		if line.lstrip().startswith ('<entry>'):
		    entryline = line
		    scanning = 'in_entry'

	    elif scanning == 'in_entry':
		ln = line.lstrip()
		if ln.startswith ('<ent_seq>'):
		    n = ln.find ('</ent_seq>')
		    if n < 0: raise IOError ('Invalid <ent_seq> element, line %d', lnnum)
		    seq = int (ln[9:n])
		else: 
		    seq += 1	# JMnedict has no seq numbers, so just count entries.
		count = wanted (seq, seqs, counts, count)
		if count > 0:
		    if keepends: 
			rettxt.append (entryline)
			rettxt.append (line)
		    else: 
			rettxt.append (entryline.rstrip())
			rettxt.append (line.rstrip())
		    scanning = 'copy'
		else: scanning = 'nocopy'

	    elif scanning == 'in_dtd':
		if dtd: 
		    if keepends: rettxt.append (line)
		    else: rettxt.append (line.rstrip())
		ln = line.strip()
		if ln.lstrip() == "]>":
		    scanning = 'after_dtd'

	    elif scanning == 'after_dtd':
		ln = line.strip()
	 	if len(ln) > 2 and ln[0] == '<' and ln[1] != '!':
		    if dtd: 
		        toplev = line.strip()[1:-1]
		        yield toplev, rettxt;  rettxt = []
		    scanning = 'between_entries'

	    
		    
	    else:
		raise ValueError (scanning)

	if seqs: 
	    raise NotFoundError ("Sequence numbers not found", seqs)

def wanted (seq, seqs, counts, count):
	""" Helper function for extract().  
	Return the number of entries to copy."""

	if count > 0: count -= 1
	s = 0
	for n, s in enumerate (seqs): 
	    if s >= seq: break
	if s == seq: 
	    count = max (counts[n], count)
	    del seqs[n]; del counts[n]
	return count

def parse_sndfile (
	inpf, 		# (file) An open sound clips XML file..
	toptag=False):	# (bool) Make first item retuned by iterator 
			#   a string giving the name of the top-level
			#   element.

	etiter = iter(ElementTree.iterparse( inpf, ("start","end")))
	event, root = etiter.next()
	vols = []
	for event, elem in etiter:
	    tag = elem.tag
	    if tag not in ('avol','asel','aclip'): continue
	    if event == 'start': lineno = inpf.lineno; continue
	    if   tag == 'aclip': yield do_clip (elem), 'clip', lineno
	    elif tag == 'asel':  yield do_sel (elem), 'sel', lineno
	    elif tag == 'avol':  yield do_vol (elem), 'vol', lineno

def do_vol (elem):
	return jdb.Obj (id=int(elem.get('id')[1:]),
			title=elem.findtext('av_title'), loc=elem.findtext('av_loc'), 
			type=elem.findtext('av_type'), idstr=elem.findtext('av_idstr'),
			corp=elem.findtext('av_corpus'), notes=elem.findtext('av_notes'))

def do_sel (elem):
	return jdb.Obj (id=int(elem.get('id')[1:]), vol=int(elem.get('vol')[1:]),
			title=elem.findtext('as_title'), loc=elem.findtext('as_loc'),
			type=elem.findtext('as_type'), notes=elem.findtext('as_notes'))

def do_clip (elem):
	return jdb.Obj (id=int(elem.get('id')[1:]), file=int(elem.get('sel')[1:]),
			strt=int(elem.findtext('ac_strt')), leng=int(elem.findtext('ac_leng')),
			trns=elem.findtext('ac_trns'), notes=elem.findtext('ac_notes'))

def main (args=[], opts=jdb.Obj()):
	global XKW
	XKW = xml_lookup_table (kwstatic.KW)
	jdb.KW = kwstatic.KW
	if len(args) >= 1: 
            inpf = JmdictFile( open( args[0] ))
	    for entr in parse_xmlfile (inpf, xlit=1):
		import fmt
		print fmt.entr (entr)
	else:
	    dir = jdb.find_in_syspath ("dtd-jmdict.xml")
	    dtd = jdb.get_dtd (dir + "/" +  "dtd-jmdict.xml")
	    while 1:
	        s = raw_input ('test> ')
		if not s: break
		while 1:
		    s2 += raw_input()
		    if not s2: break
		    s += s2
	        e = parse_entry (s, dtd)
	        print e

if __name__ == '__main__': main (args=sys.argv[1:])
