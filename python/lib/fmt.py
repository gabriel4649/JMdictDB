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

__version__ = ('$Revision$'[11:-2],
	       '$Date$'[7:-11]);

from collections import defaultdict
import jdb

def entr (entr):
	c = getattr (entr, 'chr', None)	# 'c' will be non-None for kanji entries.
	fmt = "Entry: " + entrhdr (entr)
	if getattr (entr, 'srcnote', None):
	    fmt += "\nSrcnote: %s" % entr.srcnote
	if getattr (entr, 'notes', None):
	    fmt += "\nNotes: %s" % entr.notes
	if c:
	    kanjs = []
	    ktxt = c.chr
	else:
	    kanjs = getattr (entr, '_kanj', [])
	    ktxt = " ".join([kanj(x) for x in kanjs])
	rdngs = getattr (entr, '_rdng', [])
	rtxt = " ".join([rdng(x, kanjs) for x in rdngs])
	if ktxt: fmt += "\nKanji: %s" % ktxt
	fmt += "\nReading: %s" % rtxt

	  # Print the sense information.
	emap = {} #dict ([(x.eid, x) for x in entr._erefs])

	for n, s in enumerate (getattr (entr, '_sens', [])):
	    fmt += "\n%s" % sens (s, kanjs, rdngs, n+1)

	hdr = False;
	a = getattr (entr, '_snd', [])
	if a and not hdr: 
	    fmt += "\nAudio: ";  hdr = True
	if a: fmt += snd (a, None)
	for r in rdngs:
	    a = getattr (r, '_snd', [])
	    if a and not hdr:
		fmt += "\nAudio: ";  hdr = True
	    if a: fmt += snd (a, r.txt)

	if c: 
	    fmt += "\n" + chr (c)
	    fmt += "\n" + cinf (c._cinf)
	    fmt += "\n" + encodings ([c.chr])

	if hasattr (entr, '_hist'): fmt += hist (entr._hist);
	return fmt

def kanj (k, n=None):
	KW = jdb.KW
	kinf = [KW.KINF[x.kw].kw for x in getattr (k,'_inf',[])]
	freq = [KW.FREQ[x.kw].kw+str(x.value) for x in getattr (k,'_freq',[])]
	kwds = ",".join (kinf + jdb.rmdups (freq)[0])
	if kwds: kwds = "[" + kwds + "]"
	return "%s.%s%s" % (k.kanj, k.txt, kwds)

def rdng (r, k, n=None):
	KW = jdb.KW
	restr = ""
	if hasattr (r, '_restr'):
	    restr = ','.join (restrtxts (r._restr, 'kanj', k))
	if restr: restr = "(%s)" % restr
	rinf = [KW.RINF[x.kw].kw for x in getattr (r,'_inf',[])]
	freq = [KW.FREQ[x.kw].kw+str(x.value) for x in getattr(r,'_freq',[])]
	kwds = ",".join (rinf + jdb.rmdups (freq)[0])
	if kwds: kwds = "[" + kwds + "]"
	return "%s.%s%s%s" % (r.rdng, r.txt, restr, kwds)

def sens (s, kanj, rdng, n=None):
	KW = jdb.KW
	  # Part-of-speech, misc keywords, field...
	pos = ",".join([KW.POS[p.kw].kw for p in getattr (s,'_pos',[])])
	if pos: pos = "[" + pos + "]"
	misc = ",".join([KW.MISC[p.kw].kw for p in getattr (s,'_misc',[])])
	if misc: misc = "[" + misc + "]"
	fld = ", ".join([KW.FLD[p.kw].descr for p in getattr (s,'_fld',[])])
	if fld: fld = "{%s term}" % fld
	  # Restrictions... 
	if not getattr (s,'_stagr', None): sr = []
	else: sr = jdb.filt (rdng, ["rdng"], s._stagr, ["rdng"])
	if not getattr (s,'_stagk', None): sk = []
	else: sk = jdb.filt (kanj, ["kanj"], s._stagk, ["kanj"])
	stag = ""
	if sr or sk: 
	    stag = "(%s only)" % ", ".join([x.txt for x in sk+sr])

	_lsrc = _dial = ''
	if hasattr(s,'_lsrc') and s._lsrc: 
	    _lsrc = ("Source:"  + ",".join([lsrc(x) for x in s._lsrc]))
	if hasattr(s,'_dial') and s._dial: 
	    _dial = ("Dialect:" + ",".join([KW.DIAL[x.kw].kw for x in s._dial])) 

	fmt = "%d. %s" % (getattr(s,'sens',n), ', '.join(
				[x for x in (stag, pos, misc, fld, _dial, _lsrc) if x]))
	if hasattr(s,'notes') and s.notes: fmt += "\n  <<%s>>" % s.notes

	  # Now print the glosses...
	for n, g in enumerate (getattr (s,'_gloss',[])):
	    fmt += "\n" + gloss (g, n+1)

	  # Forward Cross-refs.
	    
	if hasattr(s, '_xref'): 
	    fmt += xrefs (s._xref, "Cross references:")

	  # Reverse Cross-refs.
	if hasattr(s, '_xrer'): 
	    fmt += xrefs (s._xrer, "Reverse references:", True)

	return fmt

def gloss (g, n=None):
	KW = jdb.KW
	lang = KW.LANG[g.lang].kw
	if lang == 'eng': lang = ""
	if lang: lang = "%s: " % lang
	ginf = '' if g.ginf == 1 else '[%s]' % KW.GINF[g.ginf].kw
	fmt = "  %d. %s%s%s" % (getattr (g, 'gloss', n) ,ginf, lang, g.txt)
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

def xrefs (xrefs, sep=None, rev=False):
	fmtstr = '';  sep_done = False
	for x in xrefs:

	      # Print a separator line, the first time round the loop.
	      # The seperator text is passed by the caller because 
	      # it depends on whether we are doing forward or reverse
	      # cross-refs.

	    if sep and not sep_done: 
		fmtstr += '\n  ' + sep
		sep_done = True

	      # Print the xref info.

	    fmtstr += '\n    %s' % xref (x, rev)
	return fmtstr

def xref (xref, rev=False):
	KW = jdb.KW
	if rev: eattr,sattr = 'entr','sens'
	else: eattr,sattr = 'xentr','xsens'
	v = [str(getattr (xref, eattr))]
	snum = getattr (xref, sattr)
	stxt = '[' + str(snum) + ']'
	glosses = ''
	targ = getattr (xref, 'TARG', None)
	if targ:
	    i = getattr (xref, 'kanj', None)
	    if i: v.append (targ._kanj[i-1].txt)
	    i = getattr (xref, 'rdng', None)
	    if i: v.append (targ._rdng[i-1].txt)
	    if len(targ._sens) == 1: stxt = ''
	    glosses = ' ' + '; '.join([x.txt for x in targ._sens[snum-1]._gloss])
	t = (KW.XREF[xref.typ].kw).capitalize() + ': '
	return t + '/'.join(v) + stxt + glosses

def snd (snd_list, rtxt=None):
	fmt = ", ".join ([str(x.snd) for x in snd_list]) 
	if rtxt: fmt =  "(%s): %s" (rtxt, fmt)
	return fmt

def hist (hists):
	KW = jdb.KW
	if not hists: return ''
	fmt = "\nHistory:" 
	for h in hists:
	    stat = getattr (h, 'stat', '')
	    if stat: stat = KW.STAT[stat].kw
	    unap = '*' if getattr (h, 'unap', '') else ''
	    email =  ("<%s>" % h.email) if h.email else ''
	    fmt += "\n  %s%s %s %s<%s>" \
		    % (stat, unap, h.dt, h.name or '', email)
	    if h.notes: fmt += "\n  Comments:\n" + indent (h.notes, 4)
	    if h.refs: fmt += "\n  Refs:\n" + indent (h.refs, 4)
	    if h.diff:  fmt += "\n  Diff:\n" + indent (h.notes, 4)
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
	fmt = "%s %s %s%s {%s}" % (src, seq, stat, unap, id)
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

def restrtxts (restrs, key, kanjs,
	       english={'kanj':'kanji','sens':'senses','rdng':'readings'}):

	"""Return list of 'kanj.txt' strings of those 'kanj' items
	without a matching item in 'restrs'.  "Maching" means two
	items with the same value in the attribute named by 'key'.
	if there are no items in 'restrs', and empty list is returned
	(rather than a list of all 'kanji.txt' values).  If every item
	in 'kanj' has a matching item in 'restrs', a one-item list is
        returned containing the string 'noXXX' where XXX is a derived
	from the value of 'key'.

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
	if len(restrs) == len(kanjs):  return ['no' + english.get(key,key)]
	return [x.txt for x in jdb.filt (kanjs, [key], restrs, [key])]

def chr (c):
	fmt = []; a = []
	fmt.append ("Character %d:" % jdb.uord(c.chr))
	if getattr (c, 'strokes', None): a.append ("strokes: %d" % c.strokes)
	if getattr (c, 'bushu', None): a.append ("radical: %d" % c.strokes)
	if getattr (c, 'freq', None): a.append ("freq: %d" % c.freq)
	if getattr (c, 'grade', None): a.append ("grade: %d" % c.grade)
	if getattr (c, 'jlpt', None): a.append ("jplt: %d" % c.jlpt)
	if a: fmt.append ("  " + ', '.join (a))
	return '\n'.join (fmt)

def cinf (f):
	fmt = ['Character info:']
	d = defaultdict (list)
	for r in f: 
	    r.abbr = jdb.KW.CINF[r.kw].kw
	    d[r.abbr].append (r)
	for abbr,rs in sorted (d.items(), key=lambda x:x[0]):
	    fmt.append ("  %s: %s" % (abbr, ', '.join (x.value for x in rs)))
	return '\n'.join (fmt)

def encodings (strs):
	fmt = ['Encodings:',
	       '  Unicode: %s' % '; '.join ([ucshex (s) for s in strs])]
	for enc in ('utf-8', 'iso-2022-jp', 'sjis', 'euc-jp'):
	    fmt.append ("  %s: %s" % (enc.upper(), '; '.join ([repr (s.encode (enc)) for s in strs])))
	return '\n'.join (fmt)

def ucshex (s):
	 return ' '.join (["%0.4X" % jdb.uord(c) for c in s])

