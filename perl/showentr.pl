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
use jmdict;  use jmdictfmt;

#-----------------------------------------------------------------------

    main: {
	my ($dbh, $entries, $e, @qlist, @elist, $enc, $host,
	    $dbname, $user, $pw);

	  # Read and parse command line options.
	if (!getopts ("hvd:u:p:r:e:", \%::Opts) or $::Opts{h}) { usage (0); }

	  # Set some local variables based on the command line 
	  # options given or defaults where options not given.
	$enc =    $::Opts{e} || "utf8";
	$user =   $::Opts{u} || "postgres";
	$pw =     $::Opts{p} || "";
	$dbname = $::Opts{d} || "jmdict";
	$host =   $::Opts{r} || "";
	if ($::Opts{v}) { $::Debug{prtsql} = 1; }

	  # Make stderr unbuffered.
	my $oldfh = select(STDERR); $| = 1; select($oldfh);

	  # Set the default encoding of stdout and stderr.
	binmode(STDOUT, ":encoding($enc)");
	binmode(STDERR, ":encoding($enc)");

	  # Debugger writes to $DB::OUT.  Set its encoding but it
	  # will die if debugger not active.  So do inside and eval
	  # so as to not tereminate program in this case.
	eval { binmode($DB::OUT, ":encoding($enc)"); }; $dbh=$DB::OUT;

	  # Connect to the database.  Option PrintWarn is off to reduce
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
	foreach $e (@$entries) { print fmt_entr ($e); }

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

	  # The entries returned by EntrList() contain only the raw
	  # xref records (entry and sense numbers) which are very useful
	  # for display.  Call xrefdetails() to get summary info for 
	  # all those xrefs.  By giving the third arg, we ask xrefdetails()
	  # to distribute the info into each entry, in key {_erefs}.
	xrefdetails ($dbh, $tmptbl, $entries);

	  # ... which we return to our caller.
	return $entries; }

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
	-v -- (Verbose) print debugging info.
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

	

	 