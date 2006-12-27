# This file contains non-ascii utf-8 characters.

# Copyright (c) 2006, Stuart McGraw 
@VERSION = (substr('$Revision$',11,-2), \
	    substr('$Date$',7,-11));

# to do:
# Add xref, ant
# temp table very slow, use only for sense?
# fix encoding issues on windows.

use strict;
use Encode;  use utf8;
use Getopt::Std ('getopts');
use DBI;
use jmdict;

    binmode(STDOUT, ":utf8");

    main: {
	my ($dbh, $entries, $e, @qlist, @elist, @slist, 
	    @whr, $sql, $sens, $tmptbl, $dbname, $user, $pw);

	getopts ("hd:u:p:", \%::Opts);
	if ($::Opts{h}) { usage (0); }
	$user = $::Opts{u} || "postgres";
	$pw = $::Opts{p};
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
	if (@qlist) { push (@whr, "e.seq IN (" . '?' x length(@qlist) . ")"); }
	if (@elist) { push (@whr, "e.id IN (" . '?' x length(@elist) . ")"); }
	if (@slist) { push (@whr, "s.id IN (" . '?' x length(@slist) . ")"); }
	if (@slist) { $sens = "JOIN sens s ON s.entr=e.id"; }
	$sql = "SELECT e.id FROM entr e $sens WHERE " . join (" OR ", @whr);
	$tmptbl = Find ($dbh, $sql, [@qlist, @elist, @slist]);

	$entries = EntrList ($dbh, $tmptbl);
	foreach $e (@$entries) { p_entry ($e); }
	$dbh->disconnect(); }
	
    sub p_entry { my ($e) = @_;
	my (@x, $x, $s, $n);
	print "\nEntry $e->{seq} \{$e->{id}\}";
	print ", dialect: $e->{_dial}" if ($e->{_dial});
	print ", origin lang: $e->{_lang}" if ($e->{_lang}) ;
	print "\n";
	print "  Notes: $e->{_notes}\n" if ($e->{_notes}) ;
	@x = map (f_kanj($_), @{$e->{_kanj}});
	if (@x) { print ("Kanji: " . join ("; ", @x) . "\n"); }
	@x = map (f_rdng($_, $e->{_kanj}), @{$e->{_rdng}});
	if (@x) { print ("Readings: " . join ("; ", @x) . "\n"); }
	foreach $s (@{$e->{_sens}}) {
	    $n += 1;
	    p_sens ($s, $n); }
	@x = grep ($_->{_audi}, @{$e->{_rdng}});
	if (@x) { p_audio (\@x); }
	if ($e->{_hist}) { p_hist ($e->{_hist}); }
	}

    sub f_kanj { my ($k) = @_;
	my ($txt, @f);
	$txt = $k->{txt};  
	@f = map ($::KW->{iFREQ}{$_->{kw}}{kw}."$_->{value}", @{$k->{_kfrq}});
	push (@f, map ($::KW->{iKINF}{$_->{kw}}{kw}, @{$k->{_kinf}}));
	($txt .= "[" . join ("/", @f) . "]") if (@f);
	$txt .= "\{$k->{ord}/$k->{id}\}";
	return $txt; }

    sub f_rdng { my ($r, $kanj) = @_;
	my ($txt, @f, $restr, $klist);
	$txt = $r->{txt};  
	@f = map ($::KW->{iFREQ}{$_->{kw}}{kw}."$_->{value}", @{$r->{_kfrq}});
	push (@f, map ($::KW->{iKINF}{$_->{kw}}{kw}, @{$r->{_rinf}}));
	($txt .= "[" . join ("/", @f) . "]") if (@f);
	if ($kanj and ($restr = $r->{_restr})) {  # That's '=', not '=='.
	    if (scalar (@$restr) == scalar (@$kanj)) { $txt .= "【no kanji】"; }
	    else {
		$klist = filt ($kanj, $restr, 'kanj');
		$txt .= "【" . join ("; ", map ($_->{txt}, @$klist)) . "】"; } }
	$txt .= "\{$r->{ord}/$r->{id}\}";
	return $txt; }

    sub filt { my ($targ, $restr, $attrnm) = @_;
	my ($t, $r, @results, $found);
	foreach $t (@$targ) {
	    $found = 0;
	    foreach $r (@$restr) {
		if ($t->{id} == $r->{$attrnm}) {
		    $found = 1;
		    last; } }
	    push (@results, $t) if (!$found); }
	return \@results; }

    sub p_sens { my ($s, $n, $kanj, $rdng) = @_;
	my ($pos, $misc, $fld, $restrs, $g, @r, $stagr, $stagk);
	$pos = join (";", map ($::KW->{iPOS}{$_->{kw}}{kw}, @{$s->{_pos}}));
	if ($pos) { $pos = "[$pos]"; }
	$misc = join (";", map ($::KW->{iMISC}{$_->{kw}}{kw}, @{$s->{_misc}}));
	if ($misc) { $misc = "[$misc]"; }
	$fld = join (";", map ($::KW->{iFLD}{$_->{kw}}{kw}, @{$s->{_fld}}));
	if ($fld) { $fld = " $fld term"; }

	if ($kanj and ($stagk = $s->{stagk})) {	# That's '=', not '=='.
	    push (@r, filt ($kanj, $stagk, "kanj")); }
	if ($rdng and ($stagr = $s->{stagr})) {	# That's '=', not '=='.
	    push (@r, filt ($rdng, $stagr, "rdng")); }
	if (@r) {
	    $restrs = " (" . join (", ", map ($_->{txt}, @r)) . " only)"; }

	print "$n. $pos$misc$fld$restrs \{$s->{ord}/$s->{id}\}\n";
	if ($s->{notes}) { print "  $s->{notes}\n"; }
	foreach $g (@{$s->{_glos}}) {
	    print "  " . $::KW->{iLANG}{$g->{lang}}{kw} . ": $g->{txt} \{$g->{ord}/$g->{id}\}\n"; }
	p_xref ($s->{_xref}); 
}
	

    sub p_audio { my ($rdngs) = @_;
	my ($r, $a, $rtxt, $audio);
	print "Audio:\n";
	foreach $r (@$rdngs) {
	    next if (!($audio = $r->{_audi}));
	    $rtxt = "  " . $r->{txt} . ":";
	    foreach $a (@$audio) {
		print "$rtxt $a->{fname} $a->{strt}/$a->{leng} \{$a->{id}\}\n";
		$rtxt = "    "; } } }

    sub p_hist { my ($hists) = @_;
	my ($h, $n);
	print "History:\n";
	foreach $h (@$hists) {
	    print "  $h->{stat} $h->{dt} $h->{who} \{$h->{id}\}\n";
	    if ($n = $a->{notes}) { # That's an '=', not '=='.
		$n =~ s/(\n.)/    \1/;
		print "    $n\n"; } } }

    sub p_xref { my ($xrefs) = @_;
	my ($x, $t, $sep_done);
	foreach $x (@$xrefs) {
	    #if (!$sep_done) { print "  --\n";  $sep_done = 1; }
	    $t = ucfirst ($::KW->{iXREF}{$x->{typ}}{descr});
	    print "  $t: $x->{txt} (seq. $x->{seq})\n"; } }


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

	

	 