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

package jmdictcgi;

use strict; use warnings;
use Encode 'decode_utf8'; 
use Storable qw(freeze thaw); use MIME::Base64;
use HTML::Entities;
use POSIX qw(strftime);
use CGI::Carp;

use jmdict;

BEGIN {
    use Exporter(); our (@ISA, @EXPORT_OK, @EXPORT); @ISA = qw(Exporter);
    @EXPORT = qw(serialize unserialize fmt_restr fmt_stag set_audio_flag
		 set_editable_flag dbopen clean find_in_inc get_entrs); }

our(@VERSION) = (substr('$Revision$',11,-2), \
	         substr('$Date$',7,-11));

*esc = \&CGI::escapeHTML;

    sub clean { my ($s) = @_;
	return $s if (!defined ($s));
	croak ("Bad string received") if (!($s =~ m/^[0-9A-Za-z_]*$/));
	return $s; }

    sub serialize { my ($struct) = @_;
	my $s = freeze ($struct);
	$s = encode_base64 ($s);
	$s = encode_entities ($s);
	$s; }

    sub unserialize { my ($str) = @_;
	my $s = decode_entities ($str);
	$s = decode_base64 ($s);
	$s = thaw ($s);
	$s; }

    sub get_entrs { my ($dbh, $elist, $qlist, $errs, $seq_whr) = @_;
        my ($sql, $seq, $src, $entries, @whr, $x, @e, @args); 
        foreach $x (@$elist) {
            if (!($x =~ m/^\s*\d+\s*$/)) {
                push (@$errs, "Bad url parameter received: ".esc($x)); next; }
            push (@e, "?"); push (@args, $x); }
        if (@e) { push (@whr, "id IN (" . join (",", @e) . ")"); }

        foreach $x (@$qlist) {
            ($seq,$src) = split ('\.', $x, 2);
            if (!($seq =~ m/^\d+$/)) { 
                push (@$errs, "Bad url parameter received: ".esc($x)); next; }
            if (!$src) { $src = "jmdict"; }
            $src = $::KW->{SRC}{$src}{id};
            if (!$src) {
                push (@$errs, "Bad url parameter received: ".esc($x)); next; }
            push (@whr, "(seq=? AND src=?)" . ($seq_whr ? " AND $seq_whr" : "")); 
	    push (@args, ($seq, $src)); }

        if (!@whr) { push (@$errs, "No valid entry or seq numbers given."); }
        if (@$errs) { return undef; } 

        $sql = "SELECT e.id FROM entr e WHERE " . join (" OR ", @whr);
        $entries = EntrList ($dbh, $sql, \@args);
        if (@$entries) { add_xrefsums ($dbh, $entries); }
 	return $entries; }

    sub fmt_restr { my ($entrs) = @_;

	# In the database we store the invalid combinations of readings
	# and kanji, but for display, we want to show the valid combinations.
	# So we subtract the former set which we got from the database from
	# from the full set of all combinations, to get the latter set for
	# display.  We also set a HAS_RESTR flag on the entry so that the 
	# display machinery doesn't have to search all the readings to 
	# determine if any restrictions exist for the entry.

	my ($e, $nkanj, $r);
	foreach $e (@$entrs) {
	    next if (!$e->{_kanj});
	    $nkanj = scalar (@{$e->{_kanj}});
	    foreach $r (@{$e->{_rdng}}) {
		next if (!$r->{_restr});
		$e->{HAS_RESTR} = 1;
		if (scalar (@{$r->{_restr}}) == $nkanj) { $r->{_RESTR} = 1; }
		else {
		    my @rk = map ($_->{txt}, 
			@{filt ($e->{_kanj}, ["kanj"], $r->{_restr}, ["kanj"])});
		    $r->{_RESTR} = \@rk; } } } }

    sub fmt_stag { my ($entrs) = @_; 

	# Combine the stagr and stagk restrictions into a single
	# list, which is ok because former show in kana and latter
	# in kanji so there is no interference.  We also change
	# from the "invalid combinations" stored in the database
	# to "valid combinations" needed for display.

	my ($e, $s);
	foreach $e (@$entrs) {
	    foreach $s (@{$e->{_sens}}) {
		my @stag;
		if ($s->{_stagk} and @{$s->{_stagk}}) {
		    push (@stag, map ($_->{txt},
		      @{filt ($e->{_kanj}, ["kanj"], $s->{_stagk}, ["kanj"])})); }
		if ($s->{_stagr} and @{$s->{_stagr}}) {
		    push (@stag, map ($_->{txt},
		      @{filt ($e->{_rdng}, ["rdng"], $s->{_stagr}, ["rdng"])})); }
		$s->{_STAG} = @stag ? \@stag : undef; } } }

    sub set_audio_flag { my ($entrs) = @_; 

	# The display template shows audio records at the entry level 
	# rather than the reading level, so we set a HAS_AUDIO flag on 
	# entries that have audio records so that the template need not
	# sear4ch all readings when deciding if it should show the audio
	# block.
	# [Since the display template processes readings prior to displaying
	# audio records, perhaps the template should set its own global
	# variable when interating the readings, and use that when showing
	# an audio block.  That would eliminate the need for this function.]
 
	my ($e, $r, $found);
	foreach $e (@$entrs) {
	    $found = 0;
	    foreach $r (@{$e->{_rdng}}) {
		if ($r->{_audio}) { $found = 1; last; } }
	    $e->{HAS_AUDIO} = $found; } }

    sub set_editable_flag { my ($entrs) = @_; 

	# This is a conveniene function to avoid embedding this logic 
	# in the TAL templates.  This sets a EDITABLE flag on entries
	# that should have an "Edit" button is entr.tal. 
 
	my ($e, $r, $found);
	foreach $e (@$entrs) {
	    $e->{EDITABLE} = ($e->{unap}  
		or ($e->{stat} == $::KW->{STAT}{N}{id})
		or ($e->{stat} == $::KW->{STAT}{A}{id})); } }

    sub find_in_inc { my ($fname) = @_;
	# Search the directories in @INC for the first occurance
	# of a readable file or directory named $fname, and return 
	# the @INC directory in which it was found.
	my ($d);
	foreach $d (@INC) { 
	    return $d if (-r "$d/$fname"); }
	return undef; }

    use DBI;
    sub dbopen { my ($svcname, $svcdir) = @_;
	# This function will open a database connection.  It is
	# intended for the use of cgi scripts where we do not want
	# to embed the connection information (username, password,
	# etc) in the script itself, for both security and
	# maintenance reasons. 
	# It uses a Postgresql "service" file.  For more info
	# on the syntax and use of this file, see:
	#
	#   [Both the following are in Postgresql Docs, libpq api.]
	#   29.1. Database Connection Control Functions
	#   29.14. The Connection Service File
	#
	#   DBD-Pg / DBI Class Methods / connect() method
	#   The JMdictDB README.txt file, installation section.
	#
	# $svcname -- name of a postgresql service listed 
	#	in the pg_service.conf file.  If not supplied,
	#	"jmdict" will be used.
	# $svcdir -- Name of directory containing the pg_service.conf
	#	file.  If undefined, "../lib/" will be used.  If 
	#	an empty string (or other defined but false value)
	# 	is given, Postresql's default location will be
	#	used.

	if (!defined ($svcdir)) { $svcdir = find_in_inc("pg_service.conf"); }
	if (!$svcname) { $svcname = "jmdict"; }

	if ($svcdir) { $ENV{PGSYSCONFDIR} = $svcdir; }
	
	my $dbh = DBI->connect("dbi:Pg:service=$svcname", "", "",
			{ PrintWarn=>0, RaiseError=>1, AutoCommit=>0,
			  ShowErrorStatement=>1 } );
	$dbh->{pg_enable_utf8} = 1;
	return $dbh; }

1;
