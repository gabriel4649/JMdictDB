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

import re
import jdb, fmt
from collections import defaultdict

MIDDOT = u'\u30FB'

def qtxt (txt):
	# Enclose txt in quotes if it contains any 
	# non-alphanumeric characters other than "_" or "-". 
	  # Escape existing quotes.
	if txt: 
	    if re.search (r'[^a-zA-Z0-9_-]', txt): 
	 	txt = txt.replace ('"', '\\"')
		txt = '\"' + txt + '\"' 
	else: txt = ''	# If we got a None.
	return txt

def escgloss (txt):
	# Add backslash escape characters in front of any 
	# ";" or "[" characters in txt.  This is the escaping 
	# used in glosses processed by the JEL parser.
	txt = re.sub (r'([;\[])', r'\\\1', txt)
	return txt

def kanjs (kanjs):
    	txt = u'\uFF1B'.join ([kanj (x) for x in kanjs])
	return txt

def kanj (kanj):
	KW = jdb.KW
	txt = kanj.txt
	inf = [KW.KINF[x.kw].kw for x in getattr(kanj,'_inf',[])]
	freq = jdb.freq2txts (getattr(kanj,'_freq',[]))
	if inf or freq: txt += '[' + ','.join (inf + freq) + ']'
	return txt

def rdngs (rdngs, kanjs):
	txt = u'\uFF1B'.join ([rdng (x, kanjs) for x in rdngs])
	return txt

def rdng (rdng, kanjs):
	KW = jdb.KW
	txt = rdng.txt
	inf = [KW.RINF[x.kw].kw for x in getattr(rdng,'_inf',[])] 
	freq = jdb.freq2txts (getattr(rdng,'_freq',[]))
	if inf or freq: txt += '[' + ','.join (inf + freq) + ']'
	restrtxt = fmt.restrtxts (getattr(rdng,'_restr',[]), kanjs, '_restr')
	if restrtxt: txt += '[restr=' + ';'.join(restrtxt) + ']' 
	return txt

def senss (senss, kanjs, rdngs):
	nsens = 0;  stxts = []
	for s in senss:
	    nsens += 1
	    if s.sens and s.sens != nsens: 
		raise ValueError ("Sense %d has \{sens\} value of %s" % (nsens, s.sens))
	    stxts.append (sens (s, kanjs, rdngs, nsens))
	txt = '\n'.join (stxts)
	return txt

def sens (sens, kanjs, rdngs, nsens):
	KW = jdb.KW
	dial = ['dial='+KW.DIAL[x.kw].kw for x in getattr(sens,'_dial',[])] 
	misc = [        KW.MISC[x.kw].kw for x in getattr(sens,'_misc',[])] 
	pos  = [        KW.POS [x.kw].kw for x in getattr(sens,'_pos', [])] 
	fld  = ['fld='+ KW.FLD [x.kw].kw for x in getattr(sens,'_fld', [])] 
	stagk = fmt.restrtxts (getattr(sens,'_stagk',[]), kanjs, '_stagk')
	stagr = fmt.restrtxts (getattr(sens,'_stagr',[]), rdngs, '_stagr')
	_lsrc = [lsrc(x) for x in getattr(sens,'_lsrc',[])]

	_xref =  ['[' + xref (x)  + ']' for x in getattr (sens, '_xref', []) 
					  if getattr (x, 'SEQ', None) is not False
					     and getattr (x, '_xsens', None)!=[]]
	_xrslv = ['[' + xrslv (x) + ']' for x in getattr (sens, '_xrslv', [])]

	kwds  = iif (pos,  '[' + ','.join (pos)  + ']', '')
	kwds += iif (misc, '[' + ','.join (misc) + ']', '')
	kwds += iif (fld,  '[' + ','.join (fld)  + ']', '')
	dial  = iif (dial, '[' + ','.join(dial)  + ']', '')
	restr = stagk + stagr
	restr = iif (restr, '[restr=' + '; '.join (restr) + ']', '')
	_lsrc = iif (_lsrc, '[' + ','.join (_lsrc) + ']', '')
	note  = ''
	if getattr(sens,'notes',None): note = '[note=' + qtxt(sens.notes) + ']'

	lastginf = -1;  gloss = [];  gtxt = []
	for g in getattr (sens, '_gloss', []):
	    kws = []
	    if g.ginf != KW.GINF['equ'].id: kws.append (KW.GINF[g.ginf].kw)
	    if g.lang != KW.LANG['eng'].id: kws.append (KW.LANG[g.lang].kw)
	    kwstr = ('\n  [%s] ' % ','.join(kws)) if kws else ''
	    gtxt.append ('%s%s' % (kwstr, escgloss (g.txt)))
	gloss = ['; '.join (gtxt)]
	lines = []
	lines.append ("[%d]%s%s" % (nsens,kwds,dial))
	if restr: lines.append (restr) 
	if _lsrc: lines.append (_lsrc) 
	if note: lines.append (note) 
	lines.extend (gloss)
	lines.extend (_xref)
	lines.extend (_xrslv)
	txt = '\n  '.join (lines)
	return txt

def xref (x):
	# If only ordinary xrefs are available, the generated text will
	# be of the form "id#[n]" where 'id' is the target entry Id and
	# 'n' is the target sense number, or a comma separated list of
	# sense numbers.
	#
	# If .TARG is available, the format will be "Qc.K.R[n]" where
	# 'Q' is the seq number, 'c' is the corpus name, 'K' and 'R' are
	# the target's
	# kanji and reading texts (either but not both may be absent),
	# and 'n' is the target sense number, or a comma separated list
	# of sense numbers.  If the target entry has only one sense,
	# the "[n]" part is dropped.
	#
	# Note that if output from this function will be parsed to generate
	# a (possibly modified) copy of an entry, augmented xrefs *must*
	# be used to ensure accurate regeneration of the xrefs.  Lacking
	# the reading and kanji texts, the regenerated xrefs will use the 
	# first kanji/reading of the target entry.

	KW = jdb.KW

	#FIXME:
	corpid = 1; kwsrc = KW.SRC;  txt = []
	p = getattr (x, 'SEQ', None)
	if p is False: return None
	elif p: txt = fmt_xref_seq (x, corpid, kwsrc)
	else: txt = fmt_xref_entr (x)
	return txt


def fmt_xref_seq (xref, corpid, kwsrc):
	# Format a group of entries having a common seq number
	# to a single seq-style JEL xref line.
	# xrefs -- A list of augmented xref objects whose target 
	#   entries are assumed to have the same seq number and
	#   the same set of target senses.
	KW = jdb.KW
	corptxt = kwsrc[xref.TARG.src].kw if xref.TARG.src != corpid else ''
	numtxt = str(xref.TARG.seq) + corptxt
	krtxt = fmt_xref_kr (xref)
	return KW.XREF[xref.typ].kw + '=' + numtxt + MIDDOT + krtxt

def fmt_xref_entr (xref):
	KW = jdb.KW
	krtxt = fmt_xref_kr (xref)
	numtxt = str(xref.xentr) + "#" 
	return KW.XREF[xref.typ].kw + '=' + numtxt + MIDDOT + krtxt

def fmt_xref_kr (xref):
	snum_or_slist = getattr (xref, '_xsens', xref.xsens)
	if snum_or_slist is None: ts = ''
	elif hasattr (snum_or_slist, '__iter__'):
	    ts = '[' + ','.join ((str(x) for x in snum_or_slist)) + ']'
	else: ts = '[%d]' % snum_or_slist
	t = getattr (xref, 'TARG', None)
	if t:
	    kt = (getattr (t, '_kanj', [])[xref.kanj-1]).txt if getattr (xref, 'kanj', None) else ''
	    rt = (getattr (t, '_rdng', [])[xref.rdng-1]).txt if getattr (xref, 'rdng', None) else ''
	else:
	    kt = getattr (xref, 'ktxt', '') or ''
	    rt = getattr (xref, 'rtxt', '') or ''
	txt = kt + (MIDDOT if kt and rt else '') + rt + ts
	return txt

def xrslv (xr):
	KW = jdb.KW
	v = []; 
	ts = getattr (xr, 'tsens', '') or ''
	if ts: ts  = '[%d]' % ts
	kt = getattr (xr, 'ktxt', '') or ''
	rt = getattr (xr, 'rtxt', '') or ''
	txt = KW.XREF[xr.typ].kw + '=' + kt + (u'\u30FB' if kt and rt else '') + rt + ts
	return txt

def lsrc (lsrc):
	KW = jdb.KW
	lang = KW.LANG[lsrc.lang].kw
	p = '';  w = ''
	if lsrc.part: p = 'p'
	if lsrc.wasei: w = 'w'
	if p and w: t = p + ',' + w
	else: t = p or w
	if t: t = '/' + t
	return 'lsrc=' + lang + t + ':' + (qtxt(lsrc.txt))

def entr (entr, nohdr=False):
	# We assume that the caller has called jelfmt::markup_xrefs()
	# on entr before calling fmt_entr() (because jel_xref() uses
	# the info added by add_xrefsums()).
	sects = []
	if not nohdr: sects.append (fmt.entrhdr (entr))
	k = getattr (entr, '_kanj', [])
	r = getattr (entr, '_rdng', [])
	s = getattr (entr, '_sens', [])
	sects.append (kanjs (k)) 
	sects.append (rdngs (r, k))
	sects.append (senss (s, k, r))
	txt = '\n'.join (sects)
	return txt

def markup_entr_xrefs (cur, entries):
	all_xrefs = []
	for e in entries:
	    for s in e._sens: all_xrefs.extend (s._xref)
	markto_xrefs (cur, )

def markup_xrefs (cur, xrefs):
	jdb.add_xsens_lists (xrefs)
	jdb.mark_seq_xrefs (cur, xrefs)

def iif (c, a, b):
    if c: return a
    return b

def main():
	cur = jdb.dbOpen ('jmnew')
	entrs, data = jdb.entrList (cur, [542], ret_tuple=True)
	jdb.augment_xrefs (cur, data['xref'])
	jdb.augment_xrefs (cur, data['xref'], rev=1)
	markup_xrefs (cur, data['xref'])
	for e in entrs:
	    txt = entr (e)
	    print txt

if __name__ == '__main__': main ()
