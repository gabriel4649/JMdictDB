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

package jmdicted;
use strict; use warnings;
use jmdict;

BEGIN {
    use Exporter(); our (@ISA, @EXPORT_OK, @EXPORT); @ISA = qw(Exporter);
    @EXPORT = qw(entr2edict); }

our(@VERSION) = (substr('$Revision$',11,-2), \
	         substr('$Date$',7,-11));

our ($JLB, $JRB) = ("\x{3010}", "\x{3011}");  # Should go in jmdict.pm?

    sub entr2edict { my ($e) = @_;
	# Return an edict-like text string that summarizes the information
	# about an entry in the EntrList() structure, $e.
	### This function is currently incomplete ###

	my (@x, $x, $s, $n, $stat, $txt, $ktxt, $rtxt, $nsens);

	$ktxt = join ("; ", map (fmt_kanj($_), @{$e->{_kanj}}));
	$rtxt = join ("; ", map (fmt_rdng($_, $e->{_kanj}), @{$e->{_rdng}}));
	if ($ktxt) { $txt = "$ktxt $JLB$rtxt$JRB"; }
	else { $txt = $rtxt; }

	$nsens = scalar (@{$e->{_sens}});
	foreach $s (@{$e->{_sens}}) {
	    if ($nsens > 1) { $n += 1; }
	    $txt .= fmt_sens ($s, $n, $e->{_kanj}, $e->{_rdng}); }
	return $txt; }

    sub fmt_kanj { my ($k) = @_;
	my ($txt, @f);
	$txt = $k->{txt};  
	@f = map ($::KW->{KINF}{$_->{kw}}{kw}, @{$k->{_kinf}});
	if (@f) { $txt .= "(" . join (",", @f) . ")"; }
	if (is_p ($k->{_kfreq})) { $txt .= "(P)"; }
	return $txt; }

    sub fmt_rdng { my ($r, $kanj) = @_;
	my ($txt, @f, $restr, $klist);
	$txt = $r->{txt};  
	@f = map ($::KW->{KINF}{$_->{kw}}{kw}, @{$r->{_rinf}});
	($txt .= "[" . join (",", @f) . "]") if (@f);
	if ($kanj and ($restr = $r->{_restr})) {  # That's '=', not '=='.
	    if (scalar (@$restr) == scalar (@$kanj)) { $txt .= "(no kanji)"; }
	    else {
		$klist = filt ($kanj, ["kanj"], $restr, ["kanj"]);
		$txt .= "(" . join ("; ", map ($_->{txt}, @$klist)) . ")"; } }
	if (is_p ($r->{_rfreq})) { $txt .= "(P)"; }
	return $txt; }
 
    sub fmt_sens { my ($s, $n, $kanj, $rdng) = @_;
	my ($txt, $pos, $misc, $fld, @r, $stagr, $stagk, $stag, $notes, $xrefs);

	$pos = join (",", map ($::KW->{POS}{$_->{kw}}{kw}, @{$s->{_pos}}));
	if ($pos) { $pos = "($pos)"; }
	$misc = join (",", map ($::KW->{MISC}{$_->{kw}}{kw}, @{$s->{_misc}}));
	if ($misc) { $misc = "($misc)"; }
	$fld = join (",", map ($::KW->{FLD}{$_->{kw}}{kw}, @{$s->{_fld}}));
	if ($fld) { $fld = "{$fld}"; }

	if ($kanj and ($stagk = $s->{_stagk})) { # That's '=', not '=='.
	    push (@r, @{filt ($kanj, ["kanj"], $stagk, ["kanj"])}); }
	if ($rdng and ($stagr = $s->{_stagr})) { # That's '=', not '=='.
	    push (@r, @{filt ($rdng, ["rdng"], $stagr, ["rdng"])}); }
	$stag = @r ? "(" . join (", ", map ($_->{txt}, @r)) . " only) " : "";
	$n = $n ? "($n)" : "";
	$notes = $s->{notes} ? $s->{notes} : "";
	$xrefs = xrefstr ($s);
	$txt = "$pos$n$stag$notes$misc$fld$xrefs";
	$txt .= join ("", map ($_->{txt} . ";", @{$s->{_gloss}}));
	return $txt; }

    sub is_p { my ($freq) = @_;
	# Return true (1) if this is a 'P' freq (i.e., @$freq contain an ichi1,
	# spec1, gai1, news1, or any nf freq with a value less than 25), or
	# false (0) otherwise.

	my ($f, $t);
	foreach $f (@$freq) {
	    $t = $f->{kw};  
	    # FIXME: shouldn't hardwire the FREQ id's but how best not to do that?
	    # 1=ichi, 2=gai, 4=spec, 5=nf, 7=news
	    if (  (($t==5) and $f->{value}<=24) or \
		  (($t==1 or $t==2 or $t==4 or $t==7) and $f->{value}==1) ) {
		return 1; } }
	return 0; }

    sub xrefstr { my ($s) = @_;
	my ($x, $txt, %texts, $str, $typ, $typstr);
	$str = "";
	return "" if (!$s->{_erefs} or !@{$s->{_erefs}});
	foreach $x (@{$s->{_erefs}}) {
	    $txt = $x->{entr}{kanj} ? $x->{entr}{kanj} : $x->{entr}{rdng};
	    $texts{$x->{typ}}{$txt} = 1; }	# eliminate duplicates.	
	foreach $typ (keys (%texts)) {
	    $typstr = $::KW->{XREF}{$typ}{kw};
	    foreach $x (keys (%{$texts{$typ}})) {
		$str .= "($typstr: $x)"; } }
	return $str; }

    1;	