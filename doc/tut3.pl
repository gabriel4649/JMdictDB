# $Revision$
# $Date$
#-----------------------------------------------------------------------
# This file contains UTF-8 encoded characters.
#-----------------------------------------------------------------------
# This script is a brief tutorial intended to introduce some
# of the jmdict library functions and data structures.
#
# Using entry data read from the database
# 
# The previous file discussed how to get an object that is
# a runtime representation on a JMdict entry.  This file
# will discuss the structure of those objects, and how 
# to use them in an application program.
#
# Disclaimer: The API is still changing to adapt to the
# Needs of the still developing application code, and no
# promises are made about the permanence of any of the
# interfaces described in this document.
#
#-----------------------------------------------------------------------

# First, we execute the first tutorial using the "require" 
# statement.  This will open a connection to the database on
# handle $dbh, and then use the jmdict::Kwds() function to
# read the kw* table data into global variable $::KW.

	use utf8
	require "tut0.pl";

# Next, get an entry to look at.  We will use the object discussed
# in the schema documentation, seq num 1211370:

	$t = Find ($dbh, "SELECT id FROM entr WHERE seq=?", [1211370]);
	$entries = EntrList ($dbh, $t);
	$e = $entries->[0];


#================================================
#
#   Representation of table rows in Perl programs
#
#================================================

# jmdict.pm contains a function, dbread() that EntrList() and 
# most other api functions use to to read data from the database. 
# dbread() represents result sets (a set of rows created as a result
# of executing a SELECT statement) as an array of (references to) 
# hashes.  Each hash represents one row of the result set.  The
# keys of the hash are the names of the result set columns, and
# the values are the values for those columns in that row.
#
# $entries is such a structure and contain rows from the "entr"
# table.  Since the select statement we gave to Find() produced
# only one row from "entr", @$entries is an array with only one
# element, the hash for that one row.  $e was set to that row.

	print "id=$e->{id}, seq=$e->{seq}, src=$e->{src}, stat=$e->{stat}\n";

#	id=20894, seq=1211370, src=1, stat=2

#================================================
#
#   Child tables
#
#================================================

# Actually, %$e has more keys than just the ones for column values.
# EntrList() also reads all the child tables of "entr" and creates
# additional keys in the entr row hash to hold this additional data:
#
	print join (", ", sort (keys (%$e))) . "\n";

#	_dial, _freq, _hist, _kanj, _lang, _rdng, _restr, _sens,
#	_stagk, _stagr, id, notes, seq, src, stat

# The keys without a "_" prefix correspond to columns in table
# "entr".  Those with a "_" prefix represent child table data.
#
# The value of each "_*" key is a set of records read by dbread()
# from the named child table: a reference to an array of references
# to hashes representing the child tables rows.
#
	print scalar(@{$e->{_rdng}}) . "\n";

#	2

# There are 2 reading rows in this entry.  (Recall that Perl uses
# braces both for specifying a hash key, and for syntantical grouping
# a'la paranthesis.  The inner brackets are the former use and the
# outer, the latter.)
#
	$r = $e->{_rdng}[0];
	print join (", ", sort (keys (%$r))) . "\n";

#	_audio, _restr, _rfreq, _rinf, entr, rdng, txt

# The rdng rows were also read by dbread() and have the same kind
# structure as the entr rows.  _audio, _restr, _rfreq, and _rinf
# hold child table rows, and entr, rdng, txt are column values
# for this rdng row.
#
	print "entr=$r->{entr}, rdng=$r->{rdng}, txt=$r->{txt}\n";

#`	entr=20894, rdng=1, txt=‚½‚ñ‚Ì‚¤

# (If the txt item is mojibake, you may need to change the $enc
# value in tut0.pl.)
#
# If a child table has no related rows, its key will still exist
# in the parent table hash, but will be undefined or an empty
# array (current code is inconsistent about which is used).
#
	print "audio=$r->{_audio}\n";

#       audio=

# Here is the second rdng row:

	$r = $e->{_rdng}[1];
	print "entr=$r->{entr}, rdng=$r->{rdng}, txt=$r->{txt}\n";

#	entr=20894, rdng=2, txt=‚©‚ñ‚Ì‚¤

# Kanj rows are similar.  We will print both using a loop:

	foreach $k (@{$e->{_kanj}}) {
	    print "entr=$k->{entr}, kanj=$k->{kanj}, txt=$k->{txt}\n"; }

#	entr=20894, kanj=1, txt=Š¬”\
#	entr=20894, kanj=2, txt=Š¨”\

# Since the "rinf" table is child table of table "rdng" the rdng records
# have (as we saw) a "_rinf" key. 

	foreach $r (@{$e->{_rdng}}) {
	    $n = scalar(@{$r->{_rinf}}) || "0";
	    print "rdng $r->{rdng} has $n rinf tags\n"; }

#	rdng 1 has 0 rinf tags
#	rdng 2 has 1 rinf tags

	$r = $e->{_rdng}[1];	# rdng 2 record.
	$ri = $r->{_rinf}[0];	# first (and only) rinf record.
	print join (", ", sort (keys (%$ri))) . "\n";

#	entr, kw, rdng

	print "entr=$ri->{entr}, rdng=$ri->{rdng}, kw=$ri->{kw}\n";

#	entr=20894, rdng=2, kw=3

# kw=3 means the keyword identified by id=3 in table "rinf".
# We can look it up in the "virtual" table provided by
# $::KW.  $::KW->{RINF}{3} is the kwrinf record which as we 
# saw in tut1.pl has three colunms: id, kw, descr.

	print "$::KW->{RINF}{3}{kw} -- $::KW->{RINF}{3}{descr}\n";

#	ok -- out-dated or obsolete kana usage

# We can do everything we just did in a single expression without
# using intermediate variables:

	print $::KW->{RINF}{$e->{_rdng}[1]{_rinf}[0]{kw}}{kw} .
	      " -- " .
	      $::KW->{RINF}{$e->{_rdng}[1]{_rinf}[0]{kw}}{descr} .
	      "\n";

#	ok -- out-dated or obsolete kana usage

# Senses are similar.

	$n = scalar(@{$e->{_sens}});
	print "Entry $e->{seq} has $n senses\n";

#	Entry 1211370 has 3 senses

# Here the gloss strings for the first sense:

	$glosses = $e->{_sens}[0]{_gloss};
	for $g (@$glosses) {
	    print $g->{txt} . "\n";}

#	proficient
#	skillful 

# Sometime it's more concise to use map() rather than a "for"
# loops to do iteration.  The above could also be written as:

	$glosses = $e->{_sens}[0]{_gloss};
	print join ("\n", map ($_->{txt}, @$glosses)) . "\n";

#	proficient
#	skillful

# Here we print the PoS tags and glosses for each sense in the entry.
# Recall the discussion of the map()+$::KW idiom from tut1.pl.@{

	foreach $s (@{$e->{_sens}}) {
	    $glosses = $s->{_gloss};
	    $glosstxt = join ("; ", map ($_->{txt}, @$glosses));
	    $pos = $s->{_pos};
	    $postxt = join (",", map ($::KW->{POS}{$_->{kw}}{kw}, @$pos));
	    print "$s->{sens}. [$postxt] $glosstxt\n"; }

#	1. [adj-na] proficient; skillful
#	2. [n,vs] satisfaction
#	3. [n,vs] fortitude


#================================================
# 
#   Dual-parent tables
#
#================================================

# The "freq" table contains frequency-of-use (aka pri) values 
# for reading-kanji pairs.  Some fou records apply to a reading
# (or kanji) alone and in those the kanj (or rdng) field will
# be null (have the undefined value in Perl).  EntList() reads
# the freq table for an entry.  Each freq table record is then
# assigned to the reading and/or kanji it applies to.  The kanji
# fou records are in {_kfreq} in the kanj records, and in {_rfreq}
# in the rdng records.

	foreach $k (@{$e->{_kanj}}) {
	    $n = scalar (@{$k->{_kfreq}}) || "0";
	    print "kanj $k->{kanj} has $n freq records\n"; }

#	kanj 1 has 2 freq records
#	kanj 2 has 0 freq records

	foreach $r (@{$e->{_rdng}}) {
	    $n = scalar (@{$r->{_rfreq}}) || "0";
	    print "rdng $r->{rdng} has $n freq records\n"; }

#	rdng 1 has 2 freq records
#	rdng 2 has 0 freq records

	$k = $e->{_kanj}[0];	# First kanj record.
	$f = $k->{_kfreq}[0];	# First freq record.
	print join (", ", sort (keys (%$f))) . "\n";

#	entr, kanj, kw, rdng, value

	foreach $f (@{$e->{_rdng}[0]{_rfreq}}) {
	    print "entr=$f->{entr}, rdng=$f->{rdng}, kanj=$f->{kanj}, kw=$f->{kw}, value=$f->{value}\n"; }

#	entr=20894, rdng=1, kanj=1, kw=5, value=16
#	entr=20894, rdng=1, kanj=1, kw=7, value=1

# As with the other keyword lists we can convert these to strings
# with the minor additional wrinkle that we need to include the
# value with the keyword:

	foreach $r (@{$e->{_rdng}}) {
	    $freqstr = join (",", map (
			$::KW->{FREQ}{$_->{kw}}{kw} . $_->{value},
			@{$r->{_rfreq}}));
	    print "$r->{rdng}. $r->{txt} [$freqstr]\n"; }

#	1. ‚½‚ñ‚Ì‚¤ [nf16,news1]
#	2. ‚©‚ñ‚Ì‚¤ []

#================================================
#
#   Restriction tables
#
#================================================

# The database stores restrictions as disallowed pairs.  Generaly
# applications will want to display allowed pairs.  The restr
# table rows for each reading are avaiable via the rdng's {_restr}
# key.  In our example entr, there is restr info for the first
# reading:

	foreach $z (@{$e->{_rdng}[0]{_restr}}) {
	    print "entr=$z->{entr}, rdng=$z->{rdng}, kanj=$z->{kanj}\n"; }

#	entr=20894, rdng=1, kanj=2

# To get the set of allowed kanji for reading 1, the jmdict
# filt() function is conveniet.

	$restr = $e->{_rdng}[0]{_restr};
	$allowed_kanj = filt ($kanj, ["kanj"], $restr, ["kanj"]);

# filt() will return a list of all the elements in @$kanj that
# are not "in" @$restr.  An element of @$restr is "in" @$kanj
# if the value of the @$restr items with the keys listed in the
# 4th arg are equal to the values of the @$kanj items with the 
# keys listed in the 2nd arg.
# $allowed_kanj is now a refernce to an array of kanj records 
# that were _not_ present in @$restr.  Since there are two kanj
# records in the entry, and the restr set contains kanj=2, the
# @$allowed_kanj set contains one element which is the record 
# for kanj=1. 

	foreach $k (@{$allowed_kanj}) {
	    print "entr=$k->{entr}, kanj=$k->{kanj}, txt=$k->{txt}\n"; }

# We can use $allowed_kanj to display the restriction on
# reading to the user.  There will by no kanj $allowed_kanj
# list if the JMdict XML had the "re_nokanji" tag.  We can
# detect this even before getting $alllowed_kanj by noticing
# that the number of elementsa in @$restr is the same as in
# @$kanj.
#
# The following will print each reading text with any applicable
# restrictions on kanji use (we'll use entry 1589210).

	$t = Find ($dbh, "SELECT id FROM entr WHERE seq=?", [1589210]);
	$entries = EntrList ($dbh, $t);
	$e2 = $entries->[0];

	$kanj = $e2->{_kanj};
	foreach $r (@{$e2->{_rdng}}) {	
	    $restr = $r->{_restr};
	    if (!$restr) {
		print "$r->{rdng}. $r->{txt}\n"; }
	    elsif (scalar(@$restr) == scalar(@$kanj)) {
		print "$r->{rdng}. $r->{txt}(no kanji)\n"; }
	    else {
		$allowed = filt ($kanj, ["kanj"], $restr, ["kanj"]);
		$allowedtxt = join (";", map ($_->{txt}, @$allowed));
		print "$r->{rdng}. $r->{txt}($allowedtxt)\n"; } }

#	1. ‚¨‚½‚Ü‚¶‚á‚­‚µ
#	2. ‚©‚Æ (å˜åp)
#	3. ƒIƒ^ƒ}ƒWƒƒƒNƒV(no kanji)

# Use of the {_stagr} and {_stagk} elements in the senses are
# analogous (but without anything like "re_nokanji").

#================================================
#
#   Cross-references
#
#================================================

# the xref table is also a dual-parent table but with
# the complication that they refer to senses that are
# not in the same entry.
#
# EntrList() reads xref records for a sense like any other
# child records except that it does not build child
# records lists for the entries that are targets of the
# xref (which might have their own cross-refs which would
# be followed recursively and could result in reading a
# large amount of data and the construction of a very large
# tree.)
#
# But since having only the entry, and sense number of the
# cross-ref targets (which is the only information in the
# the xref records) is not very useful for display purposes.
# So EntrList() also reads the result set of a sql view that
# produces a simplified summary of the cross-ref targets
# and contains the target entry's id, seq number, the xref
# type, aggregted kanji and kana text strings, sense number,
# and the total number of senses in the entry.  This infomation
# can be used by the application to summerize the cross-ref
# or create a hyper-link to it.  (It should probably also
# include aggregated gloss text for the target sense but
# doesn't yet.)
#
# Unlike the other "_*" lists, the _erefs list is not a 
# simple list of row images.  It is a list of a more complex 
# structures.  Each structure in the list groups together
# all the cross-refs that point to senses in the same entry.
# There are 5 hash keys:
#
#	entr => <entry hash described below>
#	sens => list of sense numbers in the entry that
#	    are targets of this set of cross-ref.
#	typ => Number giving the type of xref.
#	srce => entry id of the entry the crodss refs
#	    are from.
#	srcs => sens number of the sense the cross refs
#	    are from,
#
# The "entr" key value is a reference to a hash that describres
# the entry of the cross-ref target senses, and has the 
# following keys:
#
#	eid => entry id of the target entry.
#	seq => sequence number of the target entry.
#	kanj => agregated text of the entry's kanj texts.
#	rdng => agregated text of the entry's rdng texts.
#	nsens => total number of senses in the target entry.
#
# Entry 1521400 (–ly‚Ú‚­z) has a two cross-refs in the third 
# sense ("manservent") to senses 1 and 2 of 1521390
# (–l G ‰º•” y ‚µ‚à‚× z).
# Here is how the {_erefs} look in the perl debugger:
#
#   '_erefs' => ARRAY(0x2394980)
#      0  HASH(0x23949d4)
#         'entr' => HASH(0x23942fc)
#            'eid' => 51673
#            'kanj' => '\x{50D5}; \x{4E0B}\x{90E8}'
#            'nsens' => 2
#            'rdng' => '\x{3057}\x{3082}\x{3079}'
#            'seq' => 1521390
#         'sens' => ARRAY(0x23949b0)
#            0  1
#            1  2
#         'srce' => 51674
#         'srcs' => 3
#         'typ' => 3
#
# Things to note: 
# There are two xref records in table xref but in the _erefs
# item, they are combined into a single item but becase both
# xrefs are to (definent senses of) the same entry.  
# The information about the sense theat the cross-refs 
# point to is contains in the {sens} elwment which is a 
# list of the sense (1 and 2 in this case).
# 
# The reason for this arrangement is to facilite display
# of cross-references to the user.  It is more concise
# to show something like 
#    see entry xxx (senses 1, 3)
# than
#    see entry xxx (sense 1)
#    see entry xxx (sense 3)
# and the _erefs structure facilitates the former.
#
# Here is a look at the actual data.

	$t = Find ($dbh, "SELECT id FROM entr WHERE seq=?", [1521400]);
	$entries = EntrList ($dbh, $t);
	$e = $entries->[0];

# The xrefs records (in sense 3):

	foreach $x (@{$e->{_sens}[2]{_xref}}) {
	    print "entr=$x->{entr}, sens=$x->{sens}, xentr=$x->{xentr}, xsens=$x->{xsens}, type=$x->{typ}\n"; }

#	entr=51674, sens=3, xentr=51673, xsens=1, type=3
#	entr=51674, sens=3, xentr=51673, xsens=2, type=3

# Here is an example of showing the cross references using
# the _erefs list:

	foreach $x (@{$e->{_sens}[2]{_erefs}}) {
	    $xreftyp = $::KW->{XREF}{$x->{typ}}{descr};
	    $senses = join (",", @{$x->{sens}});
	    if ($x->{entr}{kanj}) {
	 	# If there isa kanji and reading set #txt to "kkkk [reading]" 
		# \x{3010} is a filled left paren, \x{3011} a right one.
		$txt = "$x->{entr}{kanj}\x{3010}$x->{entr}{rdng}\x{3011}"; }
	    else {
		# Otherwise (there is no kanji text), set to just reading.
		$txt = $x->{entr}{rdng}; }
	    print "$xreftyp $x->{entr}{seq} $txt (sense $senses)\n"; }

#	See also 1521390 –l; ‰º•”y‚µ‚à‚×z (sense 1,2)

# For more examples of jmdict api use see the perl/showentr.pl script.
# The perl/cgi/entr.pl scgi script is alsop informative although a 
# lot of the data extraction and formatting occurs in the associated
# TAL template.

	print "Done!\n";
