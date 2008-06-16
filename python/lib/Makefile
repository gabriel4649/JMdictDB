# $Revision$
# $Date$
#
# kwstatic.pm contains a static representation of the data in 
# the database kw* tables which are loaded from the files in
# pg/data/kw*.csv.
# 
# If the data in any of the kw* tables (or the pg/data/kw*.csv 
# files) are changed, the appropriate data file(s) in pg/data/
# should be updated to match and "make" run in the perl/lib/
# (where kwstatic.pl and this Makefile reside) to syncronise
# the kwstatic.pm file with the changes.

KWDATADIR = ../../pg/data/

KWDATA = \
	$(KWDATADIR)kwdial.csv \
	$(KWDATADIR)kwfld.csv  \
	$(KWDATADIR)kwfreq.csv \
	$(KWDATADIR)kwginf.csv \
	$(KWDATADIR)kwkinf.csv \
	$(KWDATADIR)kwlang.csv \
	$(KWDATADIR)kwmisc.csv \
	$(KWDATADIR)kwpos.csv  \
	$(KWDATADIR)kwrinf.csv \
	$(KWDATADIR)kwstat.csv \
	$(KWDATADIR)kwxref.csv

all: kwstatic.py jelparse.py

kwstatic.py: $(KWDATA)
	python ../../tools/mkkwmod.py ../../pg/data/ >kwstatic.py

jelparse.py: jelparse.y
	python ../../tools/yply.py jelparse.y >jelparse.py

.DELETE_ON_ERROR:
