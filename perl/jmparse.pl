# Special handling: 
# - generate "ord" values.
# - propagate PoS through senses.
# - do xrefs/ants in 2nd pass
# - ke_pri, re_pri: ignore (redundant) newsX values.
# - record only 1 nfXX when multiple values present. (niy)

# This program will read a JMdict.xml file and create
# an output file containing postgresql data load commands
# that will, when executes, load the JMdict data into an
# appropriately configured Postgresql database.

# Copyright (c) 2006, Stuart McGraw 
@VERSION = (substr('$Revision$',11,-2), \
	    substr('$Date$',7,-11));

use XML::Twig;
use Encode;
use Getopt::Std ('getopts');
use strict;

use JMdict ('%JM2ID');

binmode(STDOUT, ":encoding(utf-8)");
binmode(STDERR, ":encoding(shift_jis)");
#binmode($DB::OUT, ":encoding(shift_jis)");


main: {
	my ($twig, $infn, $outfn, $tmpfiles, $tmp);

	getopts ("o:c:s:k", \%::Opts);
	  # o -- Output filename.
	  # c -- Number of entries to process.
	  # s -- seq num of first entry to process.
	  # k -- (keep) don't delete temp files.
	$infn = shift (@ARGV) || "JMdict";
	$outfn = $::Opts{o} || "JMdict.pgd";
	  # Make STDERR unbuffered so we print "."s, one at 
	  # a time, as a sort of progress bar.  
	$tmp = select(STDERR); $| = 1; select($tmp);
	  # Create an XML parser instance.  'twig_roots' is
	  # a hash whose keys (one) name the elements to be 
	  # parsed, and value(s) give the name of a subroutine
	  # to be called to process the parsed element. 
	$twig = XML::Twig->new (twig_roots => { entry => \&entry_ele });
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
	  [\$::Fkanj, "load02.tmp", "COPY kanj(id,entr,ord,txt) FROM stdin;"],
	  [\$::Fkinf, "load03.tmp", "COPY kinf(kanj,kw) FROM stdin;"],
	  [\$::Fkfrq, "load04.tmp", "COPY kfreq(kanj,kw,value) FROM stdin;"],
	  [\$::Frdng, "load05.tmp", "COPY rdng(id,entr,ord,txt) FROM stdin;"],
	  [\$::Frinf, "load06.tmp", "COPY rinf(rdng,kw) FROM stdin;"],
	  [\$::Frfrq, "load07.tmp", "COPY rfreq(rdng,kw,value) FROM stdin;"],
	  [\$::Fsens, "load08.tmp", "COPY sens(id,entr,ord,notes) FROM stdin;"],
	  [\$::Fpos,  "load09.tmp", "COPY pos(sens,kw) FROM stdin;"],
	  [\$::Fmisc, "load10.tmp", "COPY misc(sens,kw) FROM stdin;"],
	  [\$::Ffld,  "load11.tmp", "COPY fld(sens,kw) FROM stdin;"],
	  [\$::Fxref, "load12.tmp", "COPY xresolv(sens,typ,txt) FROM stdin;"],
	  [\$::Fglos, "load13.tmp", "COPY gloss(id,sens,ord,lang,txt,notes) FROM stdin;"],
	  [\$::Fdial, "load14.tmp", "COPY dial(entr,kw) FROM stdin;"],
	  [\$::Flang, "load15.tmp", "COPY lang(entr,kw) FROM stdin;"],
	  [\$::Frestr, "load16.tmp", "COPY restr(rdng,kanj) FROM stdin;"],
	  [\$::Fstagr, "load17.tmp", "COPY stagr(sens,rdng) FROM stdin;"],
	  [\$::Fstagk, "load18.tmp", "COPY stagk(sens,kanj) FROM stdin;"],
	  [\$::Fhist, "load19.tmp", "COPY hist(id,entr,ostat,dt,who,notes) FROM stdin;"] );

	$::srcid = 1; $::cntr = 0;
	  # Following globals are used to maintain the row 'id'
	  # numbers for tables entr, kanj, rdng, sens, gloss,
	  # and hist respectively.
	$::eid = $::jid = $::rid = $::sid = $::gid = $::aid = 1;

	foreach $t (@tmpfiles) {
	    open (${$t->[0]}, ">:utf8", $t->[1]) or \
		  die ("Can't open $t->[1]: $!\n") }
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

sub entry_ele { my( $t, $entry ) = @_;
	my ($seq, @x, $kmap, $rmap);
	if (!($::cntr % 1375)) { print STDERR "."; } 
	$::cntr += 1;
	$seq = ($entry->get_xpath("ent_seq"))[0]->text;
	if (!$::started_at and (!$::Opts{s} or $seq eq $::Opts{s})) { 
	    $::processing = 1;  $::started_at = $::cntr }
	return if (! $::processing);
	if ($::Opts{c} and ($::cntr - $::started_at >= int($::Opts{c}))) {
	     die ("done\n"); }
	do_entry ($seq, $entry);
	$t->purge; 0;}

sub do_entry { my ($seq, $entry) = @_;
	my (@x, $kmap, $rmap);
	# (id,src,seq,stat,note)
	print $::Fentr "$::eid\t$::srcid\t$seq\tA\t\\N\n";
	if (@x = $entry->get_xpath("k_ele")) { $kmap = do_kanj (\@x); }
	if (@x = $entry->get_xpath("r_ele")) { $rmap = do_rdng (\@x, $kmap); }
	if (@x = $entry->get_xpath("sense")) { do_sens (\@x, $kmap, $rmap); }
	if (@x = $entry->get_xpath("info/dial")) { do_dial (\@x); }
	if (@x = $entry->get_xpath("info/lang")) { do_lang (\@x); }
	if (@x = $entry->get_xpath("info/audit")) { do_hist (\@x); }
	$::eid += 1; }

sub do_kanj { my ($keles) = @_;
	my ($ord, $txt, $k, @x, $kmap);
	$ord = 10; $kmap = {};
	foreach $k (@$keles) {
	    $txt = ($k->get_xpath ("keb"))[0]->text;
	    # (id,entr,ord,txt)
	    print $::Fkanj "$::jid\t$::eid\t$ord\t$txt\n";
	    if (@x = $k->get_xpath ("ke_inf")) { do_kinfs (\@x); }
	    if (@x = $k->get_xpath ("ke_pri")) { do_kfrqs (\@x); }
	    $kmap->{$txt} = $::jid;
	    $ord += 10; 
	    $::jid += 1; }
	return $kmap; }

sub do_kinfs { my ($kinfs) = @_;
	my ($i, $kw, $txt);
	foreach $i (@$kinfs) {
	    $txt = $i->text;
	    ($kw = $::JM2ID{KINF}{$txt}) or \
		die ("Unknown ke_inf text: /$txt/\n");
	    print $::Fkinf "$::jid\t$kw\n"; } }

sub do_kfrqs { my ($kfrqs) = @_;
	my ($i, $kw, $kwstr, $val);
	foreach $i (@$kfrqs) {
	    ($kw, $val) = parse_freq ($i->text);
	    if ($kw) { print $::Fkfrq "$::jid\t$kw\t$val\n"; } } }

sub do_rdng { my ($reles, $kmap) = @_;
	my ($ord, $txt, $r, $z, @x, $rmap, %restr);
	$ord = 10;  $rmap = {}; %restr = ();
	foreach $r (@$reles) {
	    $txt = ($r->get_xpath ("reb"))[0]->text;
	    # (id,entr,ord,txt)
	    print $::Frdng "$::rid\t$::eid\t$ord\t$txt\n";
	    if (@x = $r->get_xpath ("re_inf")) { do_rinfs (\@x); }
	    if (@x = $r->get_xpath ("re_pri")) { do_rfrqs (\@x); }
	    for $z ($r->get_xpath ("re_restr")) { 
		$restr{"$::rid," . $kmap->{$z->text}} = 1; }
	    if ($r->get_xpath ("nokanji")) { $restr{$::rid} = 1; }
	    $rmap->{$txt} = $::rid;
	    $ord += 10; 
	    $::rid += 1; }
	if (%restr) { do_restr ($::Frestr, \%restr, $rmap, $kmap); }
	return $rmap; }

sub do_rinfs { my ($rinfs) = @_;
	my ($i, $kw, $txt);
	foreach $i (@$rinfs) {
	    $txt = $i->text;
	    ($kw = $::JM2ID{RINF}{$txt}) or \
		die ("Unknown re_inf text: /$txt/\n") ;
	    print $::Frinf "$::rid\t$kw\n"; } }

sub do_rfrqs { my ($rfrqs) = @_;
	my ($i, $kw, $kwstr, $val);
	foreach $i (@$rfrqs) {
	    ($kw, $val) = parse_freq ($i->text);
	    if ($kw) { print $::Frfrq "$::rid\t$kw\t$val\n"; } } }

sub do_sens { my ($sens, $kmap, $rmap) = @_;
	my ($ord, $txt, $s, @x, @p, @pp, $z, %smap, %stagr, %stagk);
	$ord=10;  @pp=(); %smap=(); %stagr=(); %stagk=();
	foreach $s (@$sens) {
	    $txt = "\\N";
	    if (@x = $s->get_xpath ("s_inf")) { $txt = $x[0]->text; }
	    # (id,entr,ord,note)
	    print $::Fsens "$::sid\t$::eid\t$ord\t$txt\n";
	    @p = $s->get_xpath ("pos");
	    if (!@p) { @p = @pp; }
	    if (@p) { do_pos (\@p); @pp = @p; }
	    if (@x = $s->get_xpath ("misc"))  { do_misc (\@x); }
	    if (@x = $s->get_xpath ("field")) { do_fld  (\@x); }
	    if (@x = $s->get_xpath ("gloss")) { do_glos (\@x); }
	    if (@x = $s->get_xpath ("xref"))  { do_xref ("see", \@x); }
	    if (@x = $s->get_xpath ("ant"))   { do_xref ("ant", \@x); }
	    for $z ($s->get_xpath ("stagr")) { 
		$stagr{"$::sid," . $rmap->{$z->text}} = 1; }
	    for $z ($s->get_xpath ("stagk")) { 
		$stagk{"$::sid," . $kmap->{$z->text}} = 1; }
	    $smap{$s::id} = $::sid;
	    $ord += 10; 
	    $::sid += 1; }
	if (%stagr) { do_restr ($::Fstagr, \%stagr, \%smap, $rmap); }
	if (%stagk) { do_restr ($::Fstagk, \%stagk, \%smap, $kmap); } }

sub do_glos { my ($gloss) = @_;
	my ($g, $ord, $lang, $txt);
	$ord = 10;
	foreach $g (@$gloss) {
	    $lang = undef; $lang = $g->att("lang");
	    $lang = $lang ? $::JM2ID{LANG}{$lang} : $::JM2ID{LANG}{"en"}; 
	    ($txt = $g->text) =~ s/\\/\\\\/go;
	    # (id,sens,ord,lang,txt,notes)
	    print $::Fglos "$::gid\t$::sid\t$ord\t$lang\t$txt\t\\N\n"; 
	    $ord += 10;
	    $::gid += 1; } }

sub do_pos { my ($pos) = @_;
	my ($i, $kw, $txt);
	foreach $i (@$pos) {
	    $txt = $i->text;
	    ($kw = $::JM2ID{POS}{$txt}) or \
		die ("Unknown \'pos\' text: /$txt/\n");
	    print $::Fpos "$::sid\t$kw\n"; } }

sub do_misc { my ($misc) = @_;
	my ($i, $kw, $txt);
	foreach $i (@$misc) {
	    $txt = $i->text;
	    ($kw = $::JM2ID{MISC}{$txt}) or \
		die ("Unknown \'misc\' text: /$txt/\n");
	    print $::Fmisc "$::sid\t$kw\n"; } }

sub do_fld { my ($fld) = @_;
	my ($i, $kw, $txt);
	foreach $i (@$fld) {
	    $txt = $i->text;
	    ($kw = $::JM2ID{FLD}{$txt}) or \
		die ("Unknown \'fld\' text: /$txt/\n");
	    print $::Ffld "$::sid\t$kw\n"; } }

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
	my ($a, $b);
	foreach $a (sort (values (%$amap))) {
	    foreach $b (sort (values (%$bmap))) {
		if (! $restr->{"$a,$b"} or $restr->{$a}) { 
		    print $file "$a\t$b\n"; } } } }

sub do_xref { my ($xtyp, $xref) = @_;
	my ($x, $txt, $kw);
	$kw = $::JM2ID{XREF}{$xtyp};
	foreach $x (@$xref) {
	    $txt = $x->text;
	    # (id,sens,ord,lang,txt,notes)
	    print $::Fxref "$::sid\t$kw\t$txt\n"; } }

sub do_hist { my ($hist) = @_;
	my ($x, $dt, $op);
	foreach $x (@$hist) {
	    $dt = ($x->get_xpath ("upd_date"))[0]->text; # Assume just one.
	    $op = ($x->get_xpath ("upd_detl"))[0]->text; # Assume just one.
	    if ($op eq "Entry created") {
		# (id,entr,ostat,dt,who,notes)
		print Fhist "$a::id\t$::eid\t\\N\t$dt\tload_jmdict.pl\t\\N"; }
	    else { die ("Unexpected <upd_detl> contents: $op"); }
	    $::aid += 1; } }

sub parse_freq { my ($fstr) = @_;
	my ($i, $kw, $val);
	($fstr =~ m/([a-z]+)(\d+)/io) or die ("Bad x_pri string: $fstr\n");
	return () if $1 eq "news";
	($kw = $::JM2ID{FREQ}{$1}) or die ("Unrecognized x_pri string: /$fstr/\n");
	$val = $2;
	return ($kw, $val); }
