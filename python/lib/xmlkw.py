import copy
import jdb

def make (kw):
	# Using a copy of 'kw', modify it for use in
	# parsing or generating XML.
	# 
	# The jdb.Kwds structure intialized from a jmdictdb
	# database or csv files uses a mapping that is intended
	# to be independent of the entities and their expansions
	# that are used in JMdict XML, although in practice,
	# most items are identical.
	# 
	# Currently, the only differences are in the descr fields
	# of MISC 'male' and 'fem', and the JMnedict 'masc' entity
	# is mapped to MISC 'male'.
	# 
	# To allow for these differences, modules that parse or 
	# write XML can call xkw to create a copy of a standard 
	# Kwds object, modified to support the xml-specific differences.
	# Specifically, we add an attribute NAME_TYPE containing the
	# kw's for jmnedict with numeric values that match the MISC
	# values used in the database. 

	xkw = copy.deepcopy (kw)
	xkw.NAME_TYPE = {}
	for r in xkw.recs('MISC'):
	      # FIXME: Get rid of hardwired numbers.
	    if r.id >= 180 and r.id < 200: 
		xkw.add ('NAME_TYPE', r)
	r = xkw.MISC['male']
	xkw.add ('NAME_TYPE', jdb.DbRow ({'id':r.id, 'kw':'masc', 'descr':r.descr}))
	xkw.add ('NAME_TYPE', xkw.MISC['fem'])
	return xkw
