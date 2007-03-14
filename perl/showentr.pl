#!/usr/bin/env perl
#######################################################################
#   This file is part of JMdictDB. 
#   Copyright (c) 2006,2007 Stuart McGraw 
# 
#   JMdictDB is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published 
#   by the Free Software Foundation; either version 2 of the License, 
#   or (at your option) any later version.
# 
#   JMdictDB is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
# 
#   You should have received a copy of the GNU General Public License
#   along with JMdictDB; if not, write to the Free Software Foundation,
#   51 Franklin Street, Fifth Floor, Boston, MA  02110#1301, USA
#######################################################################

@VERSION = (substr('$Revision$',11,-2), \
	    substr('$Date$',7,-11));

# to do:
# temp table very slow, use only for sense?
# fix encoding issues on windows.

use strict;  use warnings;
use Encode;  use DBI;
use Getopt::Std ('getopts');


BEGIN {push (@INC, "./lib");}
use jmdict;  

#-----------------------------------------------------------------------

    main: {
	my ($dbh, $entries, $e, @qlist, @elist, $enc, $host,
	    $dbname, $user, $pw);

	  # Read and parse command line options.
	if (!getopts ("hd:u:p:r:e:", \%::Opts) or $::Opts{h}) { usage (0); }

	  # Set some local variables based on the command line 
	  # options given or defaults where options not given.
	$enc =    $::Opts{e} || "utf8";
	$user =   $::Opts{u} || "postgres";
	$pw =     $::Opts{p} || "";
	$dbname = $::Opts{d} || "jmdict";
	$host =   $::Opts{r} || "";

	  # Make stderr unbuffered.
	my $oldfh = select(STDERR); $| = 1; select($oldfh);

	  # Set the default encoding of stdout and stderr.
	binmode(STDOUT, ":encoding($enc)");
	binmode(STDERR, ":encoding($enc)");

	  # Debugger writes to $DB::OUT.  Set its encoding but it
	  # will die if debugger not active.  So do inside and eval
	  # so as to not tereminate program in this case.
	eval { binmode($DB::OUT, ":encoding($enc)"); }; $dbh=$DB::OUT;

	  # Connecet to the database.  Option PrintWarn is off to reduce
	  # message noise.  RaiseError is on so we don't need to check
	  # return code after every database operation,; error will
	  # cause exception.  AutoCommit off because we want to control
	  # transactions ourself.  (Although that is moot is this app 
	  # since we will only read from the database.)
	if ($host) { $host = ";host=$host"; }
	$dbh = DBI->connect("dbi:Pg:dbname=$dbname$host", $user, $pw, 
			{ PrintWarn=>0, RaiseError=>1, AutoCommit=>0 } );

	  # This is needed so that postgresql will give us unicode
	  # characters instead of bytes. 
	$dbh->{pg_enable_utf8} = 1;

	  # Read all the kw* tables put the data into a hash
	  # structure that we will use to conver id numbers to 
	  # keywords and visa-versa.  Save as a global variable
	  # so that data (which we will treat as aread-only)
	  # will be available thoughout this app.
	$::KW = Kwds ($dbh);

	  # Parse the command line arguments.
	foreach (@ARGV) {
	      # Build two lists from the command line arguments.
	      # @qlist will hold seq. numbers, @elist will hold
	      # entry id numbers.

	      # If it is just a number, it is a seq number.
	    if (m/^[0-9]/)  { push (@qlist, int ($_)); }

	      # If is is prefixed with a "q" is is a seq number.
	    elsif (m/^q/i) { push (@qlist, int (substr ($_, 1))); }

	      # If it is prefixed with a "e", it is a entry id number.
	    elsif (m/^e/i) { push (@elist, int (substr ($_, 1))); }

	      # Otherwise it is bogus.
	    else { print STDERR "Invalid argument skipped: $_" } }

	  # Call get_entries() to read the desired entries from the
	  # database and construct runtime objects for them.
	$entries = get_entries ($dbh, \@elist, \@qlist);

	  # Go through the list of entries and print each.
	foreach $e (@$entries) { p_entry ($e); }

	  # Cleanly disconnect from the database (and thus avoid
	  # a warning message.)
	$dbh->disconnect(); }

#-----------------------------------------------------------------------

    sub get_entries { my ($dbh, $elist, $qlist) = @_;
	# $dbh -- Database handle for an open connection to jmdict db.
	# @$elist -- List of entry id numbers of entries to get.
	# @$qlist -- List of seq. numbers of entries to get.

	my (@whr, $sql, $tmptbl, $entries);

	  # To retrieve the objects, we need a sql statement that 
	  # will return their id numbers.  The WHERE clause of that
	  # statement will be like
	  #   "WHERE e.seq IN (q1,q2,q3,...) OR e.id IN (e1,e2,e3,...)"
	  # (where s1,etc are the seq numbers and e1,etc are the entry 
	  # id numbers of the entries we want.)  *Except* that we will
	  # we will use "?" paramater markers in the actual sql statement,
	  # and the q1,...e1,... values will be passed as an argument
	  # list.  This is to avoid creating a sql injection security
	  # vunerability.  
	  # We already have the q1,...,e1,... numbers is lists so all
	  # we need to do is create the WHERE clause with a corresponding
	  # number of "?" paramarer markers in the "IN(...)" part. 
	  # We may have no e numbers or no q numbers so we create each
	  # part of the clause seperately in list @whr.  The map() calls
	  # below will generate a list with the same number of "?" elements
	  # as there are numbers in @qlist or @elist, and the join() will
	  # convert that array into a comma delimited string.

	if (@$qlist) { push (@whr, "e.seq IN (" . join(",",map('?',@$qlist)) . ")"); }
	if (@$elist) { push (@whr, "e.id  IN (" . join(",",map('?',@$elist)) . ")"); }

	  # Now we can create the sql statement, including creating 
	  # the WHERE clause by joining the twp pieces together with 
	  # a " OR ".  The join will not include the "or" if there 
	  # is only one peice (because there were onle "q" numbers or 
	  # only "e" numbers.
	$sql = "SELECT e.id FROM entr e WHERE " . join (" OR ", @whr);

	  # Now we can give the sql statement to Find() which will
	  # create a temp table containing the entry id numbers of
	  # all the reqursted entries.  It returns the name of the 
	  # temp table.
	$tmptbl = Find ($dbh, $sql, [@$qlist, @$elist]);

	  # Give the name of the temp table to EntrList() which will 
	  # use it to read the data for all the entries, contruct 
	  # objects for tham, and return the list to us...
	$entries = EntrList ($dbh, $tmptbl);

	  # ... which we return to our caller.
	return $entries; }

#-----------------------------------------------------------------------

    sub p_entry { my ($e) = @_;
	# Print an entry.
	# $e -- Reference to an entry hash.

	my (@x, $x, $s, $n, $stat, $src);

	  # $e->{stat} is the value of the "stat" column 
	  # for this entry.  It is a number that corresponds
	  # to the id number of a row in table kwstat.
	  # To convert it to a keyword string, we look the 
	  # number up in the STAT secotion of the kw table 
	  # data structure in $::KW.
	$stat = $::KW->{STAT}{$e->{stat}}{kw};
	$src  = $::KW->{SRC}{$e->{src}}{kw};

	  # Print basic info about the entry (seq num, status, and id number.)
	print "\nEntry $e->{seq} [$stat] $src \{$e->{id}\}";

	  # Print a list of dialects if there are any.
	  # The map() call will return a list created from its first 
	  #   argument by setting $_ in it, to each element the second
	  #   argument (the list of dialects) in turn.  
	  # The first arg is $::KW->{DIAL}{$_->{kw}}{kw}.
	  # $::KW->{DIAL} is the section of $::KW that contains dialect
	  #   info from table kwdial.  
	  # $_ an element from the dialects list in @{$e->{_dial}} 
	  #   (which is a record from table "dial").
	  # $_->{kw} is the value in the kw column of that record (and
	  #   is a number that references the id column of the kwdial
	  #   table.)
	  # $::KW->{DIAL}{$_->{kw}} looks that number up in (effectively)
	  #   the kwdial table, and give the kwdial record (a hash ref).
	  # $::KW->{DIAL}{$_->{kw}}{kw} selects the value of the 'kw' 
	  #   column of that record.  This is a short string.
	  # The output of map is a list of these strings.
	  # The join() call turns that list into a comma delimited 
	  #   string.

	print ", Dialect: "     . join(",", 
		map ($::KW->{DIAL}{$_->{kw}}{kw}, @{$e->{_dial}})) if ($e->{_dial});

	  # Print a list of origin languages.  Works the same way as
	  # dialect above. 

	print ", Origin lang: " . join(",", 
		map ($::KW->{LANG}{$_->{kw}}{kw}, @{$e->{_lang}})) if ($e->{_lang}) ;

	  # Print entry notes if any.

	print "\n";
	print "  Notes: $e->{_notes}\n" if ($e->{_notes}) ;

	  # For every kanji record in the entry, call f_kanj() on 
	  # to foemat it into a string (along with any kinf or freq
	  # info).  Then join those strings together with ";" chars
	  # and print.

	@x = map (f_kanj($_), @{$e->{_kanj}});
	if (@x) { print ("Kanji: " . join ("; ", @x) . "\n"); }

	  # Do the same for the reading records.  However, the entry's
	  # kanji records are given to f_rdng() which needs them to
	  # properly handle any restr restrictions.

	@x = map (f_rdng($_, $e->{_kanj}), @{$e->{_rdng}});
	if (@x) { print ("Readings: " . join ("; ", @x) . "\n"); }

	  # Now go through an process each sense in the entry.

	foreach $s (@{$e->{_sens}}) {
	    $n += 1;  # Increment the sense number.  First sense is 1.

	      # Format and print the sense's data.  In order to do
	      # that, p_sens() needs to have the sense record,
	      # the sense number, and the sets of reading and 
	      # kanji records for the entry, in order to properly
	      # handle any stagr or stagk restrictions.

	    p_sens ($s, $n, $e->{_kanj}, $e->{_rdng}); }

	  # Rather than printing the audio record info when printing
	  # the reading in which it occurs, we print them all out here
	  # at the end.  Grep out the audio records from the readings
	  # and print them if any.

	@x = grep ($_->{_audio}, @{$e->{_rdng}});
	if (@x) { p_audio (\@x); }

	  # If there are any hist records, print them.

	if ($e->{_hist}) { p_hist ($e->{_hist}); }
	# owarimashita.
	}

#-----------------------------------------------------------------------

    sub f_kanj { my ($k) = @_;
	# Format a kanj record %$k.  
	# Return string with the formatted info.

	my ($txt, @f);
	$txt = $k->{txt};

	  # Convert the list of numeric freq/value items in
	  # @{$k->{_kfreq}} to a list of keyword/value strings.

	@f = map ($::KW->{FREQ}{$_->{kw}}{kw}."$_->{value}", @{$k->{_kfreq}});

	  # To that list add kinfo strings.

	push (@f, map ($::KW->{KINF}{$_->{kw}}{kw}, @{$k->{_kinf}}));

	  # Join together with commas and enclose in brackets.

	($txt .= "[" . join (",", @f) . "]") if (@f);

	  # Prepend the kanji number.

	$txt = "$k->{kanj}.$txt";
	return $txt; }

#-----------------------------------------------------------------------

    sub f_rdng { my ($r, $kanj) = @_;
	my ($txt, @f, $restr, $klist);

	  # Get the reading's text.

	$txt = $r->{txt};  

	  # Convert the list of numeric freq/value items in
	  # @{$r->{_rfreq}} to a list of keyword/value strings.

	@f = map ($::KW->{FREQ}{$_->{kw}}{kw}."$_->{value}", @{$r->{_rfreq}});

	  # To that list add rinfo strings.

	push (@f, map ($::KW->{RINF}{$_->{kw}}{kw}, @{$r->{_rinf}}));

	  # Join the rfreq/rinf strings together with commas, 
	  # enclose in brackets, and combine with the reading text.

	($txt .= "[" . join (",", @f) . "]") if (@f);

	  # If $r->{_restr} is logically true, then this reading 
	  # is restricted to certian kanj.  

	if ($kanj and ($restr = $r->{_restr})) {  # That's '=', not '=='.

	      # If the number of restr elements is the same as the 
	      # number of kanji, then no kanji are valid for this
	      # reading.

	    if (scalar (@$restr) == scalar (@$kanj)) { $txt .= "\x{3010}no kanji\x{3011}"; }
	    else {

		  # Otherwise the kanj that are valid are the
		  # set of all the kanji, minus the invalid
		  # ones.  We use jmdict::filt() to do this 
		  # set difference operation.  Filt() will return
		  # a list of all the kanj records in %$kanj that
		  # are not in %$restr.  In-ness is dtermined by 
		  # comparing the value of the "kanj"-keyed element
		  # of each kanj record, with the "kanj"-keyed 
		  # element of each restr record.

		$klist = filt ($kanj, ["kanj"], $restr, ["kanj"]);

		  # Take the remaining kanji records, get the txt, 
		  # join together into a string, enclose in brackets,
		  # and tack onto the end of the reading text.

		$txt .= "\x{3010}" . join ("; ", map ($_->{txt}, @$klist)) . "\x{3011}"; } }

	  # Prepend the reading number.

	$txt = "$r->{rdng}.$txt";

	# owarimashita.
	return $txt; }

#-----------------------------------------------------------------------

    sub p_sens { my ($s, $n, $kanj, $rdng) = @_;
	# Print a sense.
	# $s -- Reference to a sense structure.
	# $n -- Sense number.
	# @$kanj -- List of kanj records for this sense's entry,  
	# @$rdng -- List of rdng records for this sense's entry,  

	my ($pos, $misc, $fld, $restrs, $lang, $g, @r, $stagr, $stagk);

	  # Get a text string list of the sense's PoS abbreviations.

	$pos = join (",", map ($::KW->{POS}{$_->{kw}}{kw}, @{$s->{_pos}}));
	if ($pos) { $pos = "[$pos]"; }

	  # Get a text string list of the sense's misc abbreviations.

	$misc = join (",", map ($::KW->{MISC}{$_->{kw}}{kw}, @{$s->{_misc}}));
	if ($misc) { $misc = "[$misc]"; }

	  # Get a text string list of the sense's field abbreviations.

	$fld = join (",", map ($::KW->{FLD}{$_->{kw}}{kw}, @{$s->{_fld}}));
	if ($fld) { $fld = " $fld term"; }

	  # If there are any stagr or stagk restrictions we will
	  # list them.  Like the treatment of restr in f_rdng(), 
	  # we use filt() to subtract the set of invalid sens-kanji
	  # (reading) combinations given in @$stagk (@$stagr) from
	  # the full set of kanji (readings) in @$kanj (@$rdng). 
	  # The difference is the allowed combinations.

	if ($kanj and ($stagk = $s->{_stagk})) { # That's '=', not '=='.
	    push (@r, @{filt ($kanj, ["kanj"], $stagk, ["kanj"])}); }
	if ($rdng and ($stagr = $s->{_stagr})) { # That's '=', not '=='.
	    push (@r, @{filt ($rdng, ["rdng"], $stagr, ["rdng"])}); }

	  # Format the allowed kanji/reading) in @r as a text string.

	$restrs = @r ? "(" . join (", ", map ($_->{txt}, @r)) . " only) " : "";

	  # Print the sense info.

	print "$s->{sens}. $restrs$pos$misc$fld\n";
	if ($s->{notes}) { print "  $s->{notes}\n"; }

	  # Do the glosses.

	foreach $g (@{$s->{_gloss}}) {

	      # If the lsanguage is no english (1) then get
	      # the language's keyword enclosed in parens.

	    if ($g->{lang} == 1) { $lang = "" }
	    else { $lang = "(" . $::KW->{LANG}{$g->{lang}}{kw} . ") "; }

	      # Print the gloss number, language (if any), and gloss text. 

	    print "  $g->{gloss}. $lang$g->{txt}\n"; }

	  # Print the cross references.  Although each sens record
	  # has a {_xref} list, it is not very useful because all
	  # it has is the cross-ref's entry idf and sens number.
	  # Insead, we'll use {_erefs} which also has the target 
	  # entry's kanji and kana string, seq number, etc which
	  # allows a much more informative display.  {_erers} is 
	  # same, but for other xrefs poining to this sense.

	p_xref ($s->{_erefs}, "Cross references:"); 
	p_xref ($s->{_erers}, "Reverse references:"); }

#-----------------------------------------------------------------------

    sub p_audio { my ($rdngs) = @_;
	my ($r, $a, $rtxt, $audio);
	print "Audio:\n";
	foreach $r (@$rdngs) {
	    next if (!($audio = $r->{_audio}));
	    $rtxt = "  " . $r->{txt} . ":";
	    foreach $a (@$audio) {
		print "$rtxt $a->{rdng}. $a->{fname} $a->{strt}/$a->{leng}\n";
		$rtxt = "    "; } } }

#-----------------------------------------------------------------------

    sub p_hist { my ($hists) = @_;
	my ($h, $n, $kw);
	print "History:\n";
	foreach $h (@$hists) {
	    $kw = $::KW->{STAT}{$h->{stat}}{kw};
	    print "  $h->{hist}. $kw $h->{dt} $h->{who}\n";
	    if ($n = $h->{notes}) { # That's an '=', not '=='.
		$n =~ s/(\n.)/    $1/;
		print "    $n\n"; } } }

#-----------------------------------------------------------------------

    sub p_xref { my ($erefs, $sep) = @_;
	my ($x, $t, $sep_done, $txt, $slist);

	# We use the {_erefs} list rather then the {_xref} list
	# because the former provide more display-oriented info.
	# It is grouped by target entry, with a list of the 
	# target senses within each entry.  This function handles
	# both forward and reverse erefs -- the caller determines
	# which by its choice of arguments.

	foreach $x (@$erefs) {

	      # Print a separator line, the first time round the loop.
	      # The seperator text is passeed by the caller because 
	      # it depends on whether we are doing forward or reverse
	      # cross-refs.

	    if (!$sep_done) { print "  $sep\n";  $sep_done = 1; }

	      # Get the text for the xref type.

	    $t = $::KW->{XREF}{$x->{typ}}{descr};

	      # Get the target entry's text.  If only readings, use as-is.
	      # If has kanji, use that followed by reading in brackets.

	    if ($x->{entr}{kanj}) { $txt = $x->{entr}{rdng}; }
	    else { $txt = "$x->{entr}{kanj}\x{3010}$x->{entr}{rdng}\x{3011}";}

	      # If the number of senses pointed to by our xrefs is the
	      # same as the number of senses in the target entry, don't
	      # mentions the sendse at all.  This xref points to entire 
	      # entry.  Otherwise, give the senses pointed to a list of
	      # sense numbers.
	      # N.B. might want to always print the list if number of 
	      # target senses is greater than 1.   Rational is that such
	      # mutiple senses are probably in error (residue of JMdict
	      # xml's sense->entry semantics) and should be reviewed.

	    if ($x->{entr}{nsens} == scalar (@{$x->{sens}})) { $slist = ""; }
	    else { $slist = " senses (" . join (",", @{$x->{sens}}) . ")"; }

	      # Print the xref info.

	    print "    $t: $x->{entr}{seq}$slist " . $txt . "\n"; } }

#-----------------------------------------------------------------------

sub usage { my ($exitstat) = @_;
	print <<EOT;

Usage: showentr.pl [options] [['q']entry_seq] ['e'entry_id]

Arguments:
	A list of entries to display:
	  - A number or number prefixed with the letter 'q' is 
	    interpreted as an entry sequence number.
	  - A number prefixed with the letter 'e' is interpreted 
	    as an entry id number.

Options:
	-d dbname -- Name of database to use.  Default is "jmdict".
	-r host	-- Name of machine hosting the database.  Default
		is "localhost".
	-e encoding -- Encoding to use for stdout and stderr.
	 	Default is "utf-8".  Windows users running with 
		a Japanese locale may wish to use "cp932".
	-h -- (help) print this text and exit.

	  ***WARNING***
	  The following two options are not recommended because 
	  their values will be visible to anyone who can run a 
	  \"ps\" command.

	-u username -- Username to use when connecting to database.
	        Default is "postgres".
	-p password -- Password to use when connecting to database.
	        No default.
EOT
	exit $exitstat; }

	

	 