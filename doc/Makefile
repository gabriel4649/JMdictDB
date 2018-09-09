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

schema.pdf: schema.odt
	/usr/bin/libreoffice --headless --convert-to pdf schema.odt

schema.html: schema.odt
	/usr/bin/libreoffice --headless --convert-to html schema.odt
