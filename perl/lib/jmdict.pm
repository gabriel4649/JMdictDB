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

package jmdict;
use strict; use warnings;
use Time::HiRes ('time'); 

BEGIN {
    use Exporter(); our (@ISA, @EXPORT_OK, @EXPORT); @ISA = qw(Exporter);
    @EXPORT_OK = qw(Tables KANA HIRAGANA KATAKANA KANJ); 
    @EXPORT = qw(dbread dbinsert Kwds kwrecs addids mktmptbl Find EntrList 
		    matchup filt jstr_classify addentr erefs2xrefs xrefs2erefs
		    get_seq zip fmtkr bld_erefs dbopen); }

our(@VERSION) = (substr('$Revision$',11,-2), \
	         substr('$Date$',7,-11));

    our($Tables) = { 
	    entr =>  {pk=>["id"],                  parent=>"",     fk=>["entr"], al=>"e"},
	    dial =>  {pk=>["entr","kw"],           parent=>"entr", fk=>["entr"], al=>"d"},
	    lang =>  {pk=>["entr","kw"],           parent=>"entr", fk=>["entr"], al=>"l"},
	    hist =>  {pk=>["entr","hist"],         parent=>"entr", fk=>["entr"], al=>"h"},
	    rdng =>  {pk=>["entr","rdng"],         parent=>"entr", fk=>["entr"], al=>"r"},
	    rinf =>  {pk=>["entr","rdng","kw"],    parent=>"rdng", fk=>["entr","rdng"], al=>"ri"},
	    audio => {pk=>["entr","rdng"],         parent=>"rdng", fk=>["entr","rdng"], al=>"a"},
	    restr => {pk=>["entr","rdng","kanj"],  parent=>"rdng", fk=>["entr","rdng"], al=>"rk"},
	    kanj =>  {pk=>["entr","kanj"],         parent=>"entr", fk=>["entr"], al=>"k"},
	    kinf =>  {pk=>["entr","kanj","kw"],    parent=>"kanj", fk=>["entr","kanj"], al=>"ki"},
	    freq =>  {pk=>["entr","rdng","kanj","kw"],parent=>"entr", fk=>["entr"], al=>"q"},
	    sens =>  {pk=>["entr","sens"],         parent=>"entr", fk=>["entr"], al=>"s"},
	    gloss => {pk=>["entr","sens","gloss"], parent=>"sens", fk=>["entr","sens"], al=>"g"},
	    pos =>   {pk=>["entr","sens","pos"],   parent=>"sens", fk=>["entr","sens"], al=>"p"},
	    misc =>  {pk=>["entr","sens","misc"],  parent=>"sens", fk=>["entr","sens"], al=>"m"},
	    fld =>   {pk=>["entr","sens","fld"],   parent=>"sens", fk=>["entr","sens"], al=>"f"},
	    stagr => {pk=>["entr","sens","rdng"],  parent=>"sens", fk=>["entr","sens"], al=>"sr"},
	    stagk => {pk=>["entr","sens","kanj"],  parent=>"sens", fk=>["entr","sens"], al=>"sk"},
	    xrefe => {pk=>["entr","sens","xentr","xsens"], parent=>"sens", fk=>["entr","sens"], al=>"x"},
	    xrere => {pk=>["entr","sens","xentr","xsens"], parent=>"sens", fk=>["xentr","xsens"], al=>"xr"},};


    sub dbread { my ($dbh, $sql, $args) = @_;
	# Read the database result set produced by executing the
	# statement, $sql, with the arguments @$args.
 	# The results are returns as an array of hash refs.  Each 
	# hash represents one row and their position in the arrray
	# reflect the order there were received in.  Each row hash's
	# keys are the names of the SELECT statement's columns.
	
	my ($sth, @rs, $r, $start);
	if (!defined ($args)) {$args = []; }
	$start = time();
	$sth = $dbh->prepare_cached ($sql);
	$sth->execute (@$args);
	while ($r = $sth->fetchrow_hashref) { push (@rs, $r); }
	  ##print "$sql (" . join(",",@$args) . ")\n";
	  ##print "time: " . (time() - $start) . "\n";
	return \@rs; }

    sub dbinsert { my ($dbh, $table, $cols, $hash) = @_;
	# Insert a row into a database table named by $table.
	# coumns that will be used in the INSERT statement are 
	# given in list @$cols.  The values are given in hash
	# %$hash which is ecepected to contain keys matching 
	# the columns listed in @$cols.

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
	# Locate entries that meet some criteria.
	# The criteria is given in the form of a sql statement and
	# corresponding arguments.  The sql statemenht is expected 
	# to return a set of entr.id numbers.  Those id numbers will
	# be placed in a temporary table in the same order they were
	# generated, and the name of the table returned to the caller. 
	# Because it is a temporary table, it will only be visible on
	# the same database connection as $dbh.  It will automatically
	# be deleted when that database connection is closed.
	
	my ($s, $sth, $tmpnm, $ac);
	  my $start = time();

	# Get a random name for the table.
	$tmpnm = mktmptbl ($dbh);

	# Create the temporary table.  It is given an "ord" column
	# with a SERIAL datatype which will preserve the order that
	# it received the entry id numbers in.
	$s = "CREATE TEMPORARY TABLE $tmpnm (id INT NOT NULL PRIMARY KEY, ord SERIAL);";
	$sth = $dbh->prepare_cached ($s);
	$sth->execute (); 

	# Save info for debug/development.
	$::Debug->{'Search sql'} = $sql;
	$::Debug->{'Search args'} = join(",",@$args);

	# Insert the entry id's generated by the given sql statement
	# into the temp table.
	$s = "INSERT INTO $tmpnm(id) ($sql);";
	$sth = $dbh->prepare ($s);
	$sth->execute (@$args);

	# We have to vacuum the new table, or queries based on joins
	# with it may run extrordinarily slowly.  For reasons I forgot
	# it looks AutoCommit must be on to do this, so we save and
	# restore the orginial AutoCommit settings.
	$ac = $dbh->{AutoCommit}; 
	$dbh->{AutoCommit} = 1;
	$dbh->do ("VACUUM ANALYZE $tmpnm");
	$dbh->{AutoCommit} = $ac;

	# For debug/development, get the time spent to do everything.
	$::Debug->{'Search time'} = time() - $start;

	# Return the temp table's name to the caller who will probable
	# call EntrList() with it.
	return $tmpnm; }

    sub EntrList { my ($dbh, $cond, $args, $eord) = @_;
	# $dbh -- An open database connection.
	# $cond -- Either:
	#   1. Name of a table containing entry id numbers, or,
	#   2. A where clause (including the word "WHERE") that references
	#   only fields in table "entr", which will have alias "e".
	# $args -- If the form of $cond is (2), this argument is a ref to 
	#   a list of arguments for the where clause given in $cond.  
	#   If the form of $cond is (1), this argument is ignored.
	# $eord -- Optional ORDER BY clause (including the words "ORDER BY")
	#   used to order the returned set of entries.

	my ($where, $com);
	if (!defined ($args)) {$args = []; }
	if (-1 != index ($cond, " ")) { 
	    $where = $cond; 
	    $com = "FROM entr e"; 
	    if (!defined ($eord)) { $eord = ""; } }
	else {  
	    $where = ""; 
	    $com = "FROM entr e JOIN $cond t ON t.id=e.id ";
	    $eord = "ORDER BY t.ord"; }

	  my $start = time();
	my $entr  = dbread ($dbh, "SELECT e.* $com $where $eord", $args);
	my $dial  = dbread ($dbh, "SELECT x.* $com JOIN dial  x ON x.entr=e.id $where;", $args);
	my $lang  = dbread ($dbh, "SELECT x.* $com JOIN lang  x ON x.entr=e.id $where;", $args);
	my $hist  = dbread ($dbh, "SELECT x.* $com JOIN hist  x ON x.entr=e.id $where;", $args);
	my $rdng  = dbread ($dbh, "SELECT r.* $com JOIN rdng  r ON r.entr=e.id $where ORDER BY r.entr,r.rdng;", $args);
	my $rinf  = dbread ($dbh, "SELECT x.* $com JOIN rinf  x ON x.entr=e.id $where;", $args);
	my $audio = dbread ($dbh, "SELECT x.* $com JOIN audio x ON x.entr=e.id $where;", $args);
	my $kanj  = dbread ($dbh, "SELECT k.* $com JOIN kanj  k ON k.entr=e.id $where ORDER BY k.entr,k.kanj;", $args);
	my $kinf  = dbread ($dbh, "SELECT x.* $com JOIN kinf  x ON x.entr=e.id $where;", $args);
	my $sens  = dbread ($dbh, "SELECT s.* $com JOIN sens  s ON s.entr=e.id $where ORDER BY s.entr,s.sens;", $args);
	my $gloss = dbread ($dbh, "SELECT x.* $com JOIN gloss x ON x.entr=e.id $where ORDER BY x.entr,x.sens,x.gloss;", $args);
	my $misc  = dbread ($dbh, "SELECT x.* $com JOIN misc  x ON x.entr=e.id $where;", $args);
	my $pos   = dbread ($dbh, "SELECT x.* $com JOIN pos   x ON x.entr=e.id $where;", $args);
	my $fld   = dbread ($dbh, "SELECT x.* $com JOIN fld   x ON x.entr=e.id $where;", $args);
	my $restr = dbread ($dbh, "SELECT x.* $com JOIN restr x ON x.entr=e.id $where;", $args);
	my $stagr = dbread ($dbh, "SELECT x.* $com JOIN stagr x ON x.entr=e.id $where;", $args);
	my $stagk = dbread ($dbh, "SELECT x.* $com JOIN stagk x ON x.entr=e.id $where;", $args);
	my $freq  = dbread ($dbh, "SELECT x.* $com JOIN freq  x ON x.entr=e.id $where;", $args);
	my $xref  = dbread ($dbh, "SELECT x.* $com JOIN xref  x ON x.entr=e.id $where;", $args);
	my $xrer  = dbread ($dbh, "SELECT x.* $com JOIN xref  x ON x.xentr=e.id $where;", $args);
	my $erefs = [];
	if (@$xref or @$xrer) {
	    $erefs = dbread ($dbh, "SELECT DISTINCT z.eid,z.seq,z.rdng,z.kanj,z.nsens $com JOIN xrefesum z ON z.id=e.id $where;", $args); }
	$::Debug->{'Obj retrieval time'} = time() - $start;

	matchup ("_dial",  $entr, ["id"],  $dial,  ["entr"]);
	matchup ("_lang",  $entr, ["id"],  $lang,  ["entr"]);
	matchup ("_rdng",  $entr, ["id"],  $rdng,  ["entr"]);
	matchup ("_kanj",  $entr, ["id"],  $kanj,  ["entr"]);
	matchup ("_sens",  $entr, ["id"],  $sens,  ["entr"]);
	matchup ("_hist",  $entr, ["id"],  $hist,  ["entr"]);
	matchup ("_rinf",  $rdng, ["entr","rdng"], $rinf,  ["entr","rdng"]);
	matchup ("_audio", $rdng, ["entr","rdng"], $audio, ["entr","rdng"]);
	matchup ("_kinf",  $kanj, ["entr","kanj"], $kinf,  ["entr","kanj"]);
	matchup ("_gloss", $sens, ["entr","sens"], $gloss, ["entr","sens"]);
	matchup ("_pos",   $sens, ["entr","sens"], $pos,   ["entr","sens"]);
	matchup ("_misc",  $sens, ["entr","sens"], $misc,  ["entr","sens"]);
	matchup ("_fld",   $sens, ["entr","sens"], $fld,   ["entr","sens"]);
	matchup ("_freq",  $entr, ["entr"], $freq, ["entr"]);
	matchup ("_restr", $rdng, ["entr","rdng"], $restr, ["entr","rdng"]);
	matchup ("_stagr", $sens, ["entr","sens"], $stagr, ["entr","sens"]);
	matchup ("_stagk", $sens, ["entr","sens"], $stagk, ["entr","sens"]);
	matchup ("_xref",  $sens, ["entr","sens"], $xref,  ["entr","sens"]);
	matchup ("_xrer",  $sens, ["entr","sens"], $xrer,  ["xentr","xsens"]);
	## linkrecs ("_entr", $xref, ["xentr"], $erefs, ["eid"]);
	## linkrecs ("_entr", $xrer, ["entr"],  $erefs, ["eid"]);
	bld_erefs ($entr, $erefs);
	# Next two should probably be done by callers, not us.
	matchup ("_rfreq", $rdng, ["entr","rdng"], $freq,  ["entr","rdng"]);
	matchup ("_kfreq", $kanj, ["entr","kanj"], $freq,  ["entr","kanj"]);
	# Make restr et.al. info available from the entry as well
	# as from rdng, etc.  Should all other lists be available
	# from the entr to?
	matchup ("_restr", $entr, ["entr"], $restr, ["entr"]);
	matchup ("_stagr", $entr, ["entr"], $stagr, ["entr"]);
	matchup ("_stagk", $entr, ["entr"], $stagk, ["entr"]);
	return $entr; }
 
    sub matchup { my ($listattr, $parents, $pks, $children, $fks) = @_;
	# Append each element (a hash ref) in @$children to a list 
	# attached to the first element (also a hash ref) in @$parents
	# that it "matches".  The child hash will "match" a parent if
	# the values of the keys named in (list of strings) $fk are
	# "=" respectively to the values of the keys named in $pks
	# in the parent.  The list of matching children in created
	# as the value of the key $listattr on the parent element 
	# hash.
	# Matchup() is used to link database records from a foreign
	# key table to the record of the primary key table.

	my ($p, $c);
	foreach $p (@$parents) { $p->{$listattr} = (); }
	foreach $c (@$children) {
	    $p = lookup ($parents, $pks, $c, $fks);
	    if ($p) { push (@{$p->{$listattr}}, $c); } } }

    sub linkrecs { my ($listattr, $parents, $pks, $children, $fks) = @_;
	# For each parent hash in @$parents, create a key, $attrlist
	# in the parent hash that contains a list of all the children
	# hashes in @$children that match (in the $pks/$fks sense of
	# lookup()) that parent.
	my ($p, $c, $m);
	foreach $p (@$parents) { $p->{$listattr} = (); }
	foreach $c (@$children) {
	    $m = lookup ($parents, $pks, $c, $fks, 1);
	    foreach $p (@$m) {
		push (@{$p->{$listattr}}, $c); } } }

    sub filt { my ($parents, $pks, $children, $fks) = @_;
	# Return a list of all parents (each a hash) in @$parents that
	# are not matched (in the $pks/$fks sense of lookup()) in
	# @$children.
	# One use of filt() is to invert the restr, stagr, stagk, etc,
	# lists in order to convert them from the "invalid pair" form
	# used in the database to the "valid pair" form typically needed
	# for display (and visa versa).
	# For example, if $restr contains the restr list for a single
	# reading, and $kanj is the list of kanji from the same entry,
	# then 
	#        filt ($kanj, ["kanj"], $restr, ["kanj"]);
	# will return a list of kanj hashes that do not occur in @$restr.
	
	my ($p, $c, @list);
	foreach $p (@$parents) {
	    if (!lookup ($children, $fks, $p, $pks)) {
	    	push (@list, $p); } }
	return \@list; }

    sub lookup { my ($parents, $pks, $child, $fks, $multpk) = @_;
	# @$parents is a list of hashes and %$child a hash.
	# If $multpk if false, lookup will return the first
	# element of @$parents that "matches" %$child.  A match
	# occurs if the hash values of the parent element identified
	# by the keys named in list of strings @$pks are "="
	# respectively to the hash values in %$child corresponding
	# to the keys listed in list of strings @$fks. 
	# If $multpk is true, the matching is done the same way but
	# a list of matching parents is returned rather than the 
	# first match.  In either case, an empty list is returned
	# if no matches for %$child are found in @$parents.

	my ($p, $i, $found, @results);
	foreach $p (@$parents) {
	    $found = 1;
	    for ($i=0; $i<scalar(@$pks); $i++) {
		next if (($p->{$pks->[$i]} || 0) eq ($child->{$fks->[$i]} || 0)); 
		$found = 0;  }
	    if ($found) { 
		if ($multpk) { push (@results, $p); } 
		else { return $p; } } }
	if (!@results) { return (); }
	return \@results; } 

    our ($KANA,$HIRAGANA,$KATAKANA,$KANJI) = (1, 2, 4, 8);

    sub jstr_classify { my ($str) = @_;
	# Returns an integer with bits set according to whether the
	# indicated type of characters are present in string $str.
	#     1 - Kana (either hiragana or katakana)
	#     2 - Hiragana
	#     4 - Katakana
	#     8 - Kanji

	my ($r, $n); $r = 0;
	foreach (split (//, $str)) {
	    $n = ord();
	    if    ($n >= 0x3040 and $n <= 0x309F) { $r |= ($HIRAGANA | $KANA); }
	    elsif ($n >= 0x30A0 and $n <= 0x30FF) { $r |= ($KATAKANA | $KANA); }
	    elsif ($n >= 0x4E00 and $n <= 0x9FFF) { $r |= $KANJI; } }
	return $r; }

    sub addentr { my ($dbh, $entr) = @_;
	# Write the entry defined by %$entr to the database open
	# on connection $dbh.  Note the values in the primary key
	# fields of the records in $entr are ignored and regenerated.
	# Thus ordered items like the rdng records have the rndg
	# fields renumbered from 1 regardless of the values initially
	# in them.  
	# The addition is executed in a transaction so that if there
	# is an error, nothing will have been added to the database.

	my ($eid, $seq, $nrdng, $nkanj, $nsens, $ngloss, $nhist, $naudio, 
	    $cntr2, $r, $k, $s, $g, $x, $h);
	if ($entr->{seq} == 0 and $entr->{src} == 1) {	# 1:kw:jmdict
	    $entr->{seq} = $seq = get_seq ($dbh); }
	$entr->{id} = $eid = dbinsert ($dbh, "entr", ['src','seq','stat','notes'], $entr);
	foreach $h (@{$entr->{_hist}}) {
	    $h->{entr} = $eid;  $h->{hist} = ++$nhist;
	    dbinsert ($dbh, "hist", ['entr','hist','stat','dt','who','diff','notes'], $h); }
	foreach $k (@{$entr->{_kanj}}) {
	    $k->{entr} = $eid;  $k->{kanj} = ++$nkanj;
	    dbinsert ($dbh, "kanj", ['entr','kanj','txt'], $k);
	    foreach $x (@{$k->{_kinf}}) {
		$x->{entr} = $eid;  $x->{kanj} = $nkanj;
		dbinsert ($dbh, "kinf", ['entr','kanj','kw'], $x); }
	    $nkanj++; }
	foreach $r (@{$entr->{_rdng}}) {
	    $r->{entr} = $eid;  $r->{rdng} = ++$nrdng;
	    dbinsert ($dbh, "rdng", ['entr','rdng','txt'], $r);
	    foreach $x (@{$r->{_rinf}}) {
		$x->{$entr} = $eid;  $x->{rdng} = $nrdng;
		dbinsert ($dbh, "rinf", ['entr','rdng','kw'], $x); }
	    foreach $x (@{$r->{_audio}}) {
		$x->{$entr} = $eid;  $x->{rdng} = $nrdng;  $x->{audio} = ++$naudio;
		dbinsert ($dbh, "audio", ['entr','rdng','audio','fname','strt','leng','notes'], $x); }
	    foreach $x (@{$r->{_restr}}) {
		$x->{$entr} = $eid;  $x->{rdng} = $nrdng; 
		$x->{kanj} = $x->{kanj}{kanj};
		dbinsert ($dbh, "restr", ['entr','rdng','kanj'], $x); }
	    $nrdng++; }
	foreach $x (@{$entr->{_freq}}) {
	    $x->{entr} = $eid;  
	    dbinsert ($dbh, "freq", ['entr','rdng','kanj','kw','value'], $x); } 
	foreach $s (@{$entr->{_sens}}) {
	    $s->{entr} = $eid;  $s->{sens} = ++$nsens;
	    dbinsert ($dbh, "sens", ['entr','sens','notes'], $s);
	    foreach $g (@{$s->{_gloss}}) {
		$g->{entr} = $eid; $g->{sens} = $nsens; $g->{gloss} = ++$ngloss;
		dbinsert ($dbh, "gloss", ['entr','sens','gloss','lang','txt','notes'], $g); }
	    foreach $x (@{$s->{_pos}}) {
		$x->{entr} = $eid; $x->{sens} = $nsens;
		dbinsert ($dbh, "pos", ['entr','sens','kw'], $x); }
	    foreach $x (@{$s->{_misc}}) {
		$x->{entr} = $eid; $x->{sens} = $nsens;
		dbinsert ($dbh, "misc", ['entr','sens','kw'], $x); }
	    foreach $x (@{$s->{_fld}}) {
		$x->{entr} = $eid; $x->{sens} = $nsens;
		dbinsert ($dbh, "fld", ['entr','sens','kw'], $x); }
	    foreach $x (@{$s->{_stagr}}) {
		$x->{entr} = $eid; $x->{sens} = $nsens;
		$x->{rdng} = $x->{rdng}{id};
		dbinsert ($dbh, "stagr", ['entr','sens','rdng'], $x); }
	    foreach $x (@{$s->{_stagk}}) {
		$x->{entr} = $eid; $x->{sens} = $nsens;
		$x->{kanj} = $x->{kanj}{id};
		dbinsert ($dbh, "stagk", ['entr','sens','kanj'], $x); }
	    foreach $x (@{$s->{_xref}}) {
		$x->{entr} = $eid; $x->{sens} = $nsens; 
		$x->{xref} = $x->{xref}{id};
		dbinsert ($dbh, "xref", ['entr','sens','xentr','xsens','typ','notes'], $x); } }
	foreach $x (@{$entr->{_dial}}) {
	    $x->{entr} = $eid;
	    dbinsert ($dbh, "dial", ['entr','kw'], $x); }
	foreach $x (@{$entr->{_lang}}) {
	    $x->{entr} = $eid;
	    dbinsert ($dbh, "lang", ['entr','kw'], $x); }
	$dbh->commit();
	return ($eid, $seq); }

    sub bld_erefs { my ($entries, $esum) = @_;
	# For each sense in each entry in @$entries, assign to
	# key "_erefs" a structure containing the sense's xrefs
	# grouped by entry and with summary info or the entry
	# that is useful for presentation.  The structure is a
	# list of 2-tuples. 
	# The first element of each tuple is a reference to info
	# about the entry represented as a hash with keys: 
	#   eid, seq, rdng, kanj, nsens
	# (The latter is the total number of senses in the 
	# entry.)
	# The second element is a list of the senses referred
	# to in the entry.

	foreach my $e (@$entries) {
	    foreach my $s (@{$e->{_sens}}) {
		$s->{_erefs} = xrefs2erefs ($s->{_xref}, 0, $esum);
		$s->{_erers} = xrefs2erefs ($s->{_xrer}, 1, $esum); } } }

    sub erefs2xrefs { my ($erefs) = @_;
	# Convert a list of eref-style cross references to a list
	# of xref style cross-references.
	# See function xref2eref() for a description of the xref
	# and eref data structures.
	my (@a, $e, $s);
	for $e (@$erefs) {
	    foreach $s (@{$e->{sens}}) {
		push (@a, {entr=>0, sens=>0, 
			    xentr=>$e->{entr}{id}, xsens=>$s,
			    typ=>$e->{typ}, notes=>undef}); } }
	return \@a; }

    sub xrefs2erefs { my ($xrefs, $dir, $esum) = @_;
	# Convert a list of xrefs in @$xrefs to eref style.
	#
	# $dir denotes the direction of the xref: if false, these
	# are forward xrefs and the xref target pointed to by 
	# {xentr,xsens} members.  If $dir is true, this is a 
	# reverse xref and the xref target pointed to be the 
	# (entr,sens} members.
	# 
	# $esum is a reference to an array of entry summary 
	# hashes (described in Eref style" below) that contain
	# summary information for each xref target.  If and xref
	# target's information is nor found in @$esum, this function
	# will raise an exception (i.e. die).
	#
	# Xref style:
	# This format is used in the jmdict database table "xref"
	# and is a hashref with the fields: {entr, sens, xentr, xsens,
	# typ, notes}.  Fields {entr,sens} are a foreign key to table
	# "sens" that indentifies the sense to which the this xref
	# belongs.  Fields {xentr,xsens} are a foreign key to table
	# "sens" that indentifies the sense to which the this xref
	# points.  {typ} is the type of xref (per table kwxref).
	# These five fields are all integers.  {notes} is a text 
	# string.
	# 
	# Eref style:
	# This format is more suited to displaying xref information.
	# A group of xrefs to the same entry are represented as a 
	# 3-tuple: {typ, entr, sens}.  {typ is the same as in xref.
	# {entr} is a reference to an entry summary hash that contains:
	# {eid, seq, rdng, kanj, nsens}.  {eid} is the daabase id number
	# of the entry, and {seq} the jmdict seq number.  {rdng} and 
	# {kanj} are a single line aggregation on all the entry's 
	# reading and kanji text strings.  {nsens} is the total number
	# of senses in the entry.
	# The third item in the eref 3-tuple is a reference to an 
	# array of ints, each one naming a sense in the {eid} entry
	# which is the target of an xref. 

	my ($x, $k, %h, $e, $srce, $targe, $srcs, $targs, $v, @a, %ehash);

	# Index the $esum entries by entr.id to speed later lookup. 
	for $x (@$esum) { $ehash{$x->{eid}} = $x; }

	# Choose the appropriate fields depending on the direction.
	if ($dir) { $targe="entr";  $targs="sens";  $srce="xentr"; $srcs="xsens"; }
	else      { $targe="xentr"; $targs="xsens"; $srce="entr";  $srcs="sens"; }

	foreach $x (@$xrefs) {
	    $k = "$x->{$srce}/$x->{$srcs}/$x->{typ}/$x->{$targe}";
	    if ($h{$k}) { push (@{$h{$k}{sens}}, $x->{$targs}); }
	    else { 
		if (!($e = $ehash{$x->{$targe}})) {	# "=", not "=="!
		    die ("xref2eref(): Entry summary info not found for target eid $ehash{$x->{$targe}}"); }
		$h{$k} = {srce=>$x->{$srce}, srcs=>$x->{$srcs}, typ=>$x->{typ},entr=>$e,sens=>[$x->{$targs}]}; } }
	foreach $v (values (%h)) { push (@a, $v); }
	@a = sort {($a->{srce} <=> $b->{srce}) || 
		   ($a->{srcs} <=> $b->{srcs}) || 
		   ($a->{typ}  <=> $b->{typ})  || 
		   ($a->{entr}{eid} <=> $b->{entr}{eid})} @a;
	return \@a; }

    sub get_seq { my ($dbh) = @_;
	# Get and return a new entry sequence number.

	my $sql = "SELECT NEXTVAL('seq')";
	my $a = $dbh->selectrow_arrayref($sql);
	return $a->[0]; }

    sub fmtkr { my ($kanj, $rdng) = @_;
	# If string $kanji is true return a string consisting
	# of $kanji . jp-left-bracket . $rdng . jp-right-bracket.
	# Other wise return just $rdng.

	my ($txt);
	if ($kanj) { $txt = "$kanj\x{3010}$rdng\x{3011}"; }
	else { $txt = $rdng; }
	return $txt; }

    sub zip {
	# Takes an arbitrary number of arguments of references to arrays
	# of the same length, and creates and returns a reference to an
	# array of references to arrays where each array consists on one
	# element from each of the input arrays.  For example, given 3 
	# arguments array a, b, and c, all of length N, the output array will be
	# [[a[0],b[0],c[0]], [a[1],b[1],c[1]], [a[2],b[2],c[2]],...,[a[N-1],b[N-1],c[N-1]]]
	# Alterinatively, if you view the argument @_ as matrix (a list 
	# of equal-length lists), then this function returns its transpose.

	my ($n, $m, $x, $i, $j, @a);
	$n = scalar(@_); $m = scalar(@{$_[0]});  
	for ($j=0; $j<$m; $j++) {
	    $x = [];
	    for ($i=0; $i<$n; $i++) { push (@$x, $_[$i]->[$j]); }
	    push (@a, $x); }
	return \@a; }

    use DBI;
    sub dbopen { my ($cfgfile) = @_;
	# This function will open a database connection based on the contents
	# of a configuration file.  It is intended for the use of cgi scripts
	# where we do not want to embed the connection information (username,
	# password, etc) in the script itself, for both security and maintenance
	# reasons.

	my ($dbname, $username, $pw, $host, $dbh, $ln);
	if (!$cfgfile) { $cfgfile = "../lib/jmdict.cfg"; }
	open (F, $cfgfile) or die ("Can't open database config file\n");
	$ln = <F>;  close (F);  chomp($ln);
	($dbname, $username, $pw) = split (/ /, $ln); 
	$dbh = DBI->connect("dbi:Pg:dbname=$dbname", $username, $pw, 
			{ PrintWarn=>0, RaiseError=>1, AutoCommit=>0 } );
	$dbh->{pg_enable_utf8} = 1;
	return $dbh; }

    1;