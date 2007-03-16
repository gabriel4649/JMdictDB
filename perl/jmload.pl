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

# This program will adjust the relative eid numbers in the .pgx
# file produced by jmload.pl to fixed values for a specific database.
# The .dmp file produced by this program cam then be loaded into
# that database.

use strict; 
use Encode; use DBI;
use Getopt::Std ('getopts');

BEGIN {push (@INC, "./lib");}
use jmdictxml ('%JM2ID'); # Maps xml expanded entities to kw* table id's.

main: {
	my ($infn, $outfn, $enc, $eid, $user, $pw, $dbname, $host);

	getopts ("o:i:e:u:p:d:r:h", \%::Opts);
	if ($::Opts{h}) { usage (0); }
	$enc = $::Opts{e} || "utf-8";
	binmode(STDERR, ":encoding($enc)");
	eval { binmode($DB::OUT, ":encoding($enc)"); };

	$infn = shift (@ARGV) || "JMdict.pgx";
	$outfn  = $::Opts{o} || "JMdict.dmp";

	$user   = $::Opts{u} || "postgres";
	$pw     = $::Opts{p} || "";
	$dbname = $::Opts{d} || "jmdict";
	$host   = $::Opts{r} || "";

	if (defined ($::Opts{i})) {
	    $eid = int($::Opts{i}); }
	else {
	      # Get the starting values of $::eid and $::hist from the
	      # max values of entr.id and hist.id found in the database.
	      # If that database id numbers change between the time we
	      # read them, and our output file is loaded, the result will
	      # probably be duplicate key errors.
	      # FIXME: should be able to explicitly give these values 
	      #   on the commandline.
	    $eid = get_max_ids ($user, $pw, $dbname, $host); }
	if (!$eid =~ m/^-?\d+$/) {
	    die ("Did not get valid entr.id  value, please check -i\n"); }
	print STDERR "Initial entr.id = $eid\n";

	open (FIN, "<:utf8", $infn) or die ("Can't open $infn: $!\n");
	open (FOUT, ">:utf8", $outfn) or die ("Can't open $outfn: $!\n");
	while (<FIN>) {
	    s/\$\$E\$\$(\d+)/$1+$eid/eo;
	    print FOUT; }
	print STDERR ("Done\n"); }


sub get_max_ids { my ($user, $pw, $dbname, $host) = @_;
	# Get and return 1 + the max values of entr.id and hist.id
	# found in the database defined by the connection parameters
	# we were called with.

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

jmload.pl reads a .pgx such a produced by jmparse.pl and converts it
into a loadable Postgresql dmp file by converting the relative entry 
id numbers in the .pgx fie to actual numbers for a specific database.

Usage: jmparse.pl [-o output-filename] [-i starting-id-value] \\
		      [-u username] [-p password] [-d database] \\
		      [-r host] [-e encoding] \\
		    [pgx-filename]

Arguments:
	pgx-filename -- Name of input file that was created by
	  jmparse.pl.  Default is "JMdict.pgx".
Options:
	-h -- (help) print this text and exit.
	-o output-filename -- Name of output postgresql dump file. 
	    Default is "JMdict.dmp"
	-i starting-id -- Starting number for entry id fields.
	    It not give, jmload.pl will use the options below
	    to read the max id number from the databas and start 
	    with that number plus one.

	If -i was not given, the following options will be used to 
	connect to a database in order to read the max entr.id and
	hist.id values.  If the dmp file is loaded into a different
	database, or if the max entr.id or hist.id values change
	between load_jmdict.pl's read and loading the dump file, it
	is likely duplicate key errors will occur.

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
	  visible to anyone who can run a \"ps\" command.

	-u username -- Username to use when connecting to database.
	        Default is "postgres".
	-p password -- Password to use when connecting to database.
	        No default.

EOT
	exit $exitstat; }

