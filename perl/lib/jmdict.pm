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

    sub dbinsert { my ($dbh, $table, $cols, $hash) = @_;
	my ($sql, $sth, @args, $id);
	$sql = "INSERT INTO $table(" . 
		join(",", @$cols)  . 
		") VALUES(" . join (",", split(//, "?" x scalar(@$cols))) . ")";
	@args = map ($hash->{$_}, @$cols);
	$sth = $dbh->prepare_cached ($sql);
	$sth->execute (@args);
	$id = $dbh->last_insert_id (undef, undef, $table, undef);
	return $id; }

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

    sub kwrecs { my ($KW, $typ) = @_;
	return map ($KW->{$typ}{$_}, grep (!m/^[0-9]+$/, keys (%{$KW->{$typ}}))); }

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
	my $xref  = dbread ($dbh, "SELECT x.* $com JOIN sens s ON s.entr=e.id JOIN xsum  x ON x.sens=s.id $where;", $args);
	my $xrer  = dbread ($dbh, "SELECT x.* $com JOIN sens s ON s.entr=e.id JOIN xsumr x ON x.xref=s.id $where;", $args);

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


    $::KANA=1; $::HIRAGANA=2; $::KATAKANA=4; $::KANJI=8;

    sub jstr_classify { my ($str) = @_;

	# Returns an integer with bits set according to whether
	# the indicated type of characters are present in string <s>.
	#     1 - Kana (either hiragana or katakana)
	#     2 - Hiragana
	#     4 - Katakana
	#     8 - Kanji

	my ($r, $n);
	$r = 0;
	foreach (split (//, $str)) {
	    $n = ord();
	    if    ($n >= 0x3040 and $n <= 0x309F) { $r |= ($::HIRAGANA | $::KANA); }
	    elsif ($n >= 0x30A0 and $n <= 0x30FF) { $r |= ($::KATAKANA | $::KANA); }
	    elsif ($n >= 0x4E00 and $n <= 0x9FFF) { $r |= $::KANJI; } }
	return $r; }

    sub addentr { my ($dbh, $entr) = @_;
	my ($eid, $seq, $rid, $kid, $sid, $cntr, $cntr2, $r, $k, $s, $g, $x);
	$entr->{seq} = $seq = get_seq ($dbh); 
	$entr->{src} = 1;
	$entr->{id} = $eid = dbinsert ($dbh, "entr", ['src','seq','stat','notes'], $entr);
	$cntr = 1;
	foreach $k (@{$entr->{_kanj}}) {
	    $k->{entr} = $eid;  $k->{ord} = $cntr++;
	    $k->{id} = $kid = dbinsert ($dbh, "kanj", ['entr','ord','txt'], $k);
	    foreach $x (@{$k->{_kinf}}) {
		$x->{kanj} = $kid;
		dbinsert ($dbh, "kinf", ['kanj','kw'], $x); }
	    foreach $x (@{$k->{_kfreq}}) {
		$x->{kanj} = $kid;
		dbinsert ($dbh, "kfreq", ['kanj','kw','value'], $x); } }
	$cntr = 1;
	foreach $r (@{$entr->{_rdng}}) {
	    $r->{entr} = $eid;  $r->{ord} = $cntr++;
	    $r->{id} = $rid = dbinsert ($dbh, "rdng", ['entr','ord','txt'], $r);
	    foreach $x (@{$r->{_rinf}}) {
		$x->{rdng} = $rid;
		dbinsert ($dbh, "rinf", ['rdng','kw'], $x); }
	    foreach $x (@{$r->{_rfreq}}) {
		$x->{rdng} = $rid;
		dbinsert ($dbh, "rfreq", ['rdng','kw','value'], $x); }
	    foreach $x (@{$r->{_audio}}) {
		$x->{rdng} = $rid;
		dbinsert ($dbh, "audio", ['rdng','fname','strt','leng'], $x); }
	    foreach $x (@{$r->{_restr}}) {
		$x->{rdng} = $rid; $x->{kanj} = $x->{kanj}{id};
		dbinsert ($dbh, "restr", ['rdng','kanj'], $x); } }
	$cntr = 1;
	foreach $s (@{$entr->{_sens}}) {
	    $s->{entr} = $eid;  $s->{ord} = $cntr++;
	    $s->{id} = $sid = dbinsert ($dbh, "sens", ['entr','ord','notes'], $s);
	    $cntr2 = 1;
	    foreach $g (@{$s->{_gloss}}) {
		$g->{sens} = $sid; $g->{ord} = $cntr2++;
		$g->{id} = dbinsert ($dbh, "gloss", ['sens','ord','lang','txt','notes'], $g); }
	    foreach $x (@{$s->{_pos}}) {
		$x->{sens} = $sid;
		dbinsert ($dbh, "pos", ['sens','kw'], $x); }
	    foreach $x (@{$s->{_misc}}) {
		$x->{sens} = $sid;
		dbinsert ($dbh, "misc", ['sens','kw'], $x); }
	    foreach $x (@{$s->{_fld}}) {
		$x->{sens} = $sid;
		dbinsert ($dbh, "fld", ['sens','kw'], $x); }
	    foreach $x (@{$s->{_stagr}}) {
		$x->{sens} = $sid; $x->{rdng} = $x->{rdng}{id};
		dbinsert ($dbh, "stagr", ['sens','rdng'], $x); }
	    foreach $x (@{$s->{_stagk}}) {
		$x->{sens} = $sid; $x->{kanj} = $x->{kanj}{id};
		dbinsert ($dbh, "stagk", ['sens','kanj'], $x); }
	    foreach $x (@{$s->{_xref}}) {
		$x->{sens} = $sid; $x->{xref} = $x->{xref}{id};
		dbinsert ($dbh, "xref", ['sens','xref','typ','notes'], $x); } 
	    # Special hack for simulating sens->entry xrefs...
	    foreach $x (@{$s->{_eref}}) {
		$x->{sens} = $sid;
		dbinsert_eref ($dbh, $x); } }
	foreach $x (@{$entr->{_dial}}) {
	    $x->{entr} = $eid;
	    dbinsert ($dbh, "dial", ['entr','kw'], $x); }
	foreach $x (@{$entr->{_lang}}) {
	    $x->{entr} = $eid;
	    dbinsert ($dbh, "lang", ['entr','kw'], $x); }
	$dbh->commit();
	return ($eid, $seq); }

    sub dbinsert_eref { my ($dbh, $eref) = @_;
	# $eref is nearly the same as an $xref record but does not
`	# have any .xref member.  Instead it has an .eid member
	# that identifies an entry, to all of whose senses database
	# xref rows will be generated.  This is to simulate the current
	# jmdict xml file's sense->entry xref semantics.
	my ($sql, $sth, @args);
	$sql = "INSERT INTO xref(sens,xref,typ,notes) " .
		"(SELECT ?,s.id,?,? FROM entr e JOIN sens s ON s.entr=e.id WHERE e.id=?)";
	@args = ($eref->{sens}, $eref->{typ}, $eref->{notes}, $eref->{eid});
	$sth = $dbh->prepare_cached ($sql);
	$sth->execute (@args); }


    sub get_seq { my ($dbh) = @_;
	my $sql = "SELECT NEXTVAL('seq')";
	my $a = $dbh->selectrow_arrayref($sql);
	return $a->[0]; }

    1;