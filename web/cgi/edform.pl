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

use lib ("../lib", "./lib", "../perl/lib", "../../perl/lib");
use jmdict; use jmdicttal; use jmdictfmt; use jmdictcgi;

$|=1;
binmode (STDOUT, ":utf8");

    main: {
	my ($dbh, $cgi, $tmpl, @qlist, @elist, @errs, $entrs, $entr, 
	    $ktxt, $rtxt, $stxt, $srcs, $svc);
	binmode (STDOUT, ":encoding(utf-8)");
	$cgi = new CGI;
	print "Content-type: text/html\n\n";

	$svc = clean ($cgi->param ("svc"));
	$dbh = dbopen ($svc);  $::KW = Kwds ($dbh);
	@qlist = $cgi->param ('q'); 
	@elist = $cgi->param ('e'); 
	if (scalar (@elist) + scalar(@qlist) > 1) {
	    push (@errs, "Bad url parameters: more than one entry was specified."); }
	if (@elist or @qlist) {
	    $entrs = get_entrs ($dbh, \@elist, \@qlist, \@errs, 
		"stat=$::KW->{STAT}{A}{id} AND NOT unap");
	    if ($entrs && !@$entrs) { push (@errs, "Entry not found"); }
	    if (scalar (@$entrs) > 1) { push (@errs, "Multiple entries found.  (This should not happen!)"); }
	    if (@errs) { errors_page (\@errs);  exit; } 
	    $entr = $entrs->[0];
	    $ktxt = jel_kanjs ($entr->{_kanj});
	    $rtxt = jel_rdngs ($entr->{_rdng}, $entr->{_kanj});
	    $stxt = jel_senss ($entr->{_sens}, $entr->{_kanj}, $entr->{_rdng}); }
	else {
	    $ktxt = $rtxt = "";
	    $stxt = "[1][n]"; }
	$dbh->disconnect; 

	$srcs = [sort {lc($a->{kw}) cmp lc($b->{kw})} kwrecs ($::KW, "SRC")];
	unshift (@$srcs,{id=>0,kw=>"",descr=>""});

	$tmpl = new Petal (file=>find_in_inc("tal")."/tal/edform.tal", 
			   decode_charset=>'utf-8', output=>'HTML' );
	print $tmpl->process ({e=>$entr, ktxt=>$ktxt, rtxt=>$rtxt, stxt=>$stxt,
			       srcs=>$srcs, svc=>$svc, is_editor=>1,
			       isdelete=>($entr->{stat}==$::KW->{STAT}{D}{id}?1:undef),
			       method=>"get"}); }

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
