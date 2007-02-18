CSS_DIR = $(HOME)/public_html
CSS_URL = ../entr.css
CGI_DIR = $(HOME)/public_html/cgi-bin
LIB_DIR = $(HOME)/public_html/lib

CSS_FILES = perl/cgi/entr.css

CGI_FILES = perl/cgi/entr.pl \
	perl/cgi/nwconf.pl \
	perl/cgi/nwform.pl \
	perl/cgi/nwsub.pl \
	perl/cgi/srchform.pl \
	perl/cgi/srchres.pl 

LIB_FILES = perl/lib/jmdict.pm \
	perl/lib/jmdicttal.pm 

TAL_FILES = perl/lib/tal/entr.tal \
	perl/lib/tal/nwconf.tal \
	perl/lib/tal/nwform.tal \
	perl/lib/tal/srchform.tal \
	perl/lib/tal/srchres.tal

all:
	@echo 'You must supply an explicit target with this makefile: \
	  jmdict.dmp -- Create Postgres load file from jmdict xml file. \
	  loaddb -- Create load file and load it into database. \
	  mkdist -- Make development snapshot distribution file. \
	  web -- Update the web server copies of the files.'

jmdict.dmp: jmdict.xml
	cd perl
	load_jmdict.pl -o ../jmdict.dmp ../jmdict.xml

jmdict.xml: 
	wget ftp://ftp.cc.monash.edu.au/pub/nihongo/JMdict_e.gz
	gunzip JMdict_e.gz
	mv JMdict_e jmdict.xml

loaddb: jmdict.dmp
	cd pg; \
	psql -U postgres -f reload.sql; \
	psql -U postgres -d jmdict <../jmdict.dmp; \
	psql -U postgres -d jmdict -f postload.sql

mkdist: 
	tar -cz --exclude 'CVS' --exclude '*.log' --exclude '*~' \
	  -f jmdict.tgz Changes.txt README.txt schema.dia schema.png perl pg

web:	webcgi weblib webtal webcss
webcss:	$(CSS_FILES:perl/cgi/%=$(CSS_DIR)/%)
webcgi:	$(CGI_FILES:perl/cgi/%=$(CGI_DIR)/%)
weblib:	$(LIB_FILES:perl/lib/%=$(LIB_DIR)/%)
webtal:	$(TAL_FILES:perl/lib/tal/%=$(LIB_DIR)/tal/%)

$(CSS_DIR)/entr.css: perl/cgi/entr.css
	cp -p $? $@

$(CGI_DIR)/entr.pl: perl/cgi/entr.pl
	cp -p $? $@
$(CGI_DIR)/nwconf.pl: perl/cgi/nwconf.pl
	cp -p $? $@
$(CGI_DIR)/nwform.pl: perl/cgi/nwform.pl
	cp -p $? $@
$(CGI_DIR)/nwsub.pl: perl/cgi/nwsub.pl
	cp -p $? $@
$(CGI_DIR)/srchform.pl: perl/cgi/srchform.pl
	cp -p $? $@
$(CGI_DIR)/srchres.pl: perl/cgi/srchres.pl
	cp -p $? $@

$(LIB_DIR)/jmdict.pm: perl/lib/jmdict.pm
	cp -p $? $@
$(LIB_DIR)/jmdictcgi.pm: perl/lib/jmdictcgi.pm
	cp -p $? $@
$(LIB_DIR)/jmdicttal.pm: perl/lib/jmdicttal.pm
	cp -p $? $@

$(LIB_DIR)/tal/entr.tal: perl/lib/tal/entr.tal
	cp -p $? $@
	perl -pi -e 's%href="entr.css"%href="$(CSS_URL)"%' $@
$(LIB_DIR)/tal/nwconf.tal: perl/lib/tal/nwconf.tal
	cp -p $? $@
	perl -pi -e 's%href="entr.css"%href="$(CSS_URL)"%' $@
$(LIB_DIR)/tal/nwform.tal: perl/lib/tal/nwform.tal
	cp -p $? $@
	perl -pi -e 's%href="entr.css"%href="$(CSS_URL)"%' $@
$(LIB_DIR)/tal/srchform.tal: perl/lib/tal/srchform.tal
	cp -p $? $@
	perl -pi -e 's%href="entr.css"%href="$(CSS_URL)"%' $@
$(LIB_DIR)/tal/srchres.tal: perl/lib/tal/srchres.tal
	cp -p $? $@
	perl -pi -e 's%href="entr.css"%href="$(CSS_URL)"%' $@
