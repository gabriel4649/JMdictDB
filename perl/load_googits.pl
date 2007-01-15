#!/usr/bin/env perl

# Load data representing search engine hit counts into
# database frequency tables "kfreq" asnd "rfreq".
# See sub usage() below or run script with -h option for
# more info.

# Copyright (c) 2007 Stuart McGraw 
@VERSION = (substr('$Revision$',11,-2), \
	    substr('$Date$',7,-11));

use strict;  use warnings;
use Encode;  use DBI;
use Getopt::Std ('getopts');

BEGIN {push (@INC, "./lib");}
use jmdict;

    binmode(STDOUT, ":encoding(shift_jis)");
    binmode(STDERR, ":encoding(shift_jis)");
    eval { binmode($DB::OUT, ":encoding(shift_jis)"); };

    main: {
	my ($dbh, $dbname, $user, $pw, $infn, $kw);

	if (!getopts ("hnd:u:p:k:", \%::Opts)) { usage (1); }
	if ($::Opts{h}) { usage (0); }
	$user = $::Opts{u} || "postgres";
	$pw = $::Opts{p} || "";
	$dbname = $::Opts{d} || "jmdict";
	$kw = $::Opts{k} || "gA";
	$infn = shift (@ARGV) || usage (1);

	$dbh = DBI->connect("dbi:Pg:dbname=$dbname", "$user", "$pw", 
			{ PrintWarn=>0, RaiseError=>1, AutoCommit=>0 } );
	$dbh->{pg_enable_utf8} = 1;
	$::KW = Kwds ($dbh);
	($::FREQKWID = $::KW->{FREQ}{$kw}{id}) || die ("'$kw' keyword not found in kwfreq table\n");
	$::sthSK = $dbh->prepare ("SELECT id FROM kanj WHERE txt=?");
	$::sthSR = $dbh->prepare ("SELECT id FROM rdng WHERE txt=?");
	$::sthIK = $dbh->prepare ("INSERT INTO kfreq(kanj,kw,value) VALUES(?,?,?)");
	$::sthIR = $dbh->prepare ("INSERT INTO rfreq(rdng,kw,value) VALUES(?,?,?)");
	readfile ($infn); 
	$dbh->commit() if (!$::Opts{n});
	$dbh->finish(); }

   sub readfile { my ($infn) = @_;
	my (@a, $lasttxt, @freqs);
	$lasttxt = "__FIRST__";
	open (FIN,  "<:utf8", $infn) or die ("can't open $infn: $!\n"); 
	while (<FIN>) {
	    @a = split (/\t/);
	    if (scalar (@a) != 2) { die; }
	    next if ($a[1] == -1);
	    if ($a[0] ne $lasttxt) { 
		doline ($lasttxt, \@freqs) if ($lasttxt ne "__FIRST__");
		$lasttxt = $a[0]; @freqs = ($a[1]); }
	    else {
		push (@freqs, $a[1]); } }
	doline ($lasttxt, \@freqs);
	close (FIN); }

    sub doline { my ($txt, $freqs) = @_;
	my ($f, $hits, $typ, $ln);
	for $f (@$freqs) { $hits += $f; }
	$hits = int ($hits / scalar (@$freqs));
	$typ = jstr_classify ($txt);
	if ($typ & $::KANJI)   { wrtdb ($::sthSK, $::sthIK, $txt, $hits); }
	elsif ($typ & $::KANA) { wrtdb ($::sthSR, $::sthIR, $txt, $hits); }
	else { 
	    print STDERR "Warning, skipped line(s) $. ($txt), neither kana nor kanji\n"; } }

    sub wrtdb { my ($sth_s, $sth_i, $txt, $cnt) = @_;
	my ($rs, $r, $sql);
	$sth_s->execute ($txt);
	$rs = $sth_s->fetchall_arrayref ();
	if (scalar (@$rs) <= 0) { 
	    print STDERR "Warning, $txt not found (line $.)\n"; return; }
	if (scalar (@$rs) > 1) {
	    print STDERR "Warning, multiple entries found for '$txt' (line $.)\n"; }
	foreach $r (@$rs) { 
	    if (!$::Opts{n}) {
		$sth_i->execute ($r->[0], $::FREQKWID, $cnt); }
	    else {
		$sql = $sth_i->{Statement};
		$sql =~ s/[?]/$r->[0]/;
		$sql =~ s/[?]/$::FREQKWID/;
		$sql =~ s/[?]/$cnt/;
		print "$sql\n"; } } }


    sub usage { my ($exitstat, $msg) = @_;
	my ($use, $file);
	$use = <<EOT;
Usage: $0 [options] input-file
    Arguments:
	input-file -- Name of text file containing freqency-of-use
		data.  See section \"Input File Format\" below.
    Options:
	-k -- The keyword underwhich the FoU data will be stored
		in the database.  Default id \"gA\".
	-n -- Don't make any changes to the database but instead
		write the changes that would be made, in the form
		of INSERT statements, to stdout.
	-d -- Name of database to operate on.  Default is \"jmdict\".
	-h -- Print this help message and exit.

	  ***WARNING***
	  The following two options are not recommended because 
	  their values will be visible to anyone who can run a 
	  \"ps\" command.

	-u -- User name to connect to database as.  Default is
		\"postgres\".
	-p -- Password to use when connecting to database.  Default
		is \"\". 

    Input file format:
	Text in the file is utf-8 encoded.  Each line consists of
	two fields separated by a tab character.

	The first field is the string to which the FoU data applies.
	The second in the numeric (decimal) value that is the FoU
	value.

	If the first field string contains any kanji characters it
	will be looked for in the \"kanj\" database table.  If it 
	contains kana characters but no kanji characters it will
	be looked up in the \"rdng\" table.  In either case the lookup
	must result in only a single entry being found. If multiple
	entries are found, or the string contains neither kanji nor 
	kana charactes, a warning message is printed to stderr and 
	the line (and any following lines with the same string) is 
	skipped.

	If string occurs more than once in the file, those lines 
	must be consecutive (this can be arranged by sorting on
	the first field prior to using it in this program) and the
	FoU value loaded into the database will be the integer 
	floor of the average of	the values on all the lines.

	The file is loaded atomically: if there is an error while
	processing the file, no data will be loaded.
EOT

	if ($exitstat == 0) { $file = *STDOUT; }
	else { $file = *STDERR; }
	if ($msg) { print $file "$msg\n"; }
	print $file $use;
	exit ($exitstat); }
	
	
