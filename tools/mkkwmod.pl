#!/usr/bin/env perl
#
# This program will generate a module that creates the 
# same Kwds structure that is created by jmdict::Kwds(). 
# The module may them be "use"d by other programs instead
# of reading the kwds data dynamically from the database
# using jmdict::Kwds().   
#
# Usage:
#
#    mkkwmod.pl [options] >lib/kwstatic.pm
#
# Then in other programs:
#
#   [...]
#   use kwstatic;
#   $kw = $kwstatic::Kwds
#
# Copyright (c) 2007 Stuart McGraw 
@VERSION = (substr('$Revision$',11,-2), \
	    substr('$Date$',7,-11));

use strict;  use warnings;
use Encode;  use DBI;
use Getopt::Std ('getopts');
use Data::Dump qw(dump);

BEGIN {push (@INC, "./lib");}
use jmdict;

    sub main {
	my ($dbh, $host, $dbname, $user, $pw, 
	    $kw, $dt, $s1, $s2, $k, $v, $r, $x, $w, @klst);

	if (!getopts ("hd:u:p:r:e:", \%::Opts) or $::Opts{h}) { usage (0); }
	$user =   $::Opts{u} || "postgres";
	$pw =     $::Opts{p} || "";
	$dbname = $::Opts{d} || "jmdict";
	$host =   $::Opts{r} || "";

	if ($host) { $host = ";host=$host"; }
	$dbh = DBI->connect("dbi:Pg:dbname=$dbname$host", $user, $pw, 
			{ PrintWarn=>0, RaiseError=>1, AutoCommit=>0 } );
	$dbh->{pg_enable_utf8} = 1;
	$kw = Kwds ($dbh); 
	$dbh->disconnect();

	while (($k, $v) = each (%$kw)) {
	    foreach $r (sort {$a->{kw} cmp $b->{kw}} (kwrecs ($kw, $k))) { 
		($w = "\$KW${k}_$r->{kw}") =~ s/-/_/go;
		push (@klst, $w);
		$s1 .= "our($w) = $r->{id};\n"; } } 
	$s2 = dump ($kw);
	printf ($::Hdr, join(" ",@klst), $s1, $s2); }

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

