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
# Alternatively, they can be overridden when "make" is run as in 
# the following example:
#
#    make JMDICTFILE=JMdict "LANGOPT=-g fre"
#
# The JMdict file to download.  Choice is usually between JMdict 
# which contains multi-lingual glosses, and JMdict_e that contains
# only English glosses but is 25% smaller and parses faster.
JMDICTFILE = JMdict_e
#JMDICTFILE = JMdict

# Parse out only glosses of the specified language.  If not 
# supplied, all glosses will be parsed, regardless of language.
# Language specified using ISO-639-2 3-letter abbreviation.
#LANGOPT = -g eng

# Name of database to load new data into.  The new data is loaded
# into this database first, without changing the in-service
# production database, for any testing needed.  When the database
# has been verified, in can be moved into the production database
# usng the makefile target "activate".
DB = jmnew

# Name of the production database...
DBACT = jmdict

# Name of previous production database (saved when newly
# created database is moved to production status...
DBOLD = jmold

# Postgresql user under which to run postgresql commands.
# If blank, user name will be determined by the usual 
# Postgresql libpq means (see subsection "Connecting To A 
# Database" in the the Postgresql docs (Reference / PostgreSQL 
# Client Applications / psql).
USER = postgres

# Name of the machine hosting the Postgresql database server.
# If blank, localhost will be used.
HOST =

# The following specify where the cgi scripts, the perl modules they
# use, and the .css file, respectively, go.  The location and names
# can be changed, but (currently) their relative positions must remain
# the same: the cgi and lib dirs must be siblings and the css file goes
# in their common parent directory.
CGI_DIR = $(HOME)/public_html/cgi-bin
LIB_DIR = $(HOME)/public_html/lib
CSS_DIR = $(HOME)/public_html

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# You should not need to change anything below here.

PG_DB = -d $(DB)
JM_DB = -d $(DB)

ifeq ($(USER),)
PG_USER =
JM_USER =
else
PG_USER = -U $(USER)
JM_USER = -u $(USER)
endif

ifeq ($(HOST),)
PG_HOST =
JM_HOST =
else
PG_HOST = -h $(HOST)
JM_HOST = -r $(HOST)
endif

CSS_FILES = web/jmdict.css

CGI_FILES = web/cgi/entr.pl \
	web/cgi/edconf.pl \
	web/cgi/edform.pl \
	web/cgi/edhelp.pl \
	web/cgi/edsubmit.pl \
	web/cgi/srchform.pl \
	web/cgi/srchres.pl \
	web/cgi/jbparser.pl

LIB_FILES = perl/lib/jmdict.pm \
	perl/lib/jmdictcgi.pm \
	perl/lib/jmdicttal.pm \
	perl/lib/jbparser.pm \
	perl/lib/jmdictfmt.pm \
	perl/lib/jbparser.yp \
	perl/lib/kwstatic.pm 

TAL_FILES = perl/lib/tal/entr.tal \
	perl/lib/tal/edconf.tal \
	perl/lib/tal/edform.tal \
	perl/lib/tal/edhelp.tal \
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
	@echo '  activate -- Move installed database to production status.
	@echo '  web -- Install cgi and other web files to the appropriate places.'
	@echo '  dist -- Make development snapshot distribution file.'

#------ Move installation database to active ----------------------------

activate:
	psql $(PG_HOST) $(PG_USER) $(PG_DB) -c 'SELECT 1' >/dev/null # Check existance.
	psql $(PG_HOST) $(PG_USER) -d postgres -c 'drop database if exists $(DBOLD)'
	-psql $(PG_HOST) $(PG_USER) -d postgres -c 'alter database $(DBACT) rename to $(DBOLD)'
	psql $(PG_HOST) $(PG_USER) -d postgres -c 'alter database $(DB) rename to $(DBACT)'

#------ Load JMdict -----------------------------------------------------

jmdict.xml: 
	rm -f $(JMDICTFILE).gz
	wget ftp://ftp.cc.monash.edu.au/pub/nihongo/$(JMDICTFILE).gz
	gzip -d $(JMDICTFILE).gz
	mv $(JMDICTFILE) jmdict.xml

jmdict.pgi: jmdict.xml
	cd perl && perl jmparse.pl $(LANGOPT) -y -l ../jmdict.log -o ../jmdict.pgi ../jmdict.xml

jmdict.dmp: jmdict.pgi
	cd perl && perl jmload.pl $(JM_HOST) $(JM_USER) $(JM_DB) -i 1 -o ../jmdict.dmp ../jmdict.pgi


loadjm: jmdict.dmp
	psql $(PG_HOST) $(PG_USER) -d postgres -c 'drop database if exists $(DB)'
	psql $(PG_HOST) $(PG_USER) -d postgres -c "create database $(DB) encoding 'utf8'"
	cd pg && psql $(PG_HOST) $(PG_USER) $(PG_DB) -f reload.sql
	cd pg && psql $(PG_HOST) $(PG_USER) $(PG_DB) <../jmdict.dmp
	cd pg && psql $(PG_HOST) $(PG_USER) $(PG_DB) -f postload.sql
	cd perl && perl xresolv.pl -q $(JM_HOST) $(JM_USER) $(JM_DB) >../jmdict_xresolv.log
	cd pg && psql $(PG_HOST) $(PG_USER) $(PG_DB) -c "vacuum analyze xref"
	@echo 'Remember to check the log files for warning messages.'


#------ Load JMnedict ----------------------------------------------------

# Assumes the jmdict has been loaded into database already.

jmnedict.xml: 
	rm -f JMnedict.xml.gz
	wget ftp://ftp.cc.monash.edu.au/pub/nihongo/JMnedict.xml.gz
	gzip -d JMnedict.xml.gz
	mv JMnedict.xml jmnedict.tmp
	mv jmnedict.tmp jmnedict.xml

jmnedict.pgi: jmnedict.xml
	cd perl && perl jmparse.pl -l ../jmnedict.log -o ../jmnedict.pgi ../jmnedict.xml

jmnedict.dmp: jmnedict.pgi
	cd perl && perl jmload.pl $(JM_HOST) $(JM_USER) $(JM_DB) -o ../jmnedict.dmp ../jmnedict.pgi

loadne: jmnedict.dmp
	-cd pg && psql $(PG_HOST) $(PG_USER) $(PG_DB) -f drpindex.sql
	cd pg && psql $(PG_HOST) $(PG_USER) $(PG_DB) <../jmnedict.dmp
	cd pg && psql $(PG_HOST) $(PG_USER) $(PG_DB) -f mkindex.sql
	cd pg && psql $(PG_HOST) $(PG_USER) $(PG_DB) -f syncseq.sql

#------ Load examples ---------------------------------------------------

examples.txt: 
	rm -f examples.utf.gz
	wget ftp://ftp.cc.monash.edu.au/pub/nihongo/examples.utf.gz
	gzip -d examples.utf.gz
	mv examples.utf examples.txt

examples.pgi: examples.txt 
	cd perl && perl exparse.pl -o ../examples.pgi ../examples.txt >../examples.log

examples.dmp: examples.pgi 
	cd perl && perl jmload.pl $(JM_HOST) $(JM_USER) $(JM_DB) -o ../examples.dmp ../examples.pgi

loadex: examples.dmp 
	-cd pg && psql $(PG_HOST) $(PG_USER) $(PG_DB) -f drpindex.sql
	cd pg && psql $(PG_HOST) $(PG_USER) $(PG_DB) <../examples.dmp
	cd pg && psql $(PG_HOST) $(PG_USER) $(PG_DB) -f mkindex.sql
	cd pg && psql $(PG_HOST) $(PG_USER) $(PG_DB) -f syncseq.sql
	# The following command is commented out because of the long time
	# it can take to run.  It may be run manually after 'make' finishes.
	#cd perl && perl xresolv.pl -q $(JM_HOST) $(JM_USER) $(JM_DB) -s3 -t1 >../examples_xresolv.log
	#cd pg && psql $(PG_HOST) $(PG_USER) $(PG_DB) -c 'vacuum analyze xref;'

#------ Load kanjidic2,xml ---------------------------------------------------

kanjidic2.xml: 
	rm -f kanjidic2.xml.gz
	wget ftp://ftp.cc.monash.edu.au/pub/nihongo/kanjidic2.xml.gz
	gzip -d kanjidic2.xml.gz

kanjidic2.pgi: kanjidic2.xml 
	cd python && python kdparse.py -g en -o ../kanjidic2.pgi -l ../kanjidic2.log ../kanjidic2.xml 

kanjidic2.dmp: kanjidic2.pgi 
	cd perl && perl jmload.pl $(JM_HOST) $(JM_USER) $(JM_DB) -o ../kanjidic2.dmp ../kanjidic2.pgi

loadkd: kanjidic2.dmp 
	#-cd pg && psql $(PG_HOST) $(PG_USER) $(PG_DB) -f drpindex.sql
	cd pg && psql $(PG_HOST) $(PG_USER) $(PG_DB) <../kanjidic2.dmp
	#cd pg && psql $(PG_HOST) $(PG_USER) $(PG_DB) -f mkindex.sql
	cd pg && psql $(PG_HOST) $(PG_USER) $(PG_DB) -f syncseq.sql

#------ Load jmdict, jmnedict, examples -------------------------------------

# Note that we cannot reuse jmnedict.dmp or examples.dmp since the
# the number of entries may be different in the freshly loaded jmdict
# set, invalidating the starting id numbers in the other .dmp files.

loadall: jmdict.dmp jmnedict.pgi examples.pgi 
	psql $(PG_HOST) $(PG_USER) -d postgres -c 'drop database if exists $(DB)'
	psql $(PG_HOST) $(PG_USER) -d postgres -c "create database $(DB) encoding 'utf8'"
	cd pg && psql $(PG_HOST) $(PG_USER) $(PG_DB) -f reload.sql
	cd pg && psql $(PG_HOST) $(PG_USER) $(PG_DB) <../jmdict.dmp

	cd perl && perl jmload.pl $(JM_HOST) $(JM_USER) $(JM_DB) -o ../examples.dmp ../examples.pgi
	cd pg && psql $(PG_HOST) $(PG_USER) $(PG_DB) <../examples.dmp

	cd perl && perl jmload.pl $(JM_HOST) $(JM_USER) $(JM_DB) -o ../jmnedict.dmp ../jmnedict.pgi
	cd pg && psql $(PG_HOST) $(PG_USER) $(PG_DB) <../jmnedict.dmp

	cd pg && psql $(PG_HOST) $(PG_USER) $(PG_DB) -f postload.sql
	cd perl && perl xresolv.pl -q $(JM_HOST) $(JM_USER) $(JM_DB) >../jmdict_xresolv.log
	#cd perl && perl xresolv.pl -q $(JM_HOST) $(JM_USER) $(JM_DB) -s3 >../examples_xresolv.log
	cd pg && psql $(PG_HOST) $(PG_USER) $(PG_DB) -c "vacuum analyze xref"
	@echo 'Remember to check the log files for warning messages.'

#------ Other ----------------------------------------------------------

subdirs:
	cd pg/ && $(MAKE)
	cd perl/lib/ && $(MAKE)

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
	rm jmdict.tgz
	touch jmdict.tgz
	tar -cz -f jmdict.tgz --exclude 'CVS' --exclude './jmdict.tgz' .

web:	webcgi weblib webtal webcss
webcss:	$(CSS_FILES:web/%=$(CSS_DIR)/%)
webcgi:	$(CGI_FILES:web/cgi/%=$(CGI_DIR)/%)
weblib:	$(LIB_FILES:perl/lib/%=$(LIB_DIR)/%)
webtal:	$(TAL_FILES:perl/lib/tal/%=$(LIB_DIR)/tal/%)

$(CSS_DIR)/jmdict.css: web/jmdict.css
	cp -p $? $@

$(CGI_DIR)/entr.pl: web/cgi/entr.pl
	cp -p $? $@
$(CGI_DIR)/edconf.pl: web/cgi/edconf.pl
	cp -p $? $@
$(CGI_DIR)/edform.pl: web/cgi/edform.pl
	cp -p $? $@
$(CGI_DIR)/edhelp.pl: web/cgi/edhelp.pl
	cp -p $? $@
$(CGI_DIR)/edsubmit.pl: web/cgi/edsubmit.pl
	cp -p $? $@
$(CGI_DIR)/srchform.pl: web/cgi/srchform.pl
	cp -p $? $@
$(CGI_DIR)/srchres.pl: web/cgi/srchres.pl
	cp -p $? $@
$(CGI_DIR)/jbparser.pl: web/cgi/jbparser.pl
	cp -p $? $@

$(LIB_DIR)/jmdict.pm: perl/lib/jmdict.pm
	cp -p $? $@
$(LIB_DIR)/jmdictcgi.pm: perl/lib/jmdictcgi.pm
	cp -p $? $@
$(LIB_DIR)/jmdicttal.pm: perl/lib/jmdicttal.pm
	cp -p $? $@
$(LIB_DIR)/jbparser.pm: perl/lib/jbparser.pm
	cp -p $? $@
# Needed for cgi/jbparser.pl...
$(LIB_DIR)/jbparser.yp: perl/lib/jbparser.yp
	cp -p $? $@
$(LIB_DIR)/jmdictfmt.pm: perl/lib/jmdictfmt.pm
	cp -p $? $@
$(LIB_DIR)/kwstatic.pm: perl/lib/kwstatic.pm
	cp -p $? $@

$(LIB_DIR)/tal/entr.tal: perl/lib/tal/entr.tal
	cp -p $? $@
$(LIB_DIR)/tal/edconf.tal: perl/lib/tal/edconf.tal
	cp -p $? $@
$(LIB_DIR)/tal/edform.tal: perl/lib/tal/edform.tal
	cp -p $? $@
$(LIB_DIR)/tal/edhelp.tal: perl/lib/tal/edhelp.tal
	cp -p $? $@
$(LIB_DIR)/tal/srchform.tal: perl/lib/tal/srchform.tal
	cp -p $? $@
$(LIB_DIR)/tal/srchres.tal: perl/lib/tal/srchres.tal
	cp -p $? $@
