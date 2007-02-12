#!/usr/bin/env perl

# This program will read a JMdict.xml file and create
# an output file containing postgresql data load commands
# that will, when executes, load the JMdict data into an
# appropriately configured Postgresql database.
#
# Special handling: 
# - propagate PoS through senses.
# - do xrefs/ants in 2nd pass
# - ke_pri, re_pri: ignore (redundant) newsX values.
# - record only 1 nfXX when multiple values present. (niy)

# Copyright (c) 2006,2007 Stuart McGraw 
@VERSION = (substr('$Revision$',11,-2), \
	    substr('$Date$',7,-11));

# To do:
# Add command line option to give a directory for the
#   temporary files.
# Better performance if we use SAX instead of XML::Twig?
# shift_jis output encoding on windows doesn't really
#   work -- get unmappable utf8 characters in gloss which
#   cause fatal error.  Should non-fatally map to a printable
#   hex format or "?" or something.

use XML::Twig;
use Encode;
use Getopt::Std ('getopts');
use strict;

BEGIN {push (@INC, "./lib");}
use jmdictxml ('%JM2ID');

main: {
	my ($twig, $infn, $outfn, $tmpfiles, $tmp, $enc);

	getopts ("o:c:s:e:kh", \%::Opts);
	if ($::Opts{h}) { usage (0); }
	$enc = $::Opts{e} || "utf-8";
	binmode(STDOUT, ":encoding($enc)");
	binmode(STDERR, ":encoding($enc)");
	eval { binmode($DB::OUT, ":encoding($enc)"); };

	$infn = shift (@ARGV) || "JMdict";
	$outfn = $::Opts{o} || "JMdict.dmp";

	  # Make STDERR unbuffered so we print "."s, one at 
	  # a time, as a sort of progress bar.  
	$tmp = select(STDERR); $| = 1; select($tmp);

	  # Create an XML parser instance.  'twig_roots' is
	  # a hash whose keys (one) name the elements to be 
	  # parsed, and value(s) give the name of a subroutine
	  # to be called to process the parsed element. 
	$twig = XML::Twig->new (twig_handlers => { 
				    entry=>\&entry_handler,
				   '#COMMENT'=>\&comment_handler}, 
				comments=>'process');

	  # Initialize global variables and open all the 
	  # temporary table files. 
	$tmpfiles = initialize ();

	  # Parse the give xml file.  The entry_ele sub given 
	  # when the $twig was created does all the work of
	  # writing the parsed data to the tables files.
	print STDERR "Parsing xml file $infn\n";
	eval { $twig->parsefile( $infn ); };
	die if ($@ and $@ ne "done\n"); 
	print STDERR "\n";

	  # Now merge all the temp table files into one big 
	  # dump file that can be fed to Postgresql.
	print STDERR "Generating output file $outfn\n";
	finalize ($outfn, $tmpfiles, !$::Opts{k}); 
	print STDERR ("Done\n"); }

sub initialize {
	my ($t);
	my @tmpfiles = (
	  [\$::Fentr, "load01.tmp", "COPY entr(id,src,seq,stat,notes) FROM stdin;"],
	  [\$::Fkanj, "load02.tmp", "COPY kanj(entr,kanj,txt) FROM stdin;"],
	  [\$::Fkinf, "load03.tmp", "COPY kinf(entr,kanj,kw) FROM stdin;"],
	  [\$::Fkfrq, "load04.tmp", "COPY kfreq(entr,kanj,kw,value) FROM stdin;"],
	  [\$::Frdng, "load05.tmp", "COPY rdng(entr,rdng,txt) FROM stdin;"],
	  [\$::Frinf, "load06.tmp", "COPY rinf(entr,rdng,kw) FROM stdin;"],
	  [\$::Frfrq, "load07.tmp", "COPY rfreq(entr,rdng,kw,value) FROM stdin;"],
	  [\$::Fsens, "load08.tmp", "COPY sens(entr,sens,notes) FROM stdin;"],
	  [\$::Fpos,  "load09.tmp", "COPY pos(entr,sens,kw) FROM stdin;"],
	  [\$::Fmisc, "load10.tmp", "COPY misc(entr,sens,kw) FROM stdin;"],
	  [\$::Ffld,  "load11.tmp", "COPY fld(entr,sens,kw) FROM stdin;"],
	  [\$::Fxref, "load12.tmp", "COPY xresolv(entr,sens,typ,txt) FROM stdin;"],
	  [\$::Fglos, "load13.tmp", "COPY gloss(entr,sens,gloss,lang,txt,notes) FROM stdin;"],
	  [\$::Fdial, "load14.tmp", "COPY dial(entr,kw) FROM stdin;"],
	  [\$::Flang, "load15.tmp", "COPY lang(entr,kw) FROM stdin;"],
	  [\$::Frestr, "load16.tmp", "COPY restr(entr,rdng,kanj) FROM stdin;"],
	  [\$::Fstagr, "load17.tmp", "COPY stagr(entr,sens,rdng) FROM stdin;"],
	  [\$::Fstagk, "load18.tmp", "COPY stagk(entr,sens,kanj) FROM stdin;"],
	  [\$::Fhist, "load19.tmp", "COPY hist(id,entr,stat,dt,who,diff,notes) FROM stdin;"] );

	$::srcid = 1; $::cntr = 0;
	  # Following globals are used to maintain the row 'id'
	  # numbers for tables entr and hist respectively.
	$::eid = $::hid = 1;

	foreach $t (@tmpfiles) {
	    open (${$t->[0]}, ">:utf8", $t->[1]) or \
		  die ("Can't open $t->[1]: $!\n") }
	open ($::Fskiplog, ">:utf8", "skipped_comments.log") or \
	    die ("Can't open load_jmdict_skipped.log: $!\n");
	return \@tmpfiles; }

sub finalize { my ($outfn, $tmpfls, $del) = @_;
	my ($t, $tmpfn);
	open (FOUT, ">:utf8", $outfn) or die ("Can\'t open $outfn: $!\n");
	foreach $t (@$tmpfls) {
	    $tmpfn = $t->[1];
	    close (${$t->[0]});
	    if ((stat ($tmpfn))[7] != 0) {
		open (FIN, "<:utf8", $tmpfn) or die ("Can\'t open $tmpfn: $!\n");
		print FOUT "\n" . $t->[2] . "\n";
		while (<FIN>) { print FOUT; }
		print FOUT "\\.\n";
		close (FIN); } 
	    if ($del) {unlink ($t->[1]); } } 
	close (FOUT); } 

sub entry_handler { my ($t, $entry ) = @_;
	my ($seq, @x, $kmap, $rmap);
	if (!($::cntr % 1385)) { print STDERR "."; } 
	$::cntr += 1;
	$seq = ($entry->get_xpath("ent_seq"))[0]->text;
	if (!$::started_at and (!$::Opts{s} or $seq eq $::Opts{s})) { 
	    $::processing = 1;  $::started_at = $::cntr }
	return if (! $::processing);
	if ($::Opts{c} and ($::cntr - $::started_at >= int($::Opts{c}))) {
	     die ("done\n"); }
	do_entry ($seq, $entry);
	$t->purge; 0;}

sub comment_handler { my ($t, $entry ) = @_;
	my ($c, $seq, $notes, $dt, $ln); 
	return if (! $::processing);
	$c = $entry->{comment};
	if ($c =~ m/^\s*Deleted:\s*(\d{7}) with (\d{7})\s*(.*)/) {
	    $seq = $1; $notes = "Merged into $2";
	    if ($3) { $notes .= "\n" . $3; } }
	elsif ($c =~ m/^\s*Deleted:\s*(\d{7})\s*(.*)/) {
	    $seq = $1; if ($2) { $notes = $2; } }
	else { 
	    $ln = $t->current_line();
	    print $::Fskiplog "$ln: $c\n"; return; }

	$dt = "1990-01-01 00:00:00-00";
	# (id,src,seq,stat,note)
	print $::Fentr "$::eid\t$::srcid\t$seq\t4\t\\N\n";

	# Should we create a synthetic N record before creating the D record?
	# (id,entr,stat,dt,who,diff,notes)
	$notes = pgesc ($notes);
	print $::Fhist "$::hid\t$::eid\t4\t$dt\tfrom JMdict.xml\t\\N\t$notes\n"; 
	$::eid += 1;  $::hid += 1; 
	$t->purge; 0; }

sub do_entry { my ($seq, $entry) = @_;
	my (@x, $kmap, $rmap);
	# (id,src,seq,stat,note)
	print $::Fentr "$::eid\t$::srcid\t$seq\t2\t\\N\n";
	if (@x = $entry->get_xpath("k_ele")) { $kmap = do_kanj (\@x); }
	if (@x = $entry->get_xpath("r_ele")) { $rmap = do_rdng (\@x, $kmap); }
	if (@x = $entry->get_xpath("sense")) { do_sens (\@x, $kmap, $rmap); }
	if (@x = $entry->get_xpath("info/dial")) { do_dial (\@x); }
	if (@x = $entry->get_xpath("info/lang")) { do_lang (\@x); }
	if (@x = $entry->get_xpath("info/audit")) { do_hist (\@x); }
	$::eid += 1; }

sub do_kanj { my ($keles) = @_;
	my ($ord, $txt, $k, @x, $kmap);
	$ord = 1; $kmap = {};
	foreach $k (@$keles) {
	    $txt = ($k->get_xpath ("keb"))[0]->text;
	    # (entr,ord,txt)
	    print $::Fkanj "$::eid\t$ord\t$txt\n";
	    if (@x = $k->get_xpath ("ke_inf")) { do_kinfs (\@x, $ord); }
	    if (@x = $k->get_xpath ("ke_pri")) { do_kfrqs (\@x, $ord); }
	    $kmap->{$txt} = $ord;
	    $ord += 1; }
	return $kmap; }

sub do_kinfs { my ($kinfs, $ord) = @_;
	my ($i, $kw, $txt);
	foreach $i (@$kinfs) {
	    $txt = $i->text;
	    ($kw = $::JM2ID{KINF}{$txt}) or \
		die ("Unknown ke_inf text: /$txt/\n");
	    print $::Fkinf "$::eid\t$ord\t$kw\n"; } }

sub do_kfrqs { my ($kfrqs, $ord) = @_;
	my ($kw, $f);
	$f = freqs ($kfrqs);
	foreach $kw (sort (keys (%$f))) {
	    if ($kw) { print $::Fkfrq "$::eid\t$ord\t$kw\t$f->{$kw}\n"; } } }

sub do_rdng { my ($reles, $kmap) = @_;
	my ($ord, $txt, $r, $z, @x, $rmap, %restr);
	$ord = 1;  $rmap = {}; %restr = ();
	foreach $r (@$reles) {
	    $txt = ($r->get_xpath ("reb"))[0]->text;
	    # (entr,ord,txt)
	    print $::Frdng "$::eid\t$ord\t$txt\n";
	    if (@x = $r->get_xpath ("re_inf")) { do_rinfs (\@x, $ord); }
	    if (@x = $r->get_xpath ("re_pri")) { do_rfrqs (\@x, $ord); }
	    for $z ($r->get_xpath ("re_restr")) { 
		if (! defined ($restr{$ord})) { $restr{$ord} = {}; }
		$restr{$ord}->{$kmap->{$z->text}} = 1; }
	    if ($r->get_xpath ("re_nokanji")) { 
		if (! defined ($restr{$ord})) { $restr{$ord} = {}; }
		$restr{$ord} = 1; }
	    $rmap->{$txt} = $ord;
	    $ord += 1; }
	if (%restr) { do_restr ($::Frestr, \%restr, $rmap, $kmap); }
	return $rmap; }

sub do_rinfs { my ($rinfs, $ord) = @_;
	my ($i, $kw, $txt);
	foreach $i (@$rinfs) {
	    $txt = $i->text;
	    ($kw = $::JM2ID{RINF}{$txt}) or \
		die ("Unknown re_inf text: /$txt/\n") ;
	    print $::Frinf "$::eid\t$ord\t$kw\n"; } }

sub do_rfrqs { my ($rfrqs, $ord) = @_;
	my ($kw, $f);
	$f = freqs ($rfrqs);
	foreach $kw (sort (keys (%$f))) {
	    if ($kw) { print $::Frfrq "$::eid\t$ord\t$kw\t$f->{$kw}\n"; } } }

sub do_sens { my ($sens, $kmap, $rmap) = @_;
	my ($ord, $txt, $s, @x, @p, @pp, $z, %smap, %stagr, %stagk);
	$ord=1;  @pp=(); %smap=(); %stagr=(); %stagk=();
	foreach $s (@$sens) {
	    $txt = "\\N";
	    if (@x = $s->get_xpath ("s_inf")) { $txt = $x[0]->text; }
	    # (entr,ord,note)
	    print $::Fsens "$::eid\t$ord\t$txt\n";
	    @p = $s->get_xpath ("pos");
	    if (!@p) { @p = @pp; }
	    if (@p) { do_pos (\@p, $ord); @pp = @p; }
	    if (@x = $s->get_xpath ("misc"))  { do_misc (\@x, $ord); }
	    if (@x = $s->get_xpath ("field")) { do_fld  (\@x, $ord); }
	    if (@x = $s->get_xpath ("gloss")) { do_glos (\@x, $ord); }
	    if (@x = $s->get_xpath ("xref"))  { do_xref ("see", \@x, $ord); }
	    if (@x = $s->get_xpath ("ant"))   { do_xref ("ant", \@x, $ord); }
	    for $z ($s->get_xpath ("stagr")) { 
		if (! defined ($stagr{$ord})) { $stagr{$ord} = {}; }
		$stagr{$ord}->{$rmap->{$z->text}} = 1; }
	    for $z ($s->get_xpath ("stagk")) { 
		if (! defined ($stagk{$ord})) { $stagk{$ord} = {}; }
		$stagk{$ord}->{$kmap->{$z->text}} = 1; }
	    $smap{$ord} = $ord;
	    $ord += 1; }
	if (%stagr) { do_restr ($::Fstagr, \%stagr, \%smap, $rmap); }
	if (%stagk) { do_restr ($::Fstagk, \%stagk, \%smap, $kmap); } }

sub do_glos { my ($gloss, $ord) = @_;
	my ($g, $gord, $lang, $txt);
	$gord = 1;
	foreach $g (@$gloss) {
	    $lang = undef; $lang = $g->att("g_lang");
	    $lang = $lang ? $::JM2ID{LANG}{$lang} : $::JM2ID{LANG}{"en"}; 
	    ($txt = $g->text) =~ s/\\/\\\\/go;
	    # (entr,sens,ord,lang,txt,notes)
	    print $::Fglos "$::eid\t$ord\t$gord\t$lang\t$txt\t\\N\n"; 
	    $gord += 1; } }

sub do_pos { my ($pos, $ord) = @_;
	my ($i, $kw, $txt);
	foreach $i (@$pos) {
	    $txt = $i->text;
	    ($kw = $::JM2ID{POS}{$txt}) or \
		die ("Unknown \'pos\' text: /$txt/\n");
	    print $::Fpos "$::eid\t$ord\t$kw\n"; } }

sub do_misc { my ($misc, $ord) = @_;
	my ($i, $kw, $txt);
	foreach $i (@$misc) {
	    $txt = $i->text;
	    ($kw = $::JM2ID{MISC}{$txt}) or \
		die ("Unknown \'misc\' text: /$txt/\n");
	    print $::Fmisc "$::eid\t$ord\t$kw\n"; } }

sub do_fld { my ($fld, $ord) = @_;
	my ($i, $kw, $txt);
	foreach $i (@$fld) {
	    $txt = $i->text;
	    ($kw = $::JM2ID{FLD}{$txt}) or \
		die ("Unknown \'fld\' text: /$txt/\n");
	    print $::Ffld "$::eid\t$ord\t$kw\n"; } }

sub do_dial { my ($dial) = @_;
	my ($i, $kw, $txt);
	foreach $i (@$dial) {
	    $txt = substr ($i->text, 0, -1);
	    ($kw = $::JM2ID{DIAL}{$txt}) or \
		die ("Unknown \'dial\' text: /$txt/\n");
	    print $::Fdial "$::eid\t$kw\n"; } }

sub do_lang { my ($lang) = @_;
	my ($i, $kw, $txt);
	foreach $i (@$lang) {
	    $txt = substr ($i->text, 0, -1);
	    ($kw = $::JM2ID{LANG}{$txt}) or \
		die ("Unknown \'lang\' text: /$txt/\n");
	    print $::Flang "$::eid\t$kw\n"; } }

sub do_restr { my ($file, $restr, $amap, $bmap) = @_;
	my ($a, $b, $r);
	foreach $a (sort (values (%$amap))) {
	    foreach $b (sort (values (%$bmap))) {
		next if (!($r = $restr->{$a}));
		if ($r == 1 or !$r->{$b}) { 
		    print $file "$::eid\t$a\t$b\n"; } } } }

sub do_xref { my ($xtyp, $xref, $ord) = @_;
	my ($x, $txt, $kw);
	$kw = $::JM2ID{XREF}{$xtyp};
	foreach $x (@$xref) {
	    $txt = $x->text;
	    # (entr,sens,lang,txt,notes)
	    print $::Fxref "$::eid\t$ord\t$kw\t$txt\n"; } }

sub do_hist { my ($hist) = @_;
	my ($x, $dt, $op);
	foreach $x (@$hist) {
	    $dt = ($x->get_xpath ("upd_date"))[0]->text; # Assume just one.
	    $dt .= " 00:00:00-00";  # Add a time.
	    $op = ($x->get_xpath ("upd_detl"))[0]->text; # Assume just one.
	    if ($op eq "Entry created") {
		# (id,entr,stat,dt,who,diff,notes)
		print $::Fhist "$::hid\t$::eid\t2\t$dt\tfrom JMdict.xml\t\\N\t\\N\n"; }
	    else { die ("Unexpected <upd_detl> contents: $op"); }
	    $::hid += 1; } }

sub freqs { my ($frqs) = @_;
	my ($i, $kw, $val, %dupnuke);
	foreach $i (@$frqs) {
	    ($kw, $val) = parse_freq ($i->text);
	    if (!defined ($dupnuke{$kw}) or $dupnuke{$kw} < $val) { 
		$dupnuke{$kw} = $val; } }
	return \%dupnuke; }

sub parse_freq { my ($fstr) = @_;
	my ($i, $kw, $val);
	($fstr =~ m/([a-z]+)(\d+)/io) or die ("Bad x_pri string: $fstr\n");
	return () if $1 eq "news";
	($kw = $::JM2ID{FREQ}{$1}) or die ("Unrecognized x_pri string: /$fstr/\n");
	$val = int ($2);
	return ($kw, $val); }

sub pgesc { my ($str) = @_; 
	# Escape characters that are special to the Postgresql COPY
	# command.  Backslash characters are replaced by two backslash
	# characters.   Newlines are replaced by the two characters
	# backslash and "n".  Similarly for tab and return characters.
	$str =~ s/\\/\\\\/go;
	$str =~ s/\n/\\n/go;
	$str =~ s/\r/\\r/go;
	$str =~ s/\t/\\t/go;
	return $str; }

sub usage { my ($exitstat) = @_;
	print <<EOT;

Usage: load_jmdict.pl [-o output-filename] [-c entry-count] \\
		      [-s start-seq-num] [-k]  [xml-filename]

Arguments:
	xml-filename -- Name of input jmdict xml file.  Default 
	  is "JMdict".
Options:
	-o output-filename -- Name of output postgresql dump file. 
	    Default is "JMdict.dmp"
	-c entry-count -- Number of entries to process.
	-s start-seq-num -- Sequence number of first entry to process.
	-k -- (keep) do not delete temporary files.
	-e encoding -- Ecoding to use when writing messages to stderr
	    and stdout.  Default is "utf-8".
	-h -- (help) print this text and exit.
EOT
	exit $exitstat; }
