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

use strict; use warnings;
use Cwd; use CGI; use HTML::Entities;
use Encode; use utf8; use DBI; 
use Petal; use Petal::Utils (':all'); 

BEGIN {push (@INC, "../lib");}
use jmdict; use jmdicttal; use jmdictcgi;

$|=1;
*ee = \&encode_entities;

    main: {
	my ($dbh, $cgi, @qlist, @elist);
	binmode (STDOUT, ":encoding(utf-8)");
	$::Debug = {};
	$cgi = new CGI;
	print "Content-type: text/html\n\n";

	$dbh = dbopen ();  $::KW = Kwds ($dbh);
	@qlist = $cgi->param ('q');
	@elist = $cgi->param ('e'); 
	gen_page ($dbh, \@elist, \@qlist);
	$dbh->disconnect; }

    sub gen_page { my ($dbh, $elist, $qlist) = @_;
	my ($tmptbl, $tmpl, $sql, $seq, $src, $entries, @whr, $x, @errs, @e, @args); 
	foreach $x (@$elist) {
	    if (!($x =~ m/^\s*\d+\s*$/)) {
		push (@errs, "<br>Bad url parameter received: ".ee($x)); next; }
	    push (@e, "?"); push (@args, $x); }
	if (@e) { push (@whr, "id IN (" . join (",", @e) . ")"); }

	foreach $x (@$qlist) {
	    ($seq,$src) = split ('\.', $x, 2);
	    if (!($seq =~ m/^\d+$/)) { 
		push (@errs, "<br>Bad url parameter received: ".ee($x)); next; }
	    if (!$src) { $src = "jmdict"; }
	    $src = $::KW->{SRC}{$src}{id};
	    if (!$src) {
		push (@errs, "<br>Bad url parameter received: ".ee($x)); next; }
	    push (@whr, "(seq=? AND src=?)"); push (@args, ($seq, $src)); }

	if (!@whr) { push (@errs, "No valid entry or seq numbers given."); }
	if (@errs) { errors_page (\@errs);  return; } 

	$sql = "SELECT e.id FROM entr e WHERE " . join (" OR ", @whr);
	$tmptbl = Find ($dbh, $sql, \@args);
	$entries = EntrList ($dbh, $tmptbl);
	if (!@$entries) { errors_page (["None of the requested entries were found."]); return; }

	add_xrefsums ($dbh, $tmptbl, $entries);
	fmt_restr ($entries); 
	fmt_stag ($entries); 
	set_audio_flag ($entries);

	$tmpl = new Petal (file=>'../lib/tal/entr.tal', 
			   decode_charset=>'utf-8', output=>'HTML' );
	print $tmpl->process (entries=>$entries, dbg=>$::Debug); }

    sub errors_page { my ($errs) = @_;
	my $err_details = join ("<br>\n    ", @$errs);
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
    <tr><td>q=n.c</td> 
      <td>Display the entry having the sequence number &lt;n&gt; in corpus &lt;c&gt;
	  which may be given as the corpus id number or name.</td></tr>
    <tr><td>q=n</td> 
      <td>Display the entry having the sequence number &lt;n&gt; in the "jmdict" corpus.</td></tr>
    <tr><td>e=n</td> 
      <td>Display the entry having database id number &lt;n&gt;.</td></tr>
    </table>
  Parameter types may be freely intermixed and any number of parameters 
  may be given in a single url.
  </body>
</html>
EOT
	}
