http://www.edrdg.org/~smg/

The JMdictDB project is an informal project to put the contents 
of Jim Breen's [*1] JMdict Japanese-English dictionary data [*2] 
into a database, and provide a web-based maintenance system 
for it.

Discussion takes place on the edict-jmdict@yahoo.com mailing 
list (http://groups.yahoo.com/group/edict-jmdict/)

The software in this package is copyrighted by 
Stuart McGraw, <jmdictdb@mtneva.com>
(except where otherwise noted) 
and licensed under the GNU General Public License version 2.  
See the file COPYING.txt for details.

JMdictDB comes with ABSOLUTELY NO WARRANTY.

The most recent version of this code may be downloaded at
http://www.edrdg.org/~smg/.

This package contains the following directories:
  ./                   Package directory.
  ./doc/               Documentation.
  ./pg/                Database scripts.
  ./pg/data/           Database static data.
  ./python/            Command line apps.
  ./python/lib/        Library modules.
  ./python/lib/tmpl/   Web page templates.
  ./tools/             Scripts used by Makefiles.
  ./web/               Web related files.
  ./web/cgi/           CGI scripts.

======
STATUS
======

This code is under development and is alpha quality.
Everything here is subject to future change.  Python code
is written for Python 3; Python 2 is no longer supported
(although an older Python 2 version is available from the 
code repository, see INSTALLATION/Requirements below).  The 
web pages use Python/CGI.

The Python 2 to Python 3 conversion was only done recently
(2012-05 through 2012-11 approximately) thus there are likely
a number of conversion related errors remaining in less 
frequently used parts of the code.

Development uses Mercurial (http://selenic.com/mercurial)
as a version control system.  The development repository is
available for download, and the project's revision history 
can be browsed at http://www.edrdg.org/~smg/.

The JMdictDB system is currently running on Jim Breen's 
wwwjdic web sites
 (http://www.edrdg.org/cgi-bin/wwwjdic/wwwjdic?1C and mirrors)
where it is used to accept additions and corrections to the 
wwwjdic/JMdict data from wwwjdict users.

=============
DOCUMENTATION
=============

Overview and general information about JMdictDB:
  README.txt -- This file.

Database schema:
  doc/schema.odt(.pdf,.html) -- The schema is comprehensively 
	documented in schema.pdf (or schema.html).  Both were
        produced from the Open Office Writer document schema.odt.

  doc/schema.dia(.png) -- A diagram of the database tables and
        their relationships.  schema.png was produced from 
	schema.dia by the open source Dia application.

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

Although this software was written and is maintained primarily
to support Jim Breen's JMdict and wwwjdic projects, you may 
wish to install a local copy of this software:

- To contribute development work to the JMdict project.

- To use or adapt the code to a project of your own.

Requirements
------------
The code is currently developed and tested on Ubuntu using
Apache as a web server.  The webserver should be configured 
to run Python CGI scripts.  

Regarding Microsoft Windows:
Up to mid 2014 the code also ran and was supported on Microsoft 
Windows XP.  However, current lack of access to a Windows machine 
has required dropping Windows support but the Windows specific 
code and documentation have been left in place in case support 
is revived in the future.  PLEASE BE AWARE THAT REFERENCES TO
MICROSOFT WINDOWS IN THIS AND OTHER DOCUMENTATION AND CODE ARE
UNSUPPORTED AND MAY BE WRONG.

JMdictDB requires Python 3; Python 2 is no longer supported
although the last working Python 2 version is available in 
the code repository in the branch, "py2-maint".

Some additional Python modules are also needed.  Version 
numbers are the versions currently in use in the author's 
development environment -- the software may work fine with 
earlier or later versions, but this has not been verified.

  Postgresql [9.6]
  Python [3.6] (known not to work before 3.3).
  Additional Python packages:
    psycopg2-2.7.3 Python-Postgresql connector.
      http://initd.org/projects/psycopg2/
      http://stickpeople.com/projects/python/win-psycopg/ (Windows)
    ply-3.9 -- YACC'ish parser generator.
      http://www.dabeaz.com/ply/
    lxml-4.0.0 -- XML/XSLT library.  Used by xslfmt.py for doing
      xml->edict2 conversion.
    jinja2-2.9.6 -- Template engine for generating web pages.
  Apache [2.4] (on Unix/Linux/Windows systems) or
    IIS [5.0] (on MS Windows systems)
  make -- Gnu make is required if you want to use the provided
    Makefile's to automate parts of the installation.
  wget -- Used by Makefile to download the JMdict_e.gz, 
    JMnedict.gz, and examples.utf8.gz file from the Monash
    site.  If not available, you can download the needed 
    files manually.
  iconv -- Not required but very useful when dealing with
    character encoding conversions that are frequenly required
    when working with Japanese language text files.

The principle author had Cygwin (http://cygwin.com) installed on 
his Windows development machine and used the make, wget, etc.,
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
prompted for, or read from the user's ~/.pgpass [*3] 
file.  Command line tools that are part of the JMdictDB 
system generally allow a "-p" option for supplying a 
password.  Using it on a multi-user machine is usually
a bad idea since another user, using "ps" or other 
such commands, can view it.  The safest way of supplying 
passwords is to use a .pgpass file.  See [*4] for more 
info.

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

No provision is made for concurrent access while loading
data; we assume that only the access to the database being
loaded is by the procedures used for the loading.  Use of 
databases other than the one being loaded can continue as
usual during loading.

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

   If you are running on Microsoft Windows you will
   need to change the value of DBLOCALE from "ja_JP.utf8"
   to "japanese" or specify DBLOCALE when you run "make"
   in step 8 below.

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
   files updated) but must do this if you've changed
   any of the support files' dependencies.

8. In the top level directory, run "make" which won't
   do anything other than list the available targets 
   that will do something.  

   If you are running on Microsoft Windows you should
   first set the client encoding for Postgresql by
   setting an environment variable:

        set PGCLIENTENCODING=utf-8

   To load JMdict, JMnedict, and Examples on a Unix-like 
   machine, run:

	make loadall

   Similarly but on a Windows machine:

        make DBLOCALE=japanese loadall

   "make loadall" will create a database named "jmnew", download
   the needed XML files, then parse and load the JMdict, JMnedict,
   and Examples files into it and recreate the necessary foreign
   key constraints and indexes which were disabled during loading
   for performance reasons.  If any of the prerequistite files
   are already present (such as the .pgi files produced by the 
   parsers), it will use them.  To force a complete reloading
   from scratch (except for the fetching which will be done only 
   if the needed XML file are not present), use

        make reloadall

   To load a different set of corpora or in a diffent order
   you'll need to do the steps explicitly.  For example, to
   load JMdict and Kanjidic2, only, run make four times with
   the targets:

	make jmnew       # Create empty jmdictdb database.
	make loadjm      # Load JMdict 
        make loadkd      # Load Kanjidic2
        make postload    # Re-create constraints and indices.

   In particular "make postload" should be run last to finalize
   a sequence of "make loadxx" operations.
 
   After the above "make" commands have completed sucessfully
   you will have a database named "jmnew" which can be examined
   to confirm the data is as expected.

   The "make" commands generate a lot of output and it is
   normal to see as fair number of warning and a few error
   messages while "make" is running -- files and database
   objects are often deleted or recreated to be sure that
   the environment is in a consistent state, and messages
   are produced if the objects are already gone or present.
   Unfortunately it is hard to tell what is a problem and
   what is normal short of experience running the install
   a number of times.

   Some of the more significant Makefile targets are:

   jmnew:
	Create a new database named "jmnew" with all
	jmdictdb tables and other database objects needed
        and ready to load data into.

   newdb: 
        Create an cnmpletely empty database named "jmnew".
        (This can be useful if one wants to restore a 
        jmdictdb database previously saved with pg_dump.)

   data/jmdict.xml: 
	Download the current JMdict_e.gz file from the 
	Moash FTP site, and unpack it.

   data/jmdict.pgi: 
	Make target jmdict.xml if neccessary, then parse
	the jmdict.xml file, generating a rebasable 
	jmdict.pgi file and jmdict.log.

   loadjm:
	Make target jmdict.pgi if neccessary, then load
	the .pgi file into preexisting database "jmnew"
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

   There are similar sets of data/* and load* targets for
   loading JMnedict, the Examples file and Kanjidic2 (though
   kanjidic2 support, while usable, is still incomplete).
   Note that these targets expect to load their data into
   the "jmnew" database and thus should be executed before
   doing a "make activate".  Or alternatively, you can have
   them load directly into the active database (and losing
   the opportunity to validate the data before bringing it
   to the production database) by doing, for example,
   "make DB=jmdict loadex" 

   Note that currently, the Examples file cross references 
   are not resolved to jmdict xrefs as part of the Makefile
   directed install because the api display and query 
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

   which will rename any existing "jmdict" database to "jmold"
   (any existing "jmold" database is deleted), and rename the
   "jmnew" database to "jmdict", thus making it the active
   database and the one accessed by default by the cgi web
   pages.  There must be no active users in any of these
   databases or the "make activate" command will fail.

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

=========
OPERATION
=========

   Web access to the JMdictDB system can be suspended temporarily
   by creating a control file in the installed cgi directory named 
   "status_maint" or "status_load".  If either file exists, any
   web access to a cgi script will result in a redirect to 
   "status_maint.html" or "status_load.html" which present the 
   user with a message that the system is unavailable due to
   maintenance or excessive load, respectively.

   The directory in which the cgi scripts look for the control
   files can be set in the config.ini file.  The location of the
   html files is not customizable although you can of course 
   modify their contents.

   It is up to you to create and and remove the control files as
   appropriate.

======================================================================
Notes:
[*1] 
http://www.csse.monash.edu.au/~jwb/japanese.html

[*2] 
http://www.csse.monash.edu.au/~jwb/edict_doc.html

[*3] 
On Windows the Postgresql password file is typically in
"C:\Documents and Settings\<your_windows_user_name>\ -
  Application Data\Postgresql\pgpass.conf".  For brevity
we will refer simply to "~/.pgpass" in this document.

[*4]
For more information on usernames, passwords, and the .pgpass
file, see the Postgresql docs:
  31.15  Client Interfaces / libpq / The Password File
  31.1   Client Interfaces / libpq / Database Connection -
            Control Functions
  19     Server Administration / Client Authentication
  sec VI Reference / Postgresql Client Applications / -
            psql / Usage / Connecting to a Database
Note that chapter numbers are Postgresql version dependent.  
Numbers given are for Postgres version 9.2.

===
EOF
===
