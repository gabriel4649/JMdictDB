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
use Petal; use Petal::Utils (':all'); 

use lib ("../lib", "./lib", "../perl/lib", "../../perl/lib");
use jmdict; use jmdicttal; use jmdictcgi;

$|=1;

    main: {
	my ($dbh, $cgi, @qlist, @elist, $svc);
	binmode (STDOUT, ":encoding(utf-8)");
	$::Debug = {};
	$cgi = new CGI;
	print "Content-type: text/html\n\n";
	$svc = clean ($cgi->param ("svc"));
	$dbh = dbopen ($svc);  $::KW = Kwds ($dbh);

	@qlist = $cgi->param ('q');
	@elist = $cgi->param ('e'); 
	gen_page ($dbh, $svc, \@elist, \@qlist);
	$dbh->disconnect; }

    sub gen_page { my ($dbh, $svc, $elist, $qlist) = @_;
	my ($tmpl, $sql, $seq, $src, $entries, @whr, $x, @errs, @e, @args); 
	$entries = get_entrs ($dbh, $elist, $qlist, \@errs);
	fmt_restr ($entries); 
	fmt_stag ($entries); 
	set_audio_flag ($entries);
	set_editable_flag ($entries);

	$tmpl = new Petal (file=>find_in_inc("tal")."/tal/entr.tal", 
			   decode_charset=>'utf-8', output=>'HTML');
	print $tmpl->process (entries=>$entries, svc=>$svc, dbg=>$::Debug); }

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
