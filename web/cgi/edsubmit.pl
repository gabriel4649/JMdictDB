#!/usr/bin/env perl

# Copyright (c) 2007 Stuart McGraw 
@VERSION = (substr('$Revision$',11,-2), \
	    substr('$Date$',7,-11));

use strict; use warnings;
use CGI; use Encode 'decode_utf8'; use DBI; 
use Petal; use Petal::Utils; 

BEGIN {push (@INC, "../lib");}
use jmdict; use jmdictcgi; use jmdicttal;

$|=1;
binmode (STDOUT, ":utf8");
eval { binmode($DB::OUT, ":encoding(shift_jis)"); };

    main: {
	my ($dbh, $cgi, $dbname, $username, $pw, $tmpl,
	    $entr, $entrs, $x, $eid, $seq, @added);
	$cgi = new CGI;

	print "Content-type: text/html\n\n";

	open (F, "../lib/jmdict.cfg") or die ("Can't open database config file\n");
	($dbname, $username, $pw) = split (' ', <F>); close (F);
	$dbh = DBI->connect("dbi:Pg:dbname=$dbname", $username, $pw, 
			{ PrintWarn=>0, RaiseError=>1, AutoCommit=>0 } );
	$dbh->{pg_enable_utf8} = 1;
	$::KW = Kwds ($dbh);

	$x = $cgi->param ("entr");
	$entrs = unserialize ( $x );
	foreach $entr ($entrs) {
	    $entr->{stat} = 1; # Force entr.stat=New.
	    rename_xrefs ($entr);
	    ($eid,$seq) = addentr ($dbh, $entr); 
	    push (@added, [$eid,$seq]); }
	results_page (\@added);
	$dbh->disconnect; }

    sub rename_xrefs { my ($entr) = @_;
	foreach my $s (@{$entr->{_sens}}) {
	    next if (!$s->{_xref});
	    $s->{_eref} = $s->{_xref};  
	    $s->{_xref} = undef; } }

    sub results_page { my ($added) = @_;
	my @m = map ("\n      <a href=\"entr.pl?q=$_->[1]\">$_->[1]</a>", @$added);
	my $seqlnks = join ("    , " , @m);
	print <<EOT;
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
  <title>Entries added</title>
  </head>
<body>
  <h1>Entry Submitted</h1>
  <p/>Thank you for your contribution!
  <p/>Your submission(s) have been added to the JMdict database
    as provsional entries with the following seq. numbers:
  <p/>$seqlnks
  <p/>After review by the JMdict editors, they will be accepted
    and become standard entries, or rejected for reasons that
    will be described in the Comments section.  In either case
    the seq. numbers (and links) given above will show you
    their status.
  </body>
</html>
EOT
	}
