#!/usr/bin/env perl

# Copyright (c) 2007 Stuart McGraw 
@VERSION = (substr('$Revision$',11,-2), \
	    substr('$Date$',7,-11));

use strict; use warnings;
use Cwd; use CGI; use Encode; use utf8; use DBI; 
use Petal; use Petal::Utils; 

BEGIN {push (@INC, "../lib");}
use jmdict; use jmdicttal;

$|=1;
binmode (STDOUT, ":utf8");

    main: {
	my ($dbh, $cgi, $tmptbl, $tmpl, $dbname, $username, $pw,, 
	    $pos, $misc, @freq, @src, $stat, $i, @x, $kw);
	binmode (STDOUT, ":encoding(utf-8)");
	$cgi = new CGI;
	print "Content-type: text/html\n\n";

	open (F, "../lib/jmdict.cfg") or die ("Can't open database config file\n");
	($dbname, $username, $pw) = split (/ /, <F>); close (F);
	$dbh = DBI->connect("dbi:Pg:dbname=$dbname", $username, $pw, 
			{ PrintWarn=>0, RaiseError=>1, AutoCommit=>0 } );
	$dbh->{pg_enable_utf8} = 1;
	$::KW = Kwds ($dbh);

	@x = sort ({$a->{kw} cmp $b->{kw}} kwrecs ($::KW, 'POS'));
	$pos = reshape (\@x, 10);

	@x = sort ({$a->{kw} cmp $b->{kw}} kwrecs ($::KW, 'MISC'));
	$misc = reshape (\@x, 10);

	@src  = sort ({$a->{kw} cmp $b->{kw}} kwrecs ($::KW, 'SRC'));

	@x = sort ({$a->{descr} cmp $b->{descr}} kwrecs ($::KW, 'STAT'));
	$stat = reshape (\@x, 3);

	for $i (sort ({$a->{kw} cmp $b->{kw}} kwrecs ($::KW, 'FREQ'))) {
	    $kw = $i->{kw};
	    if ($kw ne "nf" and $kw ne "gA") { 
		push (@freq, $kw."1"); 
		if ($kw ne "spec") { push (@freq, $kw."2"); } } }

	$tmpl = new Petal (file=>'../lib/tal/srchform.tal', 
			   decode_charset=>'utf-8', output=>'HTML' );
	print $tmpl->process ({pos=>$pos, misc=>$misc, stat=>$stat, freq=>\@freq});
	$dbh->disconnect; }

    sub reshape { my ($array, $ncols, $default) = @_;
	my ($i, $j, $p, @out);
	for ($i=0; $i<scalar(@$array); $i+=$ncols) {
	    my @row = @{$array}[$i..$i+$ncols-1];
	    push (@out, \@row); }
	return \@out; }
