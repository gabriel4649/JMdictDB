# $Revision$
# $Date$
#-----------------------------------------------------------------------
# This file contains UTF-8 encoded characters.
#-----------------------------------------------------------------------
# This script is a brief tutorial intended to introduce some
# of the jmdict library functions and data structures.
#
# Retrieving entry data from the database
# 
# Describes the use of the Find() and EntrList() functions
# to get selected entry data from the database.
# Interpretation and use of the EntrList() data structure is
# the subject of the next tutorial.
#
#-----------------------------------------------------------------------

# We will use some functions from the module jmdicted.pm
# but before we can "use" it, we have to assure its directory
# is on the search path.  

BEGIN {push (@INC, "../perl/lib");}
use jmdicted;

# Execute the first tutorial using the "require" 
# statement.  This will open a connection to the database on
# handle $dbh, and then use the jmdict::Kwds() function to
# read the kw* table data into global variable $::KW.

	require "tut0.pl";
	use utf8;

# We now have a handle to an open database connection in variable $dbh. 
#
# The jmdict.pm function EntrList() is used to retieve entries from
# the database.  It returns a list of objects[1], and each object
# encapsulates all the information the database has about an entry.
#
# But EntrList() has to be told which entries to retrieve.  This is
# done by giving it the name of a database table that contains the
# entr.id numbers of all the entries desired.  This table can be 
# created "by hand" if desired, but using the Find() function is
# generally more convenient.
#
# Find() takes two aruments, a SQL statement and a (reference to)
# a list of arguments referred to by the SQL statement.  It returns
# the name of a temporary table that it created and populated.
# Because it is a temporary table, it will be deleted automatically
# when the database connection (represented in here by the handle
# $dbh) is closed.  The name of the temporary table returned by
# Find() is typically given to EntrList() to actually retieve the
# entry objects.
#
# The sql statement can be any SELECT statement that returns a 
# set of entry id numbers.  Here are some examples:

	$tmptbl = Find ($dbh, "SELECT id FROM entr WHERE seq=?", [1211370]);
	$entries = EntrList ($dbh, $tmptbl);

# The above will return a list of objects which will contain a single
# object, the entry with sequence number 1211370.  (This is the same
# entry used as an example in the Schema documentation.)  
# Verify the list contains one element:

	print scalar (@$entries) . "\n";
#	1

#-------------------------------------------------------------------------
# An aside:
# We could have written the Find() call above as 

	$tmptbl = Find ($dbh, "SELECT id FROM entr WHERE seq=1211370", []);

# and that wil work just as well.  However in general one should
# avoid doing this.  In the above case it is fine because the 
# sequence number is hardwired.  But if the sequence number was
# stored in a variable, them you must be sure that you have full
# control over that variable.  If an application user has any
# control over it, say because it came from a url or text input
# field, you may have a big security hole.  If you have:
#
#	$tmptbl = Find ($dbh, "SELECT id FROM entr WHERE seq=$myvar", []);
#
# expecting the user to enter a sequence number which will go
# into $myvar.  But consider what will happen if the user manages
# to enter something like this instead:
#
#	print $myvar;
#	"1211370; DELETE FROM entr;"
#
# If you use a SQL statement like
#
#	$tmptbl = Find ($dbh, "SELECT id FROM entr WHERE seq=?", [$myvar]);
# 
# the statement will simply fail to find any results in the above 
# case rather than deleting everything in your entr table as in the
# earlier case.  So in general it is better to pass all sql arguments 
# rather than embedding them in the ssql text string.
#--------------------------------------------------------------------------

# We will describe the entry data structure in detail in the next
# tutorial but for now, will will use the jmdicted.pm function 
# entr2edict() to show an edictish representation of the entry we
# got back from EntrList():

	$entr = $entries->[0];
	$txt = entr2edict ($entr);
	print "$txt\n";

#	堪能(P); 勘能 【たんのう(堪能)(P); かんのう[oK]】(adj-na)(1)proficient;skillful;n,vs)(2)satisfaction;(n,vs)(3){Buddh}fortitude;

# If we know the id of the entry we want to get, we can use that
# directly:

	$tmptbl = Find ($dbh, "SELECT ?", [20894]);
	$entries = EntrList ($dbh, $tmptbl);
	print entr2edict ($entries->[0]) . "\n";

#	堪能(P); 勘能 【たんのう(堪能)(P); かんのう[oK]】(adj-na)(1)proficient;skillful;n,vs)(2)satisfaction;(n,vs)(3){Buddh}fortitude;

# Nor are we limited to one entry a time:
	
	$tmptbl = Find ($dbh, "SELECT id FROM entr WHERE seq IN (?,?,?)",
				 [1211370,1495770,1610400]);
	$entries = EntrList ($dbh, $tmptbl);
	foreach $e (@$entries) {
	    print entr2edict ($e) . "\n\n"; }

#	[...output manually reformatted for clarity...]
#
#	堪能(P); 勘能 【たんのう(堪能)(P); かんのう[oK]】
#	(adj-na)(1)proficient;skillful;
#	(n,vs)(2)satisfaction;(n,vs)(3){Buddh}fortitude;
#
#	付ける(P); 着ける(P) 【つける(P)】
#	(v1,vt)(1)to attach;to join;to add;to append;to affix;to stick;to glue;to fasten;to sew on;to apply (ointment);
#	(v1,vt)(2)to furnish (a house with);
#	(v1,vt)(3)to wear;to put on;
#	(v1,vt)(4)to keep a diary;to make an entry;
#	(v1,vt)(5)to appraise;to set (a price);
#	(v1,vt)(6)to bring alongside;
#	(v1,vt)(7)to place (under guard or doctor);
#	(v1,vt)(8)to follow;to shadow;
#	(v1,vt)(9)to load;to give (courage to);
#	(v1,vt)(10)to keep (an eye on);
#	(v1,vt)(11)to establish (relations or understanding);
#	(v1,vt)(12)(see: 点ける)to turn on (light);
#
#	点ける(P) 【つける(P)】
#	(v1,vt)(uk)(see: 付ける; 着ける)to turn on;to switch on;to light up;


# The sql statement used to select the entry id's can be arbitrarily
# complex, the only requirement is that it return a set of entr.id
# numbers.  Here are a few simple examples.

# Get entries that have a reading containing  "つけ" and a kanji text
# containing "着", and have a sense with a noun PoS.  Recall that all
# the SQL has to do is create a list of entr.id numbers.  It does not 
# matter if these numbers come from an entr.id column, or some other
# place.  In the following sql we get them from the rdng.entr column
# which lets us avoid a join with the entr table.

	$sql = "SELECT r.entr FROM rdng r JOIN kanj k ON k.entr=r.entr " .
		 "JOIN pos p ON p.entr=k.entr " .
	         "WHERE r.txt LIKE ? AND k.txt LIKE ? AND p.kw=17";
	$entries = EntrList ($dbh, Find ($dbh, $sql, ['%つけ%','%着%']));
	foreach $e (@$entries) {
	    print entr2edict ($e) . "\n\n"; }

#	着付け(P) 【きつけ(P)】(n)dressing;fitting;

	print "Done\n";

#----------------------------------------------------------------
#
# [1] 
# They are not really objects in a technical sense; they are
# not blessed, don't have methods, etc.  They are strictly passive
# data structures built from arrays, hashes, and references thereto,
# but "data structure" sounds a little old-fashioned. :-)

