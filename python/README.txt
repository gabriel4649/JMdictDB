Here is a possible schema for the jmdict project which
I offer for discussion.  

I've attached a zip file containing:

    README.txt -- This file.
    schema.png -- Schema diagram.
    schema.sql -- Table definitions, loadable into mysql.
    loadkw.sql -- Mysql commands to load the static keyword data.
    data/*.sql -- Static keyword data for the kw* tables.
    load_jmdict.py -- Python script to load data from jmdict.
    showentr.py -- Command line script to display entry from database. 
    jbdb.py -- Mini-orm :-) used by load_jmdict.py and showentr.py.
    tables.py -- Table definitions used by jbdb.py.

Disclaimer:  this stuff has had almost no testing
and is in no way finished or polished.  But I don't
want to invest more effort without some feedback.

To load jmdict data from the script you will need 
Python-2.4 (or later) installed, and you will also 
need the following python modules installed:

    mysqldb 
      <http://sourceforge.net/project/showfiles.php?group_id=22307&package_id=15775&release_id=408321>
    elementtree 
      <http://www.effbot.org/downloads/elementtree-1.2.6-20050316.win32.exe>
      and
      <http://www.effbot.org/downloads/cElementTree-1.0.5-20051215.win32-py2.4.exe>

Fedora Core 5 includes both of those in the core 
packages.  For windows, you will need to download 
and install if you don't have them but they are an 
easy mouse-click install.  The URLs given above are 
for Windows packages.

I am considerably confused by the character set 
issues around mysql and the python interface to it.  
It seems that utf-8 support must be compiled into 
mysql (?), and that is the case with the Windows 
binaries, but not with the Fedora Core 5 packages 
(both the original 5.0.18 mysql,  and an update 
5.0.22 mysql complain when I try to tell it to use 
utf-8.)  I spent several days screwing around with 
it, and since there are other mysql+japanese users 
here,  almost all who know more than me (it's my 
first time using mysql) I decided to leave 
straightening this out to them.  Also, on FC5, the 
python MySQLdb module (rpm package "mysql-python") 
is version 1.2.0 but load_jmdict was developed with 
the 1.2.1_p2 version.  There are changes in the utf8 
handling between the two versions including syntax 
incompatabilities.  See the comments in jbdb.py
function dbOpen() (at the botton of the file).

On my windows box (Mysql-5.0.24, MySQLdb-1.2.1_p2) 
things work fine and both command-line mysql, and 
the gui tools like SqlAdministrator show Japanese 
text correctly.  However, since my Windows default 
system encoding is cp932, I am not sure whether 
there is actually utf8 in the database or whether 
it is stored as cp932. 

To load the schema and keyword data, run the mysql 
command line tool in the directory you unpacked the 
files in, and do:

mysql> create database jb;
mysql> use jb;
mysql> source schema.sql;
mysql> source loadkw.sql;

You now have a database with all the tables, and the 
semi-permanent data (keywords) loaded, but no Japanese 
language entries.  To load some data from jmdict use 
the load_jmdict.py script.  Use -u and -p to give it 
a username and password for connecting to mysql.  You 
can use the -b, -e, and -c options to limit it to a 
part of the file.  Use the --help option for more info.

Loading the full file take about 1 hour on my venerable
700mhz machine.  Speed is mainly dependent on speed
of your mysql server.  
The first time you run load_jmdict.py, try using the
-n option to supress database writing.  This will 
uncover any problems parsing the jmdict file in a 
few minutes rather than after 30+ minutes of loading 
the database.

load_jmdict.py loads data for each entry as it is 
parsed but defers adding <xref> and <ant> to the 
database until it processed all the entries since 
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

Foreign keys constraints are not enforced, nor do the 
"on delete" clause work.  Appearently mysql uses a 
different syntax than every other db in the world and 
I haven't had time to change the schema.sql file.

Any possiblity of considering using postgresql?

showentr.py is a command line script that will prompt 
for an entry to display, read the data from the database, 
and print it to stdout.  It is not intended to be a 
serious app, just to illustrate accessing the database
from a script.  Use --help for info.



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

Comments welcome.
