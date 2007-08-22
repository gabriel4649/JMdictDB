#!/usr/bin/env perl
#######################################################################
#   This file is part of JMdictDB. 
#   Copyright (c) 2007 Stuart McGraw 
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

# This program creates rows in table "xref" based on the 
# textual (kanji and kana) xref information saved in table
# "xresolv" by the programs jmparse.pl and exparse.pl when
# loading the database from a corpus file.
#
# Each xresolv row contains the entr id and sens number 
# of the entry that contained the xref, the type of xref,
# and the xref target entry kanji and or reading, and
# optionally, sense number. 
#
# This program searchs for an entry matching the kanji
# and reading and creates one or more xref records using
# the target entry's id number.  The matching process is
# more involved than doing a simple search because a kanji
# xref may match several entries, and our job is to find 
# the right one.  This is currently done by a fast but 
# inaccurate method that does not take into account restr,
# stagr, and stag restrictions which limit certain reading-
# kanji combinations and thus would make unabiguous some
# xrefs that this program considers ambiguous.  See the
# comments in sub choose_entry() for a description of
# the algorithm. 
#
# When an xref text is not found, or multiple candidate
# entries still exist after applying the selection
# algorithm, the fact is reported and that xref skipped.


use strict;  use warnings;
use Encode;  use DBI;
use Getopt::Std ('getopts');


BEGIN {push (@INC, "./lib");}
use jmdict;  use jmdictfmt;
$::Debug = {};

use Memoize;
memoize ('get_entries');

#-----------------------------------------------------------------------

    main: {
	my ($dbh, $entries, $enc, $host, $dbname, $user, $pw,
	    $xref_src, $targ_src, $start, $blksz, $krmap, $ncnt);

	  # Read and parse command line options.
	if (!getopts ("hd:u:p:r:e:s:t:D:nqv", \%::Opts) or $::Opts{h}) { usage (0); }

	  # Set some local variables based on the command line 
	  # options given or defaults where options not given.
	$enc =    $::Opts{e} || "utf8";
	$user =   $::Opts{u} || "postgres";
	$pw =     $::Opts{p} || "";
	$dbname = $::Opts{d} || "jmdict";
	$host =   $::Opts{r} || "";
	if (!$::Opts{D}) { $::Opts{D} = 0; }
	  # Debugging flags:
	  #  1 -- Print generated xref records.
	  #  2 -- Print executed sql.

	if ($::Opts{D} & 0x02) { $::Debug{prtsql} = 1; }

	  # Set the default encoding of stdout and stderr.
	binmode(STDOUT, ":encoding($enc)");
	binmode(STDERR, ":encoding($enc)");
	eval { binmode($DB::OUT, ":encoding($enc)"); }; $dbh=$DB::OUT;
	my $tmp = select(STDOUT); $| = 1; select($tmp);

	if ($host) { $host = ";host=$host"; }
	$dbh = DBI->connect("dbi:Pg:dbname=$dbname$host", $user, $pw, 
			{ PrintWarn=>0, RaiseError=>1, AutoCommit=>0 } );
	$dbh->{pg_enable_utf8} = 1;  $::KW = Kwds ($dbh);

	$xref_src = $::Opts{s} || $::KW->{SRC}{jmdict}{id};
	$targ_src = $::Opts{t} || $::KW->{SRC}{jmdict}{id};

	$krmap = read_krmap ($dbh, $::Opts{f}, $targ_src);

	$SIG{INT} = \&show_msg_sum_and_exit; 
	$start = 0; $blksz = 1000;
	while (1) {
	    if (!$::Opts{n} and $start != 0) { 
		$dbh->commit(); 
		print STDOUT "Commit\n" if ($::Opts{v}); }
	    $ncnt = resolv ($dbh, $start, $blksz, 
			    $xref_src, $targ_src, $krmap); 
	    last if (!$ncnt); 
	    $start += $ncnt; }
	print_msg_summary();
	$dbh->disconnect(); }

    sub show_msg_sum_and_exit {
	print_msg_summary();
	exit; }

#-----------------------------------------------------------------------

    sub resolv { my ($dbh, $start, $blksz, $xref_src, $targ_src, $krmap) = @_;
	my ($x, $sql, $rs, $v, $xrefs, $entries, $e, $cntr);

	$sql = "SELECT v.*,e.seq FROM xresolv v JOIN entr e ON v.entr=e.id " .
		        "WHERE e.src=? ORDER BY v.entr,v.sens,v.ord " .
			"OFFSET $start LIMIT $blksz";
	$rs = dbread ($dbh, $sql, [$xref_src]);
	if (scalar (@$rs) == 0) { return 0; }

	foreach $v (@$rs) {
	    $e = undef;
	    if ($krmap && %$krmap) { 

		  # If we have a user supplied map, lookup the xresolv
		  # reading and kanji in it first.

		$e = krlookup ($krmap, $v->{rtxt}, $v->{ktxt}); }

	    if (!$e) {

		  # If there was no map, or the xresolv reading/kanji 
		  # was not found in it, look in the database for them.
		  # get_entries() will return an abbreviated entry 
		  # summary record for each entry that has a matching 
		  # reading-kanji pair (if the xresolv rec specifies 
		  # both), reading or kanji (if the xresolv rec specifies
		  # one).

	        $entries = get_entries ($dbh, $targ_src, $v->{rtxt}, $v->{ktxt});

		  # Choose_target() will examine the entries and determine if
		  # if it can narrows the target down to a single entry, which
		  # it will return as a 7-element array (see get_entries() for
		  # description).  If it can't find a unique entry, it takes
		  # care of generating an error message and returns a false value. 

	        next if (!($e = choose_target ($v, $entries))); } # That's "=", not "==".

	      # Check that the chosen target entry isn't the same as the
	      # referring entry.

	    if ($e->[0] == $v->{entr}) {
		msg (fs($v), "self-referential", kr($v));
		next; }

	      # Now that we know the target entry, we can create the actual
	      # db xref records.  There may be more than one of the target 
	      # entry has multiple senses and no explicit sense was given
	      # in the xresolv record.

	    $xrefs = mkxrefs ($v, $e); 

	    if ($::Opts{v} and @$xrefs) { print STDOUT 
	        fs($v)." resolved to ".scalar(@$xrefs)." xrefs: " .kr($v)."\n"; }

	      # Write each xref record to the database...
	    foreach $x (@$xrefs) {
		if (!$::Opts{n}) {
		    if ($::Opts{D} & 0x01) {
	 		print STDERR "($x->{entr},$x->{sens},$x->{xref},$x->{typ},$x->{xentr},"
				    .  "$x->{xsens}," . ($x->{rdng}||"") . "," . ($x->{kanj}||"")
				    . ",$x->{notes})\n"; }
		    dbinsert ($dbh, "xref", 
			      ["entr","sens","xref","typ","xentr","xsens","rdng","kanj","notes"],
			      $x); } } }
	return scalar (@$rs); }


    sub get_entries { my ($dbh, $targ_src, $rtxt, $ktxt, $seq) = @_;

	# Find all entries in the corpus $targ_src that have a
	# reading and kanji that match $rtxt and $ktxt.  If $seq
	# is given, then the matched entries must also have a
	# as sequence number tyhat is the same.  Matches are 
	# restricted to entries with stat=2 ("active");
	#
	# The records in the entry list are lists, and are
	# indexed as follows:
	#
	#	0 -- entr.id
	#	1 -- entr.seq
	#	2 -- rdng.rdng
	#	3 -- kanj.kanj
	#	4 -- total number of readings in entry.
	#	5 -- total number of kanji in entry.
	#	6 -- total number of senses in entry.

	my ($sth, $sql, $rs, @args, @cond);

	die ("get_entries(): \$rtxt and \$ktxt args are are both empty.\n") if (!$ktxt and !$rtxt);
	@args = ();  @cond = ();
	push (@args, $targ_src); push (@cond, "src=?");
	if ($seq) {
	    push (@args, $seq); push (@cond, "seq=?"); }
	if ($rtxt) { push (@args, $rtxt); push (@cond, "r.txt=?"); }
	if ($ktxt) { push (@args, $ktxt); push (@cond, "k.txt=?"); }
	$sql = "SELECT DISTINCT id,seq,".
		($rtxt ? "r.rdng," : "NULL AS rdng,").
		($ktxt ? "k.kanj," : "NULL AS kanj,").
		  "(SELECT COUNT(*) FROM rdng WHERE entr=id) AS rcnt,".
		  "(SELECT COUNT(*) FROM kanj WHERE entr=id) AS kcnt,".
		  "(SELECT COUNT(*) FROM sens WHERE entr=id) AS scnt".
		" FROM entr e ".
		($rtxt ? "JOIN rdng r ON r.entr=e.id " : "").
		($ktxt ? "JOIN kanj k ON k.entr=e.id " : "").
		"WHERE stat=$::KW->{STAT}{A}{id} AND " . join (" AND ", @cond);
	$sth = $dbh->prepare_cached ($sql);
	$sth->execute (@args);
	$rs = $sth->fetchall_arrayref();
	return $rs; }

    sub choose_target { my ($v, $entries) = @_;
	my ($rtxt, $ktxt, $msg, @candidates);

	# From that candidate target entries in @$entries,
	# choose the one we will use for xref target for
	# the xresolv record in $v.
	#
	# The current algorithm is what was intended to be 
	# implemented by the former xresolv.sql script.
	# Like that script, it does not take into account
	# any of the restr, stagk, stagr information.
	# Ideally, if we find a single match based on the
	# first valid (considering those restrictions)
	# reading/kanji we should use that as a target.
	# The best way to do that is under review.
	#
	# The list of entries we received are those that 
	# have a matching reading and kanji (in any positions)
	# if the xresolv record had both reading and kanji,
	# or a matching reading or kani (in any position)
	# if the xresolv record had only a reading or kanji.

	$rtxt = $v->{rtxt};  $ktxt = $v->{ktxt};

	  # If there is only a single entry that matched,
	  # that must be the target.
	if (1 == scalar (@$entries)) { return $entries->[0]; }

	  # And if there were no matching entries at all...
	if (0 == scalar (@$entries)) {
	    msg (fs($v), "not found", kr($v)); return undef; }

	if (!$ktxt) {
	      # If there is only one entry that has the 
	      # given reading as the first reading, and no
	      # kanji, that's it.
	    @candidates = grep ($_->[5]==0 && $_->[2]==1, @$entries);
	    if (1 == scalar (@candidates)) { return $candidates[0]; }

	      # If there is only one entry that has the 
	      # given reading and no kanji, that's it.
	    @candidates = grep ($_->[5]==0, @$entries);
	    if (1 == scalar (@candidates)) { return $candidates[0]; }

	      # Is there is only one entry with reading 
	      # as the first reading?
	    @candidates = grep ($_->[2]==1, @$entries);
	    if (1 == scalar (@candidates)) { return $candidates[0]; } }

	elsif (!$rtxt) {
	      # Is there only one entry whose 1st kanji matches?
	    @candidates = grep ($_->[3]==1, @$entries);
	    if (1 == scalar (@candidates)) { return $candidates[0]; } }

	  # At this point we either failed to resolve in one 
	  # of the above suites, or we had both a reading and 
	  # kanji with multiple matches -- either way we give up.
	msg (fs($v), "multiple targets", kr($v));
	return undef; }

    sub mkxrefs { my ($v, $e) = @_;
	my ($s, $xref, @xrefs, $cntr);

	$cntr = 1 + ($::prev ? $::prev->{xref} : 0);
	for ($s=1; $s<=$e->[6]; $s++) {

	      # If there was a sense number given in the xresolv 
	      # record (field "tsens") then step through the
	      # senses until we get to that one and generate
	      # an xref only for it.  If there is no tsens, 
	      # generate an xref for every sense.
	    next if ($v->{tsens} && $v->{tsens} != $s);

	      # The db xref records use column "xref" as a order
	      # number and to distinguish between multiple xrefs
	      # in the same entr/sens.  We use $cntr to maintain
	      # its value, and it is reset to 1 here whenever we
	      # see an xref record with a new entr or sens value.
	    if (!$::prev or $::prev->{entr} != $v->{entr} 
			 or $::prev->{sens} != $v->{sens}) { $cntr = 1; }
	    $xref = {entr=>$v->{entr}, sens=>$v->{sens}, xref=>$cntr, typ=>$v->{typ}, 
		     xentr=>$e->[0], xsens=>$s, rdng=>$e->[2], kanj=>$e->[3] };
	    $cntr++;  $::prev = $xref;
	    push (@xrefs, $xref); }

	if (!@xrefs) {
	    if ($v->{tsens}) { msg (fs($v), "Sense not found", kr($v)); }
	    else { die "No senses in retrieved entry!\n"; } }

	return \@xrefs; }

    sub read_krmap { my ($dbh, $infn, $targ_src) = @_;
	my ($seq, $rtxt, $ktxt, $rs, %krmap, $entrs);

	return undef if !$infn;
	open (FIN, "<:utf8", $infn) || die "Can't open $infn: $!\n";

	while (<FIN>) {
	    if ($. == 1 and (substr ($_, 0, 1) eq "\x{FEFF}")) {
		$_ = substr ($_, 1); }
	    next if (m/^\s*$/ or m/^\s*\#/);  # Skip blank lines and comments.
	    ($rtxt, $ktxt, $seq) = split (/\t/, $_, 3);
	    if (!m/^(\d+)$/) { die "Bad seq# at line $. in $infn\n"; }
	    $seq = $1;
	    $entrs = get_entries ($dbh, $targ_src, $rtxt, $ktxt, $seq);
	    die "Entry $seq not found, or kana/kanji mismatch at line $. in $infn\n" if (!$entrs);
	    $krmap{$ktxt."_::_".$rtxt} = $entrs->[0]; }
	return \%krmap; }

    sub lookup_krmap { my ($krmap, $rtxt, $ktxt) = @_;
	my $key = ($ktxt||"") . "_::_" . ($rtxt||"");
	return $krmap->{$key}; }

    sub kr { my ($v) = @_;
	my $s = fmt_jitem ($v->{ktxt}, $v->{rtxt}, $v->{tsens}?[$v->{tsens}]:[]);
	$s; }

    sub fs { my ($v) = @_;
	my $s = "($v->{seq},$v->{sens},$v->{ord})";
	$s; }

    sub msg { my ($source, $msg, $arg) = @_;
	my ($sm, $tm);
	if (!$::Opts{q}) {
	    print STDERR "$source $msg: $arg\n"; } 
	if (!($sm = $::Msgs{$msg})) { $sm = $::Msgs{$msg} = {}; }
	if (!($tm = $sm->{$arg}))   { $tm = $sm->{$arg} = []; }
	push (@$tm, $source); }

    sub print_msg_summary {
	my ($msgs, $k, $t, $sm, $tm);
	$msgs = \%::Msgs;
	print STDOUT "Summary of unresolvable xrefs:\n----\n";
	foreach $k (sort (keys (%$msgs))) {
	    $sm = $msgs->{$k};
	    print STDOUT ucfirst ($k) . ":\n";
	    foreach $t (sort ( keys (%$sm))) {
		$tm = $sm->{$t};
		print "  $t (" . scalar(@$tm) . ")\n"; } } }


#-----------------------------------------------------------------------

sub usage { my ($exitstat) = @_;
	print <<EOT;

Usage: xresolv.pl [options] 

    Convert textual xrefs in table xresolv, to actual entr.id
    xrefs and write to table xrefs.

    Options:
	-n -- Resolve xrefs but don't write to database.
	-e encoding -- Encoding to use for stdout and stderr.
	 	Default is "utf-8".  Windows users running with 
		a Japanese locale may wish to use "cp932".
	-f filename -- Name of a file containing kanji/reading
		to seq# map. 
	-s n -- Limit to xrefs occuring in entries of corpus id  
		<n>.  Default = 1 (jmdict).
	-t n -- Limit to xrefs that resolve to targets in corpus
		<n>.  Default = 1 (jmdict).
	-v -- Print a message for every successfully resolved xref.
	-q -- Do not print a warning for each unresolvable xref.
	-D n -- Print debugging output to stderr.  The number 'n'
		controls what is printed.  See source code. 
	-d dbname -- Name of database to use.  Default is "jmdict".
	-r host	-- Name of machine hosting the database.  Default
		is "localhost".
	-h -- (help) print this text and exit.

	  ***WARNING***
	  The following two options are not recommended because 
	  their values will be visible to anyone who can run a 
	  \"ps\" command.

	-u username -- Username to use when connecting to database.
	        Default is "postgres".
	-p password -- Password to use when connecting to database.
	        No default.

This program creates rows in table "xref" based on the 
textual (kanji and kana) xref information saved in table
"xresolv" by the programs jmparse.pl and exparse.pl when
loading the database from a corpus file.

Each xresolv row contains the entr id and sens number 
of the entry that contained the xref, the type of xref,
and the xref target entry kanji and/or reading, and
optionally, sense number. 

This program searches for an entry matching the kanji
and reading and creates one or more xref records using
the target entry's id number.  The matching process is
more involved than doing a simple search because a kanji
xref may match several entries, and our job is to find 
the right one.  This is currently done by a fast but 
inaccurate method that does not take into account restr,
stagr, and stag restrictions which limit certain reading-
kanji combinations and thus would make unabiguous some
xrefs that this program considers ambiguous.  See the
comments in sub choose_entry() for a description of
the algorithm. 

When an xref text is not found, or multiple candidate
entries still exist after applying the selection
algorithm, the fact is reported unless the -q option
was given and that xref skipped.

Before the program exits, it prints a summary of all
unresolvable xrefs, grouped by reason and xref text.
Following the xref text, in parenthesis, is the number 
of xresolv xrefs that included that unresolvable text.
EOT
	exit $exitstat; }

	

	 