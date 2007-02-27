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
# an output file containing postgresql data COPY commands
# that will, when executeD, load the JMdict data into an
# appropriately configured Postgresql database.
#
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
use jmdictxml ('%JM2ID'); # Maps xml expanded entities to kw* table id's.

main: {
	my ($twig, $infn, $outfn, $tmpfiles, $tmp, $enc, $logfn);

	getopts ("o:c:s:e:l:kh", \%::Opts);
	if ($::Opts{h}) { usage (0); }
	$enc = $::Opts{e} || "utf-8";
	binmode(STDOUT, ":encoding($enc)");
	binmode(STDERR, ":encoding($enc)");
	eval { binmode($DB::OUT, ":encoding($enc)"); };

	$infn = shift (@ARGV) || "JMdict";
	$outfn = $::Opts{o} || "JMdict.dmp";
	$logfn = $::Opts{l} || "load_jmdict.log";

	  # Make STDERR unbuffered so we print "."s, one at 
	  # a time, as a sort of progress bar.  
	$tmp = select(STDERR); $| = 1; select($tmp);

	  # Create an XML parser instance. 'twig_handlers' is
	  # a hash whose keys name the elements to be parsed,
	  # and value(s) give the name of a subroutine to be
	  # called to process the parsed element. 
	$twig = XML::Twig->new (twig_handlers => { 
				    entry    =>\&entry_handler,
				   '#COMMENT'=>\&comment_handler}, 
				comments=>'process');

	  # Initialize global variables and open all the 
	  # temporary table files. 
	$tmpfiles = initialize ($logfn);

	  # Parse the given xml file.  The entry_ele sub given 
	  # when the $twig was created does all the work of
	  # writing the parsed data to the tables files.  
	  # The parsefile() method is called inside an eval because
	  # we want to catch the die("done") thrown by the entry
	  # handler sub when it want to quit early (due to the
	  # -c option).
	print STDERR "Parsing xml file $infn\n";
	eval { $twig->parsefile( $infn ); };
	die if ($@ and $@ ne "done\n"); 
	print STDERR "\n";

	  # Now merge all the temp table files into one big 
	  # dump file that can be fed to Postgresql.
	print STDERR "Generating output file $outfn\n";
	finalize ($outfn, $tmpfiles, !$::Opts{k}); 
	print STDERR ("Done\n"); }

sub initialize { my ($logfn) = @_;
	my ($t);
	my @tmpfiles = (
	  [\$::Fentr, "load01.tmp", "COPY entr(id,src,seq,stat,notes) FROM stdin;"],
	  [\$::Fkanj, "load02.tmp", "COPY kanj(entr,kanj,txt) FROM stdin;"],
	  [\$::Fkinf, "load03.tmp", "COPY kinf(entr,kanj,kw) FROM stdin;"],
	  [\$::Frdng, "load05.tmp", "COPY rdng(entr,rdng,txt) FROM stdin;"],
	  [\$::Frinf, "load06.tmp", "COPY rinf(entr,rdng,kw) FROM stdin;"],
	  [\$::Ffrq,  "load07.tmp", "COPY freq(entr,rdng,kanj,kw,value) FROM stdin;"],
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
	open ($::Flog, ">:utf8", $logfn) or die ("Can't open $logfn: $!\n");
	return \@tmpfiles; }

sub finalize { my ($outfn, $tmpfls, $del) = @_;
	# Close all the temp files, merge them all intro the single 
	# output file, and delete them (if no -k option).

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
	# Process each <entry> element.   When we're called (because we
	# were listed in the twig_handlers option of the Twig->new() call
	# in main()), a complete entry has been parsed including everthing
	# inside it.  We do the entry-related bookkeeping stuff here, and 
	# call do_pentry() to deal with the jmdict info contained in the
	# entry.

	my ($seq, @x, $kmap, $rmap);
	if (!($::cntr % 1385)) { print STDERR "."; } 
	$::cntr += 1;
	$seq = ($entry->get_xpath("ent_seq"))[0]->text;
	$::Seq = $seq;	# For log messages.
	if (!$::started_at and (!$::Opts{s} or $seq eq $::Opts{s})) { 
	    $::processing = 1;  $::started_at = $::cntr }
	return if (! $::processing);
	if ($::Opts{c} and ($::cntr - $::started_at >= int($::Opts{c}))) {
	     die ("done\n"); }
	do_entry ($seq, $entry);
	$t->purge; 0;}

sub comment_handler { my ($t, $entry ) = @_;
	# Process each comment.  We get called when a comment is seen
	# because  we were listed ('#COMMENT') in the twig_handlers option
	# of the Twig->new() call in main().  We look for comments that
	# described entry deletions and create synthetic 'D' status entries
	# for them.

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
	    print $::Flog "Line $ln: unparsable comment: $c\n"; return; }

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
	my (@x, $kmap, $rmap, $fklist, $frlist);
	# (id,src,seq,stat,note)
	print $::Fentr "$::eid\t$::srcid\t$seq\t2\t\\N\n";
	if (@x = $entry->get_xpath("k_ele")) { ($kmap, $fklist) = do_kanj (\@x); }
	if (@x = $entry->get_xpath("r_ele")) { ($rmap, $frlist) = do_rdng (\@x, $kmap); }
	if (@x = $entry->get_xpath("sense")) { do_sens (\@x, $kmap, $rmap); }
	if (@x = $entry->get_xpath("info/dial")) { do_dial (\@x); }
	if (@x = $entry->get_xpath("info/lang")) { do_lang (\@x); }
	if (@x = $entry->get_xpath("info/audit")) { do_hist (\@x); }
	do_freqs ($frlist, $fklist);
	$::eid += 1; }

sub do_kanj { my ($keles) = @_;
	my ($ord, $txt, $k, @x, %kmap, @flist);
	$ord = 1; 
	foreach $k (@$keles) {
	    $txt = ($k->get_xpath ("keb"))[0]->text;
	    # (entr,ord,txt)
	    print $::Fkanj "$::eid\t$ord\t$txt\n";
	    if (@x = $k->get_xpath ("ke_inf")) { do_kinfs (\@x, $ord); }
	    if (@x = $k->get_xpath ("ke_pri")) { freqs (\@x, $ord, \@flist); }
	    $kmap{$txt} = $ord;
	    $ord += 1; }
	return (\%kmap, \@flist); }

sub do_kinfs { my ($kinfs, $ord) = @_;
	my ($i, $kw, $txt);
	foreach $i (@$kinfs) {
	    $txt = $i->text;
	    ($kw = $::JM2ID{KINF}{$txt}) or \
		die ("Unknown ke_inf text: /$txt/\n");
	    if ($kw >= 200) { print $::Flog "Seq $::Seq: deprecated kinf string '$txt'\n"; }
	    print $::Fkinf "$::eid\t$ord\t$kw\n"; } }

sub do_rdng { my ($reles, $kmap) = @_;
	my ($ord, $txt, $r, $z, @x, %rmap, %restr, @flist);
	$ord = 1; 
	foreach $r (@$reles) {
	    $txt = ($r->get_xpath ("reb"))[0]->text;
	    # (entr,ord,txt)
	    print $::Frdng "$::eid\t$ord\t$txt\n";
	    if (@x = $r->get_xpath ("re_inf")) { do_rinfs (\@x, $ord); }
	    if (@x = $r->get_xpath ("re_pri")) { freqs (\@x, $ord, \@flist); }
	    for $z ($r->get_xpath ("re_restr")) { 
		if (! defined ($restr{$ord})) { $restr{$ord} = {}; }
		$restr{$ord}->{$kmap->{$z->text}} = 1; }
	    if ($r->get_xpath ("re_nokanji")) { 
		if (! defined ($restr{$ord})) { $restr{$ord} = {}; }
		$restr{$ord} = 1; }
	    $rmap{$txt} = $ord;
	    $ord += 1; }
	if (%restr) { do_restr ($::Frestr, \%restr, \%rmap, $kmap); }
	return (\%rmap, \@flist); }

sub do_rinfs { my ($rinfs, $ord) = @_;
	my ($i, $kw, $txt);
	foreach $i (@$rinfs) {
	    $txt = $i->text;
	    ($kw = $::JM2ID{RINF}{$txt}) or \
		die ("Unknown re_inf text: /$txt/\n") ;
	    if ($kw >= 200) { print $::Flog "Seq $::Seq: deprecated rinf string '$txt'\n"; }
	    print $::Frinf "$::eid\t$ord\t$kw\n"; } }

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
	    if ($kw >= 200) { print $::Flog "Seq $::Seq: deprecated pos string '$txt'\n"; }
	    print $::Fpos "$::eid\t$ord\t$kw\n"; } }

sub do_misc { my ($misc, $ord) = @_;
	my ($i, $kw, $txt);
	foreach $i (@$misc) {
	    $txt = $i->text;
	    ($kw = $::JM2ID{MISC}{$txt}) or \
		die ("Unknown \'misc\' text: /$txt/\n");
	    if ($kw >= 200) { print $::Flog "Seq $::Seq: deprecated misc string '$txt'\n"; }
	    print $::Fmisc "$::eid\t$ord\t$kw\n"; } }

sub do_fld { my ($fld, $ord) = @_;
	my ($i, $kw, $txt);
	foreach $i (@$fld) {
	    $txt = $i->text;
	    ($kw = $::JM2ID{FLD}{$txt}) or \
		die ("Unknown \'fld\' text: /$txt/\n");
	    if ($kw >= 200) { print $::Flog "Seq $::Seq: deprecated fld string '$txt'\n"; }
	    print $::Ffld "$::eid\t$ord\t$kw\n"; } }

sub do_dial { my ($dial) = @_;
	my ($i, $kw, $txt);
	foreach $i (@$dial) {
	    $txt = substr ($i->text, 0, -1);
	    ($kw = $::JM2ID{DIAL}{$txt}) or \
		die ("Unknown \'dial\' text: /$txt/\n");
	    if ($kw >= 200) { print $::Flog "Seq $::Seq: deprecated dial string '$txt'\n"; }
	    print $::Fdial "$::eid\t$kw\n"; } }

sub do_lang { my ($lang) = @_;
	my ($i, $kw, $txt);
	foreach $i (@$lang) {
	    $txt = substr ($i->text, 0, -1);
	    ($kw = $::JM2ID{LANG}{$txt}) or \
		die ("Unknown \'lang\' text: /$txt/\n");
	    if ($kw >= 200) { print $::Flog "Seq $::Seq: deprecated lang string '$txt'\n"; }
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

sub do_freqs { my ($rfrqs, $kfrqs) = @_;
	# Process collected re_pri (in @$rfrqs) and ke_pri (in @$kfrqs) info.  
	# This data is collected during the processing of the re_ele and ke_ele
	# elements but processing is deferred to here, where we find matching 
	# values that indicate tags that apply to pairs of reading-kanji values.
	# $::eid is used when writing the table data files so this sub must be
	# called in the same entry context that the @$rfrqs and @$kfrqs were 
	# generated in.

	my ($fr, $fk, $nr, $nk, %rmatched, %kmatched, $x, %dupchk);

	# Each element in @$rfrqs and @kfrqs is a 3-element array:
	#  0 - rdng or kanj number.
	#  1 - freq kw tag id number (scale).
	#  2 - scale value.
	# A reading and kanji tag match if the tag id's and values match. 

	# Go though every posible pair of readings and kanji tags.  If a 
	# match is found, add a record to the freq table for that tag with
	# the rdng and kanj numbers of the reading and kanji.  Remember 
	# (in hashes %rmatched and %kmatched) that these tags were written
	# to the freq table.

	$nr = -1;
	foreach $fr (@$rfrqs) {
	    $nr ++;  $nk = -1;
	    foreach $fk (@$kfrqs) {
		$nk++;
		if ($fr->[1] eq $fk->[1] and $fr->[2] eq $fk->[2]) {
		    $x = "$fr->[0]_$fk->[0]_$fr->[1]";
		    if ($dupchk{$x}) {
			print $::Flog "Seq $::Seq: skipped duplicate pri pair '$x $fr->[2]'\n"; }
		    else { 
			print $::Ffrq "$::eid\t$fr->[0]\t$fk->[0]\t$fr->[1]\t$fr->[2]\n";
			$dupchk{$x} = 1; }
		    $rmatched{$nr} = 1;  $kmatched{$nk} = 1; } } }

	# Go through the reading freq tags looking for any that weren't paired
	# with a kanji tag, and write out a record for them.

	if ($rfrqs and @$rfrqs) {
	    for ($nr=0; $nr<scalar(@$rfrqs); $nr++) {
		next if ($rmatched{$nr});
		$fr = $rfrqs->[$nr];
		$x = "$fr->[0]_null_$fr->[1]";
		if ($dupchk{$x}) {
		    print $::Flog "Seq $::Seq: skipped duplicate re_pri '$x $fr->[2]'\n"; }
		else {
		    print $::Ffrq "$::eid\t$fr->[0]\t\\N\t$fr->[1]\t$fr->[2]\n";
		    $dupchk{$x} = 1; } } }

	# Go through the kanji freq tags looking for any that weren't paired
	# with a reading tag, and write out a record for them.

	if ($kfrqs and @$kfrqs) {
	    for ($nk=0; $nk<scalar(@$kfrqs); $nk++) {
		next if ($kmatched{$nk});
		$fk = $kfrqs->[$nk];
		$x = "null_$fk->[0]_$fk->[1]";
		if ($dupchk{$x}) {
		    print $::Flog "Seq $::Seq: skipped duplicate ke_pri '$x $fr->[2]'\n"; }
		else {   
		    print $::Ffrq "$::eid\t\\N\t$fk->[0]\t$fk->[1]\t$fk->[2]\n"; 
		    $dupchk{$x} = 1; } } } }

sub freqs { my ($frqs, $ord, $flist) = @_;
	# Process a list of [kr]e_pri elements, by parsing each into a kwfreq
	# tag id number (scale), a scale value.  These two items and the reading
	# or kanji order number are added to list @$flist as a ref to 3-element
	# array. 

	my ($kw, $val, $kwstr, $f, %fmap);
	foreach $f (@$frqs) {
	    ($kw, $val, $kwstr) = parse_freq ($f->text, $f->name);  
	    $fmap{$kwstr} = [$ord, $kw, $val]; } 
	push (@$flist, values (%fmap)); }

sub parse_freq { my ($fstr, $ptype) = @_;
	# Convert a re_pri or ke_pri element string (e.g "nf30") into
	# numeric (id,value) pair (like 4,30) (4 is the id number of 
	# keyword "nf" in the database table "kwfreq", and we get it 
	# by looking it up in JM2ID (from jmdictxml.pm). In addition 
	# to the id,value pair, we also return keyword string.
	# $ptype is a string used only in error or warning messages 
	# and is typically either "re_pri" or "ke_pri".

	my ($i, $kw, $val, $kwstr);
	($fstr =~ m/^([a-z]+)(\d+)$/io) or die ("Bad x_pri string: $fstr\n");
	$kwstr = $1;  $val = int ($2);
	($kw = $::JM2ID{FREQ}{$kwstr}) or die ("Unrecognized $ptype string: /$fstr/\n");
	if ($kw >= 200) { print $::Flog "Seq $::Seq: deprecated $ptype keyword '$i->text'\n"; }
	return ($kw, $val, $fstr); }

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
		      [-s start-seq-num] [-k]  [-l logfile] \\
		      [xml-filename]

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
	-l logfile -- Name of file to write log messages to.  Default 
	    is "load_jmdict.log".
	-h -- (help) print this text and exit.
EOT
	exit $exitstat; }
