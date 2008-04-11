$Revision$
$Date$
http://www.edrdg.org/~smg/

The JMdictDB project is an informal project to put the contents 
of Jim Breen's
  (http://www.csse.monash.edu.au/~jwb/japanese.html)
JMdict Japanese-English dictionary data 
  (http://www.csse.monash.edu.au/~jwb/edict_doc.html)
into a database, and provide a web-based maintenance system
for it.

Discussion takes place on the edict-jmdict@yahoo.com mailing 
list (http://groups.yahoo.com/group/edict-jmdict/)

The software in this package is copyrighted by 
Stuart McGraw, <smcg4191x@frxii.com>(remove x's) 
(except where otherwise noted) 
and licensed under the GNU General Public License version 2.  
See the file COPYING.txt for details.

JMdictDB comes with ABSOLUTELY NO WARRANTY.

The most recent version of this code may be downloaded at
http://www.edrdg.org/~smg/.

This package contains the following directories:
  ./                Package directory.
  ./doc/            Documentation.
  ./perl/           Command line apps.
  ./perl/cgi/       CGI scripts.
  ./perl/lib/       Library modules.
  ./perl/lib/tal/   PETAL templates.
  ./pg/             Database scripts.
  ./pg/data/        Database static data.
  ./tools/	    Scripts used by Makefiles.

See the file doc/MANIFEST.txt for a full, annotated
listing of all the files

See doc/Changes.txt for the detailed CVS change log.

See TODO.html for list of outstanding and resolved bugs
and to-do items.

======
STATUS
======

This code is under development and is pre-alpha quality.
Everything here is subject to future change.  The web pages
currently use Perl/cgi.  These will be changed, most likely
to Apache/modperl, when the UI is stabilized.

=============
DOCUMENTATION
=============

Database schema:
  doc/schema.odt(.html) -- The schema is comprehensively 
	documented in this Open Office Writer document.
	If you do not have Open Office can read schema.html
	which was produced from it.  

  doc/schema.dia(.png) -- A diagram of the database tables
	and their relationships.  View schema.png id you do
	not have the open source Dia application.

API Documentation: 
  README.txt -- This file.
  tut0.pl, tut1.pl, tut2.pl, tut3.pl -- These tutorials are
	also executable Perl scripts.  You can run them under
	the perl debugger and step through the statements, 
	interactively examining variables, while reading 
	the extensive comments.  They discuss:

	tut0 -- Database connections.
	tut1 -- Using the Kwds() "virtual keyword tables".
	tut2 -- Finding and retrieving entries.
	tut4 -- Structure and use of entry objects.

	They may be somewhat out-of-date with respect to the
	actual software.

  perl/showentr.pl -- This is a command line tool for 
	displaying JMdict entries from the database.  It
	is well documented making it useful for understanding
	the use of the API in a real (if tiny) application.
	This program is kept up-to-date.

============
INSTALLATION
============

Eventually, the system resulting from this development will
be running on a JMdict project server, for the purpose of
receiving additions and corrections to the JMdict data.

However, you may wish to install a local copy of this software:
- To contribute development work to the JMdict project.
- To use or adapt the code to a project of your own.

Requirements
------------
The code is developed and tested on Microsoft Windows 2000, 
Fedora Core 6, and Debian, with either Apache (on Unix/Linux)
or IIS (on MS Windows) as a web server.  The webserver should
be configured to run Perl CGI scripts.

Some additional Perl modules are also needed (may be installed
using CPAN on Unix/Linux or Activestate's PPM on Windows).
Version numbers are the versions currently in use in the 
author's development environment -- the software may work
fine with earlier or later versions, but this has not been 
verified.

  Postgresql [8.2]
  Perl [5.8.8]
    Petal [2.19] [see doc/issue/000106.txt for required patch.]
    Petal::Utils [0.06]
    DBI [1.52]
    DBD::Pg [1.49] (Did not work with DBD::PgPP on Windows). 
    XML::Twig [3.26]
  Apache [2.2] (on Unix/Linux systems) or
  or IIS [6.0] (on MS Windows systems)

On Windows you will also need a copy of the GNU "make"
program if you want to use the Makefiles to automate some
of the install procedures, see below.

Authentication
--------------
Any program that accesses the database needs a username 
and possibly a pasword to do so.  In a standard Postgresql 
install, local connections made with user "postgres" do 
not need a password, the the default configuration of 
the Makefile and CGI files assumes this.  

In the Makefile, the Postgresql username is defined in 
variable $(USER).  psql and the jmdictdb perl tools do
not accept passwords on the command line so those will
need to be supplied via any of the standard methods
described in 29.1, "Database Connection Control Functions"
of the Postgreqsl docs.  See the "Connecting To A Database" 
section of the psql docs.  Each of the jmdictdb perl
tools has a -h (help) option that will describe the 
login options for the tool.
A .pgpass file will probably be most convenient.
See 29.13, "The Password File".

CGI scripts are run as the web server user and database
login credentials are stored in the postgresql service
file lib/pg_service.conf.  See the Postgresql docs
29.1, "Database Connection Control Functions", and
29.14, "The Connection Service File" for more information.
The is an example file in lib/pg_service.sample.

Procedure
---------
Note: relative file paths below (except in command 
lines) are relative to the package top level directory.

A Makefile is provided that automates the loading and
updating of JMdictDB database.  It is presumed that 
there is a functioning Postgresql instance, and that 
you have access to the database "postgres" account or
some account with enough privledges to create and drop
databases.

The Makefile is usable on both *nix and Windows systems
but the latter requires a working Gnu 'make' program.
The Cygwin package (http://www.cygwin.com) provides a 
full unix environment under Windows, including 'make'.
Alternatively, stand-alone native versions of Gnu 'make'
are available (see http://unxutils.sourceforge.net/ or
http://www.mingw.org/ for example.)

By default, the currently active database is named 
"jmdict".  The makefile targets that load data do so 
into a database named "jmnew" so as to not destroy
any working database in the event of a problem.  A
make target, "activate" is provided to move the newly
loaded database to "jmdict".

1. Check the settings in the Makefile.  There are some
   configuration settings in the Makefile that you may
   want to change.  Read the comments therein.  In 
   particular, the cgi directory is assumed to be
   ~/public_html/cgi-bin/.  You may wish to change that
   if you will be using the cgi files.  There are also
   some options for the Postgresql database server 
   commections.

2. In the top level directory, run "make" which won't
   do anything other than list the available targets 
   that will do something.  For JMdict the targets are:

   jmdict.xml: 
	Download the current JMdict_e.gz file from the 
	Moash FTP site, and unpack it.

   jmdict.pgi: 
	Do target jmdict.xml if neccessary, then parse
	the jmdict.xml file, generating a rebasable 
	jmdict.pgi file and jmdict.log.  Note that 
	this can take a long time (10's of minutes).

   jmdict.dmp:
	Do target jmdict.pgi if neccessary, then create
	a Postgresql .dmp file with the entry id numbers
	resolved.  

   loadjm:
	Do target jmdict.dmp if neccessary, then delete
	any existing jmnew database, create a new empty 
	jmnew database, load the .dmp file and do all
	the post-load tasks like creating indexes, 
	resolving xref's etc. After this, the database 
	should be fully loaded and functional, but is
	still name "jmnew" to avoid clobbering any
	existing and in-use "jmdict" database.

   activate:
	Renames the "jmnew" database produced above to 
	"jmdict", making it accessible to all the tools
	and cgi scripts.

   There are similar sets of targets for loading JMnedict
   and the Examples file.  Note that these targets expect 
   to load their data into the "jmnew" database and thus
   should be executed before doing a "make activate".  Or
   alternatively, you can have them load directly into the
   active database (with the risk of corrupting it) by 
   doing, for example, "make DB=jmdict loadex" 

   There is a target, "loadall", that will load all three
   files (JMdict, JMnedict, and Examples).

   Note that currently, the Examples file cross references 
   are not resolved to jmdict xrefs as part of the Makefile
   directed install, because the api display and query 
   functions are not able to handle the large number of
   xrefs produced (1M+ total with some entries such as the
   particle "ha" having over 100K referring to it.)

3. The makefile will load all the file data into a database
   named "jmnew".  If everything was loaded sucessfully, 
   run 

	make activate

   which will rename any existing "jmdict" database to "jmold", 
   and rename the "jmnew" database to "jmdict", thus making
   it the active database.  There must be no active users in
   any of these database or the commands will fail.

4. If you plan on using the cgi files with a web server, 
   double check the settings in the Makefile (see step #1) 
   and then run:

	make web
   
   to install the web CGI files.  

5. When the cgi files are executed by the web server, they
   read the file perl/lib/pg_service.conf (or its copy as
   installed in the web server cgi directory) to determine
   the database name and login credentials to use when
   connecting to the database.
 
   In the ./perl/lib directory, copy the file, pg_service.sample,
   to pg_service.conf.  Edit the latter file and set the user
   and password values appropriately for your database. 
   You can also delete these lines and Postgresql will use
   environment values.  If the file is on a *nix system, make
   sure it is saved with *nix line ending ("\n") and not Windows
   line endings ("\r\n").  See the Postgresql docs for more 
   info on the many ways that it offers to set the connection
   credentials.

   Copy this file webserver's cgi lib directory (the Makefile 
   does not copy this file for you).  The file must be readable
   by the user that the web server runs as.  

   You should now be able to go to the url corresponding to 
   srchform.pl and do searches for jmdict entries.  The url
   corresponding to edform.pl will let you add new entries.

6. (Optional)
   Import Kale Stutzman's Google page count data into database.
   [...to be supplied...]


===
EOF
===
