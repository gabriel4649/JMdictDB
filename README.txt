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
  ./                   Package directory.
  ./doc/               Documentation.
  ./doc/issues         Bugs and to-do's.
  ./pg/                Database scripts.
  ./pg/data/           Database static data.
  ./python/            Command line apps.
  ./python/lib/        Library modules.
  ./python/lib/tmpl/   TAL templates.
  ./tools/             Scripts used by Makefiles.
  ./web/               Web related files.
  ./web/cgi/           CGI scripts.

======
STATUS
======

This code is under development and is pre-alpha quality.
Everything here is subject to future change.  The web pages
currently use Python/CGI.

Development uses Mercurial (http://selenic.com/mercurial)
as a version control system.  The development repository is
available for download, and the project's revision history 
can be browsed at http://www.edrdg.org/~smg/.

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

========
PROGRAMS
========

The ./python/ directory contains a number of independent 
programs:

The following tools find and display entries in the database.

  shentr.py	Command line tool for searching for and
		 displaying jmdict database entries.  It
		 is well documented making it useful for
		 understanding the use of the API in a real
		 (if tiny) application.  This program is kept
		 up-to-date.
  srch.py, srch.tal, srch.xrc, srcht.tal, jmdbss.txt
		GUI tool to search for and display dajmdict
		 database entries.

The following tools read an XML or text file and write a 
file that can be loaded into a Postgresql database.

  exparse.py	Read examples.txt file and create loadable
		 Postgresql dump file.
  jmparse.py	Read JMdict or JMnedict XML file and create
		 loadable Postgresql dump file.
  kdparse.py	Read kanjidic2 XML file and create loadable
		 Postgresql dump file.
  sndparse.py	Read JMaudio XML file and create loadable
		 Postgresql dump file.

  jmload.py	Adjust the entry id numbers in a loadable
		 Postgresql dump file. 
  xresolv.py	Resolve textual xrefs loaded into database
		 from JMdict files, to real xrefs.

The following tools will read information from the database and write 
an XML file that can be loaded by the tools above.

  entrs2xml.py	Read entries from database and write to
		 XML file.
  snds2xml.py	Read Audio data from database and write
		 JMaudio XML file.

The following work with labeled audio produced by Audacity.

  mklabels.py	Generate a label file from a db sndfile entry
		 that can be imported into Audacity.
  updsnds.py	Update existing and add new snd records from
		 an Audacity label file.

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
Fedora Core 8, and Debian/Linux, with either Apache (on Linux)
or IIS (on MS Windows) as a web server.  The webserver should
be configured to run Python CGI scripts.

Some additional Python modules are also needed.
Version numbers are the versions currently in use in the 
author's development environment -- the software may work
fine with earlier or later versions, but this has not been 
verified.

  Postgresql [8.2 or 8.3]
  Python [2.5.2]
    psycopg2-2.0.5.1 Python-Postgresql connector.
      http://initd.org/projects/psycopg2/
      http://stickpeople.com/projects/python/win-psycopg/ (Windows)
    simpleTAL-4.1 -- Template file processor.
      http://www.owlfish.com/software/simpleTAL/
    simplejson-1.8.1 -- JSON en-/de-coder.
      http://pypi.python.org/pypi/simplejson/1.8.1/
      [Python-2.6 and later includes simplejson as module "json".]
    ply-2.5 -- YACC'ish parser generator.
      http://www.dabeaz.com/ply/
    wxPython-2.8.9.1 -- (Optional) JMdictDB inludes a simple
      GUI interface to the database that is similar to the
      cgi interface.  To run this requires wxPython.
      http://www.wxpython.org/
  Apache [2.2] (on Unix/Linux/Windows systems) or
    IIS [5.0] (on MS Windows systems)
  make -- Gnu make is required if you want to use the provided
    Makefile's to automate parts of the installation.
  wget -- Used by Makefile to download the JMdict_e.gz, 
    JMnedict.gz, and examples.utf8.gz file from the Monash
    site.  If not available, you can download the needed 
    files manually.
  iconv -- Not required but very useful when dealing with
    character enconding conversions that are frequenly required
    when working with Japanese language text files.

The principle author has Cygwin (http://cygwin.com) installed on 
his Windows development machine and uses the make, wget, etc.,
programs provided by that package.  A smaller (though untested)
alternative might be to use the programs provided by the Gnuwin32
project: http://gnuwin32.sourceforge.net.

Database Authentication
-----------------------
Any program that accesses the database needs a username 
and possibly a pasword to do so.  In a standard Postgresql 
install, local connections made with user "postgres" do 
not need a password, but your installation may require
you to use a different username and password.

Most command line programs supplied by Posgresql, such
as psql, allow one to specify a user name but not a 
password; the password will either be interactively 
prompted for, or read from the user's ~/.pgpass [Note *1] 
file.  Command line tools that are part of the JMdictDB 
system generally allow a "-p" option for supplying a 
password.  Using it on a multi-user machine is usually
a bad idea since another user, using "ps" or other 
such commands, can view it.  The safest way of supplying 
passwords is to use a .pgpass file.  See [Note *2] for
more info.

The database is accessed by the JMdictDB system in three
contexts:
 - When running the Makefile to install the JMdictDB 
     system.
 - When cgi scripts are executed by the web server.
 - When a local (or remote if permitted) user runs 
     the command line or GUI tools.

When the Makefile target "init" is run, it will create 
two database users (by default, "jmdictdb" and "jmdictdbv").
The other targets create and load databases as user 
"jmdictdb".  The "jmdictdbv" user is given read-only
access to the databases and is for use by the cgi scripts
and not further used by the Makefile.

When CGI scripts access the database, they do so using 
a username obtained from the file config.ini (in python/lib
or the cgi lib/ directory.)  You need to create this file
from the config.ini.sample file supplied.  The usernames
in config.ini should match the usernames used by the 
Makefile "init" target.
Passwords for these usernames may also be supplied in the 
config.ini file, but since the file must be readable by 
the operating system user that the web server runs as, 
you will want to limit read access to the file to only 
the web server user.  Alternatively, you can install a 
.pgpass file in the home directory of the web server user
to provide the passwords.

Editor Authentication
---------------------
The CGI scripts allow unauthenticated users to submit 
unapproved edited or new entries, but to approve or 
reject entries, a user must be logged in as an editor.
The CGI scripts use a separate database named "jmsess" for 
storing editor user info and active sessions.  This database
need only be setup once.

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

1. Choose passswords to use for Postgreql users "jmdictdb"
   and "jmdictdbv".

2. Copy the file python/lib/config.ini.sample to config.ini
   in the same directory.  Review it and make any changes
   neccessary.  Uncomment and change the "pw" and "sel_pw" 
   passwords in the "db_*" sections to the values chosen in
   step (1) above if you wish to supply passwords via this
   file (note warnings above.)  Otherwise create a .pgpass
   file in the web server user's home directory.  The .pgpass
   file should have two lines in it:

        localhost:*:*:jmdictdb:xxxxxx
        localhost:*:*:jmdictdbv:xxxxxx

   Change the "xxxxxx"s to match the passwords chosen in
   step 1.  Permissions on the file must be 600 (rw-------) 
   or Postgresql will ignore it.

3. When you run the Makefile in step 6 below, if there 
   are passwords on the 'jmdictdb" and "postgres" accounts
   (or their equivalents if you've changed them in Makefile)
   and Postgresql does not know the passwords, you will be
   prompted to enter them (many times).  To prevent the 
   prompting, tell postgresql the passwords by creating a 
   (or editing a preexisting) .pgpass file in your home 
   directory and add a line like:

        localhost:*:*:jmdictdb:xxxxxx
	localhost:*:*:postgres:xxxxxx

   Change the "xxxxxx"s to match the "jmdictdb" password
   chosen in step 1, and the "postgres" user password.  If
   PG_SUPER in the Makefile is changed (in next step) from
   "postgres" to some other user, adjust the second line
   above appropriately. 
   Permissions on the file must be 600 (rw-------) or
   Postgresql will ignore it.

4. Check the settings in Makefile.  There are some
   configuration settings in the Makefile that you may
   want to change.  Read the comments therein.  In 
   particular, the cgi directory is assumed to be
   ~/public_html/cgi-bin/.  You may wish to change that
   if you will be using the cgi files.  There are also
   some options for the Postgresql database server 
   connections, including authentication settings.

5. Set (or modify) the enviroment variable PYTHONPATH
   so that it contains an absolute path to the python/lib
   directory.  For example, if you installed the jmdictdb
   software in /home/joe/jmdictdb/, then PYTHONPATH must
   contain (possibly in addition to other directories)
   /home/joe/jmdictdb/python/lib. 

6. If you have not done so before, in the top-level directory, 
   run 

        make init

   to create the users/sessions database.  

   Then, use psql or similar to manually add rows to table
   "users" for each editor.  "pw" is the user's password.

7. (Optional) In the top-level directory, run 

	make subdirs

   This will make sure that the support files are up-
   to-date.  You can generally skip this step if you 
   are running unmodified copy of the source (since 
   an attempt is made to keep the distributed support 
   files updated) but must do this if you've changes
   any of the support files' dependencies.

8. In the top level directory, run "make" which won't
   do anything other than list the available targets 
   that will do something.

   To load JMdict, JMnedict, and Examples, run:

	make loadall
	make activate

   To load JMdict only, run make thrice with the
   targets:

	make newdb
	make loadjm
	make activate

   Some of the more significant Makefile targets are:

   newdb:
	Create a new database named "jmnew" with all
	tables needed and ready to load data into.

   data/jmdict.xml: 
	Download the current JMdict_e.gz file from the 
	Moash FTP site, and unpack it.

   data/jmdict.pgi: 
	Do target jmdict.xml if neccessary, then parse
	the jmdict.xml file, generating a rebasable 
	jmdict.pgi file and jmdict.log.

   data/jmdict.dmp:
	Do target jmdict.pgi if neccessary, then create
	a Postgresql .dmp file with the entry id numbers
	resolved.  

   loadjm:
	Do target jmdict.dmp if neccessary, then load
	the .dmp file into preexisting database "jmnew"
	and do all the post-load tasks like creating
	indexes, resolving xref's etc. After this, the
	database should be fully loaded and functional,
	but is still named "jmnew" to avoid clobbering
	any existing and in-use "jmdict" database.

   loadall:
	Create database "jmnew" and load JMdict, JMnedict,
	and Examples into it.

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

   Note that currently, the Examples file cross references 
   are not resolved to jmdict xrefs as part of the Makefile
   directed install, because the api display and query 
   functions are not able to handle the large number of
   xrefs produced (1M+ total with some entries such as the
   particle "ha" having over 100K referring to it.)

   Makefile will download JMdict_e.gz (or JMdict.gz if so 
   configured), JMnedict.gz, and examples.utf8.gz as needed 
   depending on the make targets used, using the 'wget' 
   program.  If wget is not available you can download 
   the needed files manually, and put them in the ./data/ 
   directory.

9. The makefile will parse the data files, create a database
   named "jmnew", load the jmdictdb schema, and finally load 
   all the parsed data into it.  If everything was loaded 
   sucessfully, run 

	make activate

   which will rename any existing "jmdict" database to "jmold", 
   and rename the "jmnew" database to "jmdict", thus making
   it the active database.  There must be no active users in
   any of these database or the commands will fail.

10. If you plan on using the cgi files with a web server, 
   double check the settings in the Makefile (see step #1) 
   and then run:

	make web
   
   to install the web CGI files.  
   Note that it is also possible to configure your web server
   to serve the cgi files directly from the development directory
   making this step unnecessary.

11. When the cgi files are executed by the web server, they
   read the file python/lib/pg_service.conf (or its copy as
   installed in the web server lib directory) to determine
   the database name and login credentials to use when
   connecting to the database.
 
   In the ./python/lib directory, copy the file, pg_service.sample,
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

Notes:

[*1] 
On Windows the Postgresql password file is typically in
"C:\Documents and Settings\<your_windows_user_name>\ -
  Application Data\Postgresql\pgpass.conf".  For obvious
reasons we will refer simply to "~/.pgpass" in this document.

[*2]
For more information on usernames, passwords, and the .pgpass
file, see the Postgresql docs:
  30.13  Client Interfaces / libpq / The Password File
  30.1   Client Interfaces / libpq / Database Connection -
            Control Functions
  21     Server Administration / Client Authentication
  sec VI Refernece / Postgresql Client Applications / -
            psql / Usage / Connecting to a Database
Note that chapter numbers are Postgresql version dependent.  
Numbers given are for Postgres version 8.3.5.

===
EOF
===
