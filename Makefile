# $Revision$
# $Date$
#
# This makefile simplifies some of the tasks needed when installing
# or updating the jmdictdb files.  It can be used on both Unix/Linux 
# and Windows systems, although on the latter you will need to install
# GNU Make, either a native port or from Cygwin.  (The Cywin Make can
# be run directly from a CMD.EXE window -- it is not necessary to run
# it from a Cygwin bash shell.)  On Windows you will likely want to 
# change the definition of WEBROOT below.
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

# Locale to use when initializing a new database.  This should
# be a Japanese locale; if not, sorted Japanese text results will
# not be ordered correctly.  You may need to change it if the 
# given locale is not available on your system.  In particular
# Microsoft Windows users will want to change this to "japanese".
DBLOCALE = ja_JP.utf8

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

# Name of database used for general testing and experimentation.
DBTEST = jmtest

# Postgresql user that will be used to create the jmdictdb
# tables and other objects.  Users defined in the
# python/lib/config.ini file should match.
USER = jmdictdb

# Postgres user that has select-only (i.e. read-only access
# to the database.  Used only for creating this user in target
# 'jminit'.  Users defined in the python/lib/config.ini file
# should match.
RO_USER = jmdictdbv

# A postgresql user that has create database privs.
PG_SUPER = postgres

# Name of the machine hosting the Postgresql database server.
# If blank, localhost will be used.
HOST =

# The following specify where the cgi scripts, the python modules they
# use, and the .css file, respectively, go.  The location and names
# can be changed, but (currently) their relative positions must remain
# the same: the cgi and lib dirs must be siblings and the css file goes
# in their common parent directory.
# On Windows "~" expansion doesn't seem to work, so you will likely
# want to change the definition of WEBROOT below.  Alternatively, you 
# can configure your web server to serve the cgi files directly from 
# the development working directory and not use the "web" target in 
# this makefile install the cgi files to WEBROOT.
WEBROOT = $(wildcard ~/public_html)
CGI_DIR = $(WEBROOT)/cgi-bin
LIB_DIR = $(WEBROOT)/lib
CSS_DIR = $(WEBROOT)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# You should not need to change anything below here.

ifeq ($(HOST),)
PG_HOST =
JM_HOST =
else
PG_HOST = -h $(HOST)
JM_HOST = -r $(HOST)
endif

CSS_FILES = jmdict.css
WEB_CSS = $(addprefix $(CSS_DIR)/,$(CSS_FILES))

CGI_FILES = entr.py \
	edconf.py \
	edform.py \
	edhelp.py \
	edhelpq.py \
	edsubmit.py \
	srchform.py \
	srchformq.py \
	srchres.py \
	srchsql.py \
	jbedit.py \
	jbedits.py
        updates.py
WEB_CGI	= $(addprefix $(CGI_DIR)/,$(CGI_FILES))

LIB_FILES = jdb.py \
	cgitbx.py \
	config.ini \
	edparse.py \
	fmt.py \
	fmtjel.py \
	fmtxml.py \
	iso639maps.py \
	jellex.py \
	jelparse.py \
	jelparse_tab.py \
	jmcgi.py \
	objects.py \
	serialize.py \
	tal.py \
	xmlkw.py \
	xslfmt.py \
	edict2.xsl
WEB_LIB	= $(addprefix $(LIB_DIR)/,$(LIB_FILES))

PYLIB_FILES = __init__.py \
	config.py \
	odict.py
WEB_PYLIB = $(addprefix $(LIB_DIR)/pylib/,$(PYLIB_FILES))

TAL_FILES = entr.tal \
	edconf.tal \
	edform.tal \
	edhelp.tal \
	edhelpq.tal \
	macros.tal \
	srchform.tal \
        srchformq.tal \
	srchres.tal \
	srchsql.tal \
	submitted.tal \
	url_errors.tal \
	jbedits.tal
WEB_TAL	= $(addprefix $(LIB_DIR)/tmpl/,$(TAL_FILES))

all:
	@echo 'You must supply an explicit target with this makefile:'
	@echo
	@echo '  newdb -- Initialize an empty jmnew database.'
	@echo
	@echo '  data/jmdict.xml -- Get latest jmdict xml file from Monash.'
	@echo '  data/jmdict.pgi -- Create intermediate file from jmdict.xml file.'
	@echo '  data/jmdict.dmp -- Create Postgres load file from intermediate file.'
	@echo '  loadjm -- Load jmdict into existing database jmnew.'
	@echo
	@echo '  data/jmnedict.xml -- Get latest jmnedict xml file from Monash.'
	@echo '  data/jmnedict.pgi -- Create intermediate file from jmdict.xml file.'
	@echo '  data/jmnedict.dmp -- Create Postgres load file from intermediate file.'
	@echo '  loadne -- Load jmnedict into existing database jmnew.'
	@echo
	@echo '  data/examples.txt -- Get latest Examples file from Monash.'
	@echo '  data/examples.pgi -- Create intermediate file from examples.xml file.'
	@echo '  data/examples.dmp -- Create Postgres load file from intermediate file.'
	@echo '  loadex -- Load examples into the existing database jmnew.'
	@echo
	@echo '  loadall -- Initialize database jmnew and load jmdict, jmnedict, examples.'
	@echo
	@echo '  activate -- Move installed database to production status.'
	@echo '  web -- Install cgi and other web files to the appropriate places.'
	@echo '  dist -- Make development snapshot distribution file.'

#------ Create jmsess and jmdictdb users ---------------------------------

    # Run this target only once when creating a jmdictdb server
    # installation.  Creates a jmsess database and two dedicated
    # users that the jmdictdb app will use to access the database.
 
init: 
	-createuser $(PG_HOST) -U $(PG_SUPER) -SDRP $(USER)
	-createuser $(PG_HOST) -U $(PG_SUPER) -SDRP $(RO_USER)
	# Don't automatically drop old session database due to risk 
	# of unintentionally loosing user logins and passwords.  If
	# it exists, the subsequent CREATE  DATABASE command will
	# fail and require the user to manually drop the session
	# database or otherwise manually correct the situation.
	#psql $(PG_HOST) -U $(PG_SUPER) -d postgres -c 'drop database if exists $(DBSESS)'
	psql $(PG_HOST) -U $(PG_SUPER) -d postgres -c 'create database jmsess'
	cd pg && psql $(PG_HOST) -U $(USER) -d jmsess -f mksess.sql
	@echo 'Remember to add jmdictdb editors to the jmsess "users" table.' 

#------ Create a new database for loading -------------------------------

newdb:
	psql $(PG_HOST) -U $(PG_SUPER) -d postgres -c 'drop database if exists $(DB)'
	psql $(PG_HOST) -U $(PG_SUPER) -d postgres -c "create database $(DB) owner $(USER) template template0 encoding 'utf8' lc_collate '$(DBLOCALE)' lc_ctype '$(DBLOCALE)'"
	cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) -f reload.sql
	cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) -f postload.sql
#
#------ Move installation database to active ----------------------------

activate:
	psql $(PG_HOST) -U $(PG_SUPER) -d $(DB) -c 'SELECT 1' >/dev/null # Check existance.
	psql $(PG_HOST) -U $(PG_SUPER) -d postgres -c 'drop database if exists $(DBOLD)'
	-psql $(PG_HOST) -U $(PG_SUPER) -d postgres -c 'alter database $(DBACT) rename to $(DBOLD)'
	psql $(PG_HOST) -U $(PG_SUPER) -d postgres -c 'alter database $(DB) rename to $(DBACT)'

#------ Move installation database to test ------------------------------

activate_test:
	psql $(PG_HOST) -U $(PG_SUPER) -d $(DB) -c 'SELECT 1' >/dev/null # Check existance.
	psql $(PG_HOST) -U $(PG_SUPER) -d postgres -c 'drop database if exists $(DBTEST)'
	psql $(PG_HOST) -U $(PG_SUPER) -d postgres -c 'alter database $(DB) rename to $(DBTEST)'

#------ Load JMdict -----------------------------------------------------

data/jmdict.xml: 
	rm -f $(JMDICTFILE).gz
	wget ftp://ftp.monash.edu.au/pub/nihongo/$(JMDICTFILE).gz
	gzip -d $(JMDICTFILE).gz
	mv $(JMDICTFILE) data/jmdict.xml

data/jmdict.pgi: data/jmdict.xml
	cd python && python jmparse.py $(LANGOPT) -y -l ../data/jmdict.log -o ../data/jmdict.pgi ../data/jmdict.xml

data/jmdict.dmp: data/jmdict.pgi
	cd python && python jmload.py $(JM_HOST) -u $(USER) -d $(DB) -i 1 -o ../data/jmdict.dmp ../data/jmdict.pgi

loadjm: data/jmdict.dmp
	-cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) -f drpindex.sql
	cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) <../data/jmdict.dmp
	cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) -f postload.sql
	cd python && python xresolv.py $(JM_HOST) -u $(USER) -d $(DB) >../data/jmdict_xresolv.log
	cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) -c "vacuum analyze xref"
	@echo 'Remember to check the log files for warning messages.'

#------ Load JMnedict ----------------------------------------------------

# Assumes the jmdict has been loaded into database already.

data/jmnedict.xml: 
	rm -f JMnedict.xml.gz
	wget ftp://ftp.monash.edu.au/pub/nihongo/JMnedict.xml.gz
	gzip -d JMnedict.xml.gz
	mv JMnedict.xml data/jmnedict.xml

data/jmnedict.pgi: data/jmnedict.xml
	cd python && python jmparse.py -l ../data/jmnedict.log -o ../data/jmnedict.pgi ../data/jmnedict.xml

data/jmnedict.dmp: data/jmnedict.pgi
	cd python && python jmload.py $(JM_HOST) -u $(USER) -d $(DB) -o ../data/jmnedict.dmp ../data/jmnedict.pgi

loadne: data/jmnedict.dmp
	-cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) -f drpindex.sql
	cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) <../data/jmnedict.dmp
	cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) -f postload.sql

#------ Load examples ---------------------------------------------------

data/examples.txt: 
	rm -f examples.utf.gz
	wget ftp://ftp.monash.edu.au/pub/nihongo/examples.utf.gz
	gzip -d examples.utf.gz
	mv examples.utf data/examples.txt

data/examples.pgi: data/examples.txt 
	cd python && python exparse.py -o ../data/examples.pgi -l ../data/examples.log ../data/examples.txt

data/examples.dmp: data/examples.pgi 
	cd python && python jmload.py $(JM_HOST) -u $(USER) -d $(DB) -o ../data/examples.dmp ../data/examples.pgi

loadex: data/examples.dmp 
	-cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) -f drpindex.sql
	cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) <../data/examples.dmp
	cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) -f postload.sql
	# The following command is commented out because of the long time
	# it can take to run.  It may be run manually after 'make' finishes.
	#cd python && python xresolv.py $(JM_HOST) -u $(USER) -d $(DB) -s3 -t1 >../data/examples_xresolv.log
	#cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) -c 'vacuum analyze xref;'

#------ Load kanjidic2,xml ---------------------------------------------------

data/kanjidic2.xml: 
	rm -f kanjidic2.xml.gz
	wget ftp://ftp.monash.edu.au/pub/nihongo/kanjidic2.xml.gz
	gzip -d kanjidic2.xml.gz
	mv kanjidic2.xml data/kanjidic2.xml

data/kanjidic2.pgi: data/kanjidic2.xml 
	cd python && python kdparse.py -g en -o ../data/kanjidic2.pgi -l ../data/kanjidic2.log ../data/kanjidic2.xml 

data/kanjidic2.dmp: data/kanjidic2.pgi 
	cd python && python jmload.py $(JM_HOST) -u $(USER) -d $(DB) -o ../data/kanjidic2.dmp ../data/kanjidic2.pgi

loadkd: data/kanjidic2.dmp 
	cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) -f drpindex.sql
	cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) <../data/kanjidic2.dmp
	cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) -f postload.sql

#------ Load jmdict, jmnedict, examples -------------------------------------

# Note that we cannot reuse jmnedict.dmp or examples.dmp since the
# the number of entries may be different in the freshly loaded jmdict
# set, invalidating the starting id numbers in the other .dmp files.

loadall: newdb data/jmdict.dmp data/jmnedict.pgi data/examples.pgi 
	cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) -f drpindex.sql
	cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) <../data/jmdict.dmp

	cd python && python jmload.py $(JM_HOST) -u $(USER) -d $(DB) -o ../data/examples.dmp ../data/examples.pgi
	cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) <../data/examples.dmp

	cd python && python jmload.py $(JM_HOST) -u $(USER) -d $(DB) -o ../data/jmnedict.dmp ../data/jmnedict.pgi
	cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) <../data/jmnedict.dmp

	cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) -f postload.sql
	cd python && python xresolv.py $(JM_HOST) -u $(USER) -d $(DB) >../data/jmdict_xresolv.log
	#cd python && python xresolv.py $(JM_HOST) -u $(USER) -d $(DB) -s3 >../data/examples_xresolv.log
	cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) -c "vacuum analyze xref"
	@echo 'Remember to check the log files for warning messages.'

#------ Move cgi files to web server location --------------------------

web:	webcgi weblib webpylib webtal webcss

webcss: $(WEB_CSS)
$(WEB_CSS): $(CSS_DIR)/%: web/%
	install -pm 644 $? $@

webcgi: $(WEB_CGI)
$(WEB_CGI): $(CGI_DIR)/%: web/cgi/%
	install -p -m 755 $? $@

weblib: $(WEB_LIB)
$(WEB_LIB): $(LIB_DIR)/%: python/lib/%
	install -pm 644 $? $@

webpylib: $(WEB_PYLIB)
$(WEB_PYLIB): $(LIB_DIR)/pylib/%: python/lib/pylib/%
	install -pm 644 $? $@

webtal: $(WEB_TAL)
$(WEB_TAL): $(LIB_DIR)/%: python/lib/%
	install -pm 644 $? $@

#------ Other ----------------------------------------------------------

subdirs:
	cd pg/ && $(MAKE)
	cd python/lib/ && $(MAKE)

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
	tar -cz -f jmdict.tgz --exclude data --exclude 'CVS' --exclude './jmdict.tgz' .

