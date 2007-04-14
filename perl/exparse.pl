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

# This program will read a JMdict.xml file and create
# an output file containing postgresql data COPY commands.
# The file can be loaded into a Postgresql jmdict database
# after subsequent processing with jmload.pl.

use strict;  use warnings;
use Encode; use DBI;
use Getopt::Std ('getopts');

BEGIN {push (@INC, "./lib");}
use jmdict;  use jmdictxml ('%EX2ID'); use jmdictpgi;

use Memoize;
memoize ('findentr');

%::Msgs = ();
$::Debug{prtsql} = 1;

main: {
	my ($dbh, $infn, $outfn, $enc, $user, $pw, $dbname, $host,
	    $begin, $count, $tmp);

	if (!getopts ("o:b:c:e:knvu:p:r:d:h", \%::Opts)) { usage (1); }
	if ($::Opts{h}) { usage (0); }

	  # Set some local variables based on the command line 
	  # options given or defaults where options not given.
	$outfn =  $::Opts{o} || "examples.pgi";
	$begin =  $::Opts{b} || 0;
	$count =  $::Opts{c} || 9999999;
	$enc =    $::Opts{e} || "utf-8";
	$user =   $::Opts{u} || "postgres";
	$pw =     $::Opts{p} || "";
	$dbname = $::Opts{d} || "jmdict";
	$host =   $::Opts{r} || "";

	binmode(STDOUT, ":encoding($enc)");
	binmode(STDERR, ":encoding($enc)");
	{no warnings;
	eval { binmode($DB::OUT, ":encoding($enc)"); }; }
	  # Make STDERR unbuffered so we print "."s, one at 
	  # a time, as a sort of progress bar.  
	$tmp = select(STDERR); $| = 1; select($tmp);

	($infn = shift (@ARGV)) || die ("No input filename given\n");

	if (!$::Opts{w}) {
	    if ($host) { $host = ";host=$host"; }
	    $dbh = DBI->connect("dbi:Pg:dbname=$dbname$host", $user, $pw, 
			{ PrintWarn=>0, RaiseError=>1, AutoCommit=>0 } ); 
	    $dbh->{pg_enable_utf8} = 1; }

	process ($dbh, $infn, $outfn, $begin, $count);
	msg_summary (\%::Msgs);
	if (!$::Opts{w}) { $dbh->disconnect(); } }
	
sub process { my ($dbh, $infn, $outfn, $begin, $count) = @_;
	my ($ln, $aln, $bln, $jtxt, $etxt, $kwds, $cntr, $idxlist, $entr, $tmpfiles, $eid); 
	open (FIN, "<:utf8", $infn) || die ("Can't open $infn: $!\n");
	if (!$::Opts{n}) { $tmpfiles = initialize (); }
	while ($aln = <FIN>) {
	    next if ($. < $begin);
	    if ($. == 1 and (substr ($aln, 0, 1) eq "\x{FEFF}")) {
		$aln = substr ($aln, 1); }
	    next if (substr ($aln, 0, 2) ne "A:");
	    $::Lnnum = $.; $bln = <FIN>;  ++$cntr;
	    $aln =~ s/[\r\n]+$//;  $bln =~ s/[\r\n]+$//;
	    ($jtxt, $etxt, $kwds) = eval { parsea ($aln); };
	    if ($@) { 
		chomp ($@); msg ($@); next; }
	    $idxlist = eval { parseb ($bln, $jtxt); };
	    if ($@) { 
		chomp ($@); msg ($@); next; }
	    if (!$::Opts{w}) {	# w--parse only option
		$entr = entrxref ($dbh, $jtxt, $etxt, $kwds, $::Lnnum, $idxlist);
		if (!$::Opts{n} && $entr) { setkeys ($entr, ++$eid); wrentr ($entr); } }
	    if (0 == $cntr % 2000) { print STDERR "."; }
	    last if ($cntr >= $count);}
	if ($cntr >= 2000) {print STDERR "\n"; }
	if (!$::Opts{n}) { finalize ($outfn, $tmpfiles, !$::Opts{k}); } }

sub entrxref { my ($dbh, $jtxt, $etxt, $kwds, $lnnum, $idxlist) = @_;
	# $idxlist data: [(ktxt,rtxt,sens,atxt),...]
	my ($xrefs, $entr, $src);
	$xrefs = resolve ($dbh, $idxlist);
	$xrefs = prunedups ($xrefs);
	if (scalar (@$xrefs) == 0) {
	    msg ("No indexable words, line skipped");  return undef;}
	$entr = mkentr ($jtxt, $etxt, $kwds, $lnnum, $xrefs);
	return $entr; } 

sub parsea { my ($aln) = @_;
	my ($j, $e, $ntxt, @ntxts, $nt, $kw, @kw);
	if (substr ($aln, 0, 1) eq "\x{feff}") { $aln = substr ($aln, 1); }  # Nuke MS BOM.
	die ("\"A\" line parse error\n") if (!($aln =~ m/^A:\s*(.+)\t(.+?)\s*(\[.+\]\s*)*$/)) ;
	($j, $e, $ntxt) = ($1, $2, $3);
	if ($ntxt) { 
	    $ntxt =~ y/]/[/; @ntxts = split ('\[', $ntxt); shift (@ntxts);  
	    foreach $nt (@ntxts) {
		next if ($nt =~ m/^\s*$/o);
		($kw = $jmdictxml::EX2ID{lc($nt)}) || die ("Unexpected note text '$nt'\n");
		push (@kw, $kw); } }
	return $j,$e,\@kw; }

sub parseb { my ($bln, $jtxt) = @_;
	my (@parts, $x, $n, @res);
	@parts = split (/[ ]+/, $bln);
	die ("Expected \"B\" line, got '$bln'\n") if (shift(@parts) ne "B:");
	foreach $x (@parts) {
	    next if ($x =~ m/^\s*$/);
	    push (@res, bpart ($x, ++$n, $jtxt)); } 
	return \@res; }

sub bpart { my ($s, $n, $jtxt) = @_;
	my ($ktxt, $rtxt, $sens, $atxt, @sens);
	die ("\"B\" line parse error in item $n: '$s'\n")
	    if (!($s =~ m/^([^([{]+)(\((\S+)\))?(\[\d+\])*(\{(\S+)\})?\s*$/));
	($ktxt,$rtxt,$sens,$atxt) = ($1, $3, $4, $6);
	die ("($rtxt) not kana in item $n\n") if ($rtxt && !kana_only ($rtxt));
	if ($ktxt eq "\x{306F}") { return (); } # Special case particle "wa (ha)".
	if (kana_only ($ktxt)) {
	    die ("Double kana in item $n: '$ktxt', '$rtxt'\n") if ($rtxt);
	    $rtxt = $ktxt;  $ktxt = undef; }
	if ($sens) { @sens = grep (length ($_)>0, split (/[\[\]]+/, $sens)); }
	die ("\{$atxt\} not in A line in item $n\n") if ($atxt && index ($jtxt, $atxt) < 0);
	return [$ktxt,$rtxt,\@sens,$atxt]; }

sub resolve { my ($dbh, $idxlist) = @_;
	my ($idx, $ktxt, $rtxt, $sens, $atxt, $targs, @teids, $teid, 
	    $tsens, @xrefs, $xr, $etxt);
	foreach $idx (@$idxlist) {
	    ($ktxt, $rtxt, $sens, $atxt) = @$idx;
	    $targs = findentr ($dbh, $ktxt, $rtxt);
	    @teids = keys(%$targs);  
	    $etxt = hw ($ktxt, $rtxt);
	    if (scalar(@teids) == 0) {
		msg ("Warning: Unresolved: $etxt"); next; }
	    if (scalar(@teids) > 1) {
		msg ("Warning: Multipliy resolved: $etxt"); next; }
	    $teid = $teids[0]; $tsens = $targs->{$teid};
	    
	    $xr = mkxrefs ($teid, $tsens, $sens, $atxt, $etxt);
	    push (@xrefs, @$xr); }
	return \@xrefs; }

sub mkxrefs { my ($teid, $tsens, $sens, $atxt, $etxt) = @_;
	# Generate xref structs to senses @sens in target entry $teid.
	#   $teid -- Entry id of target entry.
	#   $tsens -- List of sense numbers in target entry.
	#   $sens -- List if sensee numbers to generate xrefs to,
	#       If false, generate to all target senses.
	#   $atxt -- Xref note text.
	#   $etxt -- Text stringt for use in warning message to
	#       identify target entry.

	my ($s, $ts, $found, @xrefs);
	foreach $s (@$sens) {
	    $found = 0; 
	    foreach $ts (@$tsens) {
		next if ($ts != $s);
		push (@xrefs, {entr=>0, sens=>0, xentr=>$teid, xsens=>$ts, typ=>5, notes=>$atxt}); 
		$found = 1; last; }
	    if (!$found) { 
		msg ("no Sense $s in $etxt"); } }
	if (!@$sens) {
	    foreach $ts (@$tsens) {
	        push (@xrefs, {entr=>0, sens=>0, xentr=>$teid, xsens=>$ts, typ=>5, notes=>$atxt}); } }
	return \@xrefs; }

sub hw { my ($ktxt, $rtxt) = @_;
	if ($ktxt && $rtxt) { return "$ktxt($rtxt)"; }
	return $ktxt || $rtxt; }

sub findentr { my ($dbh, $ktxt, $rtxt) = @_;
	my (@f, @w, @a, $fs, $ws, $sth, $sql, $rs, $r, %eids);
	die ("both args are zilch") if (!$ktxt and !$rtxt);
	if ($ktxt && $rtxt) {
	    $fs = "JOIN kanj k ON k.entr=e.id JOIN rdng r ON r.entr=e.id";
	    $ws = "k.txt=? AND r.txt=?";  @a = ($ktxt, $rtxt); }
	elsif ($ktxt) {
	    $fs = "JOIN kanj k ON k.entr=e.id";
	    $ws = "k.txt=?";  @a = ($ktxt); }
	elsif ($rtxt) {
	    $fs = "JOIN rdng r ON r.entr=e.id LEFT JOIN kanj k ON k.entr=e.id ";
	    $ws = "r.txt=? AND k.txt IS NULL";  @a = ($rtxt); }
	$sql = "SELECT id,sens FROM entr e JOIN sens s ON s.entr=e.id $fs WHERE src=1 AND $ws";
	$sth = $dbh->prepare_cached ($sql);
	$sth->execute (@a);
	$rs = $sth->fetchall_arrayref();
	foreach $r (@$rs) { 
	    # Build hash id eid's with values being list of 
	    # sense numbers in that id.
	    if (!$eids{$r->[0]}) { $eids{$r->[0]} = [$r->[1]]; }
	    else { push (@{$eids{$r->[0]}}, $r->[1]); } }
	return \%eids; }

sub mkentr { my ($jtxt, $etxt, $kwds, $lnnum, $xrefs) = @_;
	my ($e, @kws, $snote);
	$e = {src=>3, stat=>2, seq=>$lnnum};
	if (@$kwds) {
	    # Each @$kwds item is a 2-array consisting of the kw
	    # id number and optionally a note string.
	    @kws = map ($_->[0], @$kwds);
	    {no warnings qw(uninitialized);
	    $snote = join ("; ", map ($_->[1], @$kwds)) || undef; } }
	$e->{_kanj} = [{txt=>$jtxt}];
	$e->{_sens} = [{_gloss=>[{lang=>1, txt=>$etxt}],
		        _misc=>[map ({kw=>$_}, @kws)],
			notes=>$snote,},];
	     $e->{_sens}[0]{_xref} = $xrefs;
	return $e; }

sub prunedups { my ($xrefs) = @_;
	# Eliminate any duplicate (i.e., with the same pk) xrefs.
 	my (%hash, $x, $pk, @res);
	foreach $x (@$xrefs) {
	    $pk = "$x->{entr}_$x->{sens}_$x->{xentr}_$x->{xsens}_$x->{typ}";
	    if (!$hash{$pk}) { push (@res, $x); $hash{$pk} = 1; } }
	return \@res; }

sub kana_only { my ($txt) = @_; 
	my $v = jstr_classify ($txt);
	return ($v & $jmdict::KANA) && !($v & $jmdict::KANJI); }

sub msg { my ($msg) = @_;
	if ($::Opts{v}) { print STDERR "$::Lnnum: $msg\n"; }
	if (!($::Msgs{$msg})) { $::Msgs{$msg} = [$::Lnnum]; }
	else { push (@{$::Msgs{$msg}}, $::Lnnum); } }

sub msg_summary { my ($msgs) = @_;
	my ($k, $n, $s);
	foreach $k (sort (keys (%$msgs))) {
	    $n = scalar (@{$msgs->{$k}});
	    $s = join(", ", @{$msgs->{$k}});
	    print "\n$k\n$s\n"; } }


sub usage { my ($exitstat) = @_;
	print <<EOT;

Usage: exload.pl [options] filename

Arguments:
	filename -- Name of examples file.

Options:
	-o filename -- Name of output file.  Default is 
	    examples.pgi.
	-b number -- Starting line number in examples file.  
	    Processing will start at the first "A" line at of
	    after this.
	-c number -- Maximum number of example pairs to process.
	-n -- Parse only, no database access used: do not resolve
	    index words from it.
	-v -- Verbose.  Print messages to stderr as irregularies 
	    are encountered.  With or without this option, the
	    program will print a full accounting of irregularies
	    (in a more convenient form) to stdout before it exits.
	-e encoding -- Encoding to use for stdout and stderr.
	    Default is "utf-8".  Windows users running with 
	    a Japanese locale may wish to use "cp932".
	-k (keep) Do not delete intermediate files when done.
	-h -- (help) print this text and exit.

	The following options say what database to connect to and 
	how to connect.

	-d dbname -- Name of database to use.  Default is "jmdict".
	-r host	-- Name of machine hosting the database.  Default
	    is "localhost".

	***WARNING***
	The following two options are not recommended when running 
	on a multi-user machine since their values will be visible
	to anyone who can run a \"ps\" command.

	-u username -- Username to use when connecting to database.
	    Default is "postgres".
	-p password -- Password to use when connecting to database.
	    No default.
EOT
	exit $exitstat; }
