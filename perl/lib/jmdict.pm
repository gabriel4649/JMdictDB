package jmdict;
# Copyright (c) 2006,2007 Stuart McGraw 
@VERSION = (substr('$Revision$',11,-2), \
	    substr('$Date$',7,-11));

package main;
use strict; use warnings;

    sub dbread { my ($dbh, $sql, $args) = @_;
	my ($sth, @rs, $r);
	if (!defined ($args)) {$args = []; }
	#my $x = join (", ", @$args);  print "$sql, ($x)\n";
	$sth = $dbh->prepare_cached ($sql);
	$sth->execute (@$args);
	while ($r = $sth->fetchrow_hashref) { push (@rs, $r); }
	return \@rs; }

    sub Kwds { my ($dbh) = @_;
	my (%kw);
	$kw{DIAL} = $dbh->selectall_hashref("SELECT * FROM kwdial", "kw"); addids ($kw{DIAL});
	$kw{FLD}  = $dbh->selectall_hashref("SELECT * FROM kwfld",  "kw"); addids ($kw{FLD});
	$kw{FREQ} = $dbh->selectall_hashref("SELECT * FROM kwfreq", "kw"); addids ($kw{FREQ});
	$kw{KINF} = $dbh->selectall_hashref("SELECT * FROM kwkinf", "kw"); addids ($kw{KINF});
	$kw{LANG} = $dbh->selectall_hashref("SELECT * FROM kwlang", "kw"); addids ($kw{LANG});
	$kw{MISC} = $dbh->selectall_hashref("SELECT * FROM kwmisc", "kw"); addids ($kw{MISC});
	$kw{POS}  = $dbh->selectall_hashref("SELECT * FROM kwpos",  "kw"); addids ($kw{POS});
	$kw{RINF} = $dbh->selectall_hashref("SELECT * FROM kwrinf", "kw"); addids ($kw{RINF});
	$kw{SRC}  = $dbh->selectall_hashref("SELECT * FROM kwsrc",  "kw"); addids ($kw{SRC});
	$kw{STAT} = $dbh->selectall_hashref("SELECT * FROM kwstat", "kw"); addids ($kw{STAT});
	$kw{XREF} = $dbh->selectall_hashref("SELECT * FROM kwxref", "kw"); addids ($kw{XREF});
	return \%kw; }

    sub addids { my ($hashref) = @_;
	foreach my $v (values (%$hashref)) { $hashref->{$v->{id}} = $v; } }    

    sub mktmptbl { my ($dbh) = @_;
	my ($tmpnm, $cset, $i);
	$cset = "abcdefghijklmnopqrstuvwxyz0123456789";
	for ($i=0; $i<8; $i++) {
	    $tmpnm .= substr ($cset, rand (length($cset)), 1); }
	return "_tmp" . $tmpnm; }

    sub Find { my ($dbh, $sql, $args) = @_;
	my ($s, $sth, $tmpnm);
	$tmpnm = mktmptbl ($dbh);
	$s = "CREATE TEMPORARY TABLE $tmpnm (id INT NOT NULL PRIMARY KEY, ord SERIAL);";
	$sth = $dbh->prepare_cached ($s);
	$sth->execute (); 
	$s = "INSERT INTO $tmpnm(id) ($sql);";
	$sth = $dbh->prepare ($s);
	$sth->execute (@$args);
	return $tmpnm; }

    sub EntrList { my ($dbh, $cond, $args, $eord) = @_;
	my ($where, $com);
	if (!defined ($args)) {$args = []; }
	if (-1 != index ($cond, " ")) { 
	    $where = $cond; 
	    $com = "FROM entr e"; }
	else {  
	    $where = ""; 
	    $com = "FROM entr e JOIN $cond t ON t.id=e.id ";
	    $eord = "ORDER BY t.ord" }

	my $entr  = dbread ($dbh, "SELECT e.* $com $where $eord", $args);
	my $dial  = dbread ($dbh, "SELECT x.* $com JOIN dial x ON x.entr=e.id $where;", $args);
	my $lang  = dbread ($dbh, "SELECT x.* $com JOIN lang x ON x.entr=e.id $where;", $args);
	my $hist  = dbread ($dbh, "SELECT x.* $com JOIN hist x ON x.entr=e.id $where;", $args);
	my $rdng  = dbread ($dbh, "SELECT r.* $com JOIN rdng r ON r.entr=e.id $where ORDER BY r.entr,r.ord;", $args);
	my $rfreq = dbread ($dbh, "SELECT x.* $com JOIN rdng r ON r.entr=e.id JOIN rfreq x ON x.rdng=r.id $where;", $args);
	my $rinf  = dbread ($dbh, "SELECT x.* $com JOIN rdng r ON r.entr=e.id JOIN rinf  x ON x.rdng=r.id $where;", $args);
	my $audio = dbread ($dbh, "SELECT x.* $com JOIN rdng r ON r.entr=e.id JOIN audio x ON x.rdng=r.id $where;", $args);
	my $kanj  = dbread ($dbh, "SELECT k.* $com JOIN kanj k ON k.entr=e.id $where ORDER BY k.entr,k.ord;", $args);
	my $kfreq = dbread ($dbh, "SELECT x.* $com JOIN kanj k ON k.entr=e.id JOIN kfreq x ON x.kanj=k.id $where;", $args);
	my $kinf  = dbread ($dbh, "SELECT x.* $com JOIN kanj k ON k.entr=e.id JOIN kinf  x ON x.kanj=k.id $where;", $args);
	my $sens  = dbread ($dbh, "SELECT s.* $com JOIN sens s ON s.entr=e.id $where ORDER BY s.entr,s.ord;", $args);
	my $gloss = dbread ($dbh, "SELECT x.* $com JOIN sens s ON s.entr=e.id JOIN gloss x ON x.sens=s.id $where ORDER BY x.sens,x.ord;", $args);
	my $misc  = dbread ($dbh, "SELECT x.* $com JOIN sens s ON s.entr=e.id JOIN misc  x ON x.sens=s.id $where;", $args);
	my $pos   = dbread ($dbh, "SELECT x.* $com JOIN sens s ON s.entr=e.id JOIN pos   x ON x.sens=s.id $where;", $args);
	my $fld   = dbread ($dbh, "SELECT x.* $com JOIN sens s ON s.entr=e.id JOIN fld   x ON x.sens=s.id $where;", $args);
	my $restr = dbread ($dbh, "SELECT x.* $com JOIN rdng r ON r.entr=e.id JOIN restr x ON x.rdng=r.id $where;", $args);
	my $stagr = dbread ($dbh, "SELECT x.* $com JOIN sens s ON s.entr=e.id JOIN stagr x ON x.sens=s.id $where;", $args);
	my $stagk = dbread ($dbh, "SELECT x.* $com JOIN sens s ON s.entr=e.id JOIN stagk x ON x.sens=s.id $where;", $args);
	my $xref  = dbread ($dbh, "SELECT x.sens,x.typ,z.id,z.seq,z.txt $com JOIN sens s ON s.entr=e.id JOIN xref x ON x.sens=s.id JOIN sref z ON z.sid=x.xref GROUP BY x.sens,x.typ,z.id,z.seq,z.txt ORDER BY x.sens,x.typ $where;", $args);
	my $xrer  = dbread ($dbh, "SELECT x.xref,x.typ,z.id,z.seq,z.txt $com JOIN sens s ON s.entr=e.id JOIN xref x ON x.xref=s.id JOIN sref z ON z.sid=x.sens GROUP BY x.xref,x.typ,z.id,z.seq,z.txt ORDER BY x.xref,x.typ $where;", $args);

	matchup ($entr, "_dial",  $dial,  "entr");
	matchup ($entr, "_lang",  $lang,  "entr");
	matchup ($entr, "_rdng",  $rdng,  "entr");
	matchup ($entr, "_kanj",  $kanj,  "entr");
	matchup ($entr, "_sens",  $sens,  "entr");
	matchup ($entr, "_hist",  $hist,  "entr");
	matchup ($rdng, "_rfreq", $rfreq, "rdng");
	matchup ($rdng, "_rinf",  $rinf,  "rdng");
	matchup ($rdng, "_audio", $audio, "rdng");
	matchup ($kanj, "_kfreq", $kfreq, "kanj");
	matchup ($kanj, "_kinf",  $kinf,  "kanj");
	matchup ($sens, "_gloss", $gloss, "sens");
	matchup ($sens, "_pos",   $pos,   "sens");
	matchup ($sens, "_misc",  $misc,  "sens");
	matchup ($sens, "_fld",   $fld,   "sens");
	matchup ($rdng, "_restr", $restr, "rdng");
	matchup ($sens, "_stagr", $stagr, "sens");
	matchup ($sens, "_stagk", $stagk, "sens");
	matchup ($sens, "_xref",  $xref,  "sens");
	matchup ($sens, "_xrer",  $xrer,  "xref");
	return $entr; }

    sub matchup { my ($parents, $attrname, $children, $fkname) = @_;
	my ($p, $c, $fk, $found);
	foreach $p (@$parents) { $p->{$attrname} = (); }
	foreach $c (@$children) {
	    $fk = $c->{$fkname};  $found = 0;
	    for $p (@$parents) {
		if ($p->{id} eq $fk) {
		    $found = 1;
		    push (@{$p->{$attrname}}, $c);
		    last; } }
	    if (!$found) { die ("Parent not found, fk=$fk\n"); } } }

    sub irestr { my ($entrs) = @_; 
	my ($e, $r, $nkanj, $rk, $restrs);
	foreach $e (@$entrs) {
	    $restrs = 0;
	    $nkanj = $e->{_kanj} ? scalar (@{$e->{_kanj}}) : 0;
	    foreach $r (@{$e->{_rdng}}) {
		if (!$r->{_restr}) { $r->{_restr} = []; next; } # All kanji ok.
		$restrs = 1;
		if (scalar (@{$r->{_restr}}) == $nkanj) { 
		    $r->{_restr} = 1; next; } # nokanji
		$rk = filt ($e->{_kanj}, $r->{_restr}, "kanj"); 
		$r->{_restr} = $rk; }
	    $e->{_restr} = $restrs; } }

    sub istagr { my ($entrs) = @_; 
	foreach my $e (@$entrs) {
	    foreach my $s (@{$e->{_sens}}) {
		if ($s->{_stagr}) { $s->{_stagr} = filt ($e->{_rdng}, $s->{_stagr}, "rdng"); } } } }

    sub istagk { my ($entrs) = @_; 
	foreach my $e (@$entrs) {
	    foreach my $s (@{$e->{_sens}}) {
		if ($s->{_stagk}) { $s->{_stagk} = filt ($e->{_kanj}, $s->{_stagk}, "kanj"); } } } }

    sub filt { my ($targ, $restr, $attrnm) = @_;
	# Return a list of all elements in @$targ except those that have
	# an {id} value that is equal to any {attrnm} value in the list 
	# @$restr.
	#
	# Parameters:
	#   $targ -- Ref to array table rows.
	#   $restr -- Ref to array of restr rows.
	#   $attrnm -- Name of attribute in @$restr
	#     that contains id's matching id's in
	#     @$targ.

	my ($t, $r, @results, $found);
	foreach $t (@$targ) {
	    $found = 0;
	    foreach $r (@$restr) {
		if ($t->{id} == $r->{$attrnm}) {
		    $found = 1;
		    last; } }
	    push (@results, $t) if (!$found); }
	return \@results; }

    1;