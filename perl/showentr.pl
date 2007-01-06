#!/usr/bin/env perl

# Copyright (c) 2006,2007 Stuart McGraw 
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

    binmode(STDOUT, ":utf8");

    main: {
	my ($dbh, $entries, $e, @qlist, @elist, @slist, 
	    @whr, $sql, $sens, $tmptbl, $dbname, $user, $pw);

	getopts ("hd:u:p:", \%::Opts);
	if ($::Opts{h}) { usage (0); }
	$user = $::Opts{u} || "postgres";
	$pw = $::Opts{p} || "";
	$dbname = $::Opts{db} || "jmdict";

	$dbh = DBI->connect("dbi:Pg:dbname=$dbname", "$user", "$pw", 
			{ PrintWarn=>0, RaiseError=>1, AutoCommit=>0 } );
	$dbh->{pg_enable_utf8} = 1;
	$::KW = Kwds ($dbh);

	foreach (@ARGV) {
	    if (m/^[0-9]/)  { push (@qlist, int ($_)); }
	    elsif (m/^q/i) { push (@qlist, int (substr ($_, 1))); }
	    elsif (m/^e/i) { push (@elist, int (substr ($_, 1))); }
	    elsif (m/^s/i) { push (@slist, int (substr ($_, 1))); }
	    else { print STDERR "Invalid argument skipped: $_" } }
	if (@qlist) { push (@whr, "e.seq IN (" . join(",",map('?',@qlist)) . ")"); }
	if (@elist) { push (@whr, "e.id  IN (" . join(",",map('?',@elist)) . ")"); }
	if (@slist) { push (@whr, "s.id  IN (" . join(",",map('?',@slist)) . ")"); }
	if (@slist) { $sens = "JOIN sens s ON s.entr=e.id"; }
	else { $sens = ""; }
	$sql = "SELECT e.id FROM entr e $sens WHERE " . join (" OR ", @whr);
	$tmptbl = Find ($dbh, $sql, [@qlist, @elist, @slist]);

	$entries = EntrList ($dbh, $tmptbl);
	foreach $e (@$entries) { p_entry ($e); }
	$dbh->disconnect(); }
	
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
	($txt .= "[" . join ("/", @f) . "]") if (@f);
	$txt .= "\{$k->{ord}/$k->{id}\}";
	return $txt; }

    sub f_rdng { my ($r, $kanj) = @_;
	my ($txt, @f, $restr, $klist);
	$txt = $r->{txt};  
	@f = map ($::KW->{FREQ}{$_->{kw}}{kw}."$_->{value}", @{$r->{_rfreq}});
	push (@f, map ($::KW->{KINF}{$_->{kw}}{kw}, @{$r->{_rinf}}));
	($txt .= "[" . join ("/", @f) . "]") if (@f);
	if ($kanj and ($restr = $r->{_restr})) {  # That's '=', not '=='.
	    if (scalar (@$restr) == scalar (@$kanj)) { $txt .= "\x{3010}no kanji\x{3011}"; }
	    else {
		$klist = filt ($kanj, $restr, 'kanj');
		$txt .= "\x{3010}" . join ("; ", map ($_->{txt}, @$klist)) . "\x{3011}"; } }
	$txt .= "\{$r->{ord}/$r->{id}\}";
	return $txt; }

    sub p_sens { my ($s, $n, $kanj, $rdng) = @_;
	my ($pos, $misc, $fld, $restrs, $g, @r, $stagr, $stagk);

	$pos = join (";", map ($::KW->{POS}{$_->{kw}}{kw}, @{$s->{_pos}}));
	if ($pos) { $pos = "[$pos]"; }
	$misc = join (";", map ($::KW->{MISC}{$_->{kw}}{kw}, @{$s->{_misc}}));
	if ($misc) { $misc = "[$misc]"; }
	$fld = join (";", map ($::KW->{FLD}{$_->{kw}}{kw}, @{$s->{_fld}}));
	if ($fld) { $fld = " $fld term"; }

	if ($kanj and ($stagk = $s->{_stagk})) { # That's '=', not '=='.
	    push (@r, @{filt ($kanj, $stagk, "kanj")}); }
	if ($rdng and ($stagr = $s->{_stagr})) { # That's '=', not '=='.
	    push (@r, @{filt ($rdng, $stagr, "rdng")}); }
	$restrs = @r ? "(" . join (", ", map ($_->{txt}, @r)) . " only) " : "";

	print "$n. $restrs$pos$misc$fld \{$s->{ord}/$s->{id}\}\n";
	if ($s->{notes}) { print "  $s->{notes}\n"; }
	foreach $g (@{$s->{_gloss}}) {
	    print "  " . $::KW->{LANG}{$g->{lang}}{kw} . ": $g->{txt} \{$g->{ord}/$g->{id}\}\n"; }
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
	    print "    $t: $x->{txt} (seq. $x->{seq})\n"; } }


sub usage { my ($exitstat) = @_;
	print <<EOT;

Usage: showentr.pl [['q']entry_seq] ['e'entry_id] ['s'sense_id]

Arguments:
	A list of entries to display:
	A number or number prefixed with the letter 'q' is interpreted
	  as an entry sequence number.
	A number prefexed with the letter 'e' is interpreted as an
	  entry id number.
	A number prefixed with the letter 's' is interpreted as a sense
	  id number and the entry containing that sense is displayed.

Options:
	-d -- Name of database to use.  Default is "jmdict".
	-u -- Username to use when connecting to database.
	        Default is "postgres".
	-p -- Password to use when connecting to database.
	        No default.
	-h -- (help) print this text and exit.

Currently all output is in utf-8 which and requires a display enviroment
the works with utf-8.  ln particular, output will not display correctly on 
Windows systems using cp932 default encoding.
EOT
	exit $exitstat; }

	

	 