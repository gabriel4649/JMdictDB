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

use strict; 
use XML::Twig; use Encode; use DBI;
use Getopt::Std ('getopts');

BEGIN {push (@INC, "./lib");}
use jmdictxml ('%JM2ID'); # Maps xml expanded entities to kw* table id's.
use jmdict; use jmdictpgi; use kwstatic;

main: {
	my ($twig, $infn, $outfn, $tmpfiles, $tmp, $enc, $logfn,
	    $user, $pw, $dbname, $host);

	getopts ("o:c:s:b:e:l:t:kh", \%::Opts);
	if ($::Opts{h}) { usage (0); }
	$enc = $::Opts{e} || "utf-8";
	binmode(STDOUT, ":encoding($enc)");
	binmode(STDERR, ":encoding($enc)");
	eval { binmode($DB::OUT, ":encoding($enc)"); };

	$infn = shift (@ARGV) || "JMdict";
	$outfn =  $::Opts{o} || "JMdict.pgi";
	$logfn =  $::Opts{l} || "jmparse.log";
	$::eid = 0;

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
				start_tag_handlers => {
				    entry => \&set_linenum},
				comments=>'process');

	  # Initialize global variables and open all the 
	  # temporary table files. 
	$tmpfiles = initialize ($logfn, $::Opts{t});

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

sub set_linenum { my ($t, $entry ) = @_;
	  # This function is set as a XML-Twig start-handler for <entry>
	  # tag, and remembers the line number at the start of an entry
	  # for use in error message or as a ent_seq number substitute 
	  # for JMnedict entries.
	$::Ln = $t->current_line(); }

sub entry_handler { my ($t, $entry ) = @_;
	  # This function is set as a XML-Twig handler for <entry> elements.
	  # We are called after a complete entry has been parsed including
	  # everthing inside it.  We do the entry-related bookkeeping stuff
	  # here, and call do_entry() to deal with the jmdict info contained
	  # in the entry.

	my ($seq, @x, $kmap, $rmap);

	  # $cntr counts the number of entries parsed.  The 1400 below was 
	  # picked to procude about 80 dots in the "progress bar" for a full
	  # jmdict.xml file.
	if (!($::cntr % 1400)) { print STDERR "."; } 
	$::cntr += 1;

	  # Get the entry's seq number.  jmnedict won't have a <ent_seq> element
	  # so executed inside an eval to trap the error.
	eval { $seq = ($entry->get_xpath("ent_seq"))[0]->text; };

	  # If there is no seq. number, use the entry's line number.  Save in
	  # a global variable so sub's can use in error messages.

	if (!$seq) { $seq = $::Ln; }
	$::Seq = $seq;	# For log messages.

	  # Check if we are past the -b seq number given by user.  If
	  # so, call do_entry() to process it.  And exit if we hsve processed
	  # the number of entry's given by -c.
	if (!$::started_at and (!$::Opts{b} or int($seq) >= int($::Opts{b}))) { 
	    $::processing = 1;  $::started_at = $::cntr }
	return if (! $::processing);
	if ($::Opts{c} and ($::cntr - $::started_at >= int($::Opts{c}))) {
	     die ("done\n"); }
	eval { do_entry ($seq, $entry, $::Opts{s}); };
	if ($@) {
	    print STDERR  "Seq $::Seq: $@";
	    print $::Flog "Seq $::Seq: $@"; }

	  # Free memory and other resorces used by the extry just processed.
	$t->purge; 0;}

sub comment_handler { my ($t, $entry ) = @_;
	  # Process each comment.  We get called when a comment is seen
	  # because  we were listed ('#COMMENT') in the twig_handlers option
	  # of the Twig->new() call in main().  We look for comments that
	  # described entry deletions and create synthetic 'D' status entries
	  # for them.

	my ($c, $seq, $notes, $dt, $ln, $srcid, $e); 
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
	$srcid = $KWSRC_jmdict;  # JMdict is only src with "deleted" comments.
	# (id,src,seq,stat,note)
	$e = {src=>$srcid, seq=>$seq, stat=>$KWSTAT_D};

	  # Should we create a synthetic N record before creating the D record?
	$notes = pgesc ($notes);
	# (entr,hist,stat,dt,who,diff,notes)
	$e->{_hist} = [{stat=>$KWSTAT_D, dt=>$dt, who=>"imported from JMdict.xml", notes=>$notes}];

	  # Write out the entry to the temp files.
	setkeys ($e, ++$::eid);
	wrentr ($e);
	  # Free memory and other resorces used by the extry just processed.
	$t->purge; 0; }

sub do_entry { my ($seq, $entry, $srcid) = @_;
	my (@x, $kmap, $rmap, @t, %fmap, $e);

	  # If this entry has a "trans" element then this is a JMnedict source.
	  # Otherwise assume it is JMdict.
	@t = $entry->get_xpath("trans");
	if (!$srcid) { $srcid = @t ? $KWSRC_jmnedict : $KWSRC_jmdict; }

	  # Create an entry record (a hash with the proper field names).
	  # We don't need to provide the id field since that will be
	  # automatically generated by setkeys(). 
	# (id,src,seq,stat,note)
	$e = {src=>$srcid, seq=>$seq, stat=>$KWSTAT_A};
	if (@x = $entry->get_xpath("k_ele")) { $kmap = do_kanj ($e, \@x, \%fmap); }
	if (@x = $entry->get_xpath("r_ele")) { $rmap = do_rdng ($e, \@x, $kmap, \%fmap); }
	if (@x = $entry->get_xpath("sense")) { do_sens ($e, \@x, $kmap, $rmap); }
	if (@t) 			     { do_sens ($e, \@t, $kmap, $rmap); }
	if (@x = $entry->get_xpath("info/dial"))  { do_dial ($e, \@x); }
	if (@x = $entry->get_xpath("info/lang"))  { do_lang ($e, \@x); }
	if (@x = $entry->get_xpath("info/audit")) { do_hist ($e, \@x); }
	mkfreqs (\%fmap);
	setkeys ($e, ++$::eid);
	wrentr ($e); }

sub do_kanj { my ($e, $keles, $fmap) = @_;
	my ($txt, $k, @x, %kmap, @flist, $ek);
	if (!$e->{_kanj}) { $e->{_kanj} = []; }
	foreach $ek (@$keles) {
	    $txt = ($ek->get_xpath ("keb"))[0]->text;
	    # (entr,kanj,txt)
	    $kmap{$txt} = $k = {txt=>$txt};
	    push (@{$e->{_kanj}}, $k);
	    if (@x = $ek->get_xpath ("ke_inf")) { do_kinfs ($k, \@x); }
	    if (@x = $ek->get_xpath ("ke_pri")) { do_freqs (0, $k, \@x, $fmap); } }
	return \%kmap; }

sub do_kinfs { my ($k, $kinfs) = @_;
	my ($i, $kw, $txt, %dupchk);
	if ($k->{_kinf}) { $k->{_kinf} = []; }
	foreach $i (@$kinfs) {
	    $txt = $i->text;
	    ($kw = $::JM2ID{KINF}{$txt}) or \
		die ("Unknown ke_inf text: /$txt/\n");
	    if ($kw >= 200) { print $::Flog "Seq $::Seq: deprecated kinf string '$txt'\n"; }
	    if ($dupchk{$kw}) { print $::Flog "Seq $::Seq: dupicate kinf string '$txt'\n"; }
	    else {
		$dupchk{$kw} = 1;
	        push (@{$k->{_kinf}}, {kw=>$kw}); } } }

sub do_rdng { my ($e, $reles, $kmap, $fmap) = @_;
	my ($txt, $r, $z, @x, %rmap, $er, $u);
	$e->{_rdng} = []; 
	foreach $er (@$reles) {
	    $txt = ($er->get_xpath ("reb"))[0]->text;
	    $rmap {$txt} = $r = {txt=>$txt};
	    # (entr,rdng,txt)
	    push (@{$e->{_rdng}}, $r);
	    if (@x = $er->get_xpath ("re_inf")) { do_rinfs ($r, \@x); }
	    if (@x = $er->get_xpath ("re_pri")) { do_freqs ($r, 0, \@x, $fmap); }
	    if ($er->get_xpath ("re_nokanji")) { 
	        my (@u); foreach $z (values (%$kmap)) { push ( @u, $z); }
		mkrestr ($r, $kmap, "_restr", \@u); }
	    elsif (@x = $er->get_xpath ("re_restr")) { do_restrs ($r, \@x, "_restr", $kmap); } }
	    return \%rmap; }

sub do_restrs { my ($arec, $restrele, $attrname, $bmap) = @_;
	my (@u, $u, $i);
	foreach $i (@$restrele) {
	    $u = $bmap->{$i->text};
	    if (!$u) { die ("Restriction target '$i->{text}' not found\n"); }
	    push (@u, $u); }
	mkrestr ($arec, $bmap, $attrname, \@u); }

sub do_rinfs { my ($r, $rinfs) = @_;
	my ($i, $kw, $txt, %dupchk);
	if ($r->{_rinf}) { $r->{_rinf} = []; }
	foreach $i (@$rinfs) {
	    $txt = $i->text;
	    ($kw = $::JM2ID{RINF}{$txt}) or \
		die ("Unknown re_inf text: /$txt/\n");
	    if ($kw >= 200) { print $::Flog "Seq $::Seq: deprecated rinf string '$txt'\n"; }
	    if ($dupchk{$kw}) { print $::Flog "Seq $::Seq: dupicate rinf string '$txt'\n"; }
	    else {
		$dupchk{$kw} = 1;
	        push (@{$r->{_rinf}}, {kw=>$kw}); } } }

sub do_sens { my ($e, $sens, $kmap, $rmap) = @_;
	my ($txt, $s, @x, @p, @pp, $z, %smap, %stagr, %stagk, $es);
	@pp=(); %smap=(); %stagr=(); %stagk=(); $e->{_sens} = [];
	foreach $es (@$sens) {
	    $txt = undef;
	    if (@x = $es->get_xpath ("s_inf")) { $txt = $x[0]->text; }
	    $s = {note=>$txt};
	    # (entr,sens,notes)
	    push (@{$e->{_sens}}, $s);
	    @p = $es->get_xpath ("pos");
	    if (!@p) { @p = @pp; }
	    if (@p) { do_pos ($s, \@p); @pp = @p; }
	    if (@x = $es->get_xpath ("misc"))      { do_misc   ($s, \@x); }
	    if (@x = $es->get_xpath ("field"))     { do_fld    ($s, \@x); }
	    if (@x = $es->get_xpath ("gloss"))     { do_gloss  ($s, \@x); }
	    if (@x = $es->get_xpath ("xref"))      { do_xref   ($s, \@x, $::JM2ID{XREF}{see}); }
	    if (@x = $es->get_xpath ("ant"))       { do_xref   ($s, \@x, $::JM2ID{XREF}{ant}); }
	    if (@x = $es->get_xpath ("name_type")) { do_pos    ($s, \@x); }
	    if (@x = $es->get_xpath ("trans_det")) { do_gloss  ($s, \@x); }
	    if (@x = $es->get_xpath ("stagr"))     { do_restrs ($s, \@x, "_stagr", $rmap); }
	    if (@x = $es->get_xpath ("stagk"))     { do_restrs ($s, \@x, "_stagk", $kmap); } } }

sub do_gloss { my ($s, $gloss) = @_;
	my ($g, $lang, $txt);
	$s->{_gloss} = [];
	foreach $g (@$gloss) {
	    $lang = undef; $lang = $g->att("g_lang");
	    $lang = $lang ? $::JM2ID{LANG}{$lang} : $::JM2ID{LANG}{"en"}; 
	    ($txt = $g->text) =~ s/\\/\\\\/go;
	    # (entr,sens,gloss,lang,txt,notes)
	    push (@{$s->{_gloss}}, {lang=>$lang, txt=>$txt}); } }

sub do_pos { my ($s, $pos) = @_;
	my ($i, $kw, $txt, %dupchk);
	$s->{_pos} = [];
	foreach $i (@$pos) {
	    $txt = $i->text;
	    ($kw = $::JM2ID{POS}{$txt}) or \
		die ("Unknown \'pos\' text: /$txt/\n");
	    if ($kw >= 200) { print $::Flog "Seq $::Seq: deprecated pos string '$txt'\n"; }
	    if ($dupchk{$kw}) { print $::Flog "Seq $::Seq: duplicate pos string '$txt'\n"; }
	    else {
		$dupchk{$kw} = 1;
	        push (@{$s->{_pos}}, {kw=>$kw}); } } }

sub do_misc { my ($s, $misc) = @_;
	my ($i, $kw, $txt, %dupchk);
	$s->{_misc} = [];
	foreach $i (@$misc) {
	    $txt = $i->text;
	    ($kw = $::JM2ID{MISC}{$txt}) or \
		die ("Unknown \'misc\' text: /$txt/\n");
	    if ($kw >= 200) { print $::Flog "Seq $::Seq: deprecated misc string '$txt'\n"; }
	    if ($dupchk{$kw}) { print $::Flog "Seq $::Seq: duplicate misc string '$txt'\n"; }
	    else {
		$dupchk{$kw} = 1;
	        push (@{$s->{_misc}}, {kw=>$kw}); } } }

sub do_fld { my ($s, $fld) = @_;
	my ($i, $kw, $txt, %dupchk);
	$s->{_fld} = [];
	foreach $i (@$fld) {
	    $txt = $i->text;
	    ($kw = $::JM2ID{FLD}{$txt}) or \
		die ("Unknown \'fld\' text: /$txt/\n");
	    if ($kw >= 200) { print $::Flog "Seq $::Seq: deprecated fld string '$txt'\n"; }
	    if ($dupchk{$kw}) { print $::Flog "Seq $::Seq: duplicate fld string '$txt'\n"; }
	    else {
		$dupchk{$kw} = 1;
	        push (@{$s->{_fld}}, {kw=>$kw}); } } }

sub do_dial { my ($e, $dial) = @_;
	my ($i, $kw, $txt, %dupchk);
	$e->{_dial} = [];
	foreach $i (@$dial) {
	    $txt = substr ($i->text, 0, -1);
	    ($kw = $::JM2ID{DIAL}{$txt}) or \
		die ("Unknown \'dial\' text: /$txt/\n");
	    if ($kw >= 200) { print $::Flog "Seq $::Seq: deprecated dial string '$txt'\n"; }
	    if ($dupchk{$kw}) { print $::Flog "Seq $::Seq: duplicate dial string '$txt'\n"; }
	    else {
		$dupchk{$kw} = 1;
	        push (@{$e->{_dial}}, {kw=>$kw}); } } }

sub do_lang { my ($e, $lang) = @_;
	my ($i, $kw, $txt, %dupchk);
	$e->{_lang} = [];
	foreach $i (@$lang) {
	    $txt = substr ($i->text, 0, -1);
	    ($kw = $::JM2ID{LANG}{$txt}) or \
		die ("Unknown \'lang\' text: /$txt/\n");
	    if ($kw >= 200) { print $::Flog "Seq $::Seq: deprecated lang string '$txt'\n"; }
	    if ($dupchk{$kw}) { print $::Flog "Seq $::Seq: duplicate lang string '$txt'\n"; }
	    else {
		$dupchk{$kw} = 1;
	        push (@{$e->{_lang}}, {kw=>$kw}); } } }

sub do_xref { my ($s, $xref, $xtypkw) = @_;
	my ($x, $t, $txt);
	foreach $x (@$xref) {
	    # (entr,sens,lang,txt,notes)
	    if (!$s->{_xrslv}) { $s->{_xrslv} = []; }
	    $t = jstr_classify ($x->text);
	    if ($t & $jmdict::KANJI) {
	        push (@{$s->{_xrslv}}, {typ=>$xtypkw, ktxt=>$x->text}); }
	    else {
		push (@{$s->{_xrslv}}, {typ=>$xtypkw, rtxt=>$x->text}); } } }

sub do_hist { my ($e, $hist) = @_;
	my ($x, $dt, $op, $h);
	foreach $x (@$hist) {
	    $dt = ($x->get_xpath ("upd_date"))[0]->text; # Assume just one.
	    $dt .= " 00:00:00-00";  # Add a time.
	    $op = ($x->get_xpath ("upd_detl"))[0]->text; # Assume just one.
	    if ($op eq "Entry created") {
		if (!$e->{_hist}) { $h = $e->{_hist} = []; } 
		# (entr,hist,stat,dt,who,diff,notes)
		push (@$h, {stat=>$KWSTAT_A, dt=>$dt, who=>"from JMdict.xml"}); }
	    else { die ("Unexpected <upd_detl> contents: $op"); } } }

sub do_freqs { my ($rdng, $kanj, $feles, $fmap) = @_;
	# Process a list of [kr]e_pri elements, by parsing each into a kwfreq
	# tag id number (scale), a scale value.  These two items and the reading
	# or kanji order number are added to list @$flist as a ref to 3-element
	# array. 

	my ($kw, $val, $kwstr, $f);
	foreach $f (@$feles) {
	    ($kw, $val, $kwstr) = parse_freq ($f->text, $f->name);  
	    if (!$fmap->{$kwstr}) { $fmap->{$kwstr} = [[],[]]; }
	    if ($rdng) { push (@{$fmap->{$kwstr}[0]}, $rdng); }
	    if ($kanj) { push (@{$fmap->{$kwstr}[1]}, $kanj); } } }

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

sub mkfreqs { my ($fhash) = @_;
	my ($r, $k, $v, $kw, $val, $kwstr, @rdngs, @kanjs, 
	    $frec, @flist, %dup_elim, $x, $t, $key);

	# %$fhash contains the pri element data collected while parsing 
	# one entry.
	# %$fhash's keys are the pri values as text strings (e.g. "ichi2")
	# that were found in the re_ele and ke_ele elements.
	# The value associated with each of these keys is a 2-element list where
	# the first element is a list of the rdng records that pri applies
	# to, and the second element is a list of the kanj records that pri
	# applies to.  Either (but not both) lists may have 0 elements.
	#
	# Our job is to generate "freq" table records for all the combinations
	# of rdng and kanj in each %$fhash item, eliminate duplicates having
	# the same (kw,rdng,kanj) values (choosing the one with the lowest 
	# $val is such case), then assigning these freq records to the rdng
	# and kanj records they belong to.

	while (($k, $v) = each (%$fhash)) {  # For each pri value...

	      # Parse the pri string into FREQ kw number and value number.
	      # Since it was parsed before in do_freqs() we know it is valid
	      # and needn't bother checking for errors here.
	    ($kw, $val, $kwstr) = parse_freq ($k);

	      # Get the rdng and kanj lists.
	    @rdngs = @{$v->[0]};  @kanjs = @{$v->[1]};

	    if (!@rdngs) {
		foreach $k (@kanjs) { push (@flist, [$kw, $val, undef, $k, $kwstr]); } }
	    elsif (!@kanjs) {
		foreach $r (@rdngs) { push (@flist, [$kw, $val, $r, undef, $kwstr]); } }
	    else {
		foreach $r (@rdngs) {
		    foreach $k (@kanjs) {
			 push (@flist, [$kw, $val, $r, $k, $kwstr]); } } } }

	for $x (@flist) {
	    ($kw, $val, $r, $k, $kwstr) = @$x;
	    $key = "$kw/$r/$k";
	    if ($dup_elim{$key}) {
		if ($val < $dup_elim{$key}->[1]) { 
		    $t = $dup_elim{$key};
		    $dup_elim{$key} = $x; 
		    print $::Flog "Seq $::Seq: duplicate pri '$kwstr' ignored, '$t->[4]'\n"; }
		else {
		    print $::Flog "Seq $::Seq: duplicate pri '$kwstr' ignored, '$x->[4]'\n"; } }
	    else { $dup_elim{$key} = $x; } }

	while (($k, $v) = each (%dup_elim)) {
	    ($kw, $val, $r, $k, $kwstr) = @$v;
	    $frec = {kw=>$kw, value=>$val};
	    if ($r) {
		if (!$r->{_freq}) { $r->{_freq} = []; } 
		push (@{$r->{_freq}}, $frec); }
	    if ($k) {
		if (!$k->{_freq}) { $k->{_freq} = []; } 
		push (@{$k->{_freq}}, $frec); } } } 

sub mkrestr { my ($a, $bmap, $attrname, $pos) = @_;
	# %$a -- A rdng or sens record that has restrictions.
	# @$pos -- An array containing refs to allowed restriction records.
	#    items.
	# %$bmap -- A hash, indexed by txt field, to the set of all possible
	#    restriction items.  For example, foe "restr" restrictions this
	#    would be a map of the entry's kanj records.
	# $attrname -- Name of the key used for the restr list for both "a"
	#    and "b" records.

	my ($v, $u, $restr_rec, $found);
	foreach $b (values (%$bmap)) {
	    $found = 0;
	    foreach $u (@$pos) {
		next if ($b != $u);
		$found = 1; }
	    if (!$found) {
		$restr_rec = {};
		if (!$a->{$attrname}) { $a->{$attrname} = []; }
		if (!$b->{$attrname}) { $b->{$attrname} = []; }
		push (@{$a->{$attrname}}, $restr_rec);
		push (@{$b->{$attrname}}, $restr_rec); } } } 

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
jmparse.pl reads a jmdict xml file such as JMdict or JMnedict and
creates a file that can be subsequently processed by jmload.pl them
loaded into a jmdict Postgresql database.

Usage: jmparse.pl [-s srcid] [-o output-filename] 
		      [-c entry-count] [-b start-seq-num] \\  
		      [-k]  [-l logfile] [-t tempfile-dir] \\
		      [-e encoding] \\
		      [xml-filename]

Arguments:
	xml-filename -- Name of input jmdict xml file.  Default 
	  is "JMdict".
Options:
	-h -- (help) print this text and exit.
	-o output-filename -- Name of output postgresql dump file. 
	    Default is "JMdict.dmp"
	-s srcid -- Number that will be for entries' src id, 1 for
	`   JMdict entries, 2 for JMnedict entries.  If not given,
	    jmparse will attempt to determine automatically on
	    an entry-by-entry basis by looking for a <trans> element.
	-c entry-count -- Number of entries to process.
	-b begin-seq-num -- Sequence number of first entry to process.
	-k -- (keep) do not delete temporary files.
	-e encoding -- Encoding to use when writing messages to stderr
	    and stdout.  Default is "utf-8".
	-l logfile -- Name of file to write log messages to.  Default 
	    is "jmparse.log".
	-t dir -- Directory in which to create the temp files.  
	    Default is the current directory.

EOT
	exit $exitstat; }
