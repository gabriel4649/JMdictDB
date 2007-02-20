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
use jmdict; use jmdicttal;

$|=1;
binmode (STDOUT, ":utf8");

    main: {
	my ($dbh, $cgi, $tmptbl, $tmpl, 
	    $pos, $misc, @freq, @src, $stat, $i, @x, $kw);
	binmode (STDOUT, ":encoding(utf-8)");
	$cgi = new CGI;
	print "Content-type: text/html\n\n";
	$dbh = dbopen ();  $::KW = Kwds ($dbh);

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
		push (@freq, $kw."2"); } }

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
