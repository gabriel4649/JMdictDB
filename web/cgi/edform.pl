#!/usr/bin/env perl
##########################################################################
#
#   This file is part of JMdictDB.  
#   JMdictDB is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#   JMdictDB is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#   You should have received a copy of the GNU General Public License
#   along with Foobar; if not, write to the Free Software Foundation, Inc.,
#   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
#
#   Copyright (c) 2007 Stuart McGraw 
#
############################################################################

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
	    @pos, @misc);
	binmode (STDOUT, ":encoding(utf-8)");
	$cgi = new CGI;
	print "Content-type: text/html\n\n";

	open (F, "../lib/jmdict.cfg") or die ("Can't open database config file\n");
	($dbname, $username, $pw) = split (/ /, <F>); close (F);
	$dbh = DBI->connect("dbi:Pg:dbname=$dbname", $username, $pw, 
			{ PrintWarn=>0, RaiseError=>1, AutoCommit=>0 } );
	$dbh->{pg_enable_utf8} = 1;
	$::KW = Kwds ($dbh);

	@pos = sort ({$a->{kw} cmp $b->{kw}} kwrecs ($::KW, 'POS'));
	@misc = sort ({$a->{kw} cmp $b->{kw}} kwrecs ($::KW, 'MISC'));

	$tmpl = new Petal (file=>'../lib/tal/nwform.tal', 
			   decode_charset=>'utf-8', output=>'HTML' );
	print $tmpl->process ({pos=>\@pos, misc=>\@misc});
	$dbh->disconnect; }

