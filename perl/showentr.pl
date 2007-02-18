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
use jmdict;  

    main: {
	my ($dbh, $entries, $e, @qlist, @elist, $enc, $host,
	    $dbname, $user, $pw);

	if (!getopts ("hd:u:p:r:e:", \%::Opts) or $::Opts{h}) { usage (0); }
	$enc =    $::Opts{e} || "utf8";
	$user =   $::Opts{u} || "postgres";
	$pw =     $::Opts{p} || "";
	$dbname = $::Opts{d} || "jmdict";
	$host =   $::Opts{r} || "";

	my $oldfh = select(STDERR); $| = 1; select($oldfh);
	binmode(STDOUT, ":encoding($enc)");
	binmode(STDERR, ":encoding($enc)");
	eval { binmode($DB::OUT, ":encoding($enc)"); }; $dbh=$DB::OUT;

	if ($host) { $host = ";host=$host"; }
	$dbh = DBI->connect("dbi:Pg:dbname=$dbname$host", $user, $pw, 
			{ PrintWarn=>0, RaiseError=>1, AutoCommit=>0 } );
	$dbh->{pg_enable_utf8} = 1;
	$::KW = Kwds ($dbh);

	foreach (@ARGV) {
	    if (m/^[0-9]/)  { push (@qlist, int ($_)); }
	    elsif (m/^q/i) { push (@qlist, int (substr ($_, 1))); }
	    elsif (m/^e/i) { push (@elist, int (substr ($_, 1))); }
	    else { print STDERR "Invalid argument skipped: $_" } }
	$entries = get_entries ($dbh, \@elist, \@qlist);
	foreach $e (@$entries) { p_entry ($e); }
	$dbh->disconnect(); }

    sub get_entries { my ($dbh, $elist, $qlist) = @_;
	my (@whr, $sql, $tmptbl, $entries);
	if (@$qlist) { push (@whr, "e.seq IN (" . join(",",map('?',@$qlist)) . ")"); }
	if (@$elist) { push (@whr, "e.id  IN (" . join(",",map('?',@$elist)) . ")"); }
	$sql = "SELECT e.id FROM entr e WHERE " . join (" OR ", @whr);
	$tmptbl = Find ($dbh, $sql, [@$qlist, @$elist]);
	$entries = EntrList ($dbh, $tmptbl);
	return $entries; }
	
    sub p_entry { my ($e) = @_;
	my (@x, $x, $s, $n, $stat);
	$stat = $::KW->{STAT}{$e->{stat}}{kw};
	print "\nEntry $e->{seq} [$stat] \{$e->{id}\}";
	print ", Dialect: "     . join(",", 
		map ($::KW->{DIAL}{$_->{kw}}{kw}, @{$e->{_dial}})) if ($e->{_dial});
	print ", Origin lang: " . join(",", 
		map ($::KW->{LANG}{$_->{kw}}{kw}, @{$e->{_lang}})) if ($e->{_lang}) ;
	print "\n";
	print "  Notes: $e->{_notes}\n" if ($e->{_notes}) ;
	@x = map (f_kanj($_), @{$e->{_kanj}});
	if (@x) { print ("Kanji: " . join ("; ", @x) . "\n"); }
	@x = map (f_rdng($_, $e->{_kanj}), @{$e->{_rdng}});
	if (@x) { print ("Readings: " . join ("; ", @x) . "\n"); }
	foreach $s (@{$e->{_sens}}) {
	    $n += 1;
	    p_sens ($s, $n, $e->{_kanj}, $e->{_rdng}); }
	@x = grep ($_->{_audio}, @{$e->{_rdng}});
	if (@x) { p_audio (\@x); }
	if ($e->{_hist}) { p_hist ($e->{_hist}); }
	}

    sub f_kanj { my ($k) = @_;
	my ($txt, @f);
	$txt = $k->{txt};  
	@f = map ($::KW->{FREQ}{$_->{kw}}{kw}."$_->{value}", @{$k->{_kfreq}});
	push (@f, map ($::KW->{KINF}{$_->{kw}}{kw}, @{$k->{_kinf}}));
	($txt .= "[" . join (",", @f) . "]") if (@f);
	$txt = "$k->{kanj}.$txt";
	return $txt; }

    sub f_rdng { my ($r, $kanj) = @_;
	my ($txt, @f, $restr, $klist);
	$txt = $r->{txt};  
	@f = map ($::KW->{FREQ}{$_->{kw}}{kw}."$_->{value}", @{$r->{_rfreq}});
	push (@f, map ($::KW->{KINF}{$_->{kw}}{kw}, @{$r->{_rinf}}));
	($txt .= "[" . join (",", @f) . "]") if (@f);
	if ($kanj and ($restr = $r->{_restr})) {  # That's '=', not '=='.
	    if (scalar (@$restr) == scalar (@$kanj)) { $txt .= "\x{3010}no kanji\x{3011}"; }
	    else {
		$klist = filt ($kanj, ["kanj"], $restr, ["kanj"]);
		$txt .= "\x{3010}" . join ("; ", map ($_->{txt}, @$klist)) . "\x{3011}"; } }
	$txt = "$r->{rdng}.$txt";
	return $txt; }

    sub p_sens { my ($s, $n, $kanj, $rdng) = @_;
	my ($pos, $misc, $fld, $restrs, $lang, $g, @r, $stagr, $stagk);

	$pos = join (",", map ($::KW->{POS}{$_->{kw}}{kw}, @{$s->{_pos}}));
	if ($pos) { $pos = "[$pos]"; }
	$misc = join (",", map ($::KW->{MISC}{$_->{kw}}{kw}, @{$s->{_misc}}));
	if ($misc) { $misc = "[$misc]"; }
	$fld = join (",", map ($::KW->{FLD}{$_->{kw}}{kw}, @{$s->{_fld}}));
	if ($fld) { $fld = " $fld term"; }

	if ($kanj and ($stagk = $s->{_stagk})) { # That's '=', not '=='.
	    push (@r, @{filt ($kanj, ["kanj"], $stagk, ["kanj"])}); }
	if ($rdng and ($stagr = $s->{_stagr})) { # That's '=', not '=='.
	    push (@r, @{filt ($rdng, ["rdng"], $stagr, ["rdng"])}); }
	$restrs = @r ? "(" . join (", ", map ($_->{txt}, @r)) . " only) " : "";

	print "$s->{sens}. $restrs$pos$misc$fld\n";
	if ($s->{notes}) { print "  $s->{notes}\n"; }
	foreach $g (@{$s->{_gloss}}) {
	    if ($g->{lang} == 1) { $lang = "" }
	    else { $lang = "(" . $::KW->{LANG}{$g->{lang}}{kw} . ") "; }
	    print "  $g->{gloss}. $lang$g->{txt}\n"; }
	p_xref ($s->{_xref}, "Cross references:"); 
	p_xref ($s->{_xrer}, "Reverse references:"); }

    sub p_audio { my ($rdngs) = @_;
	my ($r, $a, $rtxt, $audio);
	print "Audio:\n";
	foreach $r (@$rdngs) {
	    next if (!($audio = $r->{_audio}));
	    $rtxt = "  " . $r->{txt} . ":";
	    foreach $a (@$audio) {
		print "$rtxt $a->{fname} $a->{strt}/$a->{leng} \{$a->{id}\}\n";
		$rtxt = "    "; } } }

    sub p_hist { my ($hists) = @_;
	my ($h, $n);
	print "History:\n";
	foreach $h (@$hists) {
	    print "  $h->{stat} $h->{dt} $h->{who} \{$h->{id}\}\n";
	    if ($n = $h->{notes}) { # That's an '=', not '=='.
		$n =~ s/(\n.)/    $1/;
		print "    $n\n"; } } }

    sub p_xref { my ($xrefs, $sep) = @_;
	my ($x, $t, $sep_done);
	foreach $x (@$xrefs) {
	    if (!$sep_done) { print "  $sep\n";  $sep_done = 1; }
	    $t = $::KW->{XREF}{$x->{typ}}{descr};
	    print "    $t: $x->{seq} " . fmtkr ($x->{kanj}, $x->{rdng}) . "\n"; } }


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

	

	 