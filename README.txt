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

The software in this package copyrighted by Stuart McGraw, 
<smcgraw@frii.com> (except where otherwise noted) and licensed 
under the GNU General Public License version 2.  See the file 
COPYING.txt for details.

JMdictDB comes with ABSOLUTELY NO WARRANTY.

The most recent version of this code may be downloaded at
http://www.edrdg.org/~smg/.

This package contains the following directories:
  ./                Package dirtectory.
  ./perl/           Perl tools.
  ./perl/cgi/       CGI scripts.
  ./perl/lib/       Library modules.
  ./perl/lib/tal/   PETAL templates.
  ./pg/             Database scripts.
  ./pg/data/        Database static data.
See "ANNOTATED MANIFEST" below for more details.


======
STATUS
======

This code is under development and is pre-alpha quality.
Everything here is subject to future change.  The web pages
currently use Perl/cgi.  These will be changed, most likely
to Apache/modperl, when the UI is stabilized.


============
INSTALLATION
============

Eventually, the system resulting from this development will
be running on a JMdict project server, for the purpose of
receiving additions and corrections to the JMdict data.

However, you may wish to install a local copy of this software
for two reasons:
- To contribute development work to the JMdict project.
- To use or adapt the code here to a project of your own.

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
    Petal [2.19]
    Petal::Utils [0.06]
    DBI [1.52]
    DBD::Pg [1.49] (Did not work with DBD::PgPP on Windows). 
    XML::Twig [3.26]
  Apache [2.2] (on Unix/Linux systems) or
  or IIS [6.0] (on MS Windows systems)

Procedure
---------
[Note: relative file paths below (except in command 
lines) are relative to the package top level directory.]

1. Get a copy of the current JMdict_e.gz file from 
   ftp://ftp.cc.monash.edu.au/pub/nihongo/JMdict_e.gz
   and uncompress it.
   (You can also use the larger JMdict.gz file if you
   wish, which contains non-english glosses in addition
   to the english ones.)

2. cd to the ./perl subdirectory and run the load_jmdict.pl 
   script to create a Postgresql load file.  The example 
   below assumes you unpacked the JMdict.gz file to 
   ./JMdict. 

        ./load_jmdict.pl -o ../jmdict.dmp ../JMdict

   Run load_jmdict.pl with the -h option for usage info.
   load_jmdict.pl will write the load file as specified by
   the -o option.  It also processes comments in the jmdict 
   file to get info about deleted entries, and and will record
   any unparsable comments to the file "skipped_comments.txt".
   
3. cd to ./pg/ and do the following.  The second command
   assumes as above that the jmdict load file created
   by load_jmdict.pl is ../jmdct.dmp.

	psql -U postgres -f reload.sql
	psql -U postgres -d jmdict <../jmdict.dmp
	psql -U postgres -d jmdict -f postload.sql

   (You may want or need to use a username other than
   "postgres" depending on how your Postgresql installation
   is configured.  The above should work for an "out-of-
   the-box" Postgresql installation.)
   In addition to the normal Postgresql "notice" messages, 
   the output from postload.sql will include a list of
   unresolvable cross-references.  These will be displayed
   as utf-8 which will result in mojibake if you are running 
   on a system configured for something other than utf-8 (e.g.
   an MS Windows system configured for Japanese which uses 
   the cp932 character encoding).  You can regenerate the 
   info again later in readable form.

   You should now be able to run the ./perl/showentr.pl
   script to look at jmdict entries from the database.
   Use -h options for usage info.

4. Either copy the ./perl/cgi/ and ./perl/lib/ directories to
   someplace enabled for cgi, or configure your web server to 
   execute cgi scripts from the ./perl/cgi/ directory in its
   current location.

   Create a file lib/jmdict.cfg containing one line containing
   three space separated words which are repectively, the name
   of the jmdict database, the postgres username to use, and the 
   password for that username.  For example:
   
       jmdict postgres thepassword

   This file must be readable by the user that the web server 
   runs as.

   You should now be able to go to the url corresponding to 
   srchform.pl and do searches for jmdict entries.  The url
   corresponding to nwform.pl will let you add new entries.

5. (Optional)
   Import Kale Stutzman's Google page count data into database.
   [...to be supplied...]


==================
ANNOTATED MANIFEST
==================

./Changes.txt...................CVS change log.
./COPYING.txt...................GNU General Public License Terms.
./README.txt....................This file.
./schema.dia....................Dia source for database schema diagram.
./schema.png....................Database schema diagram.

./perl/
./perl/load_jmdict.pl...........Generates Postegresql load file from JMdict XML file.
./perl/showentr.pl..............Command line tool to show database entries.

./perl/cgi
./perl/cgi/entr.css.............CSS style sheet for all cgi pages.
./perl/cgi/entr.pl..............Show entry details page.
./perl/cgi/nwconf.pl............Confim new entry page.
./perl/cgi/nwform.pl............Add new entry form.
./perl/cgi/nwsub.pl.............Add new entry action.
./perl/cgi/srchform.pl..........JMdictDB general entry search form.
./perl/cgi/srchres.pl...........Search results list.

./perl/lib/
./perl/lib/jmdict.pm............General use functions.
./perl/lib/jmdictcgi.pm.........CGI-specfic functions.
./perl/lib/jmdicttal.pm.........PETAL modifiers.
./perl/lib/jmdictxml.pm.........JMdict XML parsing/generating functions.

./perl/lib/tal
./perl/lib/tal/entr.tal.........PETAL template for entr.pl.
./perl/lib/tal/nwconf.tal.......PETAL template for nwconf.pl.
./perl/lib/tal/nwform.tal.......PETAL template for nwform.pl.
./perl/lib/tal/srchform.tal.....PETAL template for srchfom.pl.
./perl/lib/tal/srchres.tal......PETAL template for srchres.pl.

./pg/...........................Scripts for database initialization.
./pg/loadkw.sql.................Load the data/kw* data into database.
./pg/mkfk.sql...................Create foreign keys.
./pg/mkindex.sql................Create indexes.
./pg/mkperms.sql................Set permissuions on database objects.
./pg/mktables.sql...............Create basic schema.
./pg/mkviews.sql................Create views.
./pg/postload.sql...............Execute scripts after schema creation and jmdict data load.
./pg/reload.sql.................Execute scripts to initialze database and create schema.
./pg/syncseq.sql................Set seqence numbers after jmdict load.
./pg/xresolv.sql................Create xrefs after jmdict load.

./pg/data/......................data/kw* files contain static keyword table data,
./pg/data/kwdial.sql
./pg/data/kwfld.sql
./pg/data/kwfreq.sql
./pg/data/kwkinf.sql
./pg/data/kwlang.sql
./pg/data/kwmisc.sql
./pg/data/kwpos.sql
./pg/data/kwrinf.sql
./pg/data/kwsrc.sql
./pg/data/kwstat.sql
./pg/data/kwxref.sql

===
EOF
===
