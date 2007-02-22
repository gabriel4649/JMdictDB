# $Revision$
# $Date$
#
# This makefile simplifies some of the tasks needed when installing
# or updating the jmdictdb files.  It works only on Unix/Linux systems.
# On Microsoft Windows you will need to do the things this makefile
# does, manually.
#
# "make all" will print a summary of targets.
#
# The following items should be adjusted based on your needs...

# Directory where the cgi perl scripts will go.
CGI_DIR = $(HOME)/public_html/cgi-bin

# Directory where the css file used by all the cgi scripts will go. 
CSS_DIR = $(HOME)/public_html

# A URL that will be used in the cgi generated html to refer to
# the .css file.  It is relative to the CGI_DIR directory.  Don't
# change the "entr.css" part.
CSS_URL = ../entr.css

# Directory where the perl library modules used by the cgi scripts will go.
# ***NOTE***: Currently this directory *must* be a sibling directory of
# the CGI_DIR directory and *must* be named "lib", so this is not really
# very configurable yet.  atode.
LIB_DIR = $(HOME)/public_html/lib

##############################################################################

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
	@echo 'You must supply an explicit target with this makefile:'
	@echo '  jmdict.xml -- Get latest jmdict xml file from Monash.'
	@echo '  jmdict.dmp -- Create Postgres load file from jmdict.xml file.'
	@echo '  loaddb -- Initialize new database and load jmdict.dmp.'
	@echo '  dist -- Make development snapshot distribution file.'
	@echo '  web -- Install cgi and other web files to the appropriate places.'

jmdict.xml: 
	rm -f JMdict_e.gz
	wget ftp://ftp.cc.monash.edu.au/pub/nihongo/JMdict_e.gz
	gunzip JMdict_e.gz
	mv JMdict_e jmdict.xml

jmdict.dmp: jmdict.xml
	cd perl && perl load_jmdict.pl -o ../jmdict.dmp ../jmdict.xml

loaddb: jmdict.dmp
	@echo 'Initializing jmdict database...'
	cd pg && psql -U postgres -f reload.sql
	@echo 'Loading jmdict XML data...'
	cd pg && psql -U postgres -d jmdict <../jmdict.dmp
	@echo 'Building indexes and doing other post-load actions...'
	cd pg && psql -U postgres -d jmdict -f postload.sql

clean:
	rm -f jmdict.tgz
	find -name '*~' -type f -print0 | xargs -0 /bin/rm -f
	find -name '*.tmp' -type f -print0 | xargs -0 /bin/rm -f

dist: 
	tar -cz -f jmdict.tgz \
	  --exclude 'CVS' --exclude '*.log' --exclude '*~' --exclude '*.tmp' \
	  --exclude '\#*' --exclude '\.*' \
	  README.txt Changes.txt Makefile schema.dia schema.png perl pg

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
