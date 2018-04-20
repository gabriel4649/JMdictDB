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
# Command used to run your Python interpreter.  Note that the
# JMdictDB code no longer runs under Python2.
PYTHON = python3

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

# Name of database used for running code tests.
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

# A postgresql user that has superuser database privs.
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
# this makefile (which installs the cgi files to WEBROOT).
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

CSS_FILES = jmdict.css \
	status_maint.html \
	status_load.html
WEB_CSS = $(addprefix $(CSS_DIR)/,$(CSS_FILES))

CGI_FILES = conj.py \
	entr.py \
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
	jbedits.py \
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
	jinja.py \
	jmcgi.py \
	logger.py \
	objects.py \
	serialize.py \
	xmlkw.py \
	xslfmt.py \
	edict2.xsl
WEB_LIB	= $(addprefix $(LIB_DIR)/,$(LIB_FILES))

TMPL_FILES = conj.jinja \
	entr.jinja \
	edconf.jinja \
	edform.jinja \
	edhelp.jinja \
	edhelpq.jinja \
	error.jinja \
        layout.jinja \
	srchform.jinja \
        srchformq.jinja \
	srchres.jinja \
	srchsql.jinja \
	submitted.jinja \
	updates.jinja \
	jbedits.jinja
WEB_TMPL = $(addprefix $(LIB_DIR)/tmpl/,$(TMPL_FILES))

all:
	@echo 'You must supply an explicit target with this makefile:'
	@echo
	@echo '  newdb -- Create an empty database named "jmnew".'
	@echo '  jmnew -- Create a database named "jmnew" with jmdictdb tables and '
	@echo '    jmdictdb objects created but no data loaded.'
	@echo
	@echo '  data/jmdict.xml -- Get latest jmdict xml file from Monash.'
	@echo '  data/jmdict.pgi -- Create intermediate file from jmdict.xml file.'
	@echo '  loadjm -- Load jmdict into existing database "jmnew".'
	@echo
	@echo '  data/jmnedict.xml -- Get latest jmnedict xml file from Monash.'
	@echo '  data/jmnedict.pgi -- Create intermediate file from jmdict.xml file.'
	@echo '  loadne -- Load jmnedict into existing database "jmnew".'
	@echo
	@echo '  data/examples.txt -- Get latest Examples file from Monash.'
	@echo '  data/examples.pgi -- Create intermediate file from examples.xml file.'
	@echo '  loadex -- Load examples into the existing database "jmnew".'
	@echo
	@echo '  data/kanjidic2.xml -- Get latest kanjidic2.xml file from Monash.'
	@echo '  data/kanjidic2.pgi -- Create intermediate file from examples.xml file.'
	@echo '  loadkd -- Load kanjidic into the existing database "jmnew".'
	@echo '   * WARNING: kanjidic2 support is usable but incomplete.'
	@echo
	@echo '  loadall -- Initialize database "jmnew" and load jmdict, jmnedict'
	@echo '     and examples.'
	@echo 
	@echo '  activate -- Rename the "jmnew" database to "jmdict".'
	@echo '  web -- Install cgi and other web files to the appropriate places.'
	@echo '  dist -- Make development snapshot distribution file.'
	@echo 
	@echo '  * NOTE: "make loadall" will do all needed database initialization.'
	@echo '  To load a subset of loadall (eg only loadjm and loadne), you should' 
	@echo '  do "make jmnew", then "make loadjm", "make loadne", etc as desired,'
	@echo '  then the last step should be "make postload".'

#------ Create jmsess and jmdictdb users ---------------------------------

    # Run this target only once when creating a jmdictdb server
    # installation.  Creates a jmsess database and two dedicated
    # users that the jmdictdb app will use to access the database.
 
init: 
	# Assume any errors from 'createuser' are due to the user 
	# already existing and ignore them. 
	-createuser $(PG_HOST) -U $(PG_SUPER) -SDRP $(USER)
	-createuser $(PG_HOST) -U $(PG_SUPER) -SDRP $(RO_USER)
	# Don't automatically drop old session database due to risk 
	# of unintentionally loosing user logins and passwords.  If
	# it exists, the subsequent CREATE  DATABASE command will
	# fail and require the user to manually drop the session
	# database or otherwise manually correct the situation.
	#psql $(PG_HOST) -U $(PG_SUPER) -d postgres -c 'drop database if exists $(DBSESS)'
	psql $(PG_HOST) -U $(PG_SUPER) -d postgres -c 'create database jmsess'
	psql $(PG_HOST) -U $(PG_SUPER) -d jmsess -c "CREATE EXTENSION IF NOT EXISTS pgcrypto"
	cd pg && psql $(PG_HOST) -U $(USER) -d jmsess -f mksess.sql
	@echo 'Remember to add jmdictdb editors to the jmsess "users" table.' 

#------ Create a blank jmnew database ----------------------------------
# 
# This may be useful when loading a dump of a jmdictdb database, e.g:
#   make newdb                       # Create blank jmnew database 
#   pg_restore -O jmdictdb -d jmnew  # Restore the dump into jmnew.
#   make activate                    # Rename jmnew to jmdict.

newdb:
	psql $(PG_HOST) -U $(PG_SUPER) -d postgres -c 'drop database if exists $(DB)'
	psql $(PG_HOST) -U $(PG_SUPER) -d postgres -c "create database $(DB) owner $(USER) template template0 encoding 'utf8' lc_collate '$(DBLOCALE)' lc_ctype '$(DBLOCALE)'"

#------ Create a new jmnew database with empty jmdictdb objects --------

jmnew: newdb
	cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) -f reload.sql
	cd pg && psql $(PG_HOST) -U $(PG_SUPER) -d $(DB) -f postload.sql

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

#------ Save foreign key and index definitions --------------------------

pgsubdir:
	cd pg && $(MAKE)

#------ Restore foreign key and index definitions -----------------------

postload:
	cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) -f fkcreate.sql
	cd pg && psql $(PG_HOST) -U $(PG_SUPER) -d $(DB) -f postload.sql
	cd python && $(PYTHON) xresolv.py $(JM_HOST) -u $(USER) -d $(DB) -i -s jmdict   -t jmdict  >../data/jmdict_xresolv.log
	cd python && $(PYTHON) xresolv.py $(JM_HOST) -u $(USER) -d $(DB) -i -s jmnedict -t jmnedict >../data/jmnedict_xresolv.log
        # we don't currently resolve the Examples xrefs because of the large numbers
        # of some of them (e.g. there are some 90k xrefs to the particle は.
	#cd python && $(PYTHON) xresolv.py $(JM_HOST) -u $(USER) -d $(DB) -i -s examples -t jmdict >../data/
	@echo 'Remember to check the log files for warning messages.'

#------ Load JMdict -----------------------------------------------------

data/jmdict.xml: 
	rm -f $(JMDICTFILE).gz
	wget ftp://ftp.monash.edu.au/pub/nihongo/$(JMDICTFILE).gz
	gzip -d $(JMDICTFILE).gz
	mv $(JMDICTFILE) data/jmdict.xml

data/jmdict.pgi: data/jmdict.xml
	cd python && $(PYTHON) jmparse.py $(LANGOPT) -y -l ../data/jmdict.log -o ../data/jmdict.pgi ../data/jmdict.xml

loadjm: data/jmdict.pgi pgsubdir
	cd python && $(PYTHON) jmload.py $(JM_HOST) -u $(USER) -d $(DB) -i 1 -o ../data/jmdict.dmp ../data/jmdict.pgi
	cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) -f fkdrop.sql
	cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) <../data/jmdict.dmp
	rm data/jmdict.dmp

#------ Load JMnedict ----------------------------------------------------

# Assumes the jmdict has been loaded into database already.

data/jmnedict.xml:
	rm -f JMnedict.xml.gz
	wget ftp://ftp.monash.edu.au/pub/nihongo/JMnedict.xml.gz
	gzip -d JMnedict.xml.gz
	mv JMnedict.xml data/jmnedict.xml

data/jmnedict.pgi: data/jmnedict.xml
	cd python && $(PYTHON) jmparse.py -q5000000,1 -l ../data/jmnedict.log -o ../data/jmnedict.pgi ../data/jmnedict.xml

loadne: data/jmnedict.pgi  pgsubdir
	cd python && $(PYTHON) jmload.py $(JM_HOST) -u $(USER) -d $(DB) -o ../data/jmnedict.dmp ../data/jmnedict.pgi
	cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) -f fkdrop.sql
	cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) <../data/jmnedict.dmp
	rm data/jmnedict.dmp

#------ Load examples ---------------------------------------------------

data/examples.txt: 
	rm -f examples.utf.gz
	wget ftp://ftp.monash.edu.au/pub/nihongo/examples.utf.gz
	gzip -d examples.utf.gz
	mv examples.utf data/examples.txt

data/examples.pgi: data/examples.txt 
	cd python && $(PYTHON) exparse.py -o ../data/examples.pgi -l ../data/examples.log ../data/examples.txt

loadex: data/examples.pgi  pgsubdir
	cd python && $(PYTHON) jmload.py $(JM_HOST) -u $(USER) -d $(DB) -o ../data/examples.dmp ../data/examples.pgi
	cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) -f fkdrop.sql
	cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) <../data/examples.dmp
	rm data/examples.dmp
	# The following command is commented out because of the long time
	# it can take to run.  It may be run manually after 'make' finishes.
	#cd python && $(PYTHON) xresolv.py $(JM_HOST) -u $(USER) -d $(DB) -s3 -t1 >../data/examples_xresolv.log
	#cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) -c 'vacuum analyze xref;'

#------ Load kanjidic2.xml ---------------------------------------------------

data/kanjidic2.xml: 
	rm -f kanjidic2.xml.gz
	wget ftp://ftp.monash.edu.au/pub/nihongo/kanjidic2.xml.gz
	gzip -d kanjidic2.xml.gz
	mv kanjidic2.xml data/kanjidic2.xml

data/kanjidic2.pgi: data/kanjidic2.xml 
	cd python && $(PYTHON) kdparse.py -g en -o ../data/kanjidic2.pgi -l ../data/kanjidic2.log ../data/kanjidic2.xml 

loadkd: data/kanjidic2.pgi  pgsubdir
	cd python && $(PYTHON) jmload.py $(JM_HOST) -u $(USER) -d $(DB) -o ../data/kanjidic2.dmp ../data/kanjidic2.pgi
	cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) -f fkdrop.sql
	cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) <../data/kanjidic2.dmp
	rm data/kanjidic2.dmp

#------ Load jmdict, jmnedict, examples -------------------------------------

loadall: jmnew loadjm loadne loadex postload
	cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) -c "vacuum analyze xref"
	@echo 'Remember to check the log files for warning messages.'

reloadall: loadclean jmnew loadjm loadne loadex postload
	cd pg && psql $(PG_HOST) -U $(USER) -d $(DB) -c "vacuum analyze xref"
	@echo 'Remember to check the log files for warning messages.'

loadclean:
	-cd data && rm jmdict.dmp jmdict.pgi jmdict.log jmdict_xresolv.log\
         jmnedict.dmp jmnedict.pgi jmnedict.log jmnedict_xresolv.log \
         examples.dmp examples.pgi examples.log \
         #kanjdic2.dmp kanjdic2.pgi kanjdic2.log

#------ Move cgi files to web server location --------------------------

web:	webcgi weblib webtmpl webcss

webcss: $(WEB_CSS)
$(WEB_CSS): $(CSS_DIR)/%: web/%
	install -pm 644 $? $@

webcgi: $(WEB_CGI)
$(WEB_CGI): $(CGI_DIR)/%: web/cgi/%
	install -p -m 755 $? $@

weblib: $(WEB_LIB)
$(WEB_LIB): $(LIB_DIR)/%: python/lib/%
	install -pm 644 $? $@

webtmpl: $(WEB_TMPL)
$(WEB_TMPL): $(LIB_DIR)/%: python/lib/%
	install -pm 644 $? $@

#------ Other ----------------------------------------------------------

.DELETE_ON_ERROR:

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

