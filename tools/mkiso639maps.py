from __future__ import print_function, absolute_import, division
from future_builtins import ascii, filter, hex, map, oct, zip 
import sys

def main ():
	if len (sys.argv) < 1: infname = sys.argv[1]
	else: infname = "../doc/iso-639-3_20080228.tab"
	f = open (infname)
	print ("# coding: utf-8")
	print ("iso639_1_to_2 = {")
	for line in f:
	    id,part2b,part2t,part1,scope,language_type,ref_name,comment = line.split ('\t', 7)
	    if part1 and part2b and part1 != 'Part1': 
		print ("	'%s': '%s',	# %s" % (part1, part2b, ref_name))
	print ("	}")

if __name__ == '__main__': main()



