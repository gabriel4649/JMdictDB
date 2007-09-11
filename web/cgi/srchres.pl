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
use Cwd; use CGI; use Encode 'decode_utf8'; use DBI; 
use Petal; use Petal::Utils; use Time::HiRes('time');

use lib ("../lib", "./lib", "../perl/lib");
use jmdict; use jmdicttal; use jmdictcgi;

$|=1;
binmode (STDOUT, ":utf8");

    main: {
	my ($dbh, $cgi, $tmpl, @s, @y, @t, $col, @kinf, @rinf, @fld, $svc, $svcstr,
	    @pos, @misc, @src, @stat, @freq, $nfval, $nfcmp, $gaval, $gacmp, @appr, 
	    $idval, $idtbl, $sql, $sql_args, $sql2, $rs, $i, $freq, @condlist,
	    $force_srchres);
	binmode (STDOUT, ":encoding(utf-8)");
	$cgi = new CGI;
	$svc = clean ($cgi->param ("svc"));
	$dbh = dbopen ($svc);  $::KW = Kwds ($dbh);

	$s[0]=$cgi->param("s1"); $y[0]=$cgi->param("y1"); $t[0]=decode_utf8($cgi->param("t1"));
	$s[1]=$cgi->param("s2"); $y[1]=$cgi->param("y2"); $t[1]=decode_utf8($cgi->param("t2"));
	$s[2]=$cgi->param("s3"); $y[2]=$cgi->param("y3"); $t[2]=decode_utf8($cgi->param("t3"));
	@pos=$cgi->param("pos");   @misc=$cgi->param("misc"); @fld=$cgi->param("fld");
	@rinf=$cgi->param("rinf"); @kinf=$cgi->param("kinf"); @freq=$cgi->param("freq");
	@src=$cgi->param("src");   @stat=$cgi->param("stat"); @appr=$cgi->param('appr'); 
	$nfval=$cgi->param("nfval"); $nfcmp=$cgi->param("nfcmp");
	$gaval=$cgi->param("gaval"); $gacmp=$cgi->param("gacmp");
	$idval=$cgi->param("idval"); $idtbl=$cgi->param("idtyp");
	$force_srchres = $cgi->param ("srchres"); # Force display of srchres page even if only one result.

	# The followng will convert substrings like '\u6a8e' into
	# a unicode character.  Sequences like this often occur
	# when pasting text between remote unix VNC sessions, and
	# a MS Windows application.
	1 while $t[0] =~ s/(\\u([0-9a-f]{4}))/chr(hex($2))/ei;	
	1 while $t[1] =~ s/(\\u([0-9a-f]{4}))/chr(hex($2))/ei;	
	1 while $t[2] =~ s/(\\u([0-9a-f]{4}))/chr(hex($2))/ei;	

	if ($idval) {	# Search for id number...
	    if ($idtbl ne "seqnum") { $col = "id"; }
	    else { $idtbl = "entr e";  $col = "seq"; }
	    push (@condlist, [$idtbl, sprintf ("e.%s=?", $col), [$idval]]);
	    if ($col eq "seq" and @src)  { 
		push (@condlist, ["entr e",getsel("e.src", \@src), []]); }
	    ($sql, $sql_args) = build_search_sql (\@condlist); }
	else {
	    for $i (0..2) {
		if ($t[$i]) { 
		    push (@condlist, str_match_clause ($s[$i],$y[$i],$t[$i],$i)); } }
	    if (@pos)  { push (@condlist, ["pos",   getsel("pos.kw",  \@pos), []]); }
	    if (@misc) { push (@condlist, ["misc",  getsel("misc.kw", \@misc),[]]); }
	    if (@fld)  { push (@condlist, ["fld",   getsel("fld.kw",  \@fld), []]); }
	    if (@kinf) { push (@condlist, ["kinf",  getsel("kinf.kw", \@kinf),[]]); }
	    if (@rinf) { push (@condlist, ["rinf",  getsel("rinf.kw", \@rinf),[]]); }
	    if (@src)  { push (@condlist, ["entr e",getsel("e.src",   \@src), []]); }
	    if (@stat) { push (@condlist, ["entr e",getsel("e.stat",  \@stat),[]]); }
	    if (@appr) { push (@condlist, ["entr e",getbool("e.unap",  \@appr),[]]); }
	    if (@freq) { push (@condlist, freq_srch_clause (\@freq, $nfval, $nfcmp, $gaval, $gacmp)); }
	    ($sql, $sql_args) = build_search_sql (\@condlist); }

	$::Debug->{'Search sql'} = $sql;  $::Debug->{'Search args'} = join(",", @$sql_args);
	$sql2 = sprintf ("SELECT q.* FROM esum q JOIN (%s) AS i ON i.id=q.id", $sql);
	my $start = time();
	eval { $rs = dbread ($dbh, $sql2, $sql_args); };
	$::Debug->{'Search time'} = time() - $start;
	if ($@) {
	    print "Content-type: text/html\n\n<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"/></head><body>";
	    print "<pre> $@ </pre>\n<pre>$sql2</pre>\n<pre>".join(", ", @$sql_args)."</pre></body></html>\n";
	    exit (1); }
	if (scalar (@$rs) == 1 && !$force_srchres) {
	    $svcstr = $svc ? "svc=$svc&" : "";
	    printf ("Location: entr.pl?${svcstr}e=%d\n\n", $rs->[0]{id}); }
	else {
	    print "Content-type: text/html\n\n";
	    $tmpl = new Petal (file=>find_in_inc("tal")."/tal/srchres.tal", 
			   decode_charset=>'utf-8', output=>'HTML' );
	    print $tmpl->process (results=>$rs, svc=>$svc, dbg=>$::Debug); }
	$dbh->disconnect; }

    sub str_match_clause { my ($srchin, $srchtyp, $srchtxt, $idx) = @_; 
	my ($x, $table, $alias, $whr, @args, $column);
	if ($srchin eq "auto") {
	    $x = jstr_classify ($srchtxt);
	    if ($x & $jmdict::KANJI) { $table = "kanj";  }
	    elsif ($x & $jmdict::KANA) { $table = "rdng"; }
	    else { $table = "gloss"; } }
	else { $table = $srchin; }
	$alias = " " . {kanj=>"j", rdng=>"r", gloss=>"g"}->{$table} . "$idx"; 
	$srchtyp = lc($srchtyp);

	  # The following generates implements case insensitive search
	  # for gloss searches, and non-"is" searches using the sql LIKE
	  # operator.  The case-insensitive part is a work-around for
	  # Postgresql's lack of support for standard SQL's COLLATION
	  # feature.  We can't use ILIKE for case-insensitive searches
	  # because it won't use an index and thus is very slow (~25s
	  # vs ~.2s with index on developer's machine.  So instead, we
	  # created two functional indexes on gloss.txt: "lower(txt)"
	  # and "lower(txt) varchar-pattern-ops".  The former will be
	  # used for "lower(xx)=..." searches and the latter for
	  # "lower(xx) LIKE ..." searches.  So when do a gloss search,
	  # we need to lowercase the search text, and generate a search
	  # clause in one of the above forms.  
	  #
	  # To-do: LIKE 'xxx%' dosn't use index unless the argument value 
	  # is embedded in the sql (which we don't currently do).  When
	  # the 'xxx%' is supplied as a separate argument, the query
	  # planner (runs when the sql is parsed) can't use index because
	  # it doesn't have access to the argument (which is only available
	  # when the query is executed) and doesn't know that it is not
	  # something like '%xxx'.

	if ($table eq "gloss") {
	    $srchtxt = lc ($srchtxt); 
	    $column = "lower($alias.txt)"; }
	else { $column = "$alias.txt"; }
	if ($srchtyp eq "is") { $whr = "$column=?"; }
	else { $whr = "$column LIKE(?)"; }

	  # Now generate the argument list appropriate for the
	  # search clause.

	if ($srchtyp eq "is") 		{ @args = ($srchtxt); } 
	elsif ($srchtyp eq "starts")	{ @args = ($srchtxt."%",); }
	elsif ($srchtyp eq "contains")	{ @args = ("%".$srchtxt."%"); }
	elsif ($srchtyp eq "ends")	{ @args = ("%".$srchtxt); }
	else { die "Unknown srchtyp value encountered in str_match_clause(): $srchtyp\n"; }

	return ["$table$alias",$whr,\@args]; }

    sub getsel { my ($fqcol, $itms) = @_;
	my $s = sprintf ("%s IN (%s)", $fqcol, join(",", map (int($_), @$itms)));
	return $s; }

    sub getbool { my ($fqcol, $itms) = @_;
	my $s = join (" OR ", map (int($_) ? $fqcol : "NOT $fqcol ", @$itms));
	return "($s)"; }

    sub freq_srch_clause { my ($freq, $nfval, $nfcmp, $gaval, $gacmp) = @_;
	# Create a pair of 3-tuples (build_search_sql() "conditions")
	# that build_search_sql() will use to create a sql statement 
	# that will incorporate the freq-of-use criteria defined by
	# our parameters:
	#
	# $freq -- List of string values of a freq option checkboxes, e.g. "ichi2".
	# $nfval -- String containing an "nf" number ("1" - "48").
	# $nfcmp -- String containing one of ">=", "=", "<=".
	# gaval -- String containing a gA number.
	# gacmp -- Same as nfcmp.

	my ($f, $domain, $value, %x, $k, $v, $kwid, @whr, $whr);

	# Freq items consist of a domain (such as "ichi" or "nf")
	# and a value (such as "1" or "35").
	# Process the checkboxes by creating a hash indexed by 
	# by domain and with each value a list of freq values.

	foreach $f (@$freq) {
	    # Split into text (domain) and numeric (value) parts.
	    ($domain, $value) = ($f =~ m/(^[A-Za-z_-]+)(\d*)$/);
	    # We will handle "nfxx" and "gAxxxx" later.
	    next if ($domain eq "nf" or $domain eq "ga");
	    # If this domain not in hash yet, add it.
	    if (!defined ($x{$domain})) { $x{$domain} = []; }
	    # Append this value to the list.
	    push (@{$x{$domain}}, $value); }

	# Now process each domain and it's list of values...

	while (($k,$v) = each (%x)) {
	    # Convert the domain string to a kwfreq table id number.
	    $kwid = $::KW->{FREQ}{$k}{id};

	    # The following assumes that the range of values are 
	    # limited to 1 and 2.

	    if (scalar(@$v)==2) { push (@whr, sprintf (
		# As an optimization, if there are 2 values, they must be 1 and 2, 
		# so no need to check value in query, just see if the domain exists.
		# FIXME: The above is false, there could be two "1" values.
		# FIXME: The above assumes only 1 and 2 are allowed.  Currently
		#   true but may change in future.
		"(freq.kw=%s)", $kwid)); }
	    elsif (scalar(@$v) == 1) { push (@whr, sprintf (
		# If there is only one value we need to look for kw with
		# that value.
		"(freq.kw=%s AND freq.value=%s)", $kwid, $v->[0])); }
	    elsif (scalar(@$v) > 2) { push (@whr, sprintf (
		# If there are more than 2 values then we look for them explicitly
		# using an IN() construct.
		"(freq.kw=%s AND freq.value IN (%s))", $k, join(",",@$v))); }
	    # A 0 or negative length list should be impossible.
	    else { die; } }

	# Handle the "nfxx" items specially here.

	if (grep ($_ eq "nf", @$freq) and $nfval) {
	    # Convert the domain string to a kwfreq table id number.
	    $kwid = $::KW->{FREQ}{nf}{id};
	    # Build list of "where" clause parts using the requested comparison and value.
	    push (@whr, sprintf (
		"(freq.kw=%s AND freq.value%s%s)", $kwid, $nfcmp, $nfval)); }

	# Handle the "gAxx" items specially here.

	if (grep ($_ eq "ga", @$freq) and $gaval) {
	    # Convert the domain string to a kwfreq table id number.
	    $kwid = $::KW->{FREQ}{gA}{id};
	    # Build list of "where" clause parts using the requested comparison and value.
	    push (@whr, sprintf (
		"(freq.kw=%s AND freq.value%s%s)", $kwid, $gacmp, $gaval)); }

	# Now, @whr is a list of all the various freq ewlated conditions that 
	# were  selected.  We change it into a clause by connecting them all 
	# with " OR".
	$whr = "(" . join(" OR ", @whr) . ")";

	# If there were no freq related conditions...
	return [] if (!$whr);

	# Return two triples suitable for use by build-search_sql().  That function
	# will build sql that effectivly "AND"s all the conditions (each specified 
	# in a triple) given to it.  Our freq conditions applies to two tables 
	# (rfreq and kfreq) and we want them OR'd not AND'd.  So we cheat and use a
	# strisk in front of table name to tell build_search_sql() to use left joins
	# rather than inner joins when refering to that condition's table.  This will
	# result in the inclusion in the result set of rfreq rows that match the
	# criteria, even if there are no matching kfreq rows (and visa versa). 
	# The where clause refers to both the rfreq and kfreq tables, so need only
	# be given in one constion triple rather than in each. 
	return (["freq",$whr,[]]); }
