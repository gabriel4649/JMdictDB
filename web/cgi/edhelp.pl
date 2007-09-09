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
use CGI; use DBI; 
use Petal; use Petal::Utils; 

BEGIN {push (@INC, "../lib");}
use jmdict; use jmdicttal; use jmdictcgi;

$|=1;
binmode (STDOUT, ":utf8");

    main: {
	my ($dbh, $cgi, $tmpl, @kw, @kwlist, $t, $svc, $kwhash, $kwset);
	$cgi = new CGI;
	print "Content-type: text/html\n\n";
	$svc = clean ($cgi->param ("svc"));
	$dbh = dbopen ($svc);  $::KW = Kwds ($dbh);
	$dbh->disconnect; 

	for $t qw(RINF KINF FREQ MISC POS FLD DIAL LANG GINF SRC STAT XREF) {
	    @kw = kwrecs ($::KW, $t);
	    $kwset = [ucfirst(lc($t)), [sort {lc($a->{kw}) cmp lc($b->{kw})} @kw]];
	    push (@kwlist, $kwset);
	    $kwhash->{$t} = $kwset->[1]; }

	$tmpl = new Petal (file=>'../lib/tal/edhelp.tal', 
			   decode_charset=>'utf-8', output=>'HTML' );
	print $tmpl->process (kwlist=>\@kwlist, kwhash=>$kwhash, svc=>$svc); }

