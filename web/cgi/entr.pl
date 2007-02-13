#!/usr/bin/env perl
##########################################################################
#
#   This file is part of JMdictDB.  
#   JMdictDB is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#   JMdictDB is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#   You should have received a copy of the GNU General Public License
#   along with Foobar; if not, write to the Free Software Foundation, Inc.,
#   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
#
#   Copyright (c) 2006,2007 Stuart McGraw 
#
############################################################################

@VERSION = (substr('$Revision$',11,-2), \
	    substr('$Date$',7,-11));

use strict; use warnings;
use Cwd; use CGI; use HTML::Entities;
use Encode; use utf8; use DBI; 
use Petal; use Petal::Utils (':all'); 

BEGIN {push (@INC, "../lib");}
use jmdict; use jmdicttal;

$|=1;
*ee = \&encode_entities;

    main: {
	my ($dbh, $cgi, $tmptbl, $tmpl, $sql, $entries, $e, @qlist, @errs,
	    @elist, @whr, $dbname, $username, $pw, $s);
	binmode (STDOUT, ":encoding(utf-8)");
	$::Debug = {};
	$cgi = new CGI;
	print "Content-type: text/html\n\n";

	@qlist = $cgi->param ('q'); validateq (\@qlist, \@errs);
	@elist = $cgi->param ('e'); validaten (\@elist, \@errs);
	if (@errs) { errors_page (\@errs);  exit; } 

	open (F, "../lib/jmdict.cfg") or die ("Can't open database config file\n");
	($dbname, $username, $pw) = split (' ', <F>); close (F);
	$dbh = DBI->connect("dbi:Pg:dbname=$dbname", $username, $pw, 
			{ PrintWarn=>0, RaiseError=>1, AutoCommit=>0 } );
	$dbh->{pg_enable_utf8} = 1;
	$::KW = Kwds ($dbh);

	if (@qlist) { push (@whr, "e.seq IN (" . join(",",map('?',(@qlist))) . ")"); }
	if (@elist) { push (@whr, "e.id  IN (" . join(",",map('?',(@elist))) . ")"); }
	$sql = "SELECT e.id FROM entr e WHERE " . join (" OR ", @whr);
	$tmptbl = Find ($dbh, $sql, [@qlist, @elist]);
	$entries = EntrList ($dbh, $tmptbl);

	fmt_restr ($entries); 
	fmt_stag ($entries); 
	set_audio_flag ($entries);
	
	$tmpl = new Petal (file=>'../lib/tal/entr.tal', 
			   decode_charset=>'utf-8', output=>'HTML' );
	print $tmpl->process (entries=>$entries, dbg=>$::Debug);
	$dbh->disconnect; }

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
		next if (!$s->{_stagr} and !$s->{_stagk});
		$s->{_STAG} = [map ($_->{txt},
		    (@{filt ($e->{_rdng}, ["rdng"], $s->{_stagr}, ["rdng"])},
		     @{filt ($e->{_kanj}, ["kanj"], $s->{_stagk}, ["kanj"])}))]; } } }

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

    sub validaten { my ($list, $errs) = @_;
	foreach my $p (@$list) {
	    if (!($p =~ m/^\s*\d+\s*$/)) {
		push (@$errs, "<br>Bad url parameter received: ".ee($p)); } } }

    sub validateq { my ($list, $errs) = @_;
	foreach my $p (@$list) {
	    if (!($p =~ m/^\s*\d{7}\s*$/)) {
		push (@$errs, "<br>Bad url parameter received: ".ee($p)); } } }

    sub errors_page { my ($errs) = @_;
	my $err_details = join ("\n    ", @$errs);
	print <<EOT;
<html>
<head>
  <title>Invalid parameters</title>
  </head>
<body>
  <h2>URL Parameter errors</h2>
  $err_details
  <hr>
  Parameter format:<br/>
  <table border="0">
    <tr><td>q=dddddd</td> 
      <td>Display the entry having JMdict sequence number &lt;ddddddd&gt; (a 7-digit number).</td></tr>
    <tr><td>e=n</td> 
      <td>Display the entry having database id number &lt;n&gt;.</td></tr>
    <tr><td>s=n</td> 
      <td>Display the entry that contains the sense having database id number &lt;n&gt;.</td></tr>
    </table>
  Parameter types may be freely intermixed and any number of parameters 
  may be given in a single url.
  </body>
</html>
EOT
	}
