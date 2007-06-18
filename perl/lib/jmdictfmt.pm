#######################################################################
#   This file is part of JMdictDB. 
#   Copyright (c) 2007 Stuart McGraw 
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

# Functions for working with edict-formatted data.

package jmdictfmt;
use strict; use warnings;
use jmdict;

BEGIN {
    use Exporter(); our (@ISA, @EXPORT_OK, @EXPORT); @ISA = qw(Exporter);
    @EXPORT = qw(fmt_entr jel_entr jel_rdngs jel_kanjs jel_senss jel_kanj
		 jel_rdng jel_sens jel_entr jel_entrhdr); }

our(@VERSION) = (substr('$Revision$',11,-2), \
	         substr('$Date$',7,-11));

#-----------------------------------------------------------------------

    sub fmt_entr { my ($e) = @_;
	# Print an entry.
	# $e -- Reference to an entry hash.

	my (@x, $x, $s, $n, $stat, $src, $id, $seq, $fmtstr);

	  # $e->{stat} is the value of the "stat" column 
	  # for this entry.  It is a number that corresponds
	  # to the id number of a row in table kwstat.
	  # To convert it to a keyword string, we look the 
	  # number up in the STAT section of the kw table 
	  # data structure in $::KW.
	$stat = $e->{stat} ? ("[" . $::KW->{STAT}{$e->{stat}}{kw} . "]") : "";
	$src =  $e->{src}  ? ("(" . $::KW->{SRC}{$e->{src}}{kw} . ")") : "";
	$seq =  $e->{seq}  ? ("{" . $e->{seq} . "}") : "";
	$id =   $e->{id}   ? $e->{id} : "";
	  # Print basic info about the entry (seq num, status, and id number.)
	$fmtstr = "\nEntry " . join (" ", ($seq, $stat, $id));

	  # Print a list of dialects if there are any.
	  # The map() call will return a list created from its first 
	  #   argument by setting $_ in it, to each element the second
	  #   argument (the list of dialects) in turn.  
	  # The first arg is $::KW->{DIAL}{$_->{kw}}{kw}.
	  # $::KW->{DIAL} is the section of $::KW that contains dialect
	  #   info from table kwdial.  
	  # $_ an element from the dialects list in @{$e->{_dial}} 
	  #   (which is a record from table "dial").
	  # $_->{kw} is the value in the kw column of that record (and
	  #   is a number that references the id column of the kwdial
	  #   table.)
	  # $::KW->{DIAL}{$_->{kw}} looks that number up in (effectively)
	  #   the kwdial table, and give the kwdial record (a hash ref).
	  # $::KW->{DIAL}{$_->{kw}}{kw} selects the value of the 'kw' 
	  #   column of that record.  This is a short string.
	  # The output of map is a list of these strings.
	  # The join() call turns that list into a comma delimited 
	  #   string.

	  # Print entry notes if any.

	$fmtstr .= "\n";
	$fmtstr .= "  Notes: $e->{_notes}\n" if ($e->{_notes}) ;

	  # For every kanji record in the entry, call f_kanj() on 
	  # to foemat it into a string (along with any kinf or freq
	  # info).  Then join those strings together with ";" chars
	  # and print.

	$n = 0;
	@x = map (f_kanj($_, ++$n), @{$e->{_kanj}});
	if (@x) { $fmtstr .= ("Kanji: " . join ("; ", @x) . "\n"); }

	  # Do the same for the reading records.  However, the entry's
	  # kanji records are given to f_rdng() which needs them to
	  # properly handle any restr restrictions.

	$n = 0;
	@x = map (f_rdng($_, ++$n, $e->{_kanj}), @{$e->{_rdng}});
	if (@x) { $fmtstr .= ("Readings: " . join ("; ", @x) . "\n"); }

	  # Now go through an process each sense in the entry.

	$n = 0;
	foreach $s (@{$e->{_sens}}) {

	      # Format and print the sense's data.  In order to do
	      # that, p_sens() needs to have the sense record,
	      # the sense number, and the sets of reading and 
	      # kanji records for the entry, in order to properly
	      # handle any stagr or stagk restrictions.

	    $fmtstr .= p_sens ($s, ++$n, $e->{_kanj}, $e->{_rdng}); }

	  # Rather than printing the audio record info when printing
	  # the reading in which it occurs, we print them all out here
	  # at the end.  Grep out the audio records from the readings
	  # and print them if any.

	@x = grep ($_->{_audio}, @{$e->{_rdng}});
	if (@x) { $fmtstr .= p_audio (\@x); }

	  # If there are any hist records, print them.

	if ($e->{_hist}) { $fmtstr .= p_hist ($e->{_hist}); }
	return $fmtstr; } # owarimashita.

#-----------------------------------------------------------------------

    sub f_kanj { my ($k, $n) = @_;
	# Format a kanj record %$k.  
	# Return string with the formatted info.

	my ($txt, @f);
	$txt = $k->{txt};
	if (!$k->{kanj}) { $k->{kanj} = $n; }

	  # Create a list of this kanji's kinf strings.

	@f = map ($::KW->{KINF}{$_->{kw}}{kw}, @{$k->{_kinf}});

	  # Convert the list of numeric freq/value items in
	  # @{$k->{_kfreq}} to a list of keyword/value strings,
	  # and add it to the kinf list.

	push (@f, map ($::KW->{FREQ}{$_->{kw}}{kw}."$_->{value}", @{$k->{_kfreq}}));

	  # Join together with commas and enclose in brackets.

	($txt .= "[" . join (",", @f) . "]") if (@f);

	  # Prepend the kanji number.

	$txt = "$k->{kanj}.$txt";
	return $txt; }

#-----------------------------------------------------------------------

    sub f_rdng { my ($r, $n, $kanj) = @_;
	my ($txt, @f, $restr, $klist);

	  # Get the reading's text.

	$txt = $r->{txt};  
	if (!$r->{rdng}) { $r->{rdng} = $n; }

	  # If $r->{_restr} is logically true, then this reading 
	  # is restricted to certian kanj.  

	if ($kanj and ($restr = $r->{_restr})) {  # That's '=', not '=='.

	      # If the number of restr elements is the same as the 
	      # number of kanji, then no kanji are valid for this
	      # reading.

	    if (scalar (@$restr) == scalar (@$kanj)) { $txt .= "\x{3010}no kanji\x{3011}"; }
	    else {

		  # Otherwise the kanj that are valid are the
		  # set of all the kanji, minus the invalid
		  # ones.  We use jmdict::filt() to do this 
		  # set difference operation.  Filt() will return
		  # a list of all the kanj records in %$kanj that
		  # are not in %$restr.  In-ness is dtermined by 
		  # comparing the value of the "kanj"-keyed element
		  # of each kanj record, with the "kanj"-keyed 
		  # element of each restr record.

		$klist = filt ($kanj, ["kanj"], $restr, ["kanj"]);

		  # Take the remaining kanji records, get the txt, 
		  # join together into a string, enclose in brackets,
		  # and tack onto the end of the reading text.

		$txt .= "\x{3010}" . join ("; ", map ($_->{txt}, @$klist)) . "\x{3011}"; } }

	  # Create a list of this reading's rinf strings.

	@f = map ($::KW->{RINF}{$_->{kw}}{kw}, @{$r->{_rinf}});

	  # Convert the list of numeric freq/value items in
	  # @{$r->{_rfreq}} to a list of keyword/value strings,
	  # and and the to the rinf list.

	push (@f, map ($::KW->{FREQ}{$_->{kw}}{kw}."$_->{value}", @{$r->{_rfreq}}));

	  # Join the rinf/rfreq strings together with commas, 
	  # enclose in brackets, and combine with the reading text.

	($txt .= "[" . join (",", @f) . "]") if (@f);

	  # Prepend the reading number.

	$txt = "$r->{rdng}.$txt";

	# owarimashita.
	return $txt; }

#-----------------------------------------------------------------------

    sub p_sens { my ($s, $n, $kanj, $rdng) = @_;
	# Print a sense.
	# $s -- Reference to a sense structure.
	# $n -- Sense number.
	# @$kanj -- List of kanj records for this sense's entry,  
	# @$rdng -- List of rdng records for this sense's entry,  

	my ($pos, $misc, $fld, $restrs, $lang, $g, @r, $gnum,
		$stagr, $stagk, @dl, $dl, $ginf, $fmtstr);

	if (!$s->{sens}) { $s->{sens} = $n; }

	  # Get a text string list of the sense's PoS abbreviations.

	$pos = join (",", map ($::KW->{POS}{$_->{kw}}{kw}, @{$s->{_pos}}));
	if ($pos) { $pos = "[$pos]"; }

	  # Get a text string list of the sense's misc abbreviations.

	$misc = join (",", map ($::KW->{MISC}{$_->{kw}}{kw}, @{$s->{_misc}}));
	if ($misc) { $misc = "[$misc]"; }

	  # Get a text string list of the sense's field abbreviations.

	$fld = join (",", map ($::KW->{FLD}{$_->{kw}}{kw}, @{$s->{_fld}}));
	if ($fld) { $fld = " $fld term"; }

	  # If there are any stagr or stagk restrictions we will
	  # list them.  Like the treatment of restr in f_rdng(), 
	  # we use filt() to subtract the set of invalid sens-kanji
	  # (reading) combinations given in @$stagk (@$stagr) from
	  # the full set of kanji (readings) in @$kanj (@$rdng). 
	  # The difference is the allowed combinations.

	if ($kanj and ($stagk = $s->{_stagk})) { # That's '=', not '=='.
	    push (@r, @{filt ($kanj, ["kanj"], $stagk, ["kanj"])}); }
	if ($rdng and ($stagr = $s->{_stagr})) { # That's '=', not '=='.
	    push (@r, @{filt ($rdng, ["rdng"], $stagr, ["rdng"])}); }

	  # Format the allowed kanji/reading) in @r as a text string.

	$restrs = @r ? "(" . join (", ", map ($_->{txt}, @r)) . " only) " : "";

	  # Get any dialects for this sense, and turn them into
	  # a string.  Save in an array because will will join()
	  # with source word info later.
 
	if ($s->{_dial}) {
	    push (@dl, "Dialect: " . join(", ", 
		map ($::KW->{DIAL}{$_->{kw}}{kw}, @{$s->{_dial}}))); }

	  # Get source word and source language info.  Turn into
	  # a string with the source language in parens followed
	  # by the source word.  Push onto the array with the dialect
	  # string.

	if ($s->{_lsrc}) {
	    push (@dl, "From: " . join(", ", 
		map (f_lsrc ($_), @{$s->{_lsrc}}))); }

	  # Now combine the dialect and source word strings into one.

	$dl = @dl ? "  " . join ("; ", @dl) : "";

	  # Print the sense info.

	$fmtstr = "$s->{sens}. $restrs$pos$misc$fld$dl\n";
	if ($s->{notes}) { $fmtstr .= "  $s->{notes}\n"; }

	  # Do the glosses.

	foreach $g (@{$s->{_gloss}}) {
	    if (!$g->{gloss}) { $g->{gloss} = ++$gnum; }

	      # If the language is not english (1) then get
	      # the language's keyword enclosed in parens.

	    if (!$g->{lang} or $g->{lang} == 1) { $lang = "" }
	    else { $lang = "(" . $::KW->{LANG}{$g->{lang}}{kw} . ") "; }

	      # If there is a gloss tag other than "equ", then
	      # get it enclosed in square brackets.

	    if (!$g->{ginf} or $g->{ginf} == 1) { $ginf = "" }
	    else { $ginf = "[" . $::KW->{GINF}{$g->{ginf}}{kw} . ".] "; }

	      # Print the gloss number, language (if any), and gloss text. 

	    $fmtstr .= "  $g->{gloss}. $lang$ginf$g->{txt}\n"; }

	  # Print the cross references.  Although each sens record
	  # has a {_xref} list, it is not very useful because all
	  # it has is the cross-ref's entry id and sens number.
	  # Insead, we'll use {_erefs} which also has the target 
	  # entry's kanji and kana string, seq number, etc which
	  # allows a much more informative display.  {_erers} is 
	  # same, but for other xrefs poining to this sense.

	$fmtstr .= p_xref ($s->{_erefs}, "Cross references:"); 
	$fmtstr .= p_xref ($s->{_erers}, "Reverse references:"); 
	return $fmtstr; }

#-----------------------------------------------------------------------

    sub f_lsrc { my ($lsrc) = @_;
	my (@x, $x, $lang, $txt, @flags);
	if ($lsrc->{wasei}) { push (@flags, "w"); } 
	if ($lsrc->{part})  { push (@flags, "p"); } 
	$x = @flags ? "(" . join (",", @flags) . ")" : "";
	$lang = $::KW->{LANG}{$lsrc->{lang}}{kw};
	if ($lang or $x) { $x = "$lang$x:" }
	$txt = $lsrc->{txt};
	if ($txt && ($txt =~ m/[^a-zA-Z0-9_-]/)) { $txt = "\"$txt\""; } 
	return $x . $txt; }

#-----------------------------------------------------------------------

    sub p_audio { my ($rdngs) = @_;
	my ($r, $a, $rtxt, $audio, $fmtstr);
	$fmtstr = "Audio:\n";
	foreach $r (@$rdngs) {
	    next if (!($audio = $r->{_audio}));
	    $rtxt = "  " . $r->{txt} . ":";
	    foreach $a (@$audio) {
		$fmtstr .= "$rtxt $a->{rdng}. $a->{fname} $a->{strt}/$a->{leng}\n";
		$rtxt = "    "; } }
	return $fmtstr; }

#-----------------------------------------------------------------------

    sub p_hist { my ($hists) = @_;
	my ($h, $n, $kw, $fmtstr);
	$fmtstr = "History:\n";
	foreach $h (@$hists) {
	    $kw = $::KW->{STAT}{$h->{stat}}{kw};
	    $fmtstr .= "  $h->{hist}. $kw $h->{dt} $h->{who}\n";
	    if ($n = $h->{notes}) { # That's an '=', not '=='.
		$n =~ s/(\n.)/    $1/;
		print "    $n\n"; } }
	return $fmtstr; }

#-----------------------------------------------------------------------

    sub p_xref { my ($erefs, $sep) = @_;
	my ($x, $t, $sep_done, $txt, $slist, $fmtstr);

	# We use the {_erefs} list rather then the {_xref} list
	# because the former provide more display-oriented info.
	# It is grouped by target entry, with a list of the 
	# target senses within each entry.  This function handles
	# both forward and reverse erefs -- the caller determines
	# which by its choice of arguments.

	$fmtstr = "";
	foreach $x (@$erefs) {

	      # Print a separator line, the first time round the loop.
	      # The seperator text is passeed by the caller because 
	      # it depends on whether we are doing forward or reverse
	      # cross-refs.

	    if (!$sep_done) { $fmtstr .= "  $sep\n";  $sep_done = 1; }

	      # Get the text for the xref type.

	    $t = ucfirst ($::KW->{XREF}{$x->{typ}}{kw});

	      # Get the target entry's text.  If only readings, use as-is.
	      # If has kanji, use that followed by reading in brackets.

	    if ($x->{entr}{kanj} && $x->{entr}{rdng}) { 
		$txt = "$x->{entr}{kanj}\x{3010}$x->{entr}{rdng}\x{3011}"; }
	    else { $txt = $x->{entr}{kanj} || $x->{entr}{rdng}; }
	    $txt .= (" " . $x->{entr}{gloss});

	      # If the number of senses pointed to by our xrefs is the
	      # same as the number of senses in the target entry, don't
	      # mentions the senses at all.  This xref points to entire 
	      # entry.  Otherwise, give the senses pointed to a list of
	      # sense numbers.
	      # N.B. might want to always print the list if number of 
	      # target senses is greater than 1.   Rational is that such
	      # mutiple senses are probably in error (residue of JMdict
	      # xml's sense->entry semantics) and should be reviewed.

	    if ($x->{entr}{nsens} == scalar (@{$x->{sens}})) { $slist = ""; }
	    else { $slist = "(" . join (",", @{$x->{sens}}) . ")"; }

	      # Print the xref info.

	    $fmtstr .= "    $t: $x->{entr}{seq}$slist " . $txt . "\n"; }
	return $fmtstr; }

	1;

#===========================================================================

    sub qtxt { my ($txt) = @_;
	# Enclose $txt in quotes if it contains any 
	# non-alphanumeric characters other than "_" or "-". 
	# Escape internal quotes.
	$txt =~ s/"/\\"/g;
	if ($txt && ($txt =~ m/[^a-zA-Z0-9_-]/)) { $txt = "\"$txt\""; } 
	return $txt; }

    sub escgloss { my ($txt) = @_;
	# Add backslash escape characters in front of any 
	# ";" or "[" characters in $txt.  This s the escaping 
	# used in glosses processed by the JEL parser.
	$txt =~ s/([;\[])/\\$1/g;
	return $txt; }

    sub jel_kanjs { my ($kanjs) = @_;
	my $txt = join ("\x{FF1B}", map (jel_kanj ($_), @$kanjs));
	return $txt; }

    sub jel_kanj { my ($kanj) = @_;
	my ($txt, @kinf, @freq);
	$txt = $kanj->{txt};
	@kinf = map ($::KW->{KINF}{$_->{kw}}{kw}, @{$kanj->{_kinf}}); 
	@freq = map ($::KW->{FREQ}{$_->{kw}}{kw}.$_->{value}, @{$kanj->{_kfreq}});
	if (@kinf or @freq) { $txt .= "[" . join (",", (@kinf,@freq)) . "]"; }
	return $txt; }

    sub jel_rdngs { my ($rdngs, $kanjs) = @_;
	my $txt = join ("\x{FF1B}", map (jel_rdng ($_, $kanjs), @$rdngs));
	return $txt; }

    sub jel_rdng { my ($rdng, $kanjs) = @_;
	my ($txt, @rinf, @freq, $restrtxts, $ok_kanj);
	$txt = $rdng->{txt};
	@rinf = map ($::KW->{RINF}{$_->{kw}}{kw}, @{$rdng->{_rinf}}); 
	@freq = map ($::KW->{FREQ}{$_->{kw}}{kw}.$_->{value}, @{$rdng->{_rfreq}});
	if (@rinf or @freq) { $txt .= "[" . join (",", (@rinf, @freq)) . "]"; }
	$restrtxts = restrtxts ($rdng->{_restr}, $kanjs, "kanj");
	if (!ref ($restrtxts)) { 
	    $txt .= "[restr=$restrtxts]"; }	# $restrtxts is "nokanki".
	else { 
	    if (@$restrtxts) { $txt .= "[restr=" . join(";", @$restrtxts) ."]"; } }
	return $txt; }

    sub restrtxts { my ($restrs, $kanjs, $key) = @_;
	my (@restrtxts);
	return [] if (!$restrs);
	if (scalar(@$restrs) == scalar(@$kanjs)) { return ["no$key"]; }
	@restrtxts = map ($_->{txt}, @{filt ($kanjs, [$key], $restrs, [$key])}); 
	return \@restrtxts; }

    sub jel_senss { my ($senss, $kanjs, $rdngs) = @_;
	my ($s, $nsens, $txt, @stxts);
	foreach $s (@$senss) {
	    ++$nsens;
	    if ($s->{sens}) {
		die ("Error, sense $nsens has \{sens\} value of $s->{sens}\n")
		    if ($s->{sens} != $nsens); }
	    push (@stxts, jel_sens ($s, $kanjs, $rdngs, $nsens)); }
	$txt = join ("\n", @stxts);
	return $txt; }

    sub jel_sens { my ($sens, $kanjs, $rdngs, $nsens) = @_;
	my (@dial, @misc, @pos, @fld, $stagk, $stagr, @lsrc, $note,
	    @gloss, @xref, $kwds, $dial, $restr, $lsrc, $g, $ginf,
	    $t, $qtxt, $lastginf, @lines, $txt, @restr, $ginfkw);

	@dial = map ($::KW->{DIAL}{$_->{kw}}{kw}, @{$sens->{_dial}}); 
	@misc = map ($::KW->{MISC}{$_->{kw}}{kw}, @{$sens->{_misc}}); 
	@pos  = map ($::KW-> {POS}{$_->{kw}}{kw}, @{$sens->{_pos}}); 
	@fld  = map ($::KW-> {FLD}{$_->{kw}}{kw}, @{$sens->{_fld}}); 
	$stagk = restrtxts ($sens->{_stagk}, $kanjs, "kanj");
	$stagr = restrtxts ($sens->{_stagr}, $rdngs, "rdng");
	@lsrc = map (f_lsrc($_), @{$sens->{_lsrc}});
	@xref = map ("[".jel_xref ($_)."]", @{$sens->{_erefs}});

	$kwds  = @pos   ? "[" . join (",", @pos) .  "]" : "";
	$kwds .= @misc  ? "[" . join (",", @misc) . "]" : "";
	$kwds .= @fld   ? "[" . join (",", @fld) .  "]" : "";
	$dial  = @dial  ? "[dial=" . join (",", @dial) . "]" : "";
	@restr = (@$stagk, @$stagr);
	$restr = @restr ? ("[restr=" . join ("; ", @restr) . "]") : "";
	$lsrc  = @lsrc  ? "[lsrc=" . join (", ", @lsrc) . "]" : "";
	$note  = $sens->{notes} ? "[note=\"$sens->{notes}\"]" : "";

	$lastginf = -1;
	foreach $g (@{$sens->{_gloss}}) {
	    $ginf = $g->{ginf};  $t = $g->{txt};
	    if ($ginf != 1) {
		$qtxt = qtxt ($g->{txt});
		$ginfkw = $::KW->{GINF}{$ginf}{kw};
		push (@gloss, "[$ginfkw=$qtxt]"); }
	    else {
		$t = escgloss ($g->{txt});
		if ($lastginf != 1) { push (@gloss, $t); }
		else { $gloss[-1] .= "; $t"; } }
	    $lastginf = $ginf; }

	push (@lines, "[$nsens]$kwds$dial");
	push (@lines, "$restr$lsrc") if ($restr or $lsrc);
	push (@lines, $note) if ($note);
	push (@lines, @gloss);
	push (@lines, @xref);
	$txt = join ("\n  ", @lines);
	return $txt; }

    sub jel_xref { my ($eref) = @_;
	my ($kanj, $rdng, $txt);
	$kanj = $eref->{entr}{kanj};
	$kanj =~ s/;.*//;
	$rdng = $eref->{entr}{rdng};
	$rdng =~ s/;.*//;
	$txt = $kanj . (($kanj or $rdng) ? "/" : "") . $rdng;
	if ($eref->{sens} and @{$eref->{sens}}) {
	    $txt .= "[" . join(",", @{$eref->{sens}}) . "]"; }
	$txt = $::KW->{XREF}{$eref->{typ}}{kw} . "=" . $txt;
	return $txt; }

    sub jel_entrhdr { my ($entr) = @_;
	my ($src, $stat, $txt);
	$src = $::KW->{SRC}{$entr->{src}}{kw};
	$stat = $::KW->{STAT}{$entr->{stat}}{kw};
	$txt = "$entr->{seq} ($src) [$stat] {$entr->{id}}";
	return $txt; }

    sub jel_entr { my ($entr) = @_;
	my ($txt, @sects);
	push (@sects, jel_entrhdr ($entr));
	push (@sects, jel_kanjs ($entr->{_kanj})) if ($entr->{_kanj});
	push (@sects, jel_rdngs ($entr->{_rdng}, $entr->{_kanj}));
	push (@sects, jel_senss ($entr->{_sens}, $entr->{_kanj}, $entr->{_rdng}));
	$txt .= join ("\n", @sects); }
