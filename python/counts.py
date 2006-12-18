#!/usr/bin/env python

# This program will read a JMdict XML file and count
# the number of occurances of various tags and (for
# some tags) the number of values that occur in that 
# tag.  Output is written to stdout and these is several
# hundred lines of it, so you may want to redirect
# stdout to a file.  While running, the program writes
# "." characters to stderr as a progress indicator
# (one for every 2600 entries processed.  These are 
# typically a little over 200000 entries in JMdict
# so the program should end when about one line of
# dots has been printed.)

# Copyright (c) 2006, Stuart McGraw 
_VERSION_ = ("$Revision$"[11:-2], "$Date$"[7:-11])

import sys
try: from xml.etree.cElementTree import iterparse
except ImportError: 
    try: from cElementTree import iterparse
    except ImportError: from ElementTree import iterparse

Counts = {}
Counts['pos'] = {}
Counts['misc'] = {}
Counts['ke_pri'] = {}
Counts['re_pri'] = {}
Counts['ke_inf'] = {}
Counts['re_inf'] = {}
Counts['lang'] = {}
Counts['dial'] = {}
Counts['field'] = {}
Counts['g_lang'] = {}
Counts['g_gend'] = {}

Counts['xref'] = 0
Counts['ant'] = 0
Counts['re_nokanji'] = 0
Counts['re_restr'] = 0
Counts['stagk'] = 0
Counts['stagr'] = 0
Counts['s_inf'] = 0
Counts['example'] = 0
Counts['pri'] = 0
Counts['bibl'] = 0
Counts['etym'] = 0
Counts['links'] = 0
Counts['audit'] = 0

Lengths = {}
Lengths['kanj'] = (0, '')
Lengths['read'] = (0, '')
Lengths['gloss'] = (0, '')

def main (args, opts): 
	context = iter(iterparse( args[0], ("start","end")))
	count = 0;  event, root = context.next()
	for event, elem in context:
	    if elem.tag == "entry" and event == "end":
		count_tags (elem)
		max_lengths (elem)
		if count % 1320 == 0: sys.stderr.write (".")
		count += 1
		root.clear()
	print; results ()

def count_tags (elem):
	global Counts
	for k,v in Counts.items():
	    if k != "g_lang" and k != "g_gend":
		for p in elem.getiterator (k):
		    if isinstance (v, dict):
			Counts[k][p.text] = Counts[k].setdefault (p.text, 0) + 1
	    	    else: Counts[k] += 1
	    else: 
		for p in elem.getiterator ('gloss'):
		    if k in p.attrib: 
			Counts[k][p.get(k)] = Counts[k].setdefault (p.get(k), 0) + 1

def max_lengths (elem):
	global Lengths
	seq = elem.find('ent_seq').text
	v = [len(x.text) for x in elem.findall ('k_ele/keb')]
	if v and max(v) > Lengths['kanj'][0]: Lengths['kanj'] = (max(v), seq)
	v = [len(x.text) for x in elem.findall ('r_ele/reb')]
	if v and max(v) > Lengths['read'][0]: Lengths['read'] = (max(v), seq)
	v = [len(x.text) for x in elem.findall ('sense/gloss')]
	if v and max(v) > Lengths['gloss'][0]: Lengths['gloss'] = (max(v), seq)

def results ():
	print "Max string lengths:"
	print "    Kani: %s" % str(Lengths['kanj'])
	print "    Read: %s" % str(Lengths['read'])
	print "    Gloss: %s" % str(Lengths['gloss'])
	print "\n-------------------------------------\n"
	for k in sorted (Counts.keys()):
	    v = Counts[k]
	    if isinstance (v, int):
		print "%s: %d" % (k, v)
	    else:
		print "%s: " % (k,)
		for j in sorted (v.keys()):
		    print "    %s: %d" % (j, v[j])
	print "\n-------------------------------------\n"
	use = {}
	for k,v in Counts.items():
	    if isinstance (v, int): continue
	    for j in v.keys():
	        if j in use: use[j].append(k)
		else: use[j] = [k]
	for j in sorted(use.keys()):
	    print "%s:  %s" % (j, "\n\t".join(use[j]))


#========================================================================
import sys
from optparse import OptionParser
Usage = """\
counts.py [options] filename

Warning: this program may take many minutes to run.

arguments:  filename -- name of the jmdict file to examine
"""

def parse_cmdline ():
	v = "Version %s (%s)" % _VERSION_
	p = OptionParser (usage=Usage, version=v)
	p.add_option ("-D", "--debug",
             action="store_true", dest="D", 
             help="Startup in Python pdb debugger.")
	opts, args = p.parse_args ()
	return args, opts

if __name__ == '__main__': 
	def exceptionHandler (type, value, tb):
	    if not (sys.stderr.isatty() and sys.stdin.isatty()) or type==SyntaxError: 
	        sys.__excepthook__(type, value, tb)
	    else: # Not in interactive mode, print the exception...
	        import traceback, pdb
	        traceback.print_exception(type, value, tb)
	        print;  pdb.pm()
	args, opts = parse_cmdline ()
	if (opts.D):
	    import pdb, traceback
	    sys.excepthook = exceptionHandler
	    pdb.set_trace ()
	if len (args) < 1: args.append ("/temp/JMdict.xml")

	main (args, opts)


