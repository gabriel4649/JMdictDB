#!/usr/bin/env perl

# Copyright (c) 2007 Stuart McGraw 
@VERSION = (substr('$Revision$',11,-2), \
	    substr('$Date$',7,-11));

use strict; use warnings;
use Cwd; use CGI; use HTML::Entities;
use Encode; use utf8; use DBI; 
use Petal; use Petal::Utils; 

BEGIN {push (@INC, "../lib");}
use jmdict; use jmdicttal;

$|=1;
binmode (STDOUT, ":utf8");
*ee = \&encode_entities;

    main: {
	my ($dbh, $cgi, $tmptbl, $tmpl, $sql, $entries, $e, @qlist, @errs,
	    @elist, @slist, $sens, @whr, $dbname, $username, $pw, $s);
	binmode (STDOUT, ":encoding(utf-8)");
	$cgi = new CGI;
	print "Content-type: text/html\n\n";

	@qlist = $cgi->param ('q'); validateq (\@qlist, \@errs);
	@elist = $cgi->param ('e'); validaten (\@elist, \@errs);
	@slist = $cgi->param ('s'); validaten (\@slist, \@errs);
	if (@errs) { errors_page (\@errs);  exit; } 

	open (F, "../lib/jmdict.cfg") or die ("Can't open database config file\n");
	($dbname, $username, $pw) = split (' ', <F>); close (F);
	$dbh = DBI->connect("dbi:Pg:dbname=$dbname", $username, $pw, 
			{ PrintWarn=>0, RaiseError=>1, AutoCommit=>0 } );
	$dbh->{pg_enable_utf8} = 1;
	$::KW = Kwds ($dbh);

	if (@qlist) { push (@whr, "e.seq IN (" . join(",",map('?',(@qlist))) . ")"); }
	if (@elist) { push (@whr, "e.id  IN (" . join(",",map('?',(@elist))) . ")"); }
	if (@slist) { push (@whr, "s.id  IN (" . join(",",map('?',(@slist))) . ")"); }
	if (@slist) { $sens = "JOIN sens s ON s.entr=e.id"; }
	else { $sens = ""; }
	$sql = "SELECT e.id FROM entr e $sens WHERE " . join (" OR ", @whr);
	$tmptbl = Find ($dbh, $sql, [@qlist, @elist, @slist]);
	$entries = EntrList ($dbh, $tmptbl);

	irestr ($entries); istagr ($entries); istagk ($entries); 
	combine_stag ($entries); set_audio_flag ($entries);
	
	$tmpl = new Petal (file=>'../lib/tal/entr.tal', 
			   decode_charset=>'utf-8', output=>'HTML' );
	print $tmpl->process (entries=>$entries, KW=>$::KW);
	$dbh->disconnect; }

    sub combine_stag { my ($entrs) = @_; 
	foreach my $e (@$entrs) {
	    foreach my $s (@{$e->{_sens}}) {
		$s->{_stag} = [];
		if ($s->{_stagr}) { push (@{$s->{_stag}}, @{$s->{_stagr}}); }
		if ($s->{_stagk}) { push (@{$s->{_stag}}, @{$s->{_stagk}}); } } } }

    sub set_audio_flag { my ($entrs) = @_; 
	my ($e, $r, $found);
	foreach $e (@$entrs) {
	    $found = 0;
	    foreach $r (@{$e->{_rdng}}) {
		if ($r->{_audio}) { $found = 1; last; } }
	    $e->{has_audio} = $found; } }

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
