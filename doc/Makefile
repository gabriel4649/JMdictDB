# $Revision$
# $Date$

all: schema

schema: schema.png schema.pdf schema.html

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
