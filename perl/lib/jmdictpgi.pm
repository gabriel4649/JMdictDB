#!/usr/bin/env perl
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

@VERSION = (substr('$Revision$',11,-2), \
	    substr('$Date$',7,-11));

use strict; use warnings;
use Encode;

BEGIN {
    use Exporter(); our (@ISA, @EXPORT_OK, @EXPORT); @ISA = qw(Exporter);
    @EXPORT_OK = qw(initialize finalize wrentr wrcorp pgesc); 
    @EXPORT    = qw(); }

our(@VERSION) = (substr('$Revision$',11,-2), \
	         substr('$Date$',7,-11));

use jmdictxml ('%JM2ID'); # Maps xml expanded entities to kw* table id's.

sub initialize { my ($logfn, $tmpdir) = @_;
	my ($t, $td, $i1, $i2);

	if (!$tmpdir) { $td = ""; }
	else { ($td = $tmpdir) =~ s/[\/\\]$//; }
	my @tmpfiles = (
	  [\$::Fcorp,  "${td}load01.tmp", "COPY kwsrc(id,kw,descr,dt,notes,seq) FROM stdin;"],
	  [\$::Fentr,  "${td}load02.tmp", "COPY entr(id,src,seq,stat,srcnote,notes) FROM stdin;"],
	  [\$::Fkanj,  "${td}load03.tmp", "COPY kanj(entr,kanj,txt) FROM stdin;"],
	  [\$::Fkinf,  "${td}load04.tmp", "COPY kinf(entr,kanj,kw) FROM stdin;"],
	  [\$::Frdng,  "${td}load05.tmp", "COPY rdng(entr,rdng,txt) FROM stdin;"],
	  [\$::Frinf,  "${td}load06.tmp", "COPY rinf(entr,rdng,kw) FROM stdin;"],
	  [\$::Faudio, "${td}load07.tmp", "COPY audio(entr,rdng,fname,strt,leng,notes) FROM stdin;"],
	  [\$::Ffreq,  "${td}load08.tmp", "COPY freq(entr,rdng,kanj,kw,value) FROM stdin;"],
	  [\$::Fsens,  "${td}load09.tmp", "COPY sens(entr,sens,notes) FROM stdin;"],
	  [\$::Fpos,   "${td}load10.tmp", "COPY pos(entr,sens,kw) FROM stdin;"],
	  [\$::Fmisc,  "${td}load11.tmp", "COPY misc(entr,sens,kw) FROM stdin;"],
	  [\$::Ffld,   "${td}load12.tmp", "COPY fld(entr,sens,kw) FROM stdin;"],
	  [\$::Fxrsv,  "${td}load13.tmp", "COPY xresolv(entr,sens,ord,typ,rtxt,ktxt,tsens,notes,prio) FROM stdin;"],
	  [\$::Fxref,  "${td}load14.tmp", "COPY xref(entr,sens,xref.typ,xentr,xsens,rdng,kanj,notes) FROM stdin;"],
	  [\$::Fgloss, "${td}load15.tmp", "COPY gloss(entr,sens,gloss,lang,ginf,txt) FROM stdin;"],
	  [\$::Fdial,  "${td}load16.tmp", "COPY dial(entr,sens,kw) FROM stdin;"],
	  [\$::Flsrc,  "${td}load17.tmp", "COPY lsrc(entr,sens,lang,txt,part,wasei) FROM stdin;"],
	  [\$::Frestr, "${td}load18.tmp", "COPY restr(entr,rdng,kanj) FROM stdin;"],
	  [\$::Fstagr, "${td}load19.tmp", "COPY stagr(entr,sens,rdng) FROM stdin;"],
	  [\$::Fstagk, "${td}load20.tmp", "COPY stagk(entr,sens,kanj) FROM stdin;"],
	  [\$::Fhist,  "${td}load21.tmp", "COPY hist(entr,hist,stat,dt,who,diff,notes) FROM stdin;"], );

	$::eid = 0; 
	foreach $t (@tmpfiles) {
	    {no warnings;
	    open (${$t->[0]}, ">:utf8", $t->[1]) or \
		  die ("Can't open $t->[1]: $!\n") } }
	if ($logfn) {
	    open ($::Flog, ">:utf8", $logfn) or die ("Can't open $logfn: $!\n"); }
	return \@tmpfiles; }

sub finalize { my ($outfn, $tmpfls, $del, $trans) = @_;
	# Close all the temp files, merge them all intro the single 
	# output file, and delete them (if no -k option).

	my ($t, $tmpfn);
	open (FOUT, ">:utf8", $outfn) or die ("Can\'t open $outfn: $!\n");
	if ($trans) {
	    print FOUT "\\set ON_ERROR_STOP 1\nBEGIN;\n\n"; }
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
	if ($trans) {
	    print FOUT "\nCOMMIT\n"; }
	close (FOUT); } 

sub wrentr { my ($e) = @_;
	my ($etag, $k, $r, $s, $x);
	die ("Entry object does not have a valid id number\n") 
	    if ( $e->{id} <= 0 && $e->{id} ne "0");
	$etag = "$e->{id}";

       {no warnings qw(uninitialized); 
	pout ($::Fentr, $etag, $e->{src}, $e->{seq}, $e->{stat}, $e->{srcnote}, $e->{notes});
	foreach $k (@{$e->{_kanj}}) {
	    pout ($::Fkanj, $etag, $k->{kanj}, $k->{txt}); 
	    foreach $x (@{$k->{_kinf}}) {
		pout ($::Fkinf, $etag, $x->{kanj}, $x->{kw}); }
	    foreach $x (@{$k->{_freq}}) {
		pout ($::Ffreq, $etag, $x->{rdng}, $x->{kanj}, $x->{kw}, $x->{value}); } }
	foreach $r (@{$e->{_rdng}}) {
	    pout ($::Frdng, $etag, $r->{rdng}, $r->{txt}); 
	    foreach $x (@{$r->{_rinf}}) {
		pout ($::Frinf, $etag, $x->{rdng}, $x->{kw}); }
	    foreach $x (@{$r->{_freq}}) {
		next if ($x->{kanj});  # These were already written (above).
		pout ($::Ffreq, $etag, $x->{rdng}, $x->{kanj}, $x->{kw}, $x->{value}); }
	    foreach $x (@{$r->{_restr}}) {
		pout ($::Frestr, $etag, $x->{rdng}, $x->{kanj}); }
	    foreach $x (@{$r->{_audio}}) {
		pout ($::Faudio, $etag, $x->{rdng}, $x->{kanj}); } }
	foreach $s (@{$e->{_sens}}) {
	    pout ($::Fsens, $etag, $s->{sens}, $s->{notes}); 
	    foreach $x (@{$s->{_misc}}) {
		pout ($::Fmisc, $etag, $x->{sens}, $x->{kw}); }
	    foreach $x (@{$s->{_pos}}) {
		pout ($::Fpos, $etag, $x->{sens}, $x->{kw}); }
	    foreach $x (@{$s->{_fld}}) {
		pout ($::Ffld, $etag, $x->{sens}, $x->{kw}); }
	    foreach $x (@{$s->{_gloss}}) {
		pout ($::Fgloss, $etag, $x->{sens}, $x->{gloss}, $x->{lang}, $x->{ginf}, $x->{txt}); }
	    foreach $x (@{$s->{_dial}}) {
		pout ($::Fdial, $etag, $x->{sens}, $x->{kw}); }
	    foreach $x (@{$s->{_lsrc}}) {
		pout ($::Flsrc, $etag, $x->{sens}, $x->{lang}, $x->{txt}, $x->{part}, $x->{wasei}); }
	    foreach $x (@{$s->{_stagr}}) {
		pout ($::Fstagr, $etag, $x->{sens}, $x->{rdng}); }
	    foreach $x (@{$s->{_stagk}}) {
		pout ($::Fstagk, $etag, $x->{sens}, $x->{kanj}); }
	    foreach $x (@{$s->{_xrslv}}) {
		# Warning, jmdict::setkeys() function does not set the _xresolv
		# PK (entr,sens,ord).  Builder of the object responsible for that.
		pout ($::Fxrsv, $etag, $x->{sens}, $x->{ord}, $x->{typ}, $x->{rtxt}, $x->{ktxt},
				 $x->{tsens}, $x->{notes}, $x->{prio}); } 
	    foreach $x (@{$s->{_xref}}) {
		pout ($::Fxref, $etag, $x->{sens}, $x->{xref}, $x->{typ}, $x->{xentr}, $x->{xsens}, 
				$x->{rdng}, $x->{kanj}, $x->{notes}); } 
	    foreach $x (@{$s->{_xrer}}) {
		pout ($::Fxref, $x->{entr}, $x->{sens}, $x->{xref}, $x->{typ}, $etag, $x->{xsens},
				$x->{rdng}, $x->{kanj},  $x->{notes}); } }
	foreach $x (@{$e->{_hist}}) {
	    pout ($::Fhist, $etag, $x->{hist}, $x->{stat}, $x->{dt}, 
			                $x->{who}, $x->{diff}, $x->{notes}); }} }

sub wrcorp { my ($x) = @_;
	pout ($::Fcorp, $x->{id}, $x->{kw}, $x->{descr}, $x->{dt}, $x->{notes}, $x->{seq}); }

sub pgesc { my ($str) = @_; 
	  # Escape characters that are special to the Postgresql COPY
	  # command.  Backslash characters are replaced by two backslash
	  # characters.   Newlines are replaced by the two characters
	  # backslash and "n".  Similarly for tab and return characters.
	return $str if (!$str);
	$str =~ s/\\/\\\\/go;
	$str =~ s/\n/\\n/go;
	$str =~ s/\r//go;	# Delete \r's.
	$str =~ s/\t/\\t/go;
	return $str; }

sub pout {
	my ($file, @args, $a);
	$file = shift (@_);
	while (scalar (@_) > 0) {
	    $a = shift;
	    if (!defined ($a)) { push (@args, "\\N"); }
	    else { push (@args, pgesc ($a)); } }
	print $file join ("\t", @args) . "\n"; }

	1;
