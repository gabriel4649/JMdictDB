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
use POSIX ('strftime');

BEGIN {push (@INC, "../lib");}
use jmdict; use jmdictcgi; use jmdicttal;

$|=1;
binmode (STDOUT, ":utf8");
eval { binmode($DB::OUT, ":encoding(shift_jis)"); };

    main: {
	my ($dbh, $cgi, $tmpl, $entr, $entrs, $x, $eid, $seq, $src, @added, $svc);
	$cgi = new CGI;
	print "Content-type: text/html\n\n";
	$svc = $cgi->param ("svc");
	$dbh = dbopen ($svc);  $::KW = Kwds ($dbh);

	# We do little error checking here because the url parameters came 
	# from one of our pages and should be ok.  If someone synthesizes 
	# bad url parameters, we feel no obligation to give them nice errors
	# messages.  Any serious or security problems will be caught be the 
	# database's integrity checking.  What we do preserve here (because
	# database cannot check this) is the integrity of the history
	# records -- the history records transferred to the new entry *must*
	# come from the old entr (as identified by id received by url) with
	# only one new one (from the submitter) added.  The sequence number
	# and source id must also match the original entry.  New new entries
	# must have only the history record provided by the submitter (not
	# a bunch of fake ones.)  

	$x = $cgi->param ("entr");
	$entrs = unserialize ( $x );
	foreach $entr ($entrs) {
	    if (!$entr->{id}) {	# This is new entry. 
		$entr->{stat} = $::KW->{STAT}{N}{id}; # Force entr.stat=New.
		$entr->{seq} = undef;  # Force addentr() to assign seq number.
		  # Prevent client from inserting extra bogus history.
	        if (1 != scalar(@{$entr->{_hist}})) { die "Expected exactly 1 hist record"; } 
	        $entr->{_hist}[0]{dt} = strftime ("%Y-%m-%d %H:%M:00-00", gmtime()); }
	    else {
		  # Reset seq, src, and history from original entr.
		resethist ($dbh, $entr); }
	        
	    ($eid,$seq,$src) = addentr ($dbh, $entr); 
	    $dbh->commit ();
	    push (@added, [$eid,$seq,$src]); }
	results_page (\@added);
	$dbh->disconnect; }

    sub resethist { my ($dbh, $entr) = @_;
	my ($submitter_hist, $sql, $recs);
	if (1 > scalar(@{$entr->{_hist}})) { die ("No hist records"); } 
	$submitter_hist = $entr->{_hist}[0];
	$submitter_hist->{dt} = strftime ("%Y-%m-%d %H:%M:00-00", gmtime());  
	$entr->{stat} = $::KW->{STAT}{M}{id}; # Force entr.stat=New.
	$sql = "SELECT e.seq,e.src FROM entr e WHERE e.id=?";
	$recs = dbread ($dbh, $sql, [$entr->{id}]);
	if ((scalar(@$recs)) != 1) { die "Entry id $entr->{id} not found, unable to update\n"; }

	if ($entr->{seq} and $entr->{seq} != $recs->[0]{seq}) { 
	    die "Submitted seq number $entr->{seq} does not match original seq number $recs->[0]{seq}\n" }
	if ($entr->{src} and $entr->{src} != $recs->[0]{src}) { 
	    die "Submitted src id $entr->{src} does not match original src id $recs->[0]{src}\n" }
	
	$sql = "SELECT h.* FROM hist h WHERE entr=? ORDER BY h.dt DESC";
	$recs = dbread ($dbh, $sql, [$entr->{id}]);
	unshift (@$recs, $submitter_hist); }

    sub results_page { my ($added) = @_;
	my @m = map ("\n      <a href=\"entr.pl?q=$_->[1].$_->[2]\">$_->[1]</a>", @$added);
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
