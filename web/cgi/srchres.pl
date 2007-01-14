#!/usr/bin/env perl

# Copyright (c) 2007 Stuart McGraw 
@VERSION = (substr('$Revision$',11,-2), \
	    substr('$Date$',7,-11));

use strict; use warnings;
use Cwd; use CGI; use Encode 'decode_utf8'; use DBI; 
use Petal; use Petal::Utils; 

BEGIN {push (@INC, "../lib");}
use jmdict; use jmdicttal;

$|=1;
binmode (STDOUT, ":utf8");

    main: {
	my ($dbh, $cgi, $dbname, $username, $pw, $tmpl, @s, @y, @t, 
	    @pos, @misc, @src, @freq, $nfval, $nfcmp, $idval, $col,
	    $idtbl, $sql, $sql_args, $sql2, $rs, $i, $freq, @condlist);
	binmode (STDOUT, ":encoding(utf-8)");
	$cgi = new CGI;

	open (F, "../lib/jmdict.cfg") or die ("Can't open database config file\n");
	($dbname, $username, $pw) = split (' ', <F>); close (F);
	$dbh = DBI->connect("dbi:Pg:dbname=$dbname", $username, $pw, 
			{ PrintWarn=>0, RaiseError=>1, AutoCommit=>0 } );
	$dbh->{pg_enable_utf8} = 1;
	$::KW = Kwds ($dbh);
	
	$s[0]=$cgi->param("s1"); $y[0]=$cgi->param("y1"); $t[0]=decode_utf8($cgi->param("t1"));
	$s[1]=$cgi->param("s2"); $y[1]=$cgi->param("y2"); $t[1]=decode_utf8($cgi->param("t2"));
	$s[2]=$cgi->param("s3"); $y[2]=$cgi->param("y3"); $t[2]=decode_utf8($cgi->param("t3"));
	@pos=$cgi->param("pos"); @misc=$cgi->param("misc");
	@src=$cgi->param("src"); @freq=$cgi->param("freq");
	$nfval=$cgi->param("nfval"); $nfcmp=$cgi->param("nfcmp");
	$idval=$cgi->param("idval"); $idtbl=$cgi->param("idtyp");

	if ($idval) {	# Search for id number...
	    if ($idtbl ne "seqnum") { $col = "id"; }
	    else { $idtbl = "entr";  $col = "seq"; }
	    ($sql, $sql_args) = build_search_sql (
		[[$idtbl, sprintf ("%s.%s=?", $idtbl, $col), [$idval]]]); }
	else {
	    for $i (0..2) {
		if ($t[$i]) { 
		    push (@condlist, str_match_clause ($s[$i],$y[$i],$t[$i],$i)); } }
	    if (@pos) { push  (@condlist, ["pos", getsel("pos.kw",  \@pos), []]); }
	    if (@misc) { push (@condlist, ["misc",getsel("misc.kw", \@misc),[]]); }
	    if (@src) { push  (@condlist, ["entr",getsel("entr.src",\@src), []]); }
	    if (@freq) { push (@condlist, freq_srch_clause (\@freq, $nfval, $nfcmp)); }
	    ($sql, $sql_args) = build_search_sql (\@condlist); }

	$sql2 = sprintf ("SELECT q.* FROM entr_summary q JOIN (%s) AS i ON i.id=q.id", $sql);
	eval { $rs = dbread ($dbh, $sql2, $sql_args); };
	if ($@) {
	    print "Content-type: text/html\n\n<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"/></head><body>";
	    print "<pre> $@ </pre>\n<pre>$sql2<\pre>\n<pre>".join(", ", @$sql_args)."</pre></body></html>\n";
	    exit (1);
	    }
	if (scalar (@$rs) == 1) {
	    printf ("Location: entr.pl?e=%d\n\n", $rs->[0]{id}); }
	else {
	    print "Content-type: text/html\n\n";
	    $tmpl = new Petal (file=>'../lib/tal/srchres.tal', 
			   decode_charset=>'utf-8', output=>'HTML' );
	    print $tmpl->process (results=>$rs, sql=>$sql); }
	$dbh->disconnect; }

    sub str_match_clause { my ($srchin, $srchtyp, $srchtxt, $idx) = @_; 
	my ($x, $table, $alias, $whr, @args);
	if ($srchin eq "auto") {
	    $x = jstr_classify ($srchtxt);
	    if ($x & $::KANJI) { $table = "kanj";  }
	    elsif ($x & $::KANA) { $table = "rdng"; }
	    else { $table = "gloss"; } }
	else { $table = $srchin; }
	$alias = " " . {kanj=>"j", rdng=>"r", gloss=>"g"}->{$table} . "$idx";
	$srchtyp = lc ($srchtyp);
	if ($srchtyp eq "is")		{ $whr = sprintf ("%s.txt=?", $alias); }
	else				{ $whr = sprintf ("%s.txt LIKE(?)", $alias); }
	if ($srchtyp eq "is")		{ @args = ($srchtxt); }
	elsif ($srchtyp eq "starts")	{ @args = ($srchtxt."%",); }
	elsif ($srchtyp eq "contains")	{ @args = ("%".$srchtxt."%"); }
	elsif ($srchtyp eq "ends")	{ @args = ("%".$srchtxt); }
	else { die ("srchtyp = " . $srchtyp); }
	return ["$table$alias",$whr,\@args]; }

    sub getsel { my ($fqcol, $itms) = @_;
	my $s = sprintf ("%s IN (%s)", $fqcol, join(",", @$itms));
	return $s; }

    sub freq_srch_clause { my ($freq, $nfval, $nfcmp) = @_;
	my ($f, $domain, $value, %x, $k, $v, $kwid, @whr, $whr);
	foreach $f (@$freq) {
	    ($domain, $value) = ($f =~ m/(^[A-Za-z_-]+)(\d*)$/);
	    next if ($domain eq "nf");
	    if (!defined ($x{$domain})) { $x{$domain} = []; }
	    push (@{$x{$domain}}, $value); }
	while (($k,$v) = each (%x)) {
	    $kwid = $::KW->{FREQ}{$k}{id};
	    if (scalar(@$v)==2 or $k eq"spec") { push (@whr, sprintf (
		"(kfreq.kw=%s OR rfreq.kw=%s)", $kwid,$kwid)); }
		# Above assumes only values possible are 1 and 2.
	    elsif (scalar(@$v) == 1) { push (@whr, sprintf (
		"((kfreq.kw=%s AND kfreq.value=%s) OR (rfreq.kw=%s AND rfreq.value=%s))",
		$kwid, $v->[0], $kwid, $v->[0])); }
	    elsif (scalar(@$v) > 2) { push (@whr, sprintf (
		"((kfreq.kw=%s AND kfreq.value IN (%s)) OR (rfreq.kw=%s AND rfreq.value IN (%s)))",
		$k, join(",",@$v), $k, join(",",@$v))); }
	    else { die; } }
	if (grep ($_ eq "nf", @$freq) and $nfval) {
	    $kwid = $::KW->{FREQ}{nf}{id};
	    push (@whr, sprintf (
		"((kfreq.kw=%s AND kfreq.value%s%s) OR (rfreq.kw=%s AND rfreq.value%s%s))",
		$kwid, $nfcmp, $nfval,  $kwid, $nfcmp, $nfval)); }
	$whr = "(" . join(" OR ", @whr) . ")";
	return [] if (!$whr);
	return (["*rfreq","",[]],["*kfreq",$whr,[]]); }

    sub build_search_sql { my ($condlist) = @_;

	# Build a sql statement that will find the id numbers of
	# all entries matching the conditions given in <condlist>.
	# Note: This function does not provide for generating
	# arbitrary SQL statements; it is only intented to support 
	# limited search capabilities that are typically provided 
	# on a search form.
	#
	# <condlist> is a list of 3-tuples.  Each 3-tuple specifies
	# one condition:
	#   0: Name of table that contains the field being searched
	#     on.  The name may optionally be followed by a space and
	#     an alias name for the table.  It may also optionally be
	#     preceeded (no space) by an astrisk character to indicate
	#     the table should be joinded with a LEFT JOIN rather than
	#     the default INNER JOIN. 
	#   1: Sql snippit that will be AND'd into the WHERE clause.
	#     Field names must be qualified by table.  When looking 
	#     for a value in a field.  A "?" may (and should) be used 
	#     where possible to denote an exectime parameter.  The value
	#     to be used when the sql is executed is is provided in
	#     the 3rd member of the tuple (see #2 next).
	#   2: A sequence of argument values for any exec-time parameters
	#     ("?") used in the second value of the tuple (see #1 above).
	#
	# Example:
	#     [("entr","entr.typ=1", ()),
	#      ("gloss", "gloss.text LIKE ?", ("'%'+but+'%'",)),
	#      ("pos","pos.kw IN (?,?,?)",(8,18,47))]
	#
	#   This will generate the SQL statement and arguments:
	#     "SELECT entr.id FROM (((entr INNER JOIN sens ON sens.entr=entr.id) 
	# 	INNER JOIN gloss ON gloss.sens=sens.id) 
	# 	INNER JOIN pos ON pos.sens=sens.id) 
	# 	WHERE entr.typ=1 AND (gloss.text=?) AND (pos IN (?,?,?))"
	#     ('but',8,18,47)
	#   which will find all entries that have a gloss containing the
	#   substring "but" and a sense with a pos (part-of-speech) tagged
	#   as a conjunction (pos.kw=8), a particle (18), or an irregular
	#   verb (47).

	my (%rels, %tables, @tables, @wclauses, @args, $tbl, 
	    $cond, $arg, $tnm, $frm, $where, $sql, $itm);

	%rels = (dial=>"entr", lang=>"entr", hist=>"entr",
		 rdng=>"entr", kanj=>"entr", sens=>"entr",
		 rinf=>"rdng", rfreq=>"rdng", audio=>"rdng", stagr=>"rdng",
		 kinf=>"kanj", kfreq=>"kanj",
		 gloss=>"sens", pos=>"sens", misc=>"sens", fld=>"sens", 
		 stagr=>"sens", stagk=>"sens", xref=>"sens", );

	foreach $itm (@$condlist) {
	    ($tbl, $cond, $arg) = @$itm;
	      ##Add tbl, and all of tbl's parents to the table list.  
	    while ($tbl) {
		$tnm = ($tbl =~ m/([_a-zA-Z0-9]+)/)[0];
		$tables{$tbl} = 1;
		$tbl = $rels{$tnm}; }
	    push (@wclauses, $cond);
	    push (@args, @$arg); }
	$frm = mk_from_clause( [keys (%tables)], \%rels );
	$where = join (" AND ", grep ($_, @wclauses));
	$sql = sprintf ("SELECT DISTINCT entr.id FROM %s WHERE %s", $frm, $where);
	return ($sql, \@args); }

    sub mk_from_clause { my ($tables, $rels) = @_;
	# Given a list of tables, @$tables, and a hash, %$rels, that 
	# for each possible table in 'tables' give the parent table, 
	# create a string that can be used in a SQL "FROM" clause that
	# joins all the tables.  We assume that the primary key column
	# of each parent table is named "id" and the foreign key column
	# of each child table has the same name as the parent table. 
	# The table in 'tables' may be just a table name, or may be a
	# table name followed by a space and an alias.

	my (@otables, $clause, $tb, $tx, $tbl, $join, $alias);
	@otables = ("entr","rdng","rinf","rfreq","kanj","kinf","kfreq",
		    "sens","gloss","pos","misc","fld","dial","lang");
	$clause = "";
	foreach $tb (@otables) {
	    foreach $tx (@$tables) {
		($tbl, $alias) = (split (' ', $tx), "");
		if (substr ($tbl, 0, 1) eq "*") {
		    $join = "LEFT JOIN";
		    $tbl = substr ($tbl, 1); }
		else { $join = "JOIN"; }
		next if ($tbl ne $tb);
		if (!$clause) { $clause = $tbl; }
		else { $clause = sprintf ("(%s %s %s %s ON %s.%s=%s.%s)" , 
		    $clause, $join, $tbl, $alias, $alias || $tbl, 
		    $rels->{$tbl}, $rels->{$tbl}, "id"); } } }
	return $clause; }
