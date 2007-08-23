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
use Cwd; use CGI; use Encode; use utf8; use DBI; 
use Petal; use Petal::Utils; 

BEGIN {push (@INC, "../lib");}
use jmdict; use jmdicttal; use jmdictfmt; use jmdictcgi;

$|=1;
binmode (STDOUT, ":utf8");
*ee = \&encode_entities;

    main: {
	my ($dbh, $cgi, $tmpl, $tmptbl, @qlist, @elist, @errs, $sql, 
	    @whr, $entries, $entr, $ktxt, $rtxt, $stxt, $srcs, $svc);
	binmode (STDOUT, ":encoding(utf-8)");
	$cgi = new CGI;
	print "Content-type: text/html\n\n";

	$svc = $cgi->param ("svc");
	@qlist = $cgi->param ('q'); validateq (\@qlist, \@errs);
	@elist = $cgi->param ('e'); validaten (\@elist, \@errs);
	if (@errs) { errors_page (\@errs);  exit; } 

	$dbh = dbopen ($svc);  $::KW = Kwds ($dbh);
	if (@qlist) { push (@whr, "e.seq IN (" . join(",",map('?',(@qlist))) . ")"); }
	if (@elist) { push (@whr, "e.id  IN (" . join(",",map('?',(@elist))) . ")"); }
	if (@whr) {
	    $sql = "SELECT e.id FROM entr e WHERE " . join (" OR ", @whr);
	    $tmptbl = Find ($dbh, $sql, [@qlist, @elist]);
	    $entries = EntrList ($dbh, $tmptbl);
	    add_xrefsums ($dbh, $entries);
	    $entr = $entries->[0];
	    $ktxt = jel_kanjs ($entr->{_kanj});
	    $rtxt = jel_rdngs ($entr->{_rdng}, $entr->{_kanj});
	    $stxt = jel_senss ($entr->{_sens}, $entr->{_kanj}, $entr->{_rdng}); }
	else {
	    $ktxt = $rtxt = "";
	    $stxt = "[1][n]"; }
	$dbh->disconnect; 

	$srcs = [sort {lc($a->{kw}) cmp lc($b->{kw})} kwrecs ($::KW, "SRC")];
	unshift (@$srcs,{id=>0,kw=>"",descr=>""});

	$tmpl = new Petal (file=>'../lib/tal/edform.tal', 
			   decode_charset=>'utf-8', output=>'HTML' );
	print $tmpl->process ({e=>$entr, ktxt=>$ktxt, rtxt=>$rtxt, stxt=>$stxt,
			       srcs=>$srcs, svc=$svc}); }

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
