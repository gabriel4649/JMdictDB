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

# This program will read an Examples file and create
# an output file containing postgresql data COPY commands.
# The file can be loaded into a Postgresql jmdict database
# after subsequent processing with jmload.pl.
#
# The Example file "A" lines create database entries with 
# a entr.src=3 which identifies them as from the Examples
# files.  These entries will have an single kanji, single
# sense, and single gloss.  They may have a misc tag and 
# sense note if there was a parsable "[...]" comment on the
# line.
#
# "B" line items create database xref table rows.  However,
# like jmparse, we do not create the xrefs directly from 
# within this program, but instead write pseudo-xref records
# that contain the target reading and kanji text, to the 
# xrslv table, and generate the resolved xrefs later by
# running insert queries based on joins of xrslv and the
# jmdict entries.  All the pseudo-xref genereated by this
# program will have a typ=6.

use strict;  use warnings;
use Encode; 
use Getopt::Std ('getopts');

BEGIN {push (@INC, "./lib");}
use jmdict;  use jmdictxml ('%EX2ID'); use jmdictpgi; use kwstatic;

%::Msgs = ();
$::Debug{prtsql} = 1;

main: {
	my ($infn, $outfn, $enc, $begin, $count, $tmp);

	if (!getopts ("o:b:c:e:knvh", \%::Opts)) { usage (1); }
	if ($::Opts{h}) { usage (0); }

	  # Set some local variables based on the command line 
	  # options given or defaults where options not given.
	$outfn =  $::Opts{o} || "examples.pgi";
	$begin =  $::Opts{b} || 0;
	$count =  $::Opts{c} || 9999999;
	$enc =    $::Opts{e} || "utf-8";

	binmode(STDOUT, ":encoding($enc)");
	binmode(STDERR, ":encoding($enc)");
	{no warnings;
	eval { binmode($DB::OUT, ":encoding($enc)"); }; }
	  # Make STDERR unbuffered so we print "."s, one at 
	  # a time, as a sort of progress bar.  
	$tmp = select(STDERR); $| = 1; select($tmp);

	($infn = shift (@ARGV)) || die ("No input filename given\n");

	process ($infn, $outfn, $begin, $count);
	msg_summary (\%::Msgs); }

sub process { my ($infn, $outfn, $begin, $count) = @_;

	# Process the Examples file.  
	# $infn -- Name of ther input Examples file.
	# $outfn -- Name of the output .pgi file.
	# $begin -- Line number at which to begin processing.  Everythig
	#    before that is sskipped.
	# Number of example pairs to process.  Program will terminate
	#    after this many have been done.

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
	    if ($@) { chomp ($@); msg ($@); next; }
	    $idxlist = eval { parseb ($bln, $jtxt); };
	    if ($@) { chomp ($@); msg ($@); next; }
	    $entr = mkentr ($jtxt, $etxt, $kwds, $::Lnnum);
	    $entr->{_sens}[0]{_xrslv} = mkxrslv ($idxlist);
	    if (!$::Opts{w}) {	# w--parse only option
		setkeys ($entr, ++$eid); 
		wrentr ($entr); } 
	    if (0 == $cntr % 2000) { print STDERR "."; }
	    last if ($cntr >= $count); }
	if ($cntr >= 2000) { print STDERR "\n"; }
	if (!$::Opts{n}) { finalize ($outfn, $tmpfiles, !$::Opts{k}); } }

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
	    push (@res, parsebitem ($x, ++$n, $jtxt)); } 
	return \@res; }

sub parsebitem { my ($s, $n, $jtxt) = @_;
	my ($ktxt, $rtxt, $sens, $atxt, @sens, $prio);
	die ("\"B\" line parse error in item $n: '$s'\n")
	    if (!($s =~ m/^([^([{]+)(\((\S+)\))?(\[\d+\])*(\{(\S+)\})?(\x{203e})?\s*$/));
	($ktxt,$rtxt,$sens,$atxt,$prio) = ($1, $3, $4, $6, $7);
	die ("($rtxt) not kana in item $n\n") if ($rtxt && !kana_only ($rtxt));
	if (kana_only ($ktxt)) {
	    die ("Double kana in item $n: '$ktxt', '$rtxt'\n") if ($rtxt);
	    $rtxt = $ktxt;  $ktxt = undef; }
	if ($sens) { @sens = grep (length ($_)>0, split (/[\[\]]+/, $sens)); }
	die ("\{$atxt\} not in A line in item $n\n") if ($atxt && index ($jtxt, $atxt) < 0);
	return [$ktxt,$rtxt,\@sens,$atxt,$prio?1:0]; }

sub hw { my ($ktxt, $rtxt) = @_;
	if ($ktxt && $rtxt) { return "$ktxt($rtxt)"; }
	return $ktxt || $rtxt; }

sub mkentr { my ($jtxt, $etxt, $kwds, $lnnum) = @_;
	# Create an entry object to represent the "A" line text of the 
	# example sentence.
	my ($e, @kws, $snote);
	$e = {src=>$KWSRC_examples, stat=>$KWSTAT_A, seq=>$lnnum};
	if (@$kwds) {
	    # Each @$kwds item is a 2-array consisting of the kw
	    # id number and optionally a note string.
	    @kws = map ($_->[0], @$kwds);
	    {no warnings qw(uninitialized);
	    $snote = join ("; ", map ($_->[1], @$kwds)) || undef; } }
	$e->{_kanj} = [{txt=>$jtxt}];
	$e->{_sens} = [{_gloss=>[{lang=>$KWLANG_en, ginf=>$KWGINF_equ, txt=>$etxt}],
		        _misc=>[map ({kw=>$_}, @kws)],
			notes=>$snote,},];
	return $e; }

sub mkxrslv { my ($idxlist) = @_;
	# Convert the $@indexlist that was created by bparse() into a 
	# list of database xrslv table records.  The fk fields "entr"
	# and "sens" are not set in the xrslv records; they are set
	# by setids() just prior to writing to the database.

	my ($x, @r, $s, $ktxt, $rtxt, $senslst, $note, $prio);
	foreach $x (@$idxlist) {
	    ($ktxt, $rtxt, $senslst, $note, $prio) = @$x;
	    if (@$senslst) {
		# A list of explicit sens were give in the B line, 
		# create an xrslv record for each.
		foreach $s (@$senslst) {
	    	    push (@r, {ktxt=>$ktxt, rtxt=>$rtxt, tsens=>$s,
				typ=>$KWXREF_uses, notes=>$note, prio=>$prio}); } }
	    else {
		# This is not list of senses so this cross-ref will 
		# apply to all the target's senses.  Don't set a "sens"
		# field in the xrslv record will will result in a NULL
		# in the database record.
		push (@r, {ktxt=>$ktxt, rtxt=>$rtxt, 
			    typ=>$KWXREF_uses, notes=>$note, prio=>$prio}); } }
	return \@r; }

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

EOT
	exit $exitstat; }
