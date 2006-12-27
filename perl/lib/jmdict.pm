# Copyright (c) 2006, Stuart McGraw 
@VERSION = (substr('$Revision$',11,-2), \
	    substr('$Date$',7,-11));

use strict;

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
	$kw{DIAL} = $dbh->selectall_hashref("SELECT * FROM kwdial", "kw");
	$kw{iDIAL} = $dbh->selectall_hashref("SELECT * FROM kwdial", "id");
	$kw{FLD} = $dbh->selectall_hashref("SELECT * FROM kwfld", "kw");
	$kw{iFLD} = $dbh->selectall_hashref("SELECT * FROM kwfld", "id");
	$kw{FREQ} = $dbh->selectall_hashref("SELECT * FROM kwfreq", "kw");
	$kw{iFREQ} = $dbh->selectall_hashref("SELECT * FROM kwfreq", "id");
	$kw{KINF} = $dbh->selectall_hashref("SELECT * FROM kwkinf", "kw");
	$kw{iKINF} = $dbh->selectall_hashref("SELECT * FROM kwkinf", "id");
	$kw{LANG} = $dbh->selectall_hashref("SELECT * FROM kwlang", "kw");
	$kw{iLANG} = $dbh->selectall_hashref("SELECT * FROM kwlang", "id");
	$kw{MISC} = $dbh->selectall_hashref("SELECT * FROM kwmisc", "kw");
	$kw{iMISC} = $dbh->selectall_hashref("SELECT * FROM kwmisc", "id");
	$kw{POS} = $dbh->selectall_hashref("SELECT * FROM kwpos", "kw");
	$kw{iPOS} = $dbh->selectall_hashref("SELECT * FROM kwpos", "id");
	$kw{RINF} = $dbh->selectall_hashref("SELECT * FROM kwrinf", "kw");
	$kw{iRINF} = $dbh->selectall_hashref("SELECT * FROM kwrinf", "id");
	$kw{SRC} = $dbh->selectall_hashref("SELECT * FROM kwsrc", "kw");
	$kw{iSRC} = $dbh->selectall_hashref("SELECT * FROM kwsrc", "id");
	$kw{XREF} = $dbh->selectall_hashref("SELECT * FROM kwxref", "kw");
	$kw{iXREF} = $dbh->selectall_hashref("SELECT * FROM kwxref", "id");
	return \%kw; }

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

	my $entr = dbread ($dbh, "SELECT e.* $com $where $eord", $args);
	my $dial = dbread ($dbh, "SELECT x.* $com JOIN dial x ON x.entr=e.id $where;", $args);
	my $lang = dbread ($dbh, "SELECT x.* $com JOIN lang x ON x.entr=e.id $where;", $args);
	my $hist = dbread ($dbh, "SELECT x.* $com JOIN hist x ON x.entr=e.id $where;", $args);
	my $rdng = dbread ($dbh, "SELECT r.* $com JOIN rdng r ON r.entr=e.id $where ORDER BY r.entr,r.ord;", $args);
	my $rfrq = dbread ($dbh, "SELECT x.* $com JOIN rdng r ON r.entr=e.id JOIN rfreq x ON x.rdng=r.id $where;", $args);
	my $rinf = dbread ($dbh, "SELECT x.* $com JOIN rdng r ON r.entr=e.id JOIN rinf  x ON x.rdng=r.id $where;", $args);
	my $audi = dbread ($dbh, "SELECT x.* $com JOIN rdng r ON r.entr=e.id JOIN audio x ON x.rdng=r.id $where;", $args);
	my $kanj = dbread ($dbh, "SELECT k.* $com JOIN kanj k ON k.entr=e.id $where ORDER BY k.entr,k.ord;", $args);
	my $kfrq = dbread ($dbh, "SELECT x.* $com JOIN kanj k ON k.entr=e.id JOIN kfreq x ON x.kanj=k.id $where;", $args);
	my $kinf = dbread ($dbh, "SELECT x.* $com JOIN kanj k ON k.entr=e.id JOIN kinf  x ON x.kanj=k.id $where;", $args);
	my $sens = dbread ($dbh, "SELECT s.* $com JOIN sens s ON s.entr=e.id $where ORDER BY s.entr,s.ord;", $args);
	my $glos = dbread ($dbh, "SELECT x.* $com JOIN sens s ON s.entr=e.id JOIN gloss x ON x.sens=s.id $where ORDER BY x.sens,x.ord;", $args);
	my $misc = dbread ($dbh, "SELECT x.* $com JOIN sens s ON s.entr=e.id JOIN misc  x ON x.sens=s.id $where;", $args);
	my $pos  = dbread ($dbh, "SELECT x.* $com JOIN sens s ON s.entr=e.id JOIN pos   x ON x.sens=s.id $where;", $args);
	my $fld  = dbread ($dbh, "SELECT x.* $com JOIN sens s ON s.entr=e.id JOIN fld   x ON x.sens=s.id $where;", $args);
	my $restr = dbread ($dbh, "SELECT x.* $com JOIN rdng r ON r.entr=e.id JOIN restr x ON x.rdng=r.id $where;", $args);
	my $stagr = dbread ($dbh, "SELECT x.* $com JOIN sens s ON s.entr=e.id JOIN stagr x ON x.sens=s.id $where;", $args);
	my $stagk = dbread ($dbh, "SELECT x.* $com JOIN sens s ON s.entr=e.id JOIN stagk x ON x.sens=s.id $where;", $args);
	my $xref = dbread ($dbh, "SELECT x.sens,x.typ,z.id,z.seq,z.txt $com JOIN sens s ON s.entr=e.id JOIN xref x ON x.sens=s.id JOIN sref z ON z.sid=x.xref GROUP BY x.sens,x.typ,z.id,z.seq,z.txt ORDER BY x.sens,x.typ $where;", $args);

	matchup ($entr, "_dial", $dial, "entr");
	matchup ($entr, "_lang", $lang, "entr");
	matchup ($entr, "_rdng", $rdng, "entr");
	matchup ($entr, "_kanj", $kanj, "entr");
	matchup ($entr, "_sens", $sens, "entr");
	matchup ($entr, "_hist", $hist, "entr");
	matchup ($rdng, "_rfrq", $rfrq, "rdng");
	matchup ($rdng, "_rinf", $rinf, "rdng");
	matchup ($rdng, "_audi", $audi, "rdng");
	matchup ($kanj, "_kfrq", $kfrq, "kanj");
	matchup ($kanj, "_kinf", $kinf, "kanj");
	matchup ($sens, "_glos", $glos, "sens");
	matchup ($sens, "_pos",  $pos,  "sens");
	matchup ($sens, "_misc", $misc, "sens");
	matchup ($sens, "_fld",  $fld,  "sens");
	matchup ($rdng, "_restr", $restr, "rdng");
	matchup ($sens, "_stagr", $stagr, "sens");
	matchup ($sens, "_stagk", $stagk, "sens");
	matchup ($sens, "_xref", $xref, "sens");
	#matchup ($sens, "_xrer", $xrer, "xref");

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

    1;