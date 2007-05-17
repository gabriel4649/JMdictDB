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

PG_USER = -U postgres
PG_HOST =

### WARNING...
### If you change the database name below, you must also
### change it in reload.sql.
PG_DB = jmdict


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
	@echo '  jmdict.pgi -- Create intermediate file from jmdict.xml file.'
	@echo '  jmdict.dmp -- Create Postgres load file from intermediate file.'
	@echo '  loadjm -- Initialize database and load jmdict.'
	@echo
	@echo '  jmnedict.xml -- Get latest jmnedict xml file from Monash.'
	@echo '  jmnedict.pgi -- Create intermediate file from jmdict.xml file.'
	@echo '  jmnedict.dmp -- Create Postgres load file from intermediate file.'
	@echo '  loadne -- Load jmnedict into the existing database.'
	@echo
	@echo '  examples.txt -- Get latest Examples file from Monash.'
	@echo '  examples.pgi -- Create intermediate file from examples.xml file.'
	@echo '  examples.dmp -- Create Postgres load file from intermediate file.'
	@echo '  loadex -- Load examples into the existing database.'
	@echo
	@echo '  loadall -- Initialize database and load jmdict, jmnedict, and examples.'
	@echo
	@echo '  web -- Install cgi and other web files to the appropriate places.'
	@echo '  dist -- Make development snapshot distribution file.'

#------ Load JMdict -----------------------------------------------------

jmdict.xml: 
	rm -f JMdict_e.gz
	wget ftp://ftp.cc.monash.edu.au/pub/nihongo/JMdict_e.gz
	gunzip JMdict_e.gz
	mv JMdict_e jmdict.xml

jmdict.pgi: jmdict.xml
	cd perl && perl jmparse.pl -l ../jmdict.log -o ../jmdict.pgi ../jmdict.xml

jmdict.dmp: jmdict.pgi
	cd perl && perl jmload.pl -i 1 -o ../jmdict.dmp ../jmdict.pgi


loadjm: jmdict.dmp
	cd pg && psql $(PG_HOST) $(PG_USER) -f reload.sql
	cd pg && psql $(PG_HOST) $(PG_USER) -d $(PG_DB) <../jmdict.dmp
	cd pg && psql $(PG_HOST) $(PG_USER) -d $(PG_DB) -f postload.sql
	cd pg && psql $(PG_HOST) $(PG_USER) -d $(PG_DB) -f xresolv.sql

#------ Load JMnedict ----------------------------------------------------

# Assumes the jmdict has been loaded into database already.

jmnedict.xml: 
	rm -f JMnedict.xml.gz
	wget ftp://ftp.cc.monash.edu.au/pub/nihongo/JMnedict.xml.gz
	gunzip JMnedict.xml.gz
	mv JMnedict.xml jmnedict.xml

jmnedict.pgi: jmnedict.xml
	cd perl && perl jmparse.pl -l ../jmnedict.log -o ../jmnedict.pgi ../jmnedict.xml

jmnedict.dmp: jmnedict.pgi
	cd perl && perl jmload.pl -o ../jmnedict.dmp ../jmnedict.pgi

loadne: jmnedict.dmp
	cd pg && psql $(PG_HOST) $(PG_USER) -d $(PG_DB) -f drpindex.sql
	cd pg && psql $(PG_HOST) $(PG_USER) -d $(PG_DB) <../jmnedict.dmp
	cd pg && psql $(PG_HOST) $(PG_USER) -d $(PG_DB) -f mkindex.sql
	cd pg && psql $(PG_HOST) $(PG_USER) -d $(PG_DB) -f syncseq.sql
	
#------ Load examples ---------------------------------------------------

examples.txt: 
	rm -f examples.utf8.gz
	wget ftp://ftp.cc.monash.edu.au/pub/nihongo/examples.utf8.gz
	gunzip examples.utf8.gz
	mv examples.utf8 >examples.txt

examples.pgi: examples.txt
	cd perl && perl exparse.pl -o ../examples.pgi ../examples.txt >../exparse.log

examples.dmp: examples.pgi
	cd perl && perl jmload.pl -o ../examples.dmp ../examples.pgi

loadex: examples.dmp
	cd pg && psql $(PG_HOST) $(PG_USER) -d $(PG_DB) -f drpindex.sql
	cd pg && psql $(PG_HOST) $(PG_USER) -d $(PG_DB) <../examples.dmp
	cd pg && psql $(PG_HOST) $(PG_USER) -d $(PG_DB) -f mkindex.sql
	cd pg && psql $(PG_HOST) $(PG_USER) -d $(PG_DB) -f syncseq.sql

#------ Load all three -------------------------------------------------

# Note that we cannot reuse jmnedict.dmp or examples.dmp since the
# the number of entries may be different in the freshly loaded jmdict
# set, invalidating the starting id numbers in the other .dmp files.

loadall: jmdict.dmp jmnedict.pgi examples.pgi
	cd pg && psql $(PG_HOST) $(PG_USER) -f reload.sql
	cd pg && psql $(PG_HOST) $(PG_USER) -d $(PG_DB) <../jmdict.dmp

	cd perl && perl jmload.pl -o ../jmnedict.dmp ../jmnedict.pgi
	cd pg && psql $(PG_HOST) $(PG_USER) -d $(PG_DB) <../jmnedict.dmp

	cd perl && perl jmload.pl -o ../examples.dmp ../examples.pgi
	cd pg && psql $(PG_HOST) $(PG_USER) -d $(PG_DB) <../examples.dmp
	cd pg && psql $(PG_HOST) $(PG_USER) -d $(PG_DB) -f postload.sql
	cd pg && psql $(PG_HOST) $(PG_USER) -d $(PG_DB) -f xresolv.sql

#------ Other ----------------------------------------------------------

clean:
	rm -f jmdict.tgz
	find -name '*.log' -type f -print0 | xargs -0 /bin/rm -f
	find -name '*~' -type f -print0 | xargs -0 /bin/rm -f
	find -name '*.tmp' -type f -print0 | xargs -0 /bin/rm -f
	find -name '\#*' -type f -print0 | xargs -0 /bin/rm -f
	find -name '\.*' -type f -print0 | xargs -0 /bin/rm -f

dist: 
	# This should be run in a freshly checked out
	# directory to avoid including spurious files.
	tar -cz -f jmdict.tgz \
	  --exclude 'CVS' --exclude '*.log' --exclude '*~' --exclude '*.tmp' \
	  --exclude '\#*' --exclude '\.*' .

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
