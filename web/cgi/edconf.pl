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
use CGI; use Encode 'decode_utf8'; use DBI; 
use Petal; use Petal::Utils; 
use POSIX qw(strftime);


BEGIN {push (@INC, "../lib");}
use jmdict; use jmdictcgi; use jmdicttal;

$|=1;
binmode (STDOUT, ":utf8");
eval { binmode($DB::OUT, ":encoding(shift_jis)"); };

    main: {
	my ($dbh, $cgi, $tmpl, $entr, $entrs, $errs, $serialized, $chklist);
	$cgi = new CGI;
	print "Content-type: text/html\n\n";
	$dbh = dbopen ();  $::KW = Kwds ($dbh);

	($entr, $errs) = cgientr ($dbh, $cgi);
	$entrs = [$entr];
	$chklist = find_similar ($dbh, $entr->{_kanj}, $entr->{_rdng});

	if (!@$errs) {
	    $serialized = serialize ($entr);
	    $tmpl = new Petal (file=>'../lib/tal/nwconf.tal', 
			   decode_charset=>'utf-8', output=>'HTML' );
	    print $tmpl->process (entries=>$entrs, 
				chklist=>$chklist,
				serialized=>$serialized); }
	else { errors_page ($errs); }
	$dbh->disconnect; } 

    sub find_similar { my ($dbh, $kanj, $rdng) = @_;
	my ($whr, @args, $sql, $rs);
	$whr = join (" OR ", (map ("r.txt=?", @$rdng), map ("k.txt=?", @$kanj)));
	@args = map ("$_->{txt}", (@$rdng,@$kanj));
	$sql = "SELECT DISTINCT e.* FROM esum e " .
		 "LEFT JOIN rdng r ON r.entr=e.id " .
		 "LEFT JOIN kanj k ON k.entr=e.id " .
		 "WHERE " . $whr;
	$rs = dbread ($dbh, $sql, \@args);
	return $rs; }

    sub errors_page { my ($errs) = @_;
	my $err_details = join ("\n    <br/>", @$errs);
	print <<EOT;
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
  <title>Invalid parameters</title>
  </head>
<body>
  <h2>Form data errors</h2>
	Your submission cannot be processed due to the following errors:
  <p>$err_details
  <hr>
  Please use your brower's "back" button to return to your form,
  correct the errors above, and resubmit it.
  </body>
</html>
EOT
	}
