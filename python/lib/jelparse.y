%{
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

__version__ = ('$Revision$'[11:-2], \
	       '$Date$'[7:-11]);

import sys,ply.yacc, re, pdb
import jellex, jdb
import fmt, fmtjel	# For code in main().

class ParseError (Exception): 
    def __init__(self,msg,lineno,charno,toktyp,tokval):
	Exception.__init__(self,msg,lineno,charno,toktyp,tokval)	
    def __str__(self):
	msg,lineno,charno,toktyp,tokval = self.args
	if lineno is None:  pos = '(at EOF)'
	else:  pos = "(at or before '%s' in line %s position %s)" \
		      % (tokval,lineno,charno)
	s = "%s %s" % (msg, pos)
	return s

%}

%%

entr	: preentr
		{ p.lexer.begin('INITIAL')
		e = p[1]
		  # Set the foreign key ids since they will be used 
		  # needed by mk_restrs() below.
		jdb.setkeys (e, -1)
		  # The reading and sense restrictions here are simple
		  # lists of text strings that give the allowed readings
		  # or kanji.  mk_restrs() converts those to the canonical
		  # format which uses the index number of the disallowed 
		  # readings or kanji.
		if hasattr (e, '_rdng') and hasattr (e, '_kanj'): 
		    err = mk_restrs ("_RESTR", e._rdng, "rdng", e._kanj, "kanj")
		    if err: 
			p.error(); xerror (p, err)
		if hasattr (e, '_sens') and hasattr (e, '_kanj'): 
		    err = mk_restrs ("_STAGK", e._sens, "sens", e._kanj, "kanj")
		    if err: 
			p.error(); xerror (p, err)
		if hasattr (e, '_sens') and hasattr (e, '_rdng'): 
		    err = mk_restrs ("_STAGR", e._sens, "sens", e._rdng, "rdng")
		    if err: 
			p.error(); xerror (p, err)
		  # Note that the entry object returned may have an _XREF list
		  # on its senses but the supplied xref records are not
		  # complete.  We do not assume database access is available
		  # when parsing so we cannot look up the xrefs to find the 
		  # the target entry id numbers, validate that the kanji
		  # reading (if given) are unique, or the target senses exist,
		  # etc.  It is expected that the caller will do this resolution
		  # on the xrefs using something like jdb.resolv_xref() prior
		  # to using the object.
		p[0] = e }
	;
preentr
	: rdngsect senses
		{ p[0] = jdb.Obj(_rdng=p[1], _sens=p[2]) }			
	| kanjsect senses
		{ p[0] = jdb.Obj(_kanj=p[1], _sens=p[2]) }			
	| kanjsect rdngsect senses
		{ p[0] = jdb.Obj(_kanj=p[1], _rdng=p[2], _sens=p[3]) }
	;
kanjsect
	: kanjitem
		{ p[0] = [p[1]] }
	| kanjsect SEMI kanjitem
		{ p[0] = p[1];  p[0].append (p[3]) }
	;
kanjitem
	: KTEXT 
		{ p[0] = jdb.Obj(txt=p[1]) }
	| KTEXT taglists
		{ kanj = jdb.Obj(txt=p[1])
		err = bld_kanj (kanj, p[2])
		if err: 
		    p.error(); xerror (p, err)
		p[0] = kanj }
	;
rdngsect
	: rdngitem
		{ p[0] = [p[1]] }
	| rdngsect SEMI rdngitem
		{ p[0] = p[1];  p[0].append (p[3]) }			
	;
rdngitem
	: RTEXT
		{ p[0] = jdb.Obj(txt=p[1]) }
	| RTEXT taglists
		{ rdng = jdb.Obj(txt=p[1])
		err = bld_rdng (rdng, p[2])
		if err:
		    p.error(); xerror (p, err)
		p[0] = rdng }
	;
senses
	: sense
		{ p[0] = [p[1]] }
	| senses sense
		{ p[0] = p[1]; p[0].append(p[2]) }
	;
sense
	: SNUM glosses
		{ sens = jdb.Obj()
		err = bld_sens (sens, p[2])
		if err: 
		    p.error(); xerror (p, "Unable to build sense %s\n%s" % (p[1], err))
		p[0] = sens }
	;
glosses
	: gloss 
		{ p[0] = [p[1]] }
	| glosses SEMI gloss
		{ p[0] = p[1]; p[0].append (p[3]) }
	;
gloss
	: GTEXT
		{ p[0] = [p[1], None] }
	| GTEXT taglists
		{ p[0] = [p[1], p[2]] }
	| taglists  GTEXT
		{ p[0] = [p[2], p[1]] }
	| taglists GTEXT taglists
		{ p[0] = [p[2], p[1] + p[3]] }
	;
taglists
	: taglist
		{ p[0] = p[1] }
	| taglists taglist
		{ p[0] = p[1]
		p[0].extend(p[2]) }
	;
taglist
	: BRKTL tags BRKTR
		/* # Note: Each tag is a
		  # n-seq' where n is typically 2 or 3. The
		  # first item of the n-seq is either None or a string
		  # giving the type of tag, e.g. 'POS', 'lsrc',
		  # etc.  In the tagitem production, we can identify
		  # the tag type based on syntax in many cases, and 
		  # when so, we resolve
		  # the tag to a type string and number id value.
		  # However, is some cases, particularly when we have
		  # an single unadorned tag string like "vi", we cannot
		  # tell what type of tag it is because the tag is ambiguous.
		  # In the case of "vi" for
		  # example, it could be a POS tag (instransitive verb)
		  # or a LANG tag (Vietnamese).  In these cases we represent
		  # the tag as a 2-tuple of (None, <tag-string>) and
		  # resolve the tag at a higher level when we know
		  # the context of the tag (kanji, gloss, sense, etc). 
		  # 
		  # Thus, if we parse a string with a sense
		  # 
		  #   [1][vs,misc=exp,'freq=nf12'] foo [lit]
		  #
		  # we will get a tag list that looks like:
		  #
		  #   [(None,'vs'), ('MISC',33), ('FREQ',4,12), (None,'lit')]
		  #
		  # (where 33 is the id value of 'exp' in the kwmisc table, and
		  # and 4 is the value of 'nf' in the kwfreq table.)
		  #
		*/
		{ p[0] = p[2] }
	;
tags
	: tagitem
		{ p[0] = [p[1]] }
	| tags COMMA tagitem
		{ p[0] = p[1]
		p[0].append (p[3]) }
	;
tagitem
	: TEXT			    /* Simple keyword tag (including "nokanji"). */
		{ x = lookup_tag (p[1])
		if not x: 
		    p.error(); xerror (p, "Unknown keyword: '%s'" % p[1])
		else: 
		    p[0] = [None, p[1]] }

	| TEXT EQL TEXT /* typ=tag,note=xxx,lsrc=txt,lit=text,expl=text,restr=nokanji */
		{ KW = jdb.KW
		if p[1] in ["note","lsrc","restr"]+[x.kw for x in KW.recs('GINF')]:
		    if p[1] == "restr": p[1] = "RESTR"
		    p[0] = [p[1], p[3], 1, None] 
		else:
		    x = lookup_tag (p[3], p[1])
		    if x and len(x) > 1:
			raise RuntimeError ("Unexpected return value from lookup_tag()")
		    if x is None:
			p.error(); xerror (p, "Unknown keyword type: '%s'" % p[1])
		    elif not x:
			p.error(); xerror (p, "Unknown %s keyword: '%s" % (p[1],p[3]))
		    else:
			p[0] = x[0] } 

	| TEXT EQL QTEXT	    /* note=xxx, lsrc=txt, lit=text, expl=text */
		{ KW = jdb.KW 
		if p[1] in ["note","lsrc"]+[x.kw for x in KW.recs('GINF')]:
		    p[0] = [p[1], jellex.qcleanup (p[3][1:-1]), 1, None] 
		else:
		    p.error(); xerror (p, "Unknown keyword: '%s" % p[1]) } 

	| TEXT EQL TEXT COLON	    /* lsrc=xx: ('xx' is language code.) */
		{ KW = jdb.KW 
		if p[1] != "lsrc":
		    p.error(); xerror (p, "Keyword must be \"lsrc\"")
		la = KW.LANG.get(p[3])
		if not la: 
		    p.error(); xerror (p, "Unrecognised language '%s'" % p[3])
		p[0] = ["lsrc", None, la.id, None] }

	| TEXT EQL TEXT COLON atext  /* lsrc=xx:text, lsrc=w:text, lit=xx:text, expl=xx:text */
		{ KW = jdb.KW 
		lsrc_flags = None; lang = None
		if p[1] in ["lsrc"]:
		    la = KW.LANG.get(p[3])
		    if not la:
			p.error(); xerror (p, "Unrecognised language '%s'" % p[3])
		    lang = la.id
		elif p[1] in [x.kw for x in KW.recs('GINF')]:
		    la = KW.LANG.get(p[3])
		      # FIXME: following works only because there are no 
		      # languages with two-letter code 'wp' or 'pw'.  Same
		      # contruct also used in rule below.
		    if not la:
			if p[3] not in ('w','p','wp','pw'):
			    p.error(); xerror (p, "Unrecognised language '%s'" % p[3])
			else: 
			    lsrc_flags = p[3]
		    else:
			lang = la.id
		else:
		    p.error(); xerror (p, "Keyword not \"lsrc\", \"lit\", or \"expl\"")
		p[0] = ["lsrc", p[5], lang, lsrc_flags] }
 
	| TEXT EQL TEXT SLASH TEXT COLON atext /* lsrc=xx/wp:text */
		{ KW = jdb.KW 
		if p[1] != "lsrc":
		    p.error(); xerror (p, "Keyword not \"lsrc\"")
		la = KW.LANG.get(p[3])
		if not la:
		    p.error(); xerror (p, "Unrecognised language '%s'" % p[3])
		if p[5] not in ('w','p','wp','pw'):
		    p.error(); xerror (p, 
			"Bad lsrc flags '%s', must be 'w' (wasei), 'p' (partial),or both" % p[5])
		p[0] = ["lsrc", p[7], la.id, p[5]] }
 
	| TEXT EQL jitems   /* xref=k/r[n1,n2,..], restr=k;k;.. (restr, stagr,stagk) */
		{ if p[1] != "restr" and p[1] != "see" and p[1] != "ant":
		    p.error(); xerror (p, "Keyword not \"restr\", \"see\", or \"ant\"")
		if p[1] == "restr": p[1] = "RESTR"
		p[0] = [p[1], p[3]] }
	;
atext
	: TEXT
		{ p[0] = p[1] }
	| QTEXT
		{ p[0] = jellex.qcleanup (p[1][1:-1]) }
	;
jitems
	: jitem
		{ p[0] = [p[1]] }
	| jitems SEMI jitem	
		{ p[0] = p[1]
		p[0].append (p[3]) }
	;
jitem
	: jtext
		{ p[0] = p[1] }
	| jtext slist
		{ p[0] = p[1]
		p[0][2] = p[2] }
	;
jtext	
	: KTEXT
		{ p[0] = [p[1],None,None,None] }
	| RTEXT
		{ p[0] = [None,p[1],None,None] }
	| KTEXT SLASH RTEXT
		{ p[0] = [p[1],p[3],None,None] }
	| NUMBER SLASH KTEXT
		{ p[0] = [p[3],None,None,toint(p[1])] }
	| NUMBER SLASH RTEXT
		{ p[0] = [None,p[3],None,toint(p[1])] }
	| NUMBER SLASH KTEXT SLASH RTEXT
		{ p[0] = [p[3],p[5],None,toint(p[1])] }
	| NUMBER
		{ p[0] = [None,None,None,toint(p[1])] }
	;
slist
	: BRKTL snums BRKTR
		{ p[0] = p[2] }
	;
snums
	: NUMBER
		{ n = int(p[1])
		if n<1 or n>99:
		    p.error(); xerror (p, "Invalid sense number: '%s' % n")
		p[0] = [n] }
	| snums COMMA NUMBER
		{ n = int(p[3])
		if n<1 or n>99:
		    p.error(); xerror (p, "Invalid sense number: '%s' % n")
 		p[0] = p[1] + [n] }
	;

%%
def xp_error (tok):
	if tok is None:
	    ln = None;  lp = None;  t = None;  v = None
	else: 
	    ln = tok.lineno;  t = tok.type;  v = tok.value
	    lp = find_column (tok)
	raise ParseError ("Syntax error (p_error)", ln, lp, t, v)

def xerror (p, msg=None):
	ln = None;  lp = None;  t = None;  v = None
	if p is not None: 
	    ln = p.lineno;  #t = p.type;  v = p.value
	    #lp = find_column (p)
	print >>sys.stderr, msg or "Syntax error"

def find_column (token):
	i = token.lexpos
	input = token.lexer.lexdata
	while i > 0:
	    if input[i] == '\n': break
	    i -= 1
	column = (token.lexpos - i) + 1
	return column

def lookup_tag (tag, typs=None):
	# Lookup 'tag' (given as a string) in the keyword tables
	# and return the kw id number.  If 'typs' is given it 
	# should be a string or list of strings and gives the
	# specific KW domain(s) (e.g. FREQ, KINF, etc) that 'tag'
	# should be looked for in. 
	# The return value is:
	#   None -- A non-existent KW domain was given in'typs'.
	#   [] -- (Empty list) The 'tag' was not found in any of 
	#         the doimains given in 'typs'.
	#   [[typ1,id1],[typ2,id2],...] -- A list of lists.  Each
	#         item represents a domain in which 'tag' was found.
	#         The first item of each item is a string giving  
	#         the domain name.  The second item gives the id 
	#         number of that tag in the domain.  In the case of
	#         the FREQ keyword, the item will be a 3-list
	#         consisting of "FREQ", the freq kw id, and the 
	#         a number for the freq value.  E.g. lookup_tag('nf23')
	#         will return [["FREQ",5,23]] (assuming that the "nf"
	#         kw has the id value of 5 in the kwfreq table.)

	KW = jdb.KW 
	matched = []
	if not typs:
	    typs = [x for x in KW.attrs() if x not in ('LANG','GINF')]+['RESTR']
	if isinstance (typs, (str, unicode)): typs = [typs]
	for typ in typs:
	    typ = typ.upper(); val = None
	    if typ == "RESTR":
		if tag == "nokanji": 
		    matched.append ([typ, 1])
	    else:
		if typ == "FREQ":
		    mo = re.search (r'^([^0-9]+)(\d+)$', tag)
		    if mo:
			tag = mo.group(1)
			val = int (mo.group(2))
		try:
		    x = (getattr (KW, typ))[tag]
		except AttributeError: return []
		except KeyError: pass
		else: 
		    if not val: matched.append ([typ, x.id])
		    else: matched.append ([typ, x.id, val])
	return matched

def bld_sens (sens, glosses):
	# Build a sense record.  'glosses' is a list of gloss items.
	# Each gloss item is a 2-tuple: the first item is the gloss
	# record and the second, a list of sense tags.  
	# Each of the sense tag items is an n-tuple.  The first item
	# in an n-tuple is either a string giving the type of the tag
	# ('KINF', 'POS'. 'lsrc', etc) or None indicating the type was
	# not specified (for example, the input text contained a single
	# keyword like "vi" rather than "pos=vi").  The second and any
	# further items are dependent on the the tag type.
	# Our job is to iterate though this list, and put each item 
	# on the appropriate sense list: e.g. all the "gloss" items go 
	# into the list @{$sens->{_gloss}}, all the "POS" keyword items 
	# go on @{$sens->{_pos}}, etc.

	KW = jdb.KW 
	errs = []; sens._gloss = []
	for gtxt, tags in glosses:
	    gloss = jdb.Obj (txt=jellex.gcleanup(gtxt),
			 lang=KW.LANG['eng'].id, ginf=KW.GINF['equ'].id)
	    sens._gloss.append (gloss)
	    if tags: errs.extend (sens_tags (sens, gloss, tags))
	return "\n".join (errs)

def sens_tags (sens, gloss, tags):
	# See the comments in the "taglist" production for a description
	# of the format of 'taglist'.

	KW = jdb.KW 
	errs = []
	for t in tags:
	    vals = None
	    typ = t.pop(0)	# Get the item type.

	    if typ is None:	
		  # Unknown type, figure it out...
		  # First, if we can interpret the tag as a sense tag, do so.
		candidates = lookup_tag (t[0], ('POS','MISC','FLD','DIAL'))
		if candidates and len(candidates) > 1: 
		    errs.append (
			"Sense tag '%s' is ambiguous, may be either any of %s." 
			" Please specify tag explicity, using, for instance,"
			" \"%s=%s\"" % (t[0], ','.join([x[0] for x in candidates]),
				        candidates[0][0], t[0]))
		    continue
		if candidates:
		    typ, t = candidates[0][0], [candidates[0][1]]
	    if typ is None:
		candidates = lookup_tag (t[0], ('GINF','LANG'))
		if candidates: 
		    for candidate in candidates:
		        z = candidate[0]; v = candidate[1]
		        if z == 'GINF':
			    typ = z;  t = v
	    	        elif z == 'LANG' and not typ:
			    typ = z;  t = v
			else: assert False, "Internal program error"
	    if typ is None:
		errs.append ("Unknown tag '%r'" % t)
		continue

	    if typ in ('POS','MISC','FLD','DIAL'):
		assert len(t)==1, "invalid length"
		assert type(t[0])==int, "Unresolved kw"
	        append (sens, "_"+typ.lower(), jdb.Obj(kw=t[0]))
	    elif typ == 'RESTR':
		# We can't create real @{_stagk} or @{_stagr} lists here
		# because the readings and kanji we are given by the user
		# are allowed ones, but we need to store disallowed ones. 
		# To get the disallowed ones, we need access to all the
 		# readings/kanji for this entry and we don't have to that
		# info at this point.  So we do what checking we can. and
		# save the texts as given, and will fix later after the 
		# full entry is built and we have access to the entry's
		# readings and kanji.

		for jitem in t[0]:
		    if ((jitem[0] and jitem[1]) or 
			     (not jitem[0] and not jitem[1]) or jitem[3]): 
			errs.append ("Sense restrictions must have a "
				     "reading or kanji (but not both): "
			       + fmt_jitem (jitem))
			errs += 1
		    if jitem[0]: append (sens, '_STAGK', jitem[0])
		    if jitem[1]: append (sens, '_STAGR', jitem[1])

	    elif typ == 'lsrc':  
		wasei   = t[2] and 'w' in t[2]
		partial = t[2] and 'p' in t[2]
		append (sens, '_lsrc', 
			jdb.Obj(txt=t[0], lang=(t[1] or lang_en), 
				part=partial, wasei=wasei))
	    elif typ == 'note': 
		if hasattr (sens, 'notes'): 
		    errs.append ("Only one sense note allowed")
		sens.notes = t[0]
	    elif typ == 'see' or typ == 'ant':
		for jitem in t[0]:
		      # jitem format: a 4-seq: [0]:kanji text, 
		      # [1]:reading text, [2]list of sense numbers,
		      # [3]:seq number
		    kw = KW.XREF[typ].id
		    append (sens, '_XREF', jdb.Obj (typ=kw, 
			rtxt  = jitem[1] or None,	# Target reading text.
			ktxt  = jitem[0] or None, 	# Target kanji text.
			slist = jitem[2] or [], 	# Target sense numbers.
			enum  = jitem[3]))		# Target seq or id number.

	    elif typ == 'GINF':
		assert len(t)==1, "invalid length"
		assert type(t[0])==int, "Non-int kw"
		if hasattr (gloss, ginf): 
		    errs.append ( 
		        "Warning, duplicate GINF tag '%s' ignored\n" % KW.GINF[t[0]].kw)
		else: gloss.ginf = t[0]
 	    elif typ == 'LANG': 
		assert type(t[0])==int, "Non-int kw"
		assert len(t)==1, "invalid length"
		if hasattr (gloss, lang): 
		    errs.append ( 
		        "Warning, duplicate LANG tag '%s' ignored\n" % KW.LANG[t[0]].kw)
		else: gloss.lang = t[0]

	    elif typ: 
		errs.append ("Cannot use '%s' tag in a sense" % typ)

	return errs

def bld_rdng (r, taglist=[]):
	errs = [];  nokanj = False
	for t in taglist:
	    typ = t.pop(0)
	    if typ is None:
		if t[0] == 'nokanji': 
		    typ = 'RESTR'
		else:
		    v = lookup_tag (t[0], ('RINF','FREQ'))
		    if not v: 
			typ = None
			errs.append ("Unknown reading tag %s" % t[0])
		    else:
		        typ, t = v[0][0], v[0][1:] 
	    if typ == 'RINF': append (r, '_inf', jdb.Obj(kw=t[0]))
	    elif typ == 'FREQ': append (r, '_freq', jdb.Obj(kw=t[0], value=t[1]))
	    elif typ == 'RESTR':
		# We can't generate real restr records here because the real
		# records are the disallowed kanji.  We have the allowed
		# kanji here and need the set of all kanji in order to get
		# the disallowed set, and we don't have that now.  So we 
		# just save the allowed kanji as given, and will convert it
		# after the full entry is built and we have all the info we
		# need.
		if t[0] == 'nokanji':
		    nokanj = True
		    r._NOKANJI = 1
		    continue
		for jitem in t[0]:
		      # A jitem represents a reference to another entry
		      # or other info within an entry, in textual form.  It
		      # is used for xrefs and restr info.  It is a 3-seq
		      # with the following values:
		      #   [0] -- Kanji text
		      #   [1] -- Reading text
		      #   [2] -- A sequence of sense numbers.
		      # For a reading restr, it is expected to contain only 
		      # a kanji text.
		    if not jitem[0] or jitem[1] or jitem[2]:
			errs.append ("Reading restrictions must be kanji only: "
				      + fmt_jitem (jitem))
		    append (r, "_RESTR", jitem[0])
		if r._RESTR and nokanj:
		    errs.append ("Can't use both kanji and 'nokanji' in 'restr' tags")
	    elif typ: 
		errs.append ("Cannot use '%s' tag in a reading" % typ)
	return "\n".join (errs)

def bld_kanj (k, taglist=[]):
	errs = []
	for t in taglist:
	    typ = t.pop(0)
	    if typ is None:
		v = lookup_tag (t[0], ('KINF','FREQ'))
		if not v: xerror ("Unknown kanji tag %s" % t[0])
 		  # Warning: The following simply uses the first resolved tag in
		  # the candidates list returned by lookup_tag().  This assumes
		  # there are no possible tags that are ambiguous in the KINF and
		  # FREQ which could cause lookup_tag() to return more than one
		  # candidate tags.
		typ, t = v[0][0], v[0][1:]
	    if typ == "KINF": append (k, "_inf", jdb.Obj(kw=t[0]))
	    elif typ == "FREQ": append (k, "_freq", jdb.Obj(kw=t[0], value=t[1]))
	    else: 
		errs.append ("Cannot use %s tag with a kanji" % typ); 
	return "\n".join (errs)

def mk_restrs (listkey, rdngs, rdngkey, kanj, kanjkey, kmap=None):
	# Note: mk_restrs() are used for all three
	# types of restriction info: restr, stagr, stagk.  However to
	# simplify things, the comments and variable names assume use
	# with reading restrictions (restr).  
	#
	# What we do is take a list of restr text items received from
	# a user which list the kanji (a subset of all the kanji for
	# the entry) that are valid with this reading, and turn it 
	# into a list of restr records that identify the kanji that
	# are *invalid* with this reading.  The restr records identify
	# kanji by id number rather than text.
	#
	# $listkey -- Name of the key used to get the list of text
	#    restr items from $rdngs.  These are the text strings
	#    provided by the user.  Should be "_RESTR", "_STAGR", 
	#    or "_STAGK".
	# @$rdngs -- Lists of rdng or sens records depending on whether
	#    we're doing restr or stagr/stagk restrictions.
	# $rdngkey -- Either "rdng" or "sens" depending on whether we're
	#    doing restr or  stagr/stagk restrictions.
	# @$kanj -- List of the entry's kanji or reading records 
	#    depending on whether we are doing restr/stagk or stagr
	#    restrictions.
	# $kanjkey -- Either "kanj" or "rdng" depending on whether we're
	#    doing restr/stagk or stagr restrictions.
	# %$kmap -- (Optional)  A hash of @$kanj keyed by the text strings.
	#    If not given it will be automatically generated, but caller
	#    can supply it to prevent it from being recalculated multiple
	#    times.  [NB: we should cache after generation so caller need
	#    not worry about it at all.]

	if kmap is None: kmap = {}
	errs = []
	for r in rdngs:

	      # Get the list of restr text strings and nokanji flag and
	      # delete them from the rdng object since they aren't part
	      # of the standard api.
	    restrtxt = getattr (r, listkey, None)
	    if restrtxt: delattr (r, listkey)
	    nokanj = getattr (r, '_NOKANJI', None)
	    if nokanj: delattr (r, '_NOKANJI')

	      # Continue with next reading if nothing to be done 
	      # with this one.
	    if not nokanj and not restrtxt: continue

	      # bld_rdngs() guarantees that {_NOKANJI} and {_RESTR} 
	      # won't both be present on the same rdng.

	    if not nokanj:
		  # 'kmap' is a dict that indexes kanj records by 
		  # by their text, to allow quick lookup by text.
		  # If we did not receive it as a parameter, generate
		  # it now.
		if not kmap: kmap = dict ([(x.txt, x) for x in kanj])

		  # Look for any restr kanji text that is not in the
		  # entry's kanji text.
		nomatch = [x for x in restrtxt if x not in kmap]

		if nomatch:
		    not_found_in = {'rdng':'readings','kanj':'kanji'}[kanjkey]
		    errs.append ("restr value(s) '" + 
			    "','".join (nomatch) + 
			    "' not in the entry's %s" % not_found_in)

		  # The restr kanji we received are the kanji allowed
		  # for a given reading.  In the entry object being 
		  # created (and in the database) the disallowed kanji
		  # (the entry's kanji minus the ones in 'restrtxt') are
		  # stored.  
		disallowed = [x for x in kanj if x.txt not in restrtxt]

	    else:
		disallowed = [];
		if not kanj:
		    errs.append ("Entry has no kanji but reading has 'nokanji' tag")

		  # If this reading was marked "nokanji", then all 
		  # the entries kanji are disallowed.
		else: disallowed = kanj

	      # Use the list of disallowed kanji to create the restr 
	      # list that is attached to the reading.
	    restr = []
	    for x in disallowed:
		z = jdb.Obj (entr=r.entr)
		setattr (z, rdngkey, getattr(r,rdngkey))
		setattr (z, kanjkey, getattr(x,kanjkey))
		restr.append (z)
	    if restr: setattr (r, listkey.lower(), restr)

	return "\n".join (errs)

def resolv_xrefs (cur, entr):
	"""\
	Convert any jelparser generated _XREF lists that are attached
	to any of the senses in 'entr' to a normal augmented xref list.
	An _XREF list is a list of objects, each with attributes:
	  kw -- The type of xref per id number in table kwxref.
	  rtxt -- Reading text of the xref target entry or None.
	  ktxt -- Kanji text of the target xref or None.
	  slist -- A list of ints specifying the target senses in
		    in the target entry.  
	  enum -- An entry id number or None.
	At least one of 'rtxt', 'ktxt', or 'enum' must be non-None.\
	"""
	xrefs = []
	for s in getattr (entr, '_sens', []):
	    if not hasattr (s, '_XREF'): continue
	    for x in s._XREF: 
		xrfs = jdb.resolv_xref (cur, x.typ, x.rtxt, x.ktxt,
					x.slist, x.enum, None)
		xrefs.extend (xrfs)
	    if xrefs: s._xref = xrefs
	    del s._XREF
	return []

def append (sens, key, item):
    # Append $item to the list, @{$sens->{$key}}, creating 
    # the latter if needed.
	v = []
	try: v = getattr (sens, key)
	except AttributeError: setattr (sens, key, v)
	v.append (item)

_uni_numeric = {
    '\uFF10':'0','\uFF11':'1','\uFF12':'2','\uFF13':'3',
    '\uFF14':'4','\uFF15':'5','\uFF16':'6','\uFF17':'7',
    '\uFF18':'8','\uFF19':'9',}

def toint (s):
	n = int (s.translate (_uni_numeric))
	return n

def create_parser (toks, **args):
	global tokens
	tokens = toks
	parser = ply.yacc.yacc (**args)
	return parser

def main (args, opts):
	global KW, tokens

	cur = jdb.dbOpen ('jmdict')
	# Get local ref to the keyword tables...
	KW = jdb.KW

        lexer, tokens = jellex.create_lexer (debug=opts.debug>>8)
        parser = create_parser (tokens)
	parser.debug = opts.debug

	if opts.seq:
	    seq = opts.seq
	    srctxt, parsedtxt = _roundtrip (cur, lexer, parser, seq, 1)
	    if not srctxt:
		print "Entry %s not found" % seq
	    else:
		print srctxt
		print "----"
		print parsedtxt
	else:
	    _interactive (lexer, parser)

def _roundtrip (cur, lexer, parser, seq, src):
    # Helper function useful for testing.  It will read an entry
    # identified by 'seq' and 'src' from the database opened on the
    # dpapi cursor object 'cur', convert that entry to a JEL text
    # string, parse the text to get a new entry object, and convert
    # that entry object top JEL text.  The text generated from the
    # the original object, and from the parser-generated object,
    # are returned and can be compared.  The should be identical.

	#pdb.set_trace()
	sql = "SELECT id FROM entr WHERE seq=%s AND src=%s"
	obj = jdb.entrList (cur, sql, [seq, src])
	if not obj: return None,None
	for s in obj[0]._sens:
	    jdb.augment_xrefs (cur, getattr (s, '_xref', []))
	jeltxt = _get_jel_text (obj[0])
	jellex.lexreset (lexer, jeltxt)
	result = parser.parse (jeltxt,lexer=lexer)
	jeltxt2 = _get_jel_text (result)
	return jeltxt, jeltxt2

def _get_jel_text (entr):

	'''Generate and return a JEL string from entry object
	'entr'.  The first line (text before the first "\n"
	character) is removed since it contains nformation
	that will vary between objects read from a database
	and created by parsing input text.'''

	jeltxt = fmtjel.entr (entr)
	return jeltxt.partition('\n')[2]

def _interactive (lexer, parser):
	cnt = 0;  instr = ''
        while 1:
	    instr = _getinptext ()
	    if not instr: break
	    jellex.lexreset (lexer, instr)
	    try: 
		result = parser.parse(instr,lexer=lexer,debug=opts.debug)
	    except ParseError, e: 
		print e
	    else:
                s = fmtjel.entr (result)
                print s

def _getinptext ():
	instr = '';  cnt = 0;  prompt = 'test> '
	while cnt < 1:
            try: s = raw_input(prompt).decode('sjis')
            except EOFError: break
	    prompt = ''
            if s: cnt = 0
	    else: cnt += 1
	    if cnt < 1: instr += s + '\n'
	return instr.rstrip()


def _parse_cmdline ():
	from optparse import OptionParser 
	u = \
"""\n\tpython %prog [-d n][-q SEQ]
	
  This is a simple test/exerciser for the JEL parser.  It operates
  in two different modes depending on the presence or absense of 
  the --seq (-q) option.  

  When present it will read the entry with the given seq number
  from the jmdict corpus in the database, format it as a JEL text 
  string, and parse it.  It prints both the input text and the
  object generated from the parse in the same format, and both
  should be functionally identical.  (There may be non-significant
  differences such as tag order.)

  If the --seq (-q) option is not given, this program will read 
  text input interactively until a blank line is entered, feed the 
  text to the parser, and print the resulting object. 

Arguments: (None)
"""
	p = OptionParser (usage=u)
	p.add_option ("-q", "--seq", 
            type="int", dest="seq", default=None,
            help="Parse text generated by reading jmdict seq SEQ from" 
		" database rather than the default behavior of prompting" 
		" interactively for input text.")
	p.add_option ("-d", "--debug",
            type="int", dest="debug", default=0,
            help="Debug value to pass to parser:"
		" 2: Productions,"
		" 4: Shifts,"
		" 8: Reductions,"
		" 16: Actions,"
		" 32: States,"
		" 256: Lexer tokens")
	opts, args = p.parse_args ()
	#...arg defaults can be setup here...
	return args, opts

if __name__ == '__main__': 
	args, opts = _parse_cmdline ()
	main (args, opts)
