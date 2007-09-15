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
	    $user, $pw, $dbname, $host, $corpid, $corpkw);

	getopts ("o:c:s:b:e:l:t:g:kyh", \%::Opts) || usage (1);
	if ($::Opts{h}) { usage (0); }
	$enc = $::Opts{e} || "utf-8";
	if ($::Opts{g}) { $::Opts{g} = $::JM2ID{LANG}{$::Opts{g}}; }
	binmode(STDOUT, ":encoding($enc)");
	binmode(STDERR, ":encoding($enc)");
	eval { binmode($DB::OUT, ":encoding($enc)"); };

	$infn = shift (@ARGV) || "JMdict";
	$outfn =  $::Opts{o} || "JMdict.pgi";
	$logfn =  $::Opts{l} || "jmparse.log";

	($corpid, $corpkw) = split (/\./, $::Opts{s});
	$::Corpus = {id=>$corpid, kw=>$corpkw};
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
	if ($::Corpus->{kw}) { 
	    if    ($::Corpus->{kw} eq "jmdict")   { $::Corpus->{seq} = "seq_jmdict"; }
	    elsif ($::Corpus->{kw} eq "jmnedict") { $::Corpus->{seq} = "seq_jmnedict"; }
	    else  { $::Corpus->{seq} = "seq"; }
	    wrcorp ($::Corpus); }
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

        die "No corpus id available, rerun with -s option.\n" if (!$::Corpus->{id});

	  # $cntr counts the number of entries parsed.  The 1400 below was 
	  # picked to procude about 80 dots in the "progress bar" for a full
	  # jmdict.xml file.
	if (!($::cntr % 1500)) { print STDERR "."; } 
	$::cntr += 1;

	  # Get the entry's seq number.  jmnedict won't have a <ent_seq> element
	  # so executed inside an eval to trap the error.
	eval { $seq = int(($entry->get_xpath("ent_seq"))[0]->text); };

	  # If there is no seq. number, use the entry's line number.  Save in
	  # a global variable so sub's can use in error messages.

	if (!$seq) { $seq = $::Ln; }
	if ($::Seq && $seq<=$::Seq) {
	    print $::Flog "Seq $seq: Entry out of order, preceeding entry was $::Seq\n"; }
	$::Seq = $seq;	# For log messages.

	  # Check if we are past the -b seq number given by user.  If
	  # so, call do_entry() to process it.  And exit if we hsve processed
	  # the number of entry's given by -c.
	if (!$::started_at and (!$::Opts{b} or int($seq) >= int($::Opts{b}))) { 
	    $::processing = 1;  $::started_at = $::cntr }
	return if (! $::processing);
	if ($::Opts{c} and ($::cntr - $::started_at >= int($::Opts{c}))) {
	     die ("done\n"); }
	eval { do_entry ($seq, $entry, $::Corpus->{id}); };	
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

	my ($c, $seq, $notes, $dt, $ln, $srcid, $e, $srcid, $srckw, $srcdt); 
	$c = $entry->{comment};
	if (!$::processing) {
	    if ($c =~ m/(\S+) created:\s*(\d+-\d+-\d+)/i) {
		if (!$::Corpus->{kw}) { 
		    $::Corpus->{kw} = lc($1); 
		    if (!$::Corpus->{dt}) { $::Corpus->{dt} = $2; } }
		if (!$::Corpus->{id}) {
		    if ($::Corpus->{kw} eq "jmdict") { $::Corpus->{id} = 1; }
		    if ($::Corpus->{kw} eq "jmnedict") { $::Corpus->{id} = 2; } } }
	    return; }

	if ($c =~ m/^\s*Deleted:\s*(\d{7}) with (\d{7})\s*(.*)/) {
	    $seq = $1; $notes = "Merged into $2";
	    if ($3) { $notes .= "\n" . $3; } }
	elsif ($c =~ m/^\s*Deleted:\s*(\d{7})\s*(.*)/) {
	    $seq = $1; if ($2) { $notes = $2; } }
	else { 
	    $ln = $t->current_line();
	    print $::Flog "Line $ln: unparsable comment: $c\n"; return; }

	$dt = "1990-01-01 00:00:00-00";
	die "No corpus id available, rerun with -s option.\n" if (!$::Corpus->{id});
	# (id,src,stat,seq,dfrm,unap,notes)
	$e = {src=>$::Corpus->{id}, seq=>$seq, stat=>$KWSTAT_D, unap=>0};

	  # Should we create a synthetic N record before creating the D record?
	if ($notes) { $notes = pgesc ($notes); }
	
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

	  # Create an entry record (a hash with the proper field names).
	  # We don't need to provide the id field since that will be
	  # automatically generated by setkeys(). 
	# (id,src,stat,seq,dfrm,unap,notes)
	$e = {src=>$srcid, stat=>$KWSTAT_A, seq=>$seq, dfrm=>undef, unap=>0};
	if (@x = $entry->get_xpath("k_ele")) { $kmap = do_kanj ($e, \@x, \%fmap); }
	if (@x = $entry->get_xpath("r_ele")) { $rmap = do_rdng ($e, \@x, $kmap, \%fmap); }
	if (@x = $entry->get_xpath("sense")) { do_sens ($e, \@x, $kmap, $rmap); }
	if (@t) 			     { do_sens ($e, \@t, $kmap, $rmap); }
	if (@x = $entry->get_xpath("info/audit")) { do_hist ($e, \@x); }
	mkfreqs (\%fmap);
	die ("Has no senses") if (scalar (!$e->{_sens} or !@{$e->{_sens}}));
	die ("Has no readings") if (scalar (!$e->{_rdng} or !@{$e->{_rdng}}));
	setkeys ($e, ++$::eid);
	wrentr ($e); }

    sub do_kanj { my ($e, $keles, $fmap) = @_;
	my ($txt, $k, @x, %kmap, @flist, $ek);
	if (!$e->{_kanj}) { $e->{_kanj} = []; }
	foreach $ek (@$keles) {
	    $txt = ($ek->get_xpath ("keb"))[0]->text;
	    if ($kmap{$txt}) { 
		print $::Flog "Seq $::Seq: duplicate keb element: '$txt'\n";
		next; }
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
	    if (!($kw = $::JM2ID{KINF}{$txt})) {
		print $::Flog "Seq $::Seq: unknown ke_inf text: '$txt'\n";
		next; }
	    if ($dupchk{$kw}) { 
		print $::Flog "Seq $::Seq: duplicate kinf string '$txt'\n"; 
		next; }
	    else {
		$dupchk{$kw} = 1;
	        push (@{$k->{_kinf}}, {kw=>$kw}); } } }

    sub do_rdng { my ($e, $reles, $kmap, $fmap) = @_;
	my ($txt, $r, $z, @x, %rmap, $er, $u);
	$e->{_rdng} = []; 
	foreach $er (@$reles) {
	    $txt = ($er->get_xpath ("reb"))[0]->text;
	    if ($rmap{$txt}) { 
		print $::Flog "Seq $::Seq: duplicate reb element: '$txt'\n";
		next; }
	    $rmap{$txt} = $r = {txt=>$txt};
	    # (entr,rdng,txt)
	    push (@{$e->{_rdng}}, $r);
	    if (@x = $er->get_xpath ("re_inf")) { do_rinfs ($r, \@x); }
	    if (@x = $er->get_xpath ("re_pri")) { do_freqs ($r, 0, \@x, $fmap); }
	    if ($er->get_xpath ("re_nokanji")) { 
		mkrestr ($r, $kmap, "_restr", []); }
	    elsif (@x = $er->get_xpath ("re_restr")) { do_restrs ($r, \@x, "_restr", $kmap); } }
	return \%rmap; }

    sub do_restrs { my ($arec, $restrele, $attrname, $bmap) = @_;
	my (@u, $u, $i, $txt);
	foreach $i (@$restrele) {
	    $txt = $i->text;
	    $u = $bmap->{$txt};
	    if (!$u) { 
		print $::Flog "Seq $::Seq: restriction target '$txt' not found\n";
		next; }
	    push (@u, $u); }
	mkrestr ($arec, $bmap, $attrname, \@u); }

    sub do_rinfs { my ($r, $rinfs) = @_;
	my ($i, $kw, $txt, %dupchk);
	if ($r->{_rinf}) { $r->{_rinf} = []; }
	foreach $i (@$rinfs) {
	    $txt = $i->text;
	    if (!($kw = $::JM2ID{RINF}{$txt})) {
		print $::Flog "Seq $::Seq: unknown re_inf text: '$txt'\n";
		next; }
	    if ($dupchk{$kw}) { 
		print $::Flog "Seq $::Seq: dupicate rinf string '$txt'\n"; 
		next; }
	    else {
		$dupchk{$kw} = 1;
	        push (@{$r->{_rinf}}, {kw=>$kw}); } } }

    sub do_sens { my ($e, $sens, $kmap, $rmap) = @_;
	my ($txt, $s, @x, @p, @pp, $z, %smap, %stagr, %stagk, $es, $cntr);
	@pp=(); %smap=(); %stagr=(); %stagk=(); $e->{_sens} = [];
	foreach $es (@$sens) {
	    $txt = undef;  ++$cntr;
	    if (@x = $es->get_xpath ("s_inf")) { $txt = $x[0]->text; }
	    $s = {notes=>$txt};
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
	    if (@x = $es->get_xpath ("stagk"))     { do_restrs ($s, \@x, "_stagk", $kmap); }
	    if (@x = $es->get_xpath ("dial"))      { do_dial   ($s, \@x); }
	    if (@x = $es->get_xpath ("lsource"))   { do_lsrc   ($s, \@x); }
	    # (entr,sens,notes)
	    if ($s->{_gloss} && scalar (@{$s->{_gloss}}) > 0) { push (@{$e->{_sens}}, $s); }
	    else {
		# This sense has no glosses,
		# If running with -g, this is normal so don't log 
		# them.  Otherwise something is amiss.
		if (!$::Opts{g}) {
		    print $::Flog "Seq $::Seq: No glosses found in sense $cntr\n"; } } } }

    sub do_gloss { my ($s, $gloss) = @_;
	my ($g, $lang, $lng, $txt, $lit, $trans, @lit, %dupchk);
	$s->{_gloss} = [];
	foreach $g (@$gloss) {
	    $lng = $g->att("xml:lang");
	    $lang = $lng ? $::JM2ID{LANG}{$lng} : $KWLANG_en;
	    if (!$lang && $lng) { 
		print $::Flog "Seq $::Seq: invalid lang attribute '$lng'\n"; 
		next;}
	    ($txt = $g->text) =~ s/\\/\\\\/go;
	    $lit = $trans = "";
	    if ($::Opts{y} and $txt =~ m/(lit:)|(trans:)/) { 
		($txt,$lit,$trans) = extract_lit ($txt); }
	    if ($dupchk{"${lang}_$txt"}) { 
		print $::Flog "Seq $::Seq: duplicate lang/text in gloss '$lang/$txt'\n";
		next; }
	    else { $dupchk{"${lang}_$txt"} = 1; }
	    # (entr,sens,gloss,lang,txt)
	    if ((!$::Opts{g} or $::Opts{g}=$lang) and $txt) {
	        push (@{$s->{_gloss}}, {lang=>$lang, ginf=>$KWGINF_equ, txt=>$txt}); }
	    if ($lit) {
	        push (@lit, [$lang, $lit]); }	# Save and write after all reg. glosses.
	    if ($trans) {
	        push (@{$s->{_lsrc}}, {lang=>$KWLANG_en, txt=>$trans, part=>0, wasei=>1}); } }
	foreach $lit (@lit) {
	    push (@{$s->{_gloss}}, {lang=>$lit->[0], ginf=>$KWGINF_lit, txt=>$lit->[1]}); } }

    sub do_pos { my ($s, $pos) = @_;
	my ($i, $kw, $txt, %dupchk);
	$s->{_pos} = [];
	foreach $i (@$pos) {
	    $txt = $i->text;
	    if (!($kw = $::JM2ID{POS}{$txt})) {
		print $::Flog "Seq $::Seq: unknown pos text: '$txt'\n"; 
		next; }
	    if ($dupchk{$kw}) { 
		print $::Flog "Seq $::Seq: duplicate pos string '$txt'\n";
		next; }
	    else {
		$dupchk{$kw} = 1;
	        push (@{$s->{_pos}}, {kw=>$kw}); } } }

    sub do_misc { my ($s, $misc) = @_;
	my ($i, $kw, $txt, %dupchk);
	$s->{_misc} = [];
	foreach $i (@$misc) {
	    $txt = $i->text;
	    if (!($kw = $::JM2ID{MISC}{$txt})) {
		print $::Flog "Seq $::Seq: unknown misc text: '$txt'\n";
		next; }
	    if ($dupchk{$kw}) { 
		print $::Flog "Seq $::Seq: duplicate misc string '$txt'\n";
		next; }
	    else {
		$dupchk{$kw} = 1;
	        push (@{$s->{_misc}}, {kw=>$kw}); } } }

    sub do_fld { my ($s, $fld) = @_;
	my ($i, $kw, $txt, %dupchk);
	$s->{_fld} = [];
	foreach $i (@$fld) {
	    $txt = $i->text;
	    if (!($kw = $::JM2ID{FLD}{$txt})) {
		print $::Flog "Seq $::Seq: unknown fld text: '$txt'\n";
		next; }
	    if ($dupchk{$kw}) { 
		print $::Flog "Seq $::Seq: duplicate fld string '$txt'\n";
		next; }
	    else {
		$dupchk{$kw} = 1;
	        push (@{$s->{_fld}}, {kw=>$kw}); } } }

    sub do_dial { my ($s, $dial) = @_;
	my ($i, $kw, $txt, %dupchk);
	$s->{_dial} = [];
	foreach $i (@$dial) {
	    $txt = $i->text;
	    if (substr ($txt, -1) eq ":") { $txt = substr ($txt, 0, -1); }
	    else { print $::Flog "Seq $::Seq: missing dialect colon: '$txt'\n"; }
	    if (!($kw = $::JM2ID{DIAL}{$txt})) {
		print $::Flog "Seq $::Seq: unknown dial text: '$txt'\n";
		next; }
	    if ($dupchk{$kw}) { 
		print $::Flog "Seq $::Seq: duplicate dial string '$txt'\n";
		next; }
	    else {
		$dupchk{$kw} = 1;
	        push (@{$s->{_dial}}, {kw=>$kw}); } } }

    sub do_lsrc { my ($s, $lsrc) = @_;
	my ($i, $kw, $txt, $lang, $lng, $lskw, $kw, %dupchk);
	$s->{_lsrc} = [];
	foreach $i (@$lsrc) {
	    $txt = $i->text;  
	    $lang = $::JM2ID{LANG}{($lng=$i->att("xml:lang")) || "en"};
	    if (!$lang) { 
		print $::Flog "Seq $::Seq: invalid lsource lang attribute '$lng'\n";
		next; }
	    $kw = $::JM2ID{LSRC}{($lskw=$i->att("ls_type")) || "full"};
	    if (!$kw) { 
		print $::Flog "Seq $::Seq: invalid lsource type attribute '$lskw'\n";
		next; }
	    if ($kw != 1 and !$txt ) { 
		print $::Flog "Seq $::Seq: non-default lsource type '$lskw' and no text\n";
		next; }
	    push (@{$s->{_lsrc}}, {lang=>$lang, txt=>$txt, part=>($kw==2?1:0), wasei=>0} ); } }

    sub do_xref { my ($s, $xref, $xtypkw) = @_;
	my ($x, $txt, @frags, $frag, $ktxt, @ktxt, $rtxt, @rtxt, $jtyp, $snum, $kflg);

	  # Create a xresolv record for each <xref> element.  The xref may
	  # contain a kanji string, kana string, or kanji.\x{30fb}kana.  
	  # (\x{30fb} is a mid-height dot.)  It may optionally be followed
	  # by a \x{30fb} and a sense number.
	  # Since jmdict words may also contain \x{30fb} as part of their
	  # kanji or reading text we try to handle that by ignoring the 
	  # \x{30fb} between two kana strings, two kanji strings, or a
	  # kana\x{30fb}kanji string.  Of course is a jmdict word is 
	  # kanji\x{30fb}kana then we're out of luck, it's ambiguous.

	foreach $x (@$xref) {
	    $txt = $x->text; @ktxt=(); @rtxt=(); $kflg = 0; $snum = undef;

	      # Split the xref text on the separator character.

	    @frags = split ("\x{30fb}", $txt);

	      # Check for a sense number in the rightmost fragment.
	      # But don't treat it as a sense number if it is the 
	      # only fragment (which will leave us without any kana
	      # or kanji text which will fail when loading xresolv.
 
	    if ($#frags > 0 && $frags[$#frags] =~ /^\d+$/) {
		$snum = pop (@frags); }

	      # Go through all the fragments, from right to left.
	      # For each, if it has no kanji, push it on the @rtxt 
	      # list.  If it has kanji, and every fragment thereafter
	      # regardless of its kana/kanji status, push on the @ktxt
	      # list.  $kflg is set to true when we see a kanji word
	      # to make that happen.
	      # We could do more checking here (that entries going
	      # into @rtxt are kana for, example) but don't bother 
	      # since, as long as the data loads into xresolv ok, 
	      # wierd xrefs will be found later by being unresolvable.

	    while ($frag = pop (@frags)) {
		if (!$kflg) { $jtyp = jstr_classify ($frag); }
		if ($kflg || ($jtyp & $jmdict::KANJI)) {
		    push (@ktxt, $frag);
		    $kflg = 1; }
		else { push (@rtxt, $frag); } }

	      # Put the kanji and kana parts back together into
	      # strings, and write the xresolv resord.

	    $ktxt = join ("\x{30fb}", @ktxt) || undef;
	    $rtxt = join ("\x{30fb}", @rtxt) || undef;
	    if (!$s->{_xrslv}) { $s->{_xrslv} = []; }
	    push (@{$s->{_xrslv}}, {typ=>$xtypkw, ktxt=>$ktxt, rtxt=>$rtxt, tsens=>$snum}); } } 

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
	    else { 
		print $::Flog "Seq $::Seq: Unexpected <upd_detl> contents: $op"; } } }

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
	($kw = $::JM2ID{FREQ}{$kwstr}) or die ("Unrecognized $ptype string: '$fstr'\n");
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
	# Create restriction records for %$bmap items that are not
	# found in @$pos.
	#
	# %$a -- A rdng or sens record.
	# %$bmap -- A hash, indexed by txt field, to the set of all
	#    possible restriction items (which will be kanj records
	#    for restr or stagk restrictions or rdng records for stagr
	#    restrictions.  The value of each element is the record
	#    with that key text.  For example, for "restr" restrictions,
	#    each item in this hash will be keyed by the 'txt' field of
	#    a kanji record, and each value would be a ref to the kanji
	#    record itself (which in turn is a hashref with only a single
	#    item with the key 'txt'.)  We ask for a hash indexed by field
	#    'txt' here, rather than actual record list, in order to speed
	#    up lookups of matching txt values.  This hash will typically
	#    be created by the caller once per entry and then used in
	#    multiple calls to mkrestr() (one for each reading with
	#    restrictions.)
	# $attrname -- Name of the key used for the generated restr list.
	#    An attribute of this name with be created in both %$a and in
	#    each restricting item in %{%$bmap->{text}} item (which for
	#    restr items will be each restricting kanj row).  The attributes
	#    will contain a list of restriction records, which are simply
	#    empty hashes.  (Empty because they contain no information 
	#    other than who their parents are, and that info will be filled
	#    in later, when the entry is written out.)
	# @$pos -- An array containing refs to allowed restriction records.
	#    items.  For 'restr' items for example, this would be a list of
	#    the "restr" text strings parsed from the xml file.
	#
	# mkrestr() creates restriction records and attaches them to
	# the appropriate parent records.  Restrictions are created 
	# for every text item in %$bmap *not* found in @$pos.  In the
	# case or restr restrictions, %$bmap contains the entry's full
	# set of kanj records (already created by previously parsing
	# the XML <k_ele> items), and @$pos, the text's of the restrictions
	# given in the XML <restr> elements.  The <restr> elmements give
	# "allowed" reading-kanji combinations but the database stores
	# "disallowed" combinations which is why we do the set difference
	# (%$bmap - @$pos) operation.
	# 
	# Note that each created restriction record will be simply an
	# empty hash, but will be referenced twice, once from the 
	# %$a item's _restr (or _stagr or _stagk) list, and once from 
	# a %$bmap value's (which is a ref to a kanj or rdng record)
	# _restr (or ...) list.  The restriction records apperance in 
	# these lists is all that is needed to create that correct
	# database record later; no other info is needed which is why
	# the hash respresenting the restriction list item is empty.

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

    sub extract_lit { my ($txt) = @_;
	my ($lit, $trans) = ("", "");
	if ($txt =~ s/\s*\(lit:\s*([^)]*)\)\s*/ /) { $lit = $1; }
	elsif ($txt =~ s/\s*\(trans:\s*([^)]*)\)\s*/ /) { $trans = $1; }
	elsif ($txt =~ s/^lit:\s*(.*)//) { $lit = $1; }
	elsif ($txt =~ s/^trans:\s*(.*)//) { $trans = $1; }
	$txt =~ s/^\s+//; $txt =~ s/\s+$//;
	return ($txt, $lit, $trans); }


    sub usage { my ($exitstat) = @_;
	print <<EOT;
jmparse.pl reads a jmdict xml file such as JMdict or JMnedict and
creates a file that can be subsequently processed by jmload.pl them
loaded into a jmdict Postgresql database.

Usage: jmparse.pl [-s srcid] [-o output-filename] 
		      [-c entry-count] [-b start-seq-num] \\  
		      [-y] [-k] [-l logfile] [-t tempfile-dir] \\
		      [-e encoding] \\
		      [xml-filename]

Arguments:
	xml-filename -- Name of input jmdict xml file.  Default 
	  is "JMdict".
Options:
	-h -- (help) print this text and exit.
	-o output-filename -- Name of output postgresql dump file. 
	    Default is "JMdict.dmp"
	-b begin-seq-num -- Sequence number of first entry to process.
	-c entry-count -- Number of entries to process.
	-s id[.kw] -- 'id' is a corpus id number (between 1 and 32767), 
	    'kw' a short text string giving a corpus abbreviaion.
	    If only 'id' is given, a kwsrc record with that id will
	    be assumed to exist, and entry records generated by this
	    program will use that id.
	    If both 'id' and 'kw' are given. a new kwsrc record will
	    be generated and entry records generated by this program 
	    will use the new record.
	    If -s is not given, jmparse.pl will attempt to determine
	    if the input file is a JMdict or JMnedict file and will 
	    use "1.jmdict" and "2.jmnedict" accordingly.
	    If the form "id.kw" is used, or -s is not given, and
	    jmparse,pl is able to find a "...created" comment in the
	    input file, the date from that comment will be used in 
	    the kwsrc record. 
	-g lang -- Include only gloss tag with language code 'lang'.
	    If not given default is to include all glosses regardless
	    of language.
	-y -- Extract literal and trans information from glosses.
	-k -- (keep) do not delete temporary files.
	-e encoding -- Encoding to use when writing messages to stderr
	    and stdout.  Default is "utf-8".
	-l logfile -- Name of file to write log messages to.  Default 
	    is "jmparse.log".
	-t dir -- Directory in which to create the temp files.  
	    Default is the current directory.

EOT
	exit $exitstat; }
