This directory contains scripts for creating a Mysql or
Postgresql database schema for Jim Breen's JMdict project.
The schema and supporting tools are not well tested and
are in no way finished or polished.  This is offered as 
a starting point for discussion and possibly further 
development.

This directory contains

    README.txt -- This file.
    load_jmdict.py -- Python script to load data from jmdict.
    schema.png -- Schema diagram.
    showentr.py -- Command line script to display entry from database. 
    tables.py -- Table definitions used by jbdb.py.
    data/*.sql -- Static keyword data for the kw* tables.

    pg/jbdb.py -- Mini-orm :-) used by load_jmdict.py and showentr.py.\
    pg/loadkw.sql -- Mysql commands to load the static keyword data.
    pg/reload.sql -- Script for creating a fresh empty schema.
    pg/schema.sql -- Table definitions, loadable into mysql.

    mysql/jbdb.py -- Mini-orm :-) used by load_jmdict.py and showentr.py.
    mysql/loadkw.sql -- Mysql commands to load the static keyword data.
    mysql/reload.sql -- Script for creating a fresh empty schema.
    mysql/schema.sql -- Table definitions, loadable into mysql.

These scripts can be used with both Postgresql and Mysql databases.
They have been tested with Mysql-5.0.22 and Postgresql-8.1.4.

To load jmdict data from the script you will need Python-2.4 
(or later) installed, and you will also need the following 
python modules installed:

    elementtree 
      (needed for Python-2.4.x and earlier, not needed for Python-2.5)
      windows: <http://www.effbot.org/downloads/elementtree-1.2.6-20050316.win32.exe>
      and
      windows: <http://www.effbot.org/downloads/cElementTree-1.0.5-20051215.win32-py2.4.exe>

    For mysql database:
    mysqldb-1.2.1_p2 or -1.2.0
      <http://sourceforge.net/project/showfiles.php?group_id=22307&package_id=15775&release_id=408321>

    For postgresql database:
    psycopg2
      src: <http://initd.org/pub/software/psycopg/psycopg2-2.0.5.1.tar.gz>
      windows: <http://www.stickpeople.com/projects/python/win-psycopg/index.html>
      fc5 extras: python-psycopg2

Fedora Core 5 includes MySQLdb and ElementTree in the core 
packages, and pyscopg2 in the extras packages.  For windows, 
you will need to download and install if you don't have them 
but they are an easy mouse-click install. 

Database-specific files are in the subdirectories myqsl/ 
and pg/.  In each of those directories is a file, jbdb.py
that encapulates the python related differences.  You
tell the scripts in this directory which database to use
by copying the file jbdb.py from either the mysql/ or pg/
subdirectory, to this directory.

To install jmdict in a Postgresql database...

  1. cd to this direcory's parent directory.

  2. Copy pg/jbdb.py to the current directory.

  3. Start the psql program.

  4. If there is no existing database named "jb" 
     create it:

       psql> create database jb;

  5. Initialize the database:

       psql> \i pg/reload.sql;

     Exit psql after the reload.sql finishes.

  6. Load jmdict:

       python load_jmdict.py -u pgUsername -p ***** JMdict

     Subsitute "JMdict" with the path and name of the
     JMdict xml file to be loaded.  This will take a 
     long time (2hrs on my 700Mhz machine).

  7. Add the current directory to the environment variable PYTHONPATH
     If if doesn't exist, create it.  We assume for illustration
     that the directory you have unpacked everything in is 
     /home/me/jmdict/.  For Unix:

	$ PYTHONPATH=/home/me/jmdict; export PYTHONPATH

    For windows:

	> set PYTHONPATH c:\me\jmdict

    If the PYTHONPATH variable already exists, add the current
    directory to it.

To install jmdict in a Mysql database:

  1. cd to the directory where these files were unpacked.

  2. Copy mysql/jbdb.py to the current directory.

  3. Start the mysql program.

  4. Initialize the database:

       mysql> source mysql/reload.sql;

     Exit mysql after the reload.sql finishes.

  5. Load jmdict:

       python load_jmdict.py -u mysqlUsername -p ***** JMdict

     Subsitute "JMdict" with the path and name of the
     JMdict xml file to be loaded.  This will take a 
     long time (1hr on my 700Mhz machine).

  6. Add the current directory to the environment variable PYTHONPATH
     If if doesn't exist, create it.  We assume for illustration
     that the directory you have unpacked everything in is 
     /home/me/jmdict/.  For Unix:

	$ PYTHONPATH=/home/me/jmdict; export PYTHONPATH

    For windows:

	> set PYTHONPATH c:\me\jmdict

    If the PYTHONPATH variable already exists, add the current
    directory to it.

The load_jmdict.py script has a number of command 
options,  type "python load_jmdict.py --help" for more 
info.  Use -u and -p options to give it the username 
and password to connect to the database with.  You can 
use the -b, -e, and -c options to load only a part of 
the jmdict file.  

load_jmdict.py loads data for each entry as it is 
parsed but defers adding <xref>s and <ant>s to the 
database until it has processed all the entries since 
the xref target may not be in the database when the 
xref is parsed.  If you only load a part of the 
jmdict file, it is likely that some of the loaded 
entries xrefs won't have been added to the database.  
load_jmdict will report these as unresolvable xrefs 
before it finishes.  As of 9/18/06 jmdict itself 
also contained some unresolvable xrefs.

load_jmdict.py does not currently do anythng with 
<etym>, <bibl>, <links>, or <example> because for 
most of those, there is no information in the current 
jmdict. 

load_jmdict.py is intended as a hack to get some 
data into the database so people can evaluate 
the schema with real data.  In particular, error 
handling is nearly non-existent (if running under 
-D, an error will cause script go into drop into 
the python debugger, otherwise a traceback is printed 
and script exits.)

showentr.py is a command line script that will prompt 
for an entry to display, read the data from the database, 
and print it to stdout.  It is not intended to be a 
serious app, just to illustrate accessing the database
from a script.  Use --help for info.

The version of db.py that is in the top directory 
determines which database (mysql or postgresql) that
showentry.py will use.  After the databases are loaded,
you can change the top level db.py ar will.

showentry.py uses a view restricted by a join to get
the list of meatching entries when a search is done.
Because of the mysql problem discussed on the jmdict
mailing list previously, this is very slow in mysql.
It can be speeded up by including a mysql-specific 
query in the coe, but I haven't done that yet.


Some notes about the schema.
=======================
- The schema is pretty generic so it should be easy 
  to   load into some other db (eg postgresql) with 
  suitable munging   of things like quote characters
  and other minor syntax.  Mysql seems not to enforce
  the fk constraints or "on delete" clauses and
  something more to make that work which I haven't
  added yet.

See the schema.png diagram.

Entries are in table "entr".  Each entry can have 
zero or more kanji (in table "kanj"), zero or more 
readings in table "kana", and zero or more senses 
in "sens".  Senses have zeero or more glosses in 
"gloss".  Restrictions (reading/kanji, sense/reading, 
sense/kanji) are represented as pairs (kana.id,kanj.id), 
(sen.is,kana.id), (sens.id,kanj.id) in tables "restr", 
"stagr", "stagk".  (See note below about difference 
between JMdict restrictions and DB restrictions.)  
Cross references between senses are in table "xref" 
which contains the sense id's of the two senses, 
and a keyword that indicaters the type of cross 
reference.  Entries have a list of zero or more 
audit items in table "audit".

Each of the entry, reading, kanji, and sense enties 
have lists of zero or more keywords.  Specifically, 
keywords for entry are dialect (table "dial") and 
language (table "lang").  Kanji have keywords k_inf 
(table "kinf") and ke_pri (table kfreq).  Readings 
have keywords r_inf (table "rinf") and re_pri (table 
"rfreq").  Sense have keywords misc (table "misc"), 
part-of-speech (table "pos"), and field (table "fld").  
Each of these keyword tables excep "kfreq" and 
"rfreq" contain two columns, one of which contains 
the id of the item the keyword belongs to, the other 
column is the keyword id.  "rfreq" and "kfreq" have 
a third column that holds the frequency value.  

The keyword display values, in both a short form 
and a longer description, are in tables prefixed 
with "kw": "kwfial", "kwlang", "kwkinf", "kwfreq", 
"kwrinf", "kwrfreq", "kwmisc", kwpos".  There is 
also a keyword table "kwsrc" which are keyords 
for column "src" in "entr", table "kwxref" for 
cross referrncew types, and table "kwaudit" for 
audit items types.

Use of integer pk's 
-------------------
The major tables use numeric primary keys to allow 
efficient joins.  

Keywords and kw tables
----------------------
Keywords (constant strings and entities in jmdict) are 
stored in tables (whose names are prefixed with "kw") 
and each keyword has an (byte) integer primary key.  
Generally, joins on the kw* tables are not common since 
application or middleware will probably prefer to read 
this data at startup, and do the conversion from kw id 
number to string in the app (load_jmdict.py does this).
Integer pks decouple presentation data from structural 
data. 


Alternatives
------------
There are some alternatives that might be worth exploring.

  - Strings as keyword pk's
    -----------------------
    Instead of using a number like 5 as the pk for 
    (5,"ik","irregular kana useage"), the string "ik" 
    could be used.  This would make manual viewing 
    of table data a little easier since no join 
    would be needed but:
    - Direct editing of tables is typically infrequent.
    - Views can be used to present data with kw tables 
      already joined.  
    - Strings as primary keys are less efficient than 
      numbers.
    - Introduces undesireable coupling between information
      used to define structural relationships, and 
      information used for display for human consumption.
    - Changing pk's can be difficult, which means changing
      the kw strings could be difficult.

    Bitfields
    ---------
    Some info like kinf, rinf, jmnedict name_type have
    a small number of values that are not likely to 
    increase much (?).  These could be stored as boolean
    columns directly in the kanj or kana tables.  

    Combining keywords
    ------------------
    Different type of keywords used for the same element
    could be combined.  For example "sense" uses seperate
    child tables to keep lists of the "pos", "misc", and
    "field" keywords associated with the sense.  By putting
    the pos, misc and field keywords in the same table
    (with non-overlapping pk's of course) a sense element
    would need only one table to represent all three types
    of keywords instead of three tables as now.

restr, stagk, stagr inversion
-----------------------------
In jmdict, the default assumption is that all combinations
of kanji and readings are valid.  If this assumption is not 
true, the restr tag info defines a subset of the full K x R 
cross product that are valid.  Since the absence of restr 
means all are valid (rather than none, which would more 
consistent) a separate re_nokanji flag is used to indicate 
the none condition.  In the database, the restr table has
an inverted meaning. It identifies the K x R subset that 
is invalid rather than valid.  This also eliminates the need
for a separate nokanji flag.  The same applies analogously 
to the stagk and stagr tables.

ke_pri, re_pri generalization
----------------------------------
There are a number of keywords in jmdict such as 
"ichi1", "ichi2", "spec1", "ns01"-"ns48", etc, that 
indicate frequency of use on various scales.  Rather 
than mimicking jmdict keyword based approach, the 
database schema generalizes the notion of freq-of-use 
using a representation consisting of a scale indicator 
such as "ichi" or "ns", and a metric such as "1", "17", 
etc.  Thus "ichi1" is replaced by ("ichi",1) and "nf14" 
by ("nf",14).  This allows for the inclusion of other 
finer-grained metrics in the future such as 
("google", 338400).

cross-references
----------------
Cross references (<xref> and <ant> in jmdict) are represented
by rows in table "xref".  Each row identifies the type of
cross-reference, the sense the xref is from (this is the 
sense in jmdict where it is listed) and a *sense* that is
the target of the xref.  In jmdict, the target is an entire
entry, not a specific sense.  When creating sense, 
load_jmdict.py will create multiple xref's if there are 
multiple senses in the entry target of a jmdict <xref> (same
of <ant>.)  If multiple <xref>s or <ant>s in jmdict resolve 
to the same target sense, load_jmdict.py will print a warning.

Comments welcome.
