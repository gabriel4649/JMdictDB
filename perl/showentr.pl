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
$::Debug = {};

#-----------------------------------------------------------------------

    main: {
	my ($dbh, $entries, $e, @qlist, @elist, $enc, $host,
	    $dbname, $user, $pw, $typ, $corp, $numb);

	  # Read and parse command line options.
	if (!getopts ("hvd:u:p:r:e:j", \%::Opts) or $::Opts{h}) { usage (0); }

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

	      # Check the command line argument format with a regex.
	    if (!(m/^([qe])?([0-9]+)(\.(\S+))?$/))  { 

		  # If no match, it has a bad format.
		print STDERR "Bad entry specifier in: $_\n";  next; }

	      # Get the three individual pieces of the argument format,
	      # providing default values for missing pieces. 
	    ($typ, $numb, $corp) = ($1 || 'q', $2, $4 || "jmdict");

	      # If it is an entry id specifier, push the value on to
	      # the @elist.

	    if ($typ eq 'e') { push (@elist, $numb); }

	      # Else (we know it is 'q' or otherwise the regex would
	      # have rejected it), check the the corpus values is 
	      # legit.  Note that one can lookup both keyword id numbers
	      # or the kw text in the $::KW structure.  Save the 'q'
	      # value and corpus id number on the @qlist. 
	    else {
		if (!($corp = $::KW->{SRC}{$corp}{id})) {
		    print STDERR "Invalid corpus value in: $_\n"; next; } 
		push (@qlist, [$numb, $corp]); } }

	  # Call get_entries() to read the desired entries from the
	  # database and construct runtime objects for them.
	$entries = get_entries ($dbh, \@elist, \@qlist);

	  # Go through the list of entries and print each.
	foreach $e (@$entries) { 
	    if ($::Opts{j}) { print jel_entr ($e); }
	    else { print fmt_entr ($e); } }

	print "--\nObj retrieval time: " . $::Debug->{'Obj retrieval time'} . "\n";
	print "Obj build time: " . $::Debug->{'Obj build time'} . "\n";
	print "Xrefsum retrieval time: " . $::Debug->{'Xrefsum retrieval time'} . "\n";

	  # Cleanly disconnect from the database (and thus avoid
	  # a warning message.)
	$dbh->disconnect(); }

#-----------------------------------------------------------------------

    sub get_entries { my ($dbh, $elist, $qlist) = @_;
	# $dbh -- Database handle for an open connection to jmdict db.
	# @$elist -- List of entry id numbers of entries to get.
	# @$qlist -- List of seq. numbers of entries to get.

	my (@whr, $sql, $entries);

	  # To retrieve the objects, we need a sql statement that 
	  # will return their id numbers.  The WHERE clause of that
	  # statement will be like
	  #   "WHERE e.id IN (e1,e2,e3,...) 
	  #        OR (src=c1 AND seq=q1)
	  #        OR (src=c2 AND seq=q2)
	  #        OR ..."
	  # (where e1,etc are the entry id numbers and q1,c1,etc are 
	  # the entry seq and corpus numbers of the entries we want.)

	if (@$qlist) { push (@whr, join(" OR ",
			map("(src=$_->[1] AND seq=$_->[0])",@$qlist))); }
	if (@$elist) { push (@whr, "e.id IN (" . join(",",map($_,@$elist)) . ")"); }

	  # Now we can create the sql statement, including creating 
	  # the WHERE clause by joining the twp pieces together with 
	  # a " OR ".  The join will not include the "or" if there 
	  # is only one piece (because there were only "q" numbers or 
	  # only "e" numbers).
	$sql = "SELECT e.id FROM entr e WHERE " . join (" OR ", @whr);

	  # Now we can give the sql statement to  EntrList() which  
	  # will use it to read the data for all the entries, contruct 
	  # objects for them, and return the list of objects to us...
	$entries = EntrList ($dbh, $sql);

	  # The entries returned by EntrList() contain only the raw
	  # xref records (entry and sense numbers) which are not very 
	  # useful for display.  Call add_xrefsums() to get summary
	  # info for all those xrefs.  By giving the third arg, we ask
	  # add_xrefsums to distribute the summary info into each xref,
	  # in key {ssum}.
	add_xrefsums ($dbh, $entries);

	  # ... which we return to our caller.
	return $entries; }

#-----------------------------------------------------------------------

sub usage { my ($exitstat) = @_;
	print <<EOT;

Usage: showentr.pl [options] ['e'entry_id] [['q']entry_seq[.[n|corpus]]] ...

    Arguments:
	A list of entries to display where each entry is specified
	in one of the following formats:
	  * nnnn -- Entry sequence number <nnnn>.
	  * ennnn -- Entry id number <nnnn>.
	  * qnnnn -- Entry sequence number <nnnn> in corpus "jmdict".
	  * qnnnn.mm -- Entry sequence number <nnnn> in corpus
	      number <mm>.
	  * qnnnn.aaaaa -- Entry sequence number in corpus named 
	      <aaaaa>, for example, "q14359.jmnedict".

    Options:
	-d dbname -- Name of database to use.  Default is "jmdict".
	-r host	-- Name of machine hosting the database.  Default
		is "localhost".
	-e encoding -- Encoding to use for stdout and stderr.
	 	Default is "utf-8".  Windows users running with 
		a Japanese locale may wish to use "cp932".
	-j -- Generate output in "JEL" format.  
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

	

	 