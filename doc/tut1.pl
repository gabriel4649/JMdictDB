# $Revision$
# $Date$
#-----------------------------------------------------------------------
# This script is a brief tutorial intended to introduce some
# of the jmdict library functions and data structures.
#
# The Kwds() data structure
# 
# The jmdict::Kwds() function reads the database kw* tables and 
# builds a data structure that allows retrieving those rows via
# id number or keyword, without further trips to the database.
#
# The returned data structure is used extensively thoughout the 
# JMdictDB code to convert kw id numbers to keyword strings and
# visa versa.
#
#-----------------------------------------------------------------------

# Execute the first tutorial using the "require" 
# statement.  This will open a connection to the database on
# handle $dbh, and then use the jmdict::Kwds() function to
# read the kw* table data into global variable $::KW.

	require "tut0.pl";

# We will look at the structure and contents of $::KW.

	print $::KW . "\n";
#	HASH(0x2019150)

# It is a (reference to) a hash of (references to) more hashes.
# 
# Aside: 
# I use Perl references extensively in the code since they are cleaner
# for passing and returning complex parameters (and I have been using
# Python for the last few years where everything is a reference :-).
# So if $x is a reference to a hash, then the hash itself is accessible as 
# %$x, and the value of the element with the key "foo" is $x->{foo}.
# For a hash %x (as opposed to a reference to one) the "foo" element
# is $x{foo}.  Similarly, a reference to an array is dereferenced
# like "@$x" and a particular element like "$x->[3]" to get the forth
# element.  Arrays can contain hash refs and hashes can contain
# array refs, so it is common to see things like:
#   $x->{foo}->[3]->[2]->{bar}
# Since onlt the first "->" is required, the above would usually be
# be written:
#   $x->{foo}[3][2]{bar}

# Print the hash keys of the $::KW hash...

	print join (", ", keys (%$::KW)) . "\n";

#	MISC, FREQ, XREF, SRC, RINF, STAT, KINF, FLD, LANG, DIAL, POS

# The keys of $::KW correspond to the names of the kw*
# tables but in upper case and without the "kw" prefix.
#
# The values of each item is another hash reference:

	print $::KW->{KINF} . "\n";

#	HASH(0x234d780)

# These second-level hashes contain the table data.  Each item
# in the hash is the image of a row from the kw* table.  The
# rows are keyed by both the id number of the row, and the 
# "kw" value of the row.  Here are the keys of the KINF table
# hash: 

	print join (", ", keys (%{$::KW->{KINF}})) . "\n";

#	3, 2, iK, ik, 4, 1, oK, io

# This allows one to lookup kw* table data by id _or_ keyword.
# The value retreived by each of these keys is... another 
# hash reference.  This third-level hash represents the row 
# from the kw* table that has the id number or keyword given 
# by the key that got us the row.  Its keys are the names of
# the tables columns, and its values are the columns' values.

	$x = $::KW->{KINF};

# $x is a hash reference for the kwkinf table data.  Note
# that when a row id number is used, it is used as a hash
# key, not as an array index.

	$row = $x->{3};

# $row is the image of the row with id=3 in the kwkinf table.
# The keys of $row are the names of the table's columns.

	print $row->{kw} . "\n";

#	oK

	print $row->{descr} . "\n";



#	word containing out-dated kanji

	print $row->{id} . "\n";

#	3

# Of course we can get the same information without
# the intermediate variables.  

	print $::KW->{KINF}{3}{descr} . "\n";

#	word containing out-dated kanji	

# And instead of looking it up by id number ({3}), we can
# lookup by keyword:

	print $::KW->{KINF}{oK}{descr} . "\n";

#	word containing out-dated kanji	

# Or, given the keyword, find the id number:

	print $::KW->{KINF}{oK}{id} . "\n";

#	3	

# It works the same way for all the kw* tables.  Note that
# we need to put "adj-na" in quotes below because of the
# "-" character.

	print $::KW->{POS}{'adj-na'}{id} . "\n";

#	2
	
	print $::KW->{POS}{2}{kw} . "\n";

#	adj-na

	print $::KW->{POS}{'adj-na'}{descr} . "\n";

#	adjectival nouns or quasi-adjectives (keiyodoshi)

	print $::KW->{LANG}{fr}{id} . "\n";

#	8

	print $::KW->{LANG}{fr}{descr} . "\n";

#	French

	print $::KW->{FREQ}{1}{kw} . "\n";

#	ichi


# There is an idiom that I use frequently thoughout the 
# code.  It is used for creating a list of keyword abbreviations
# that we can display to a user, from the records read from a 
# keyword list table such a "pos" (or "misc", or "kinf", or...). 
# The format of such lists will be examined in detail
# in a later tutorial, but for now we will create it buy hand.
# The data used is identical to that for entry 1004090.

	$s = {_pos=> [
	  {entr=>388, sens=>1, kw=>2},
	  {entr=>388, sens=>1, kw=>3},
	  {entr=>388, sens=>1, kw=>6},
	  {entr=>388, sens=>1, kw=>17},
	  {entr=>388, sens=>1, kw=>46},]};

# This is what we will get if we read all the records in table
# "pos" that are for entr=388 and sense=1.  $s would contain
# all the information about a sense, and the _pos element 
# has the list of pos'.  Each "kw" value is the id number of 
# a row in table "kwpos".  # We want turn this into a string 
# like:
# 
#     "adj-na, adj-no, adv, n, vs"
#
# which we can display to a user.  We use the data in $::KW 
# to do this.

	@pos = map ($::KW->{POS}{$_->{kw}}{kw}, @{$s->{_pos}});

# Here is a deconstruction of that statement.
# 
#   The map() function will evaluate its first argument
#     for every element in its second argument, setting 
#     $_ to each of those elements, and returning a list of
#     the results of those evaluations. 
#     map ($_+3, (1, 2, 3, 4)) will return (4, 5, 6, 7).
#   $s is as we created and described above.
#   $s->{_pos} is a reference to the list of records from 
#     the "pos" table.
#   @{$s->{_pos}} is the actual (dereferenced) list and
#     it the list map() will iterate over.
#   The expression map evaluates is $::KW->{POS}{$_->{kw}}{kw}
#   $_-> is set in turn to each element of @{$s->{_pos}}.
#     That is, {entr=>388, sens=>1,  kw=>2}, then
#     {entr=>388, sens=>1,  kw=>3}, ... for all 5 elements.
#   $_->{kw} is just the "kw" values: 2, 3,...,46 
#   $::KW->{POS} is the part of the $::KW data that contains
#     the kwpos rows.
#   $::KW->{POS}{$_->{kw}} is the row selected by the pos
#     table kw values:  {id=>2,kw="adj-na",descr=>...}, 
#     {id=>3,kw=>"adj-no",descr=>...},..., {id=>46,kw="vs",descr=>...}
#   $::KW>{POS}{$_->{kw}} selects just the kw string values
#     from those rows: "adj-na", "adj-no", ..., "vs".
#   And that is the list that is assigned to @pos.
#   We can turn that list into a string with join():

	print join (", ", @pos) . "\n";

#	adj-na, adj-no, adv, n, vs

# Lists of freq table records are similar except the records
# apply to reading-kanj pairs, and each freq kw also has a 
# value.

	$k = {_kfreq=>[
	    {entr=>211, rdng=>1, kanj=>1, kw=>1, value=>1},
	    {entr=>211, rdng=>1, kanj=>1, kw=>5, value=>32},
	    {entr=>211, rdng=>1, kanj=>1, kw=>7, value=>2},]};

# And turned into a string similarly:

	print join (", ", map (
			$::KW->{FREQ}{$_->{kw}}{kw} . $_->{value},
		        @{$k->{_kfreq}})) . "\n";

#	ichi1,nf32,news2

# Sometimes you will want to get a list of the rows in (say) 
# kwfreq (rather that the hash that $::KW->{FREQ} gives you).
# If you use the Perl functions, keys(), each(), values(), etc,
# which are the usual way to get a list from a hash, you will get
# twice as many items back as you expect.  Each row is duplicated
# because there are two keys it is listed under, the id number
# and the keyword. 
# 
# So jmdict.pm has a function, kwrecs(), called like
# 
	@kwfreq_rows_list = kwrecs ($::KW, "FREQ");
#
# Note that kwrecs returns an array, not an array reference.
# It will give you a list of all the records in %$::KW->{FREQ}
# without duplicates.
# 
	print "These are the kwfreq table keywords and id's:\n";
	foreach $x (@kwfreq_rows_list) {
	    print "$x->{kw}, $x->{id}\n"; }

#	These are the kwfreq table keywords and id's:
#	spec, 4
#	gai, 2
#	gA, 6
#	ichi, 1
#	news, 7
#	nf, 5

# Note the list returned is not in any particular order;
# use Perl's sort function if you want it ordered.

	print "Done!\n";

