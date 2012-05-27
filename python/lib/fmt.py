#######################################################################
#  This file is part of JMdictDB. 
#  Copyright (c) 2008 Stuart McGraw 
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
from __future__ import print_function

__version__ = ('$Revision$'[11:-2],
	       '$Date$'[7:-11]);

from collections import defaultdict
import jdb

def entr (entr, wantlist=False):
	fmt = entrrec (entr)
	fmt.extend (kanjs (entr))
	fmt.extend (rdngs (entr))
	fmt.extend (senss (entr))
	fmt.extend (char (entr))
	fmt.extend (audio (entr))
	fmt.extend (hists (entr))
	if wantlist: return fmt
	txt = '\n'.join (fmt)
	return txt

def kanjs (entr, label="Kanji: "):
	kanjs = getattr (entr, '_kanj', [])
	ktxt = " ".join([kanj(x) for x in kanjs])
	if ktxt and label: ktxt = label + ktxt
	return [ktxt] if ktxt else []

def rdngs (entr, label="Readings: "):
	rdngs = getattr (entr, '_rdng', [])
	kanjs = getattr (entr, '_kanj', [])
	rtxt = " ".join([rdng(x, kanjs) for x in rdngs])
	if rtxt and label: rtxt = label + rtxt
	return [rtxt] if rtxt else []

def senss (entr, label="Senses: "):
	fmt = []
	rdngs = getattr (entr, '_rdng', [])
	kanjs = getattr (entr, '_kanj', [])
	senss = getattr (entr, '_sens', [])
	for n, s in enumerate (senss):
	    fmt.extend (sens (s, kanjs, rdngs, n+1, entr.src))
	if fmt and label: fmt[0:0] = [label]
	return fmt

def kanj (k, n=None):
	KW = jdb.KW
	kinf = [KW.KINF[x.kw].kw for x in getattr (k,'_inf',[])]
	kinf.sort()
	freq = jdb.freq2txts (getattr (k,'_freq',[]))
	kwds = ",".join (kinf + jdb.rmdups (freq)[0])
	if kwds: kwds = "[" + kwds + "]"
	return "%s.%s%s" % (k.kanj, k.txt, kwds)

def rdng (r, k, n=None):
	KW = jdb.KW
	restr = ""
	if hasattr (r, '_restr'):
	    restr = ','.join (restrtxts (r._restr, k, '_restr'))
	if restr: restr = "(%s)" % restr
	rinf = [KW.RINF[x.kw].kw for x in getattr (r,'_inf',[])]
	rinf.sort()
	freq = jdb.freq2txts (getattr (r,'_freq',[]))
	kwds = ",".join (rinf + jdb.rmdups (freq)[0])
	if kwds: kwds = "[" + kwds + "]"
	return "%s.%s%s%s" % (r.rdng, r.txt, restr, kwds)

def sens (s, kanj, rdng, n=None, entrcorp=None):
	KW = jdb.KW;  fmt = []
	  # Part-of-speech, misc keywords, field...
	pos = ",".join([KW.POS[p.kw].kw for p in getattr (s,'_pos',[])])
	if pos: pos = "[" + pos + "]"
	misc = ",".join([KW.MISC[p.kw].kw for p in getattr (s,'_misc',[])])
	if misc: misc = "[" + misc + "]"
	fld = ", ".join([KW.FLD[p.kw].descr for p in getattr (s,'_fld',[])])
	if fld: fld = "{%s term}" % fld
	  # Restrictions... 
	sr = restrtxts (getattr (s,'_stagr',[]), rdng, '_stagr')
	sk = restrtxts (getattr (s,'_stagk',[]), kanj, '_stagk')
	stag = ""
	if sr or sk: stag = "(%s only)" % ", ".join (sk + sr)

	_lsrc = _dial = ''
	if hasattr(s,'_lsrc') and s._lsrc: 
	    _lsrc = ("Source:"  + ",".join([lsrc(x) for x in s._lsrc]))
	if hasattr(s,'_dial') and s._dial: 
	    _dial = ("Dialect:" + ",".join([KW.DIAL[x.kw].kw for x in s._dial])) 

	fmt.append ("%d. %s" % (getattr(s,'sens',n), ', '.join(
				[x for x in (stag, pos, misc, fld, _dial, _lsrc) if x])))
	if hasattr(s,'notes') and s.notes: fmt.append (u"  \u00AB%s\u00BB" % s.notes)

	  # Now print the glosses...
	for n, g in enumerate (getattr (s,'_gloss',[])):
	    fmt.append (gloss (g, n+1))

	  # Forward Cross-refs.
	if hasattr(s, '_xref'): 
	    fmt.extend (xrefs (s._xref, "Cross references:", False, entrcorp))

	  # Reverse Cross-refs.
	if hasattr(s, '_xrer'): 
	    fmt.extend (xrefs (s._xrer, "Reverse references:", True, entrcorp))

	  # Unresolved Cross-refs.
	if hasattr (s, '_xrslv'):
	    fmt.extend (xrslvs (s._xrslv, "Unresolved references:"))

	return fmt

def gloss (g, n=None):
	KW = jdb.KW
	kws = []
	if g.ginf != KW.GINF['equ'].id: kws.append (KW.GINF[g.ginf].kw)
	if g.lang != KW.LANG['eng'].id: kws.append (KW.LANG[g.lang].kw)
	kwstr = ('[%s] ' % ','.join(kws)) if kws else ''
	fmt = "  %d. %s%s" % (getattr (g, 'gloss', n), kwstr, g.txt)
	return fmt

def char (entr):
	fmt = [] 
	c = getattr (entr, 'chr', None)
	if not c: return fmt
	fmt.extend (chr (c))
	fmt.extend (cinf (c._cinf))
	fmt.extend (encodings ([c.chr]))
	return fmt

def lsrc (x):
	KW = jdb.KW
	lang = KW.LANG[x.lang].kw
	if lang == 'eng': lang = ''
	flgs = [];  f = '';  colon = ''
	if x.part: flgs.append ('p')
	if x.wasei: flgs.append ('w')
	if flgs: f = '(' + ','.join(flgs) + ')'
	if lang or f: colon = ':'
	if not x.txt and not f and not lang: lang = "eng:"
	fmt = lang + f + colon + x.txt
	return fmt

def xrefs (xrefs, sep=None, rev=False, entrcorp=None):
	fmt = [];  sep_done = False
	for x in xrefs:

	    txt = xref (x, rev, entrcorp)
	    if txt is None: continue

	      # Print a separator line, the first time round the loop.
	      # The seperator text is passed by the caller because 
	      # it depends on whether we are doing forward or reverse
	      # cross-refs.

	    if sep and not sep_done: 
		fmt.append ('  ' + sep)
		sep_done = True

	      # Print the xref info.

	    fmt.append ('    %s' % txt)
	return fmt

def xref (xref, rev=False, entrcorp=None):
	KW = jdb.KW
	if not getattr (xref, 'SEQ', True): return None
	if rev: eattr,sattr = 'entr','sens'
	else: eattr,sattr = 'xentr','xsens'
	eidtxt = str(getattr (xref, eattr))
	snum = getattr (xref, sattr)
	stxt = '[' + str(snum) + ']'
	glosses = '';  kr = []; seqtxt = ''; corp = None
	targ = getattr (xref, 'TARG', None)
	if targ:
	    seqtxt = str (targ.seq)
	    corp = targ.src
	    if not rev:
	          # If this is a normal (forward) xref, display
		  # the kanji and reading given in the xref.
		i = getattr (xref, 'kanj', None)
		if i: kr.append (targ._kanj[i-1].txt)
		i = getattr (xref, 'rdng', None)
		if i: kr.append (targ._rdng[i-1].txt)
	    else:
	          # This is a reverse xref so we don't know what
		  # kanji and reading to use when displaying the
		  # xref's target.  So just use the first of each.
	        if targ._kanj: kr.append (targ._kanj[0].txt)
	        if targ._rdng: kr.append (targ._rdng[0].txt)
	    if len(targ._sens) == 1: stxt = ''
	    glosses = ' ' + '; '.join([x.txt for x in targ._sens[snum-1]._gloss])
	t = (KW.XREF[xref.typ].kw).capitalize() + ': '
	corp = '' if (entrcorp == corp or corp is None) else (KW.SRC[corp].kw + ' ')
	enum = "%s%s[%s] " % (corp, seqtxt, eidtxt)
	return t + enum + u'\u30fb'.join(kr) + stxt + glosses

def xrslvs (xr, sep=None):
	fmt = [];  sep_done = False
	for x in xr:
	      # Print a separator line, the first time round the loop.
	      # The seperator text is passed by the caller because 
	      # it depends on whether we are doing forward or reverse
	      # cross-refs.
	    if sep and not sep_done: 
		fmt.append ('  ' + sep)
		sep_done = True
	      # Print the xref info.
	    fmt.append ('    %s' % xrslv (x))
	return fmt

def xrslv (xr):
	KW = jdb.KW
	k = getattr (xr, 'ktxt', '') or '' 
	r = getattr (xr, 'rtxt', '') or '' 
	kr = k + (u'\u30FB' if k and r else '') + r
	t = (KW.XREF[xr.typ].kw).capitalize() + ': '
	return t + kr

def audio (entr, label="Audio: "):
	fmt = [];  hdr = False
	a = getattr (entr, '_snd', [])
	if a and label and not hdr: 
	    fmt.append (label);  hdr = True
	if a: fmt.append (snd (a, None))
	for r in getattr (entr, '_rdng', []):
	    a = getattr (r, '_snd', [])
	    if a and label and not hdr:
		fmt.append (label);  hdr = True
	    if a: fmt.append (snd (a, r.txt))
	return fmt

def snd (snd_list, rtxt=None):
	fmt = ", ".join ([str(x.snd) for x in snd_list]) 
	if rtxt: fmt =  "(%s): %s" (rtxt, fmt)
	return fmt

def hists (entr, label="History: "):
	KW = jdb.KW;  fmt = []
	for n, h in enumerate (getattr (entr, '_hist', [])):
	    stat = getattr (h, 'stat', '')
	    if stat: stat = KW.STAT[stat].kw
	    unap = '*' if getattr (h, 'unap', '') else ''
	    email =  ("<%s>" % h.email) if h.email else ''
	    fmt.append ("%d. %s%s %s %s%s" \
		    % (n+1, stat, unap, h.dt, h.name or '', email))
	    if h.notes: fmt.extend (["  Comments:", indent (h.notes, 4)])
	    if h.refs:  fmt.extend (["  Refs:", indent (h.refs, 4)])
	    if h.diff:  fmt.extend (["  Diff:", indent (h.diff, 4)])
	if fmt and label: fmt[0:0] = [label]
	return fmt

def entrhdr (entr):
	KW = jdb.KW
	id   = getattr (entr, 'id',   '')
	seq  = getattr (entr, 'seq',  '')
	src  = getattr (entr, 'src',  '')
	if src: src = KW.SRC[src].kw
	stat = getattr (entr, 'stat', '')
	if stat: stat = KW.STAT[stat].kw
	unap = '(pend)' if getattr (entr, 'unap', '') else ''
	idtxt = (" {%s}" % id) if id is not None else ''
	txt = "%s %s %s%s%s" % (src, seq, stat, unap, idtxt)
	return txt

def entrrec (entr, label="Entry: "):
	fmt = [label + entrhdr (entr)]
	if entr.srcnote: fmt.append ("SrcNote: " + entr.srcnote)
	if entr.notes: fmt.append ("Note: " + entr.notes)
	grpstxt = grps (entr, label="Group(s): ")
	if grpstxt: fmt.append (grpstxt)
	return fmt

def indent (s, n):
	a = s.split ("\n")
	b = "\n".join ([" "*n + x for x in a])
	return b

def kr (ktxt, rtxt):
	if ktxt and rtxt: txt = u'%s \u3010%s\u3011' % (ktxt, rtxt)
	elif ktxt: txt = ktxt
	elif rtxt: txt = rtxt
	return txt

def restrtxts (restrs, kanjs, attr, quote_func=lambda x:x):

	"""Return list of 'kanj.txt' strings of those 'kanj' items
	without a matching item in 'restrs'.  "Maching" means two
	items with the same value in the attribute named by 'key'.
	if there are no items in 'restrs', and empty list is returned
	(rather than a list of all 'kanji.txt' values).  If every item
	in 'kanj' has a matching item in 'restrs', a one-item list is
        returned containing the string 'noXXX' where XXX is a derived
	from the value of 'key'.

        Each restr item will be passed to function 'quote_func' and 
        the string returned from that function is actually uwed top
        build the return list.

	This function is convenient for getting restriction text from
	an entry for display.  Assuming 'entr' is a jdb entry with a 
        non-empty list of kanji items in entr._kanj and rdng has been
	set to a reading from entr._rdng:

	    restrtxt = ''
	    if hasattr (rdng, '_restr'): 
		restrtxt = ','.join (restrtxts (rdng._restr, 'kanj', entr._kanj))
	    if restrtxt: restrtxt = " (%s)" % restrtxt
	    print rdng.txt + restrtxt

	It can also be used for stagr or stagk restrictions (although 
	one would not normally expect the ['noXXX'] form of output to
	occur in these cases):

	    if hasattr (sens, '_stagr'): 
		restrtxt = ','.join (restrtxts (sens._stagr, 'rdng', entr._rdng))

	If the "noXXX" case does not occur (as it would be expected not
	to), the above is equivalent to:

	    if getattr (s,'_stagr', None):  #Use getattr to filter out empty list case.
	        restrtxt = ','.join ([x.txt for x in 
			              jdb.filt (rdng, ["rdng"], s._stagr, ["rdng"])])
	"""

	if not restrs: return []
	if len(restrs) == len(kanjs): return ['no' + 
		{'_restr':"kanji", '_stagr':"readings", '_stagk':"kanji"}[attr]]
	return [quote_func(x.txt) for x in jdb.restrs2ext_ (restrs, kanjs, attr)]

def chr (c):
	fmt = []; a = []
	fmt.append ("Character %d:" % jdb.uord(c.chr))
	if getattr (c, 'strokes', None): a.append ("strokes: %d" % c.strokes)
	if getattr (c, 'bushu', None): a.append ("radical: %d" % c.strokes)
	if getattr (c, 'freq', None): a.append ("freq: %d" % c.freq)
	if getattr (c, 'grade', None): a.append ("grade: %d" % c.grade)
	if getattr (c, 'jlpt', None): a.append ("jlpt: %d" % c.jlpt)
	if a: fmt.append ("  " + ', '.join (a))
	return fmt

def cinf (f):
	fmt = ['Character info:']
	d = defaultdict (list)
	for r in f: 
	    r.abbr = jdb.KW.CINF[r.kw].kw
	    d[r.abbr].append (r)
	for abbr,rs in sorted (d.items(), key=lambda x:x[0]):
	    fmt.append ("  %s: %s" % (abbr, ', '.join (x.value for x in rs)))
	return fmt

def xunrs (e):
	# Format unresolved xrefs.
	KW = jdb.KW
	fmt = []
	for n, s in enumerate (e._sens):
	    for x in getattr (s, '_xunr', []):
		k = getattr (x,'ktxt','') or ''; r = getattr (x,'rtxt','') or ''
		t = k + (u'\u30FB' if k and r else '') + r
		fmt.append ("    Sense %d: %s %s" % (n+1, KW.XREF[x.typ].kw, t))
	if fmt: fmt.insert (0, '  Unresolved xrefs:')
	return fmt

def grps (e, label="Group(s): "):
	KW = jdb.KW
	s = ','.join (["%s(%s)" % (KW.GRP[x.kw].kw, x.ord)
			 for x in getattr (e, '_grp', [])])
	if s and label: s = label + s
	return s

def encodings (strs):
	fmt = ['Encodings:',
	       '  Unicode: %s' % '; '.join ([ucshex (s) for s in strs])]
	for enc in ('utf-8', 'iso-2022-jp', 'sjis', 'euc-jp'):
	    try:
	        fmt.append ("  %s: %s" % (enc.upper(), '; '.join ([repr (s.encode (enc)) for s in strs])))
	    except UnicodeEncodeError: pass
	return fmt

def ucshex (s):
	 return ' '.join (["%0.4X" % jdb.uord(c) for c in s])
