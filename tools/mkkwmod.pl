#!/usr/bin/env perl
#
# Generate a static keywords module from the kw table csv files.
#
# Copyright (c) 2007 Stuart McGraw 
@VERSION = (substr('$Revision$',11,-2), \
	    substr('$Date$',7,-11));

use strict;  use warnings;
use Encode;  
use Getopt::Std ('getopts');
use Data::Dump qw(dump);

BEGIN {push (@INC, "./lib");}
use jmdict;

    sub main {
	my (%KW, $dt, $s1, $s2, $k, $v, $r, $x, $w, @klst, $pgdatadir, $fn, $set);

	if (!getopts ("hd:", \%::Opts) or $::Opts{h}) { usage (0); }
	$pgdatadir = $::Opts{d} || "../pg/data/";
	if (!($pgdatadir =~ /[\\\/]$/)) { $pgdatadir .= "/"; }

	  # Read all the kw .csv files, and build into a keyword table
	  # structure assigned to $KW.

	for $set qw(DIAL FLD FREQ KINF LANG MISC POS RINF SRC STAT XREF) {
	    $fn = "kw" . lc ($set);
	    kwcsv (\%KW, $set, $pgdatadir . $fn . ".csv"); }

	  # Using the kw table data in %$KW, build two strings, $s1 and $s2.
	  # $s1, when eval'd, will create a list of scalar variable that 
	  # define the numeric (id) value for each keyword.  $s2 is the 
	  # output Data::dump() applied to %$KW, and will recreate %$KW 
	  # the program it is eval'd in.

	while (($k, $v) = each (%KW)) {
	    foreach $r (sort {$a->{kw} cmp $b->{kw}} (kwrecs (\%KW, $k))) { 
		($w = "\$KW${k}_$r->{kw}") =~ s/-/_/go;
		push (@klst, $w);
		$s1 .= "our($w) = $r->{id};\n"; } } 
	$s2 = dump (\%KW);

	  # Include $s1 and $s2 in a template that forms a perl module,
	  # and print the result to stdout, which the user will presumably
	  # sabe as a perl module somewhere.

	printf ($::Hdr, join(" ",@klst), $s1, $s2); }


    sub kwcsv { my ($KW, $set, $kwfile) = @_; 
	# Open .csv file $kwfile and read it contents into the data
	# structure %$KW.  $set is the key for the table's data in
	# %$KW and is by convention uc(substr($kwfile,2)).

	my ($id, $kw, $descr, $rec);
	open (F, $kwfile) || die ("mkkwmod.pl: unable to open file $kwfile: $!\n");
	while (<F>) {
	    next if (/^\s*(#.*)?$/o);	# Skip blank and comment lines.
	    ($id, $kw, $descr) = split ("\t", $_);
	    $rec = {id=>$id, kw=>$kw, descr=>$descr};
	    $KW->{$set}{$id} = $rec;  $KW->{$set}{$kw} = $rec; }
	close F; }

    sub usage { my ($exitstat) = @_;
	local (*F);
	if ($exitstat == 0) { *F = *STDOUT; }
	else { *F = *STDERR; }
	print F <<EOT;

Usage: mkkwmod.pl [-d pg_data_dir]

	mkkwmod.pl reads the kw table csv files in <pg_data_dir>
	and writes (to stdout) a perl module the will, when used 
	in a perl program, create a KW structure containing all
	the kw table data:

	    ./mkkwmod.pl >lib/kwstatic.pm

	Then in other programs:

	   use kwstatic;
	   \$kw = \$kwstatic::Kwds

    Arguments: none

    Options:
	-d pg_data_dir -- Name of a directory containing the kw
	    table csv files.  Default is "../pg/data/".
EOT
	; exit $exitstat; }


$::Hdr = <<EOT;
#======================================================
# CAUTION!
# This file was generated automatically my mkkwmod.pl
# and any changes made to this file will be overwritten 
# the next time it is regenerated.
#======================================================
use strict;  use warnings;
package kwstatic;

BEGIN {
    use Exporter();
    our (\$VERSION, \@ISA, \@EXPORT);
    \@ISA = qw(Exporter);
    \@EXPORT   = qw(\$Kdws %s); }

our (\@EXPORT);

%s

our (\$Kwds)   = %s; 

1;
EOT
	;

main ();

