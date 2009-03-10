﻿#######################################################################
#  This file is part of JMdictDB. 
#  Copyright (c) 2009 Stuart McGraw 
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
	       '$Date$'[7:-11])

# Parse Edict2 text into an jmdictdb entry object.  Note that 
# edict2 is not a serialization format: there is information 
# that is not unambiguously representable in edict2 and will 
# either lost or misrepresented when and jmdict object is 
# is formatted to edict2 and then parsed back into an object.
#
# WARNING -- This module is currently incomplete.
# TO DO:
#	Need to convert xrefs/ants into an _xresolv list a'la jmxml.py.
#	Add check/warning message for non-keb, non-reb compatible strings.
#	lsource info currently ignored.
#	Resurect old lit/trans gloss parser and apply here.
#	
import sys, re, collections, pdb
import jdb
from objects import *
from jelparse import lookup_tag
from iso639maps import iso639_1_to_2

Lineno = None

def entr (text):
	fmap = collections.defaultdict (lambda:([list(),list()]))
	krtxt, x, stxt = text.partition ('/')
	kanjs, rdngs = parse_jppart (krtxt.rstrip(), fmap)
	entr = Entr (_kanj=kanjs, _rdng=rdngs)
	sens = parse_spart (stxt.lstrip(), entr, fmap)
	errs = jdb.make_freq_objs (fmap, entr)
	for err in errs:
	    errtyp, r, k, kw, val = err
	    warn ("%s freq tag(s) %s%s in %s%s%s" 
		  % (errtyp, KW.FREQ[kw].kw, val, k or '',
		    u'\u30FB' if k and r else '', r or ''))
	return entr

def parse_jppart (krtxt, fmap):
	# 'krtxt', the jp part of an Edict2 line, may look like either
	# "K [R]" or just "R".  (It may also have trailing whitespace.)
	# FIXME? We split K and R on whitespace making the brackets
	# around R optional.  Could also reasonably split on the "["
	# making the whitespace between K and [R] optional (and also
	# permitting whitespace within K and R).  Note that we cannot
	# easilty use jstr_reb(), et.al. tests here because the reading
	# text can contain non-reb text like "[", ";", "(", etc.
	# To write an edict2 line that is has kanji but no reading,
	# use "[]" for the reading.

	ktxt, x, rtxt = krtxt.partition(' ')
	if not rtxt:
	    rtxt, ktxt = ktxt, ''
	if ktxt: kanjs = parse_krpart (ktxt.strip(), fmap)
	else: kanjs = []
	if rtxt: rdngs = parse_krpart (rtxt.strip('[] '), fmap, kanjs)
	else: rdngs = []
	return kanjs, rdngs

def parse_krpart (krtext, fmap, kanjs=None):
	# Parse the edict2 text section 'krtext', interpreting it as a 
	# kanji section if 'kanjs' is None or a reading segment is 'kanjs'
	# is not None.  'fmap' is a dict in which we accumulate freq tags
	# for later processing.  If we are parsing a reading section, 
	# the caller needs to supply 'kanjs', a list of Kanj objects
	# resulting from the earlier parse of the kanji section.  These
	# are needed to resolve any "restr" items in the readings.
	#
	# Whether paring a kanji section or a reading section, the section
	# is expected to consist of number of kanji or reading words
	# separated by ";".  Each word consists of the kanji or kana text,
	# followed by zero or more parenthesized expressions.  Each of
	# these may be: 1) A "P" character, 2) In the case of readings, a
	# ";" separated list of reading restrictions where each restriction
	# matched a kanji text string that occured in the kanji section,
	# or 3) a KINF or RINF keyword.
	#
	# parse_krpart() return a list of Kanj of Rdng objects fully
	# populated with the given restrictions and K/R/INF keyword
	# objects attached.

	if not krtext: return []
	exps = []; pexps = []; krlist = []; krobjs = []; MARKER = u'\u1000'
	  # We are going to get each individual kanji or reading word 
	  # by splitting the string on ';' characters.  But because semi-
	  # colons can also occur in restr part or readings, will first
	  # extract all the parenthesised substrings (which will contain
	  # the the extra ";"s and replace them with a marker character
	  # that allows us to restore them after the ";" split. 
	  #
	  # Break the text up into a list, 'exp', of substrings where 
	  # each substring is unparenthesised text or parenthesised text.  
	  # Copy of the parenthesised substrings to a separate list, 'pexp',
	  # and in 'exp', replace with the marker character.
	parts = re.split (r'(\([^)]*\))', krtext)
	for p in parts:
	    if not p: continue
	    if p[0] == '(': 
		pexps.append(p)
		p = MARKER
	    exps.append (p)
	  # Put the string back together again; it will now have the marker
	  # characters replacing the parenthesised strings.  Split on ';' 
	  # to get the individual kanji or reading items in list 'parts'.
	parts = (''.join (exps)).split (';')
	  # For each part, look for marker characters and replace them with
	  # the parenthesised texts that were extracted earlier.
	pcnt = 0; m = 0
	for p in parts:
	      # Use re.split with the marker character in parens so that 
	      # the marker characters will be in to result list.
	    plst = re.split ('('+MARKER+')', p)
	    for n, q in enumerate (plst):
	        if q == MARKER:
		    plst[n] = pexps[m]
		    m += 1
	      # Put the string back together again.
	    krlist.append (''.join (plst))

	  # Parse each kanji or reading item idividually.
	for kr in krlist:
	    krobj = parse_kritem (kr, fmap, kanjs)
	    if krobj: krobjs.append (krobj)
	return krobjs

def parse_kritem (text, fmap, kanjs=None):
	# 'text' is a single kanji or reading item.
	a = text.split ('(')
	krtxt = a.pop (0)
	tags = [x.strip ('() ') for x in a]
	ptag = 'P' in tags
	if ptag:    
	    tags.remove ('P')
	    if 'P' in tags: warn ('Duplicate "P" tag ignored')	
	if kanjs is None:
	    krobj = parse_kitem (krtxt, tags, fmap)
	else:
	    krobj = parse_ritem (krtxt, tags, fmap, kanjs)
	if ptag:
	    add_spec1 (fmap, krobj, 'k' if kanjs is None else 'r')
	return krobj

def parse_ritem (rtxt, tags, fmap, kanjs):
	if not jdb.jstr_reb (rtxt):
	    warn ('Reading field not kana: "%s".' % rtxt)
	rdng = Rdng (txt=rtxt)
	for tag in tags:
	    if not tag: continue
	    if not jdb.jstr_gloss (tag):
		parse_restrs (rdng, tag, kanjs)
		continue
	    t = lookup_tag (tag, ['RINF','FREQ'])
	    if t: 
		tagtyp, tagval = t[0]
		if   tagtyp == 'RINF': rdng._inf.append (Rinf(kw=tagval)) 
		elif tagtyp == 'FREQ': fmap[t[1:]][0].append (rdng)
	    else:
		warn ('Unknown tag "%s" on reading "%s" ignored' % (tag, rtxt))
	
	return rdng 

def parse_kitem (ktxt, tags, fmap):
	if not jdb.jstr_keb (ktxt):
	    warn ('Kanji field not kanji: "%s".' % ktxt)
	kanj = Kanj (txt=ktxt)
	for tag in tags:
	    if not tag: continue
	    t = lookup_tag (tag, ['KINF','FREQ'])
	    if t: 
		tagtyp, tagval = t[0]
		if   tagtyp == 'KINF': kanj._inf.append (Kinf(kw=tagval)) 
		elif tagtyp == 'FREQ': fmap[t[1:]][1].append (kanj)
	    else:
		warn ('Unknown tag "%s" on kanji "%s" ignored' % (tag, ktxt))
	return kanj 

def parse_restrs (rdng, tag, kanjs):
	restrtxts = [x.strip(' ') for x in tag.split (';')]
	errs = []
	jdb.txt2restr (restrtxts, rdng, kanjs, '_restr', errs)
	for err in  errs:
	    warn ('Reading restriction "%s" doesn\'t match any kanji' % err)

def add_spec1 (fmap, krobj, typ):
	freq = (jdb.KW.FREQ['spec'].id, 1)
	if   typ == 'r': listidx = 0
	elif typ == 'k': listidx = 1
	else: raise ValueError (typ)
	fmap[freq][listidx].append (krobj)

def parse_spart (txt, entr, fmap):
	kanjs = getattr (entr, '_kanj', [])
	rdngs = getattr (entr, '_rdng', [])
	gtxts = txt.split('/')
	senslist = []
	for n, gtxt in enumerate (gtxts):
	    new_sense = (n == 0)
	    front_opts_list = []
	    gtxt = gtxt.strip()
	    if gtxt == '': continue
	    elif gtxt == '(P)': 
		fklist, frlist = fmap[(jdb.KW.FREQ['spec'].id,1)]
		  # If a "spec1" has already been applied to any kanji or
		  # reading, this sense (P) tag is redundent and can be ignored.
		if fklist or frlist: continue
		if len(kanjs) > 1  or len(rdngs) > 1:
		      # If there is more than 1 kanji or reading, then at least
		      # one of them should have a "spec1" tag applied as a result
		      # of a required explicit kanji or reading P tag.
		    warn ("P tag in sense, but not in kanji or readings")
		  # If there is only one reading and/or kanj a P tag on them is
		  # not required so we assign the coresponding "spec1" tag on
		  # them here.  (Also assign if multiple kanji/readings since
		  # warning has been given.)
		if kanjs: add_spec1 (fmap, kanjs[0], "k")
		if rdngs: add_spec1 (fmap, rdngs[0], "r")
		continue
	    elif gtxt.startswith ('EntrL'):
		entr.seq = int (gtxt[5:])
	 	continue

	      # The following regex will match an arbitrary number
	      # of sequential parenthesised texts, optionally followed
	      # by one curly-bracketed one, at the start of a text string.
	      # Note that although most such tags occur  ob the first
	      # gloss of a sense, that is not a requirement, we will
	      # apply tags to the current sense regardles of the gloss
	      # it occurs with.
	    mo = re.match (r'(\([^)]*\)\s*)+\s*({[^}]*})?\s*', gtxt)
	    if mo:
		front_opts_txt = mo.group()
		  # FIXME: We throw away info on whether a tag occured in
		  #  parens or brackets, which implies that we must rely 
		  #  on FLD tag values being distinct from other tags.
		front_opts_list = re.split (r'[)}]\s*[({]', front_opts_txt.strip('(){} '))
		  # Strip the leading paren'd text off 'gtxt'.
		gtxt = gtxt[mo.end():]

		if not new_sense: 
		      # See if there is a sense number in the paren'd
		      # options.  If so, this gloss is the first one of
		      # a new sense.  No need for this check if n==0 
		      # since the first gloss is always a new sense.
		    for x in front_opts_list:
			if x.isdigit():  new_sense = True
		if not new_sense:
		      # We have a gloss that is not the first of a sense but
		      # that has parenthesised leading text.  Put the text back
		      # on the gloss.
		    gtxt = front_opts_txt + gtxt 
		    front_opts_list = []
	    if new_sense:
		glosses = []
		senslist.append ((front_opts_list, glosses))
	    if gtxt: glosses.append (gtxt)
	senss = parse_senses (senslist, kanjs, rdngs)
	entr._sens = senss

def parse_senses (senslist, kanjs, rdngs):
	# senslist -- List of senses where each sense is a 2-tuple
	#   consisting of:
	#	[0] -- A list of the leading parenthesised texts extracted
	#	     from the first gloss.
	#	[1] -- A list of gloss texts.
	#   kanjs -- List of Kanj objects constructed from the parsed kanji field.
	#   rdngs -- List of Rdng objects constructed from the parsed readings field.

	sense_list = []
	prev_pos = None
	for snum0, (tags, glosses) in enumerate (senslist):
	    sens = process_sense (tags, glosses, snum0+1, prev_pos, kanjs, rdngs)
	    if not sens: continue
	    prev_pos = getattr (sens, '_pos', [])
	    sense_list.append (sens)
	return sense_list

def process_sense (tags, glosstxts, snum, prev_pos, kanjs, rdngs):
	sens = Sens()
	  # Tags may be (in the order listed):
	  #	POS
	  #	sense_num
	  #	STAG
	  #	see, ant
	  #	MISC
	  #	DIAL
	  #	FLD (I think this comes last (and this edict code
	  # 	      assumes so) but I don't see any entries in the
	  #	      Breen Edict2 file with both DIAL and FLD so
	  #	      can't tell for sure.)
	  #
	  # FIXME? The tag parsing code below does not assume that
	  # different tyopes of tags come in any particular order.
	  # That is, it will be equally happy with "(n)(uk)" or
	  # "(uk)(n)", or "(uk,n)".  It is this way because the 
	  # author is not aware of any documentation of an expected
	  # tag order, and thus presumes that it is likely Edict2
	  # files from other than Jim Breen may have been produced
	  # without much regard to tag order.
	  # Down side to this is that is is difficult to generate
	  # precise error messages because we are never sure what
	  # we should be parsing.  It also assumes that tag values
	  # are unique across all tag types, e.g. there is no "n"
	  # tag in both the POS and MISC domains.

	for tag in tags:
	      # Classify the type of tag...
	    if tag.isdigit(): 				# Sense number.
		  # Don;'t do anything with it other than check
		  # that is what was expected.  There is no check
		  # for duplicates.
		if int (tag) != snum: warn ('Sense number "%s" out of order' % tag)
		continue
	    if tag.lower().startswith ('see') or \
		  tag.lower().startswith ('ant'): 	# XREF
		parse_xrefs (tag, sens)
		continue
	    if tag.endswith (' only'):			# STAG
		parse_stags (tag[:-5], sens, kanjs, rdngs)
		continue
	      # Strip off any trailing ":" (which dialect tags will have) but
	      # change it on a temp variable because we don't know for sure 
	      # that this is a tag yet,
	    if re.match (r'[a-zA-Z0-9,:-]+$', tag): # Could be pos, misc, dial or fld tags.
		failed, pos, misc, fld, dial = parse_tags (tag, sens, snum)
		if not failed:
		    if pos:  sens._pos.extend  (pos)
		    if misc: sens._misc.extend (misc)
		    if fld:  sens._fld.extend  (fld)
		    if dial: sens._dial.extend (dial)
		    continue
		  # If not all the tags were ok, fallthough to following code 
		  # to process as sense note or gloss prefix.
	    if 1:
		if sens.notes:
		      # If we already found a sense note, this put this 
		      # current unidentifiable text back onto the first gloss.
		      # FIXME? May loose whitespace that was in original line.
		      # FIXME: If multiple tags are pushed back onto gloses, 
		      #  they are put back in reversed (wrong) order and white-
		      #  space between then is lost.
		      # FIXME: I believe that at least for JB's edict2 file,
		      #  fields are always in the same order and that s_inf 
		      #  comes before stagr/stagk, see/ant, MISC, DIAL, FLD,
		      #  so if we have seen any of those fields, we can say
		      #  that we are looking at gloss text now.
		    #warn ('note="%s", dup="%s"' % (sens.notes, tag))
		    if len(glosstxts) < 1: glosstxts.append ('')
		    glosstxts[0] = '(' + tag + ') ' + glosstxts[0] 
		else: sens.notes = tag.strip()

	if not sens._pos and prev_pos:
	      # If this sense had no part-of-speech tags, inherit them
	      # from the previous sense, if any.
	      # FIXME: Should make a copy of 'prev_pos' rather than using ref.
	    sens._pos = prev_pos

	for gtxt in glosstxts:
	    glosses = parse_gloss (gtxt, sens)

	return sens

def parse_tags (tagtxt, sens, snum):
	tags = tagtxt.split (',')
	found = failed = 0
	pos=[]; misc=[]; fld=[]; dial=[]
	for tag in tags:
	    tag = tag.strip()
	    if not tag:
		warn ("Empty tag in sense %d.", (snum))
		continue
	    tagx = tag[:-1] if tag[-1] == ':' else tag
	    t = lookup_tag (tagx, ['POS','MISC','DIAL','FLD'])
	    if t:
		typ, val = t[0]
		if len (t) > 1:
		    warn ('Ambiguous tag "%s", interpreting as "%s" but could be "%s"' 
			  % (tag, typ, '","'.join ([x[0] for x in t[1:]])))
		if   typ == 'POS':  pos.append  (Pos  (kw=val))
		elif typ == 'MISC': misc.append (Misc (kw=val))
		elif typ == 'FLD':  fld.append  (Fld  (kw=val))
		elif typ == 'DIAL': dial.append (Dial (kw=val))
		else: raise ValueError (typ)
		found += 1
	    else:
		failed += 1
		# Don't report failed tag lookups because likely
		# we are mistakenly processing a sense note or gloss
		# prefix which will be correctly handled by the caller.  
		#warn ('Unknown sense tag in sense %d: "%s".' % (snum, tag))

	  # Because of the loosy-goosy edict syntax, if there were
	  # erroneous tags, we don't know if they were really erroneous
	  # tags or we were trying to parse a sense note or something.
	  # So return all the information we have and let the caller
	  # decide if she wants to use the valid tags or throw out
	  # everything. 
	return failed, pos, misc, fld, dial

def parse_gloss (gtxt, sens):
	KW = jdb.KW
	  # FIXME? Handle other ginf tags ("fig", "expl", etc) here?
	if gtxt.startswith ("lit:"):
	    gtxt = gtxt[4:].strip()
	    sens._gloss.append (Gloss (txt=gtxt, lang=KW.LANG['eng'].id, 
				       ginf=KW.GINF['lit'].id))
	elif gtxt.endswith (')'):
	    gtxt, ginftuple, lsrclist = extract_lsrc_or_ginf (gtxt)
	    if gtxt:
	        sens._gloss.append (Gloss (txt=gtxt, ginf=KW.GINF['equ'].id,
					   lang=KW.LANG['eng'].id))
	    if ginftuple[0]:
		kwid, txt = ginftuple
	        sens._gloss.append (Gloss (txt=txt, ginf=kwid,
					   lang=KW.LANG['eng'].id))
	    for x in lsrclist:
		lang, wasei, txt = x
		sens._lsrc.append (Lsrc (txt=txt, lang=lang, wasei=wasei))
	else:
	    sens._gloss.append (Gloss (txt=gtxt, ginf=KW.GINF['equ'].id, 
					lang=KW.LANG['eng'].id))
	return

def extract_lsrc_or_ginf (gtxt):
	# This will find lsrc ot ginf descriptions where the text before
	# the colon is a three-letter language code, or "wasei:", or a 
	# ginf tag ("lit:", "fig:", "expl:")
	# We extract only a single clause which must occur at the end
	# of a gloss.
	#
	# Return a 3-tuple:
	#   [0] -- Gloss with lsrc/ginf removed.
	#   [1] -- (None,None) or 2-tuple:
	#	[0] -- GINF keyword id number.
	#	[1] -- Ginf text.
	#   [2] -- List (possibly empty) of 3-tuples:
	#       [0] -- Language id number.
	#       [1] -- True if "wasei".
	#       [2] -- Lsource text.
	# 

	  # The following regex will match a substring like "(ger: xxxx)".  
	  # The "xxxx" part may have parenthesised text but not nested. 
	  # Thus, "eng: foo (on you) dude" will be correctly parsed, but
	  # "eng: (foo (on you)) dude" won't.  Also note that an lsrc
	  # string may contain multiple comma-separated sections:
	  # "(ger: xxx, fre: yyy)"
	  # A similar regex is used in jmxml.extract_lit() so if a
	  # revision is needed here, that function should be checked
	  # as well.
	KW = jdb.KW
	regex = r'\s*\(([a-z]{3,5}):\s*((([^()]+)|(\([^)]+\)))+?)\)\s*$'
	mo = re.search (regex, gtxt)
	if not mo: return gtxt, (None,None), []

	tag, ptext = mo.group (1, 2)
	div = mo.start ()  # Division point between gloss and ptext.

	  # First check if 'tag' is GINF tag.
	tagid = None
	rec = KW.GINF.get (tag)
	if rec: tagid = rec.id
	if tagid:
	      # It was, return the gloss sans ptext, and the ginf text tuple.
	    return gtxt[:div].strip(), (tagid, ptext), []

	  # Check for lsource.  There may be multiple, comma-separated
	  # lsource clauses within the parens.  But the lsource text may
	  # also contain commas so we need to do better then splitting
	  # on comas.

 	  # Getthe matched clause which is prefixed and suffixed with
	  # parend and whitespace.  Strip whitespace and leading paren.
	  # There will be at most one "(".
	fulltxt = mo.group().strip (' (')
	  # There may be multiple ")" and we must remove only one.
	if fulltxt[-1] == ')': fulltxt = fulltxt[:-1]
	lsrctxts = []
	  # Split on a pattern that matches the tag part of the lsource, 
	  # e.g. "ger:".  Require the tag to be at start of string or preceeded
	  # by a non-alpha character to avoid matching a non-lang tag like
	  # "xxxx:".  Special case "wasei".
	lsrcx = re.split (r'(?:^|[^a-z])((?:[a-z]{3}|wasei):)', fulltxt)
	if len (lsrcx) < 3: 	# Not an lsources text string.
	    return gtxt, (None, None), []
	  # The list from the split has alternating tag and text elements, 
	  # with empty elements interspersed.  Collect each tag element
	  # (identified by a ":" suffix) together with a possible following
	  # lsource text, in as pairs in 'lsrctxts'.
	for x in lsrcx:
	    x = x.strip(' ,')
	    if len (x) > 3 and x[-1] == ':':
		pair = [x[:-1], '']
		lsrctxts.append (pair)
	    elif x: 
		if pair[1]: raise ValueError (pair[1]) # Should not happen.
		pair[1] = x

	lsrctuples = []
	for lang, txt in lsrctxts:
	      # Give each lang,txt pair to parse_lsrc() to decipher.
	      # It will throw an exception if "lang" is not recognised.
	      # If that happens, abort processing of all the lsource
	      # specs and presume the entire (tetative) lsource text
	      # is part of the gloss.
	    try: lsrctuple = parse_lsrc (lang, txt)
	    except KeyError, e: 
		warn ('Lsrc keyerror on "%s" in "%s"' % (str(e), ptext))
		return (gtxt, (None, None), [])
	      # If it parsed ok, add it to the collection.
	    if lsrctuple: lsrctuples.append (lsrctuple)
	return gtxt[:div].strip(), (None,None), lsrctuples

def parse_lsrc (langtag, srctxt):
	if langtag == 'wasei':
	    langid = jdb.KW.LANG['eng'].id
	    wasei = True
	else:
	    langid = jdb.KW.LANG[langtag].id
	    wasei = False
	return langid, wasei, srctxt.strip(' ,')

def parse_stags (tag, sens, kanjs, rdngs):
	stagrtxts = [];  stagktxts = []
	words = tag.split(',')
	for word in words:
	    word = word.strip()
	    if jdb.jstr_reb (word): stagrtxts.append (word)
	    elif jdb.jstr_keb (word): stagktxts.append (word)
	    else: warn ('stagx restriction word neither reading or kanji: "%s"' % word)
	errs = []
	jdb.txt2restr (stagrtxts, sens, rdngs, '_stagr', bad=errs)
	if errs: warn ('Stagr text not in readings: "%s"' % '","'.join (errs))
	errs = []
	jdb.txt2restr (stagktxts, sens, kanjs, '_stagk', bad=errs)
	if errs: warn ('Stagk text not in kanji: "%s"' % '","'.join (errs))
	return

def parse_xrefs (txt, sens):
	  # Following regex is used to allow any xref type designator
	  # separated from the xref text by either or both colon or spaces.
	p = re.split (r'^(?:([a-zA-Z]+)(?:[: ]+))', txt)
	if len(p) != 3: 
	    warn ('Xref "%s" ignored, bad format' % txt)
	    return
	typ, xtxt = p[1:3]
	xtyp = jdb.KW.XREF[typ.lower()].id
	xrefs = re.split (r'[, ]', xtxt);
	xrsvs = []
	for n, x in enumerate (xrefs):
	    if not x: continue
	    krs = x.split (u'\u30FB')
	    if len (krs) > 3 or len(krs) == 0:
		warn ('Xref "%s" ignored, bad format' % x);  continue

	      # 'krs' has 1, 2, or 3 items.  Using "x" to indicate a non-
	      # existent item, the valid arrangements if kanji, reading, 
	      # and sense number are:
	      #   Kxx, KRx, KRS, KSx, Rxx RSx
	      # or rephrased in terms of what part of the xref can be in
	      # what item:
	      #    [0]:KR, [1]:RS, [2]:S

	    ktxt = None;  rtxt = None;  tsens = None
	    for n,v in enumerate (krs):
		if n==0:	# v is K or R
		    if jdb.jstr_reb (v): rtxt = v
		    else: ktxt = v
		elif n==1:	# v is R or S (if n==0 was K) or S (if n==0 was R)
		    if v.isdigit(): tsens = int (v)
		    elif jdb.jstr_reb (v):
		        if rtxt:
			    warn ('Xref "%s" ignored, two reading parts present' % x)
			    break
			rtxt = v
		    else:
			warn ('Xref "%s" ignored, two kanji parts present' % x)
			break
		else:		# v is S (n==1 must have been R)
		    if not v.isdigit():
			warn ('Xref "%s" ignored, "%s" is not a sense number' % (x, v))
			break
		    if tsens:
			warn ('Xref "%s" ignored, has two sense numbers' % x)
			break
		    tsens = int (v)
	    else:
		xrsvs.append (Xrslv (typ=xtyp, ord=n+1, ktxt=ktxt, rtxt=rtxt, tsens=tsens))
	if xrsvs:
	    if not getattr (sens, '_xrslv', None): sens._xrslv = []
	    sens._xrslv.extend (xrsvs)

def warn (msg):
	global Lineno
	if Lineno: msg = str(Lineno) + ": " + msg
	print >>sys.stderr, msg.encode (sys.stderr.encoding or 'utf-8')

