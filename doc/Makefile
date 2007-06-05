# $Revision$
# $Date$

all: 
	@echo 'Please specify an explicit target:'
	@echo '  schema (use on unix only)'
	@echo '  changes (use on windows only)'

schema: schema.png schema.pdf schema.html

changes: Changes.txt TODO.html

.DELETE_ON_ERROR:

# Following only works on *nix... (sigh)
# DIA runs on Windows but in my tests, the output looks awful
# (perhaps because diffent font sizes on Windows alter element 
# positions?)  Don't have OpenOffice installed on Windows so
# have not tested that.

schema.png: schema.dia
	dia --export $@ -s 1500x $?

# (See README.txt for info about the macros below...)

schema.pdf: schema.odt
	/usr/bin/openoffice.org-2.0 -invisible \
	  "macro:///DannysLibrary.Conversion.ExportDoc(/home/stuart/jb/doc/$?,pdf)"

schema.html: schema.odt
	/usr/bin/openoffice.org-2.0 -invisible \
	  "macro:///DannysLibrary.Conversion.ExportDoc(/home/stuart/jb/doc/$?,html)"

# Following only works on Windows... (sigh)
# Generate updated Changes.txt and todo.html files from the change 
# data in the ChgLog Microsoft Access database.  The database and 
# other tools in subdirectory ./chglog/ are not # distributed as
# part of the JMdictDB distribution.

TODO.html: chglog/ChgLog.mdb
	./chglog/mktodo.py chglog/ChgLog.mdb >TODO.html

# Not all the old Change log entries have been imported into the 
# database yet so append the old entries to those generated from
# the database.

Changes.txt: chglog/ChgLog.mdb Changes-old.txt
	./chglog/mkchglog.py chglog/ChgLog.mdb >temp.txt
	cat temp.txt Changes-old.txt >Changes.txt

# Create manifest from the Access database file list.

MANIFEST.txt: chglog/ChgLog.mdb
	./chglog/mkmanifest.py chglog/ChgLog.mdb >MANIFEST.txt
