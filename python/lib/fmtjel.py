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
	txt = re.sub (r'([;\[])', r'\$1', txt)
	return txt

def kanjs (kanjs):
    	txt = u'\uFF1B'.join ([kanj (x) for x in kanjs])
	return txt

def kanj (kanj):
	KW = jdb.KW
	txt = kanj.txt
	inf = [KW.KINF[x.kw].kw for x in getattr(kanj,'_inf',[])]
	freq = [KW.FREQ[x.kw].kw + str(x.value) for x in getattr(kanj,'_freq',[])]
	if inf or freq: txt += '[' + ','.join (inf + freq) + ']'
	return txt

def rdngs (rdngs, kanjs):
	txt = u'\uFF1B'.join ([rdng (x, kanjs) for x in rdngs])
	return txt

def rdng (rdng, kanjs):
	KW = jdb.KW
	txt = rdng.txt
	inf = [KW.RINF[x.kw].kw for x in getattr(rdng,'_inf',[])] 
	freq = [KW.FREQ[x.kw].kw + str(x.value) for x in getattr(rdng,'_freq',[])]
	if inf or freq: txt += '[' + ','.join (inf + freq) + ']'
	restrtxt = fmt.restrtxts (getattr(rdng,'_restr',[]), 'kanj', kanjs)
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
	stagk = fmt.restrtxts (getattr(sens,'_stagk',[]), 'kanj', kanjs)
	stagr = fmt.restrtxts (getattr(sens,'_stagr',[]), 'rdng', rdngs)
	_lsrc = [lsrc(x) for x in getattr(sens,'_lsrc',[])]
	cxrefs = jdb.grp_xrefs (getattr(sens,'_xref',[]))
	_xref = ['[' + xref (x) + ']' for x in cxrefs]

	kwds  = iif (pos,  '[' + ','.join (pos)  + ']', '')
	kwds += iif (misc, '[' + ','.join (misc) + ']', '')
	kwds += iif (fld,  '[' + ','.join (fld)  + ']', '')
	dial  = iif (dial, '[' + ','.join(dial)  + ']', '')
	restr = stagk + stagr
	restr = iif (restr, '[restr=' + '; '.join (restr) + ']', '')
	_lsrc = iif (_lsrc, '[' + ','.join (_lsrc) + ']', '')
	note  = ''
	if getattr(sens,'notes',None): note = '[note=' + qtxt(sens.notes) + ']'

	lastginf = -1;  gloss = []
	for g in getattr (sens, '_gloss', []):
	    ginf = g.ginf;  t = g.txt
	    if ginf != 1:
		esctxt = qtxt (g.txt)
		ginfkw = KW.GINF[ginf].kw
		gloss.append ('[%s=%s]' % (ginfkw, esctxt))
	    else:
		t = escgloss (g.txt)
		if lastginf != 1: gloss.append (t)
		else: gloss[-1] += '; ' + t
	    lastginf = ginf
	lines = []
	lines.append ("[%d]%s%s" % (nsens,kwds,dial))
	if restr: lines.append (restr) 
	if _lsrc: lines.append (_lsrc) 
	if note: lines.append (note) 
	lines.extend (gloss)
	lines.extend (_xref)
	txt = '\n  '.join (lines)
	return txt

def xref (xrefs):
	# If only ordinary xrefs are available, the generated text will
	# be of the form "{id}[n]" where 'id' is the target entry Id and
	# 'n' is the target sense number, or a comma separated list of
	# sense numbers.
	#
	# If .TARG is available, the format will be "Q.c/K/R[n]" where
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
	xref = xrefs[0]
	v = [];  stxt = ''
	if hasattr (xref, 'xentr') and not hasattr (xref, 'TARG'):
	    v.append ('{' + str(xref.xentr) + '}')
	if hasattr (xref, 'xsens'):
	    stxt = '[' + ','.join ([str(x.xsens) for x in xrefs]) + ']'
	targ = getattr (xref, 'TARG', None)
	if targ:
	    a = getattr (xref, 'kanj', None)
	    if a: v.append (targ._kanj[a-1].txt)
	    a = getattr (xref, 'rdng', None)
	    if a: v.append (targ._rdng[a-1].txt)
	    if len(targ._sens) == 1: stxt = ''
	else:
	    if hasattr (xref, 'ktxt'): v.append (xref.ktxt)
	    if hasattr (xref, 'rtxt'): v.append (xref.rtxt)
	txt = '/'.join (v)
	txt = KW.XREF[xref.typ].kw + '=' + txt + stxt
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

def entr (entr):
	# We assume that the caller has called jmdict::add_xrefsums()
	# on entr before calling fmt_entr() (because jel_xref() uses
	# the info added by add_xrefsums()).
	sects = []
	sects.append (fmt.entrhdr (entr))
	k = getattr (entr, '_kanj', [])
	r = getattr (entr, '_rdng', [])
	s = getattr (entr, '_sens', [])
	if k: sects.append (kanjs (k)) 
	if r: sects.append (rdngs (r, k))
	if s: sects.append (senss (s, k, r))
	txt = '\n'.join (sects)
	return txt

def iif (c, a, b):
    if c: return a
    return b
