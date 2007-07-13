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

# This program will adjust the entr id numbers in a postgresql
# dump file of a jmdict database in order to make it loadable
# into a database where the file's entr id numbers are already
# in use.

use strict; 
use Encode; use DBI;
use Getopt::Std ('getopts');

BEGIN {push (@INC, "./lib");}
use jmdictxml ('%JM2ID'); # Maps xml expanded entities to kw* table id's.

main: {
	my ($infn, $outfn, $enc, $eid, $user, $pw, $dbname, $host, 
	    $v, $tblnm, $offtbl, $rmin, $rmax, @a, @cols, $col, 
	    $eiddelt, $delt, @updtd);

	getopts ("o:i:m:x:e:u:p:d:r:h", \%::Opts);
	if ($::Opts{h}) { usage (0); }
	$enc = $::Opts{e} || "utf-8";
	binmode(STDERR, ":encoding($enc)");
	eval { binmode($DB::OUT, ":encoding($enc)"); };

	$infn   = shift (@ARGV) || "jmdict.pgi";
	$outfn  = $::Opts{o}    || "jmdict.dmp";
	$rmin   = $::Opts{m}    || 1;
	$rmax   = $::Opts{x}    || 0;

	$user   = $::Opts{u}    || "postgres";
	$pw     = $::Opts{p}    || "";
	$dbname = $::Opts{d}    || "jmdict";
	$host   = $::Opts{r}    || "";

	$eid    = int($::Opts{i}) || 0;
	if (!$eid) {
	      # Get the starting value of $::eid from the
	      # max values of entr.id found in the database.
	      # If that database id number changes between the time we
	      # read it, and our output file is loaded, the result will
	      # probably be duplicate key errors.
	      # FIXME: should be able to explicitly give these values 
	      #   on the commandline.
	    $eid = get_max_ids ($user, $pw, $dbname, $host); }
	if (!$eid =~ m/^-?\d+$/) {
	    die ("Did not get valid entr.id  value, please check -i\n"); }
	$eiddelt = $eid - $rmin;
	print STDERR "Rebasing $rmin" . ($rmax ? "-".$rmax : "") . " to " . 
	    ($rmin + $eiddelt) . ($rmax ? "-".$rmin+$eiddelt+$rmax : "") ."\n";

	open (FIN, "<:utf8", $infn) or die ("Can't open $infn: $!\n");
	open (FOUT, ">:utf8", $outfn) or die ("Can't open $outfn: $!\n");

	# This hash identifies the database tables that have a foreign
	# reference to entr.id, and the column(s) (by number) of each 
	# such.
	$offtbl = {
	    entr    => [0],
	    rdng    => [0],
	    rinf    => [0],
	    kanj    => [0],
	    kinf    => [0],
	    sens    => [0],
	    gloss   => [0],
	    misc    => [0],
	    pos     => [0],
	    fld     => [0],
	    hist    => [0],
	    dial    => [0],
	    lsrc    => [0],
	    ginf    => [0],
	    restr   => [0],
	    stagr   => [0],
	    stagk   => [0],
	    xref    => [0,2], 
	    xresolv => [0],
	    tcard   => [2], 
	    tsndasn => [1], };

	$delt = 0;
	while (<FIN>) {
	    s/[\n\r]+$//o;
	    if ($. == 1 and (substr ($_, 0, 1) eq "\x{FEFF}")) {
		$_ = substr ($_, 1); }
	    if (m/^[\\]?COPY\s+([^\s(]+)/oi) {
		$tblnm = $1;
		if ($v = $offtbl->{$tblnm}) { # That's '=', not '=='!
		    @cols = @{$v};
		    $delt = $eiddelt;
		    push (@updtd, $tblnm); } }
	    elsif (m/^\\\.\s*$/o) {
		$delt = 0; }
	    elsif ($delt) {
		@a = split ("\t");
		foreach $col (@cols) {
		    $v = $a[$col];
		    if ($v >= $rmin && (!$rmax || $v < $rmax)) {
		        $a[$col] += $delt; } }
		$_ = join ("\t", @a); } 
	    print FOUT "$_\n"; }
	if (@updtd && $eiddelt != 0) {
	    print STDERR "Rebased tables: " . join (",",@updtd) . "\n"; }
	else { print STDERR "No changes made\n"; } }

sub get_max_ids { my ($user, $pw, $dbname, $host) = @_;
	# Get and return 1 + the max values of entr.id found in the
	# database defined by the connection parameters we were called
	# with.

	my ($dbh, $sql, $rs);

	if ($host) { $host = ";host=$host"; }
	$dbh = DBI->connect("dbi:Pg:dbname=$dbname$host", $user, $pw, 
			{ PrintWarn=>0, RaiseError=>1, AutoCommit=>0 } );
	$dbh->{pg_enable_utf8} = 1;
	$sql = "SELECT 1+COALESCE((SELECT MAX(id) FROM entr),0) AS entr";
	$rs = $dbh->selectall_arrayref ($sql);
	$dbh->disconnect();
	return $rs->[0][0]; }

sub usage { my ($exitstat) = @_;
	print <<EOT;

jmload.pl reads a postgresql dump file such as produced by 
jmparse.pl and adjusts the entr.id numbers in it.  This allows
jmparse.pl and other loader programs to generate entr.id numbers 
starting at 1, and rely on this program to adjust the numbers 
prior to loading into a database to avoid duplicate id numbers
when the database already contains other entries.

It also allows entries to be extracted from a database with
the postgresql 'copy' command and loaded into another database 
by rebasing the entr.id numbers.

Usage: jmload.pl [-o output-filename] [-i starting-id-value] \\
		      [-m minimum-id] [-x maximum-id]
		      [-u username] [-p password] [-d database] \\
		      [-r host] [-e encoding] \\
		    [pgi-filename]

Arguments:
	pgi-filename -- Name of input dump file.  Default is 
	    "jmdict.pgi".
Options:
	-h -- (help) print this text and exit.
	-o output-filename -- Name of output postgresql dump file. 
	    Default is "jmdict.dmp"
	-i starting-id -- Value that the minimum entr id (given
	    by the -m option) will be adjusted to.
	    It not given, jmload.pl will connect to the database
	    (using the options below) to read the max id number
	    from the database and use that number plus one.
	-m minimum-id -- Only entr id's equal or greater than this
	    will be modified.  If not given, default is 1.
	-x maximum-id -- Only entr id's less than this will be
	    modified.  If not given or 0, no maximum will apply.

	   If -i was not given, the following options will be used  
	   to connect to a database in order to read the max entr.id 
           value.  If the dmp file is loaded into a different database, 
	   or if the max entr.id value changes between load_jmdict.pl's 
	   read and loading the dump file, it is likely duplicate key  
	   errors will occur.

	-d dbname -- Name of database to use.  Default is "jmdict".
	-r host	-- Name of machine hosting the database.  Default
		is "localhost".
	-e encoding -- Encoding to use for stdout and stderr.
	 	Default is "utf-8".  Windows users running with 
		a Japanese locale may wish to use "cp932".
	-h -- (help) print this text and exit.

	   ***WARNING***
	   The following two options are not recommended for use 
	   on a multi-user machine because their values will be 
	   visible to anyone who can run a \"ps\" command.  Instead
	   use a Postgresql password file (see section 29.13. "The
	   Password File" in the Postgresql docs.)

	-u username -- Username to use when connecting to database.
	        Default is "postgres".
	-p password -- Password to use when connecting to database.
	        No default.

EOT
	exit $exitstat; }

