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
		    zip fmtkr bld_erefs dbopen xrefdetails setkeys
		    resolv_xref fmt_jitem); }

our(@VERSION) = (substr('$Revision$',11,-2), \
	         substr('$Date$',7,-11));

    our($Tables) = { 
	    entr =>  {pk=>["id"],                  parent=>"",     fk=>["entr"], al=>"e"},
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
	    pos =>   {pk=>["entr","sens","kw"],    parent=>"sens", fk=>["entr","sens"], al=>"p"},
	    misc =>  {pk=>["entr","sens","kw"],    parent=>"sens", fk=>["entr","sens"], al=>"m"},
	    fld =>   {pk=>["entr","sens","kw"],    parent=>"sens", fk=>["entr","sens"], al=>"f"},
	    dial =>  {pk=>["entr","sens","kw"],    parent=>"sens", fk=>["entr","sens"], al=>"d"},
	    lsrc =>  {pk=>["entr","sens","lang","txt"],parent=>"sens", fk=>["entr","sens"], al=>"l"},
	    stagr => {pk=>["entr","sens","rdng"],  parent=>"sens", fk=>["entr","sens"], al=>"sr"},
	    stagk => {pk=>["entr","sens","kanj"],  parent=>"sens", fk=>["entr","sens"], al=>"sk"},
	    xrefe => {pk=>["entr","sens","xref"],  parent=>"sens", fk=>["entr","sens"], al=>"x"},
	    xrere => {pk=>["entr","sens","xref"],  parent=>"sens", fk=>["xentr","xsens"], al=>"xr"},};


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
	    {no warnings qw(uninitialized); 
	    if ($::Debug{prtsql}) {print "$sql (" . join(",",@$args) . ")\n";}}
	$sth = $dbh->prepare_cached ($sql);
	$sth->execute (@$args);
	while ($r = $sth->fetchrow_hashref) { push (@rs, $r); }
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
	    {no warnings qw(uninitialized); 
	    if ($::Debug{prtsql}) {print "$sql (" . join(",",@args) . ")\n";}}
	$sth = $dbh->prepare_cached ($sql);
	$sth->execute (@args);
	$id = $dbh->last_insert_id (undef, undef, $table, undef);
	return $id; }

    sub Kwds { my ($dbh) = @_;
	my (%kw);
	$kw{DIAL} = $dbh->selectall_hashref("SELECT * FROM kwdial", "kw"); addids ($kw{DIAL});
	$kw{FLD}  = $dbh->selectall_hashref("SELECT * FROM kwfld",  "kw"); addids ($kw{FLD});
	$kw{FREQ} = $dbh->selectall_hashref("SELECT * FROM kwfreq", "kw"); addids ($kw{FREQ});
	$kw{GINF} = $dbh->selectall_hashref("SELECT * FROM kwginf", "kw"); addids ($kw{GINF});
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

    sub EntrList { my ($dbh, $tmptbl) = @_;
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

	  my $start = time();
	my $entr  = dbread ($dbh, "SELECT e.* FROM $tmptbl t JOIN entr  e ON e.id=t.id ORDER BY t.ord");
	my $hist  = dbread ($dbh, "SELECT x.* FROM $tmptbl t JOIN hist  x ON x.entr=t.id;");
	my $rdng  = dbread ($dbh, "SELECT r.* FROM $tmptbl t JOIN rdng  r ON r.entr=t.id ORDER BY r.entr,r.rdng;");
	my $rinf  = dbread ($dbh, "SELECT x.* FROM $tmptbl t JOIN rinf  x ON x.entr=t.id;");
	my $audio = dbread ($dbh, "SELECT x.* FROM $tmptbl t JOIN audio x ON x.entr=t.id;");
	my $kanj  = dbread ($dbh, "SELECT k.* FROM $tmptbl t JOIN kanj  k ON k.entr=t.id ORDER BY k.entr,k.kanj;");
	my $kinf  = dbread ($dbh, "SELECT x.* FROM $tmptbl t JOIN kinf  x ON x.entr=t.id;");
	my $sens  = dbread ($dbh, "SELECT s.* FROM $tmptbl t JOIN sens  s ON s.entr=t.id ORDER BY s.entr,s.sens;");
	my $gloss = dbread ($dbh, "SELECT x.* FROM $tmptbl t JOIN gloss x ON x.entr=t.id ORDER BY x.entr,x.sens,x.gloss;");
	my $misc  = dbread ($dbh, "SELECT x.* FROM $tmptbl t JOIN misc  x ON x.entr=t.id;");
	my $pos   = dbread ($dbh, "SELECT x.* FROM $tmptbl t JOIN pos   x ON x.entr=t.id;");
	my $fld   = dbread ($dbh, "SELECT x.* FROM $tmptbl t JOIN fld   x ON x.entr=t.id;");
	my $dial  = dbread ($dbh, "SELECT x.* FROM $tmptbl t JOIN dial  x ON x.entr=t.id;");
	my $lsrc  = dbread ($dbh, "SELECT x.* FROM $tmptbl t JOIN lsrc  x ON x.entr=t.id;");
	my $restr = dbread ($dbh, "SELECT x.* FROM $tmptbl t JOIN restr x ON x.entr=t.id;");
	my $stagr = dbread ($dbh, "SELECT x.* FROM $tmptbl t JOIN stagr x ON x.entr=t.id;");
	my $stagk = dbread ($dbh, "SELECT x.* FROM $tmptbl t JOIN stagk x ON x.entr=t.id;");
	my $freq  = dbread ($dbh, "SELECT x.* FROM $tmptbl t JOIN freq  x ON x.entr=t.id;");
	my $xref  = dbread ($dbh, "SELECT x.* FROM $tmptbl t JOIN xref  x ON x.entr=t.id ORDER BY x.entr,x.sens,x.xref;");
	my $xrer  = dbread ($dbh, "SELECT x.* FROM $tmptbl t JOIN xref  x ON x.xentr=t.id;");
	$::Debug->{'Obj retrieval time'} = time() - $start;

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
	matchup ("_dial",  $sens, ["entr","sens"], $dial,  ["entr","sens"]);
	matchup ("_lsrc",  $sens, ["entr","sens"], $lsrc,  ["entr","sens"]);
	matchup ("_freq",  $entr, ["entr"], $freq, ["entr"]);
	matchup ("_restr", $rdng, ["entr","rdng"], $restr, ["entr","rdng"]);
	matchup ("_stagr", $sens, ["entr","sens"], $stagr, ["entr","sens"]);
	matchup ("_stagk", $sens, ["entr","sens"], $stagk, ["entr","sens"]);
	matchup ("_xref",  $sens, ["entr","sens"], $xref,  ["entr","sens"]);
	matchup ("_xrer",  $sens, ["entr","sens"], $xrer,  ["xentr","xsens"]);
	# Next two should probably be done by callers, not us.
	matchup ("_rfreq", $rdng, ["entr","rdng"], $freq,  ["entr","rdng"]);
	matchup ("_kfreq", $kanj, ["entr","kanj"], $freq,  ["entr","kanj"]);
	# Make restr et.al. info available from the entry as well
	# as from rdng, etc.  Should all other lists be available
	# from the entr too?
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
	# Return a ref to a list of all parents (each a hash) in @$parents 
	# that are not matched (in the $pks/$fks sense of lookup()) in
	# @$children.
	# One use of filt() is to invert the restr, stagr, stagk, etc,
	# lists in order to convert them from the "invalid pair" form
	# used in the database to the "valid pair" form typically needed
	# for display (and visa versa).
	# For example, if $restr contains the restr list for a single
	# reading, and $kanj is the list of kanji from the same entry,
	# then 
	#        filt ($kanj, ["kanj"], $restr, ["kanj"]);
	# will return a reference to a list of kanj hashes that do not
	# occur in @$restr.
	
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

    sub xrefdetails { my ($dbh, $tmptbl, $entrs) = @_;
	# Get xref details.  The entry structures returned by EntrList() 
	# contain only the raw xref records (which have only the target
	# sens.entr and sens.sens numbers) -- not very useful for display
	# to users.  Xrefdetails will get summary records for all targets
	# (both forward and reverse) for all the xrefs in a set on entries.
	# The set is defined by a table whose name is $tmptbl and should
	# be the same as was given to EntrList().  $entrs is optional but
	# if supplied, xrefdetails() will distribute the xref summary 
	# info to each entry in @$entrs, in the member (_erefs}.

	my ($erefs, $sql, $sqf, $x1, $x2);
	  # The following sql sans the join with $tmptbl was in a view but 
	  # though it was quite fast when restricted with a "where" clause
	  # if was 3 orders of magnitude slower when restrict by a join with
	  # $tmptbl.  Including $tmptbl in the qery itself seems to work
	  # around the problem.
	$sqf = "SELECT e1.id,e2.id AS eid,".
		   "e2.seq,e2.src,e2.stat,e2.nsens,e2.rdng,e2.kanj,e2.gloss ".
		"FROM entr e1 ".
		"JOIN %s t on t.id=e1.id ".
        	"JOIN xref x ON (x.entr=e1.id OR x.xentr=e1.id) ".
		"JOIN esum e2 ON (x.entr=e2.id OR x.xentr=e2.id) ".
		"WHERE e2.id!=e1.id %s ".
		"GROUP BY e1.id,x.typ,e2.id,e2.seq,e2.src,e2.stat,".
		         "e2.nsens,e2.rdng,e2.kanj,e2.gloss ";
	  # Get the non-examples xrefs...
	$sql = sprintf ($sqf, $tmptbl, "AND x.typ!=5");
	$x1 = dbread ($dbh, $sql);  
	  # ...but only a random subset of the copius example xrefs.
	$sql = sprintf ($sqf, $tmptbl, "AND x.typ=5") . " ORDER BY RANDOM() LIMIT 10";
	$x2 = dbread ($dbh, $sql);  # Get the non-examples xrefs.

	  # Merge them together.
	push (@$x1, @$x2); 
	  # And build an erefs structure from them.
	if ($entrs) { bld_erefs ($entrs, $x1); }
	return $erefs; }
    
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
		    #die ("xref2eref(): Entry summary info not found for target eid $ehash{$x->{$targe}}"); }
		    # Above commented out since we currently only retrieve summary
		    # info for a subset of xrefs, so now just ignore xrefs for which
		    # we can't find summary info.
		    next; }
		$h{$k} = {srce=>$x->{$srce}, srcs=>$x->{$srcs}, typ=>$x->{typ},entr=>$e,sens=>[$x->{$targs}]}; } }
	foreach $v (values (%h)) { push (@a, $v); }
	@a = sort {($a->{srce} <=> $b->{srce}) || 
		   ($a->{srcs} <=> $b->{srcs}) || 
		   ($a->{typ}  <=> $b->{typ})  || 
		   ($a->{entr}{eid} <=> $b->{entr}{eid})} @a;
	return \@a; }

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
	    elsif ($n >= 0x4E00)                  { $r |= $KANJI; } }
	return $r; }

    sub setkeys { my ($e, $eid) = @_;
	# Set the foreign and primary key values in each record.
	my ($k, $r, $s, $g, $x, $nkanj, $nrdng, $nsens, $ngloss, $nhist, $nxr);
	if ($eid) { $e->{id} = $eid; }
	die ("No entr.id number found or received") if (!$e->{id});
	if ($e->{_kanj}) { foreach $k (@{$e->{_kanj}}) {
	    $k->{entr} = $eid;
	    $k->{kanj} = ++$nkanj;
	    if ($k->{_kinf})  { foreach $x (@{$k->{_kinf}})  { $x->{entr} = $eid;  $x->{kanj} = $nkanj; } }
	    if ($k->{_freq})  { foreach $x (@{$k->{_freq}})  { $x->{entr} = $eid;  $x->{kanj} = $nkanj; } }
	    if ($k->{_restr}) { foreach $x (@{$k->{_restr}}) { $x->{entr} = $eid;  $x->{kanj} = $nkanj; } }
	    if ($k->{_stagk}) { foreach $x (@{$k->{_stagk}}) { $x->{entr} = $eid;  $x->{kanj} = $nkanj; } } } }
	if ($e->{_rdng}) { foreach $r (@{$e->{_rdng}}) {
	    $r->{entr} = $eid;  $r->{rdng} = ++$nrdng;
	    if ($r->{_rinf})  { foreach $x (@{$r->{_rinf}})  { $x->{entr} = $eid;  $x->{rdng} = $nrdng; } }
	    if ($r->{_audio}) { foreach $x (@{$r->{_audio}}) { $x->{entr} = $eid;  $x->{rdng} = $nrdng; } }
	    if ($r->{_freq})  { foreach $x (@{$r->{_freq}})  { $x->{entr} = $eid;  $x->{rdng} = $nrdng; } }
	    if ($r->{_restr}) { foreach $x (@{$r->{_restr}}) { $x->{entr} = $eid;  $x->{rdng} = $nrdng; } }
	    if ($r->{_stagr}) { foreach $x (@{$r->{_stagr}}) { $x->{entr} = $eid;  $x->{rdng} = $nrdng; } } } }
	if ($e->{_sens}) { foreach $s (@{$e->{_sens}}) {
	    $s->{entr} = $eid;  $s->{sens} = ++$nsens; $ngloss = 0;  $nxr = 0;
	    if ($s->{_gloss}) { foreach $g (@{$s->{_gloss}}) { $g->{entr} = $eid;  $g->{sens} = $nsens;
							         $g->{gloss} = ++$ngloss; } }
	    if ($s->{_pos})   { foreach $x (@{$s->{_pos}})   { $x->{entr} = $eid;  $x->{sens} = $nsens; } }
	    if ($s->{_misc})  { foreach $x (@{$s->{_misc}})  { $x->{entr} = $eid;  $x->{sens} = $nsens; } }
	    if ($s->{_fld})   { foreach $x (@{$s->{_fld}})   { $x->{entr} = $eid;  $x->{sens} = $nsens; } }
	    if ($s->{_dial})  { foreach $x (@{$s->{_dial}})  { $x->{entr} = $eid;  $x->{sens} = $nsens; } }
	    if ($s->{_lsrc})  { foreach $x (@{$s->{_lsrc}})  { $x->{entr} = $eid;  $x->{sens} = $nsens; } }
	    if ($s->{_stagk}) { foreach $x (@{$s->{_stagk}}) { $x->{entr} = $eid;  $x->{sens} = $nsens; } }
	    if ($s->{_stagr}) { foreach $x (@{$s->{_stagr}}) { $x->{entr} = $eid;  $x->{sens} = $nsens; } }
	    if ($s->{_xrslv}) { foreach $x (@{$s->{_xrslv}}) { $x->{entr} = $eid;  $x->{sens} = $nsens;  
								 $x->{ord} = ++$nxr } }
	    if ($s->{_xref})  { foreach $x (@{$s->{_xref}})  { $x->{entr} = $eid;  $x->{sens} = $nsens;  
								 $x->{ord} =   $nxr  } }
	    if ($s->{_xrer})  { foreach $x (@{$s->{_xrer}})  { $x->{xentr}= $eid;  $x->{xsens}= $nsens; } } } }
	if ($e->{_hist}) { foreach $x (@{$e->{_hist}})       { $x->{entr} = $eid;  $x->{hist} = ++$nhist; } } }

    sub addentr { my ($dbh, $entr) = @_;
	# Write the entry defined by %$entr to the database open
	# on connection $dbh.  Note the values in the primary key
	# fields of the records in $entr are ignored and regenerated.
	# Thus ordered items like the rdng records have the rndg
	# fields renumbered from 1 regardless of the values initially
	# in them.  

	my ($eid, $r, $k, $s, $g, $x, $h, $rs);
	if (!$entr->{seq}) { $entr->{seq} = undef; }
	$eid = dbinsert ($dbh, "entr", ['src','seq','stat','srcnote','notes'], $entr);
	setkeys ($entr, $eid);
	foreach $h (@{$entr->{_hist}})   {
	    dbinsert ($dbh, "hist", ['entr','hist','stat','dt','who','diff','notes'], $h); }
	foreach $k (@{$entr->{_kanj}})   {
	    dbinsert ($dbh, "kanj", ['entr','kanj','txt'], $k);
	    foreach $x (@{$k->{_kinf}})  { dbinsert ($dbh, "kinf",  ['entr','kanj','kw'], $x); } }
	foreach $r (@{$entr->{_rdng}})   {
	    dbinsert ($dbh, "rdng", ['entr','rdng','txt'], $r);
	    foreach $x (@{$r->{_rinf}})  { dbinsert ($dbh, "rinf",  ['entr','rdng','kw'], $x); }
	    foreach $x (@{$r->{_audio}}) { dbinsert ($dbh, "audio", ['entr','rdng','audio','fname','strt','leng','notes'], $x); }
	    foreach $x (@{$r->{_restr}}) { dbinsert ($dbh, "restr", ['entr','rdng','kanj'], $x); } }
	foreach $x (@{$entr->{_freq}}) {
	    dbinsert ($dbh, "freq", ['entr','rdng','kanj','kw','value'], $x); } 
	foreach $s (@{$entr->{_sens}}) {
	    dbinsert ($dbh, "sens", ['entr','sens','notes'], $s);
	    foreach $g (@{$s->{_gloss}}) { dbinsert ($dbh, "gloss", ['entr','sens','gloss','lang','ginf','txt'], $g); }
	    foreach $x (@{$s->{_pos}})   { dbinsert ($dbh, "pos",   ['entr','sens','kw'], $x); }
	    foreach $x (@{$s->{_misc}})  { dbinsert ($dbh, "misc",  ['entr','sens','kw'], $x); }
	    foreach $x (@{$s->{_fld}})   { dbinsert ($dbh, "fld",   ['entr','sens','kw'], $x); }
	    foreach $x (@{$s->{_dial}})  { dbinsert ($dbh, "dial",  ['entr','sens','kw'], $x); }
	    foreach $x (@{$s->{_lsrc}})  { dbinsert ($dbh, "lsrc",  ['entr','sens','lang','txt','part','wasei'], $x); }
	    foreach $x (@{$s->{_stagr}}) { dbinsert ($dbh, "stagr", ['entr','sens','rdng'], $x); }
	    foreach $x (@{$s->{_stagk}}) { dbinsert ($dbh, "stagk", ['entr','sens','kanj'], $x); }
	    foreach $x (@{$s->{_xref}})  { dbinsert ($dbh, "xref",  ['entr','sens','xref','typ','xentr','xsens','notes'], $x); } }
	if (!$entr->{seq}) { 
	    $rs = dbread ($dbh, "SELECT seq FROM entr WHERE id=?", [$eid]);
	    $entr->{seq} = $rs->[0]{seq}; }
	return ($eid, $entr->{seq}); }

    sub resolv_xref { my ($dbh, $kanj, $rdng, $slist, $typ,
			   $one_entr_only, $one_sens_only) = @_;
	# $dbh -- Handle to open database connection.
	# $kanj -- If true, cross-ref target(s) must have this kanji text.
	# $rdng -- If true, cross-ref target(s) must have this reading text.
	# $slist -- Ref to array of sense numbers.  Resolved xrefs
	#   will be limited to these target senses. 
	# $typ -- (int) Type of reference per $::KW->{XREF}.
	# $one_entr_only -- Raise error if xref resolves to more than
	#   one entry.  Regardless of this value, it is always an error
	#   if $slist is given and the xref resolves to more than one
	#   entry.
	# $one_sens_only -- Raise error if $slist not given and any
	#   of the resolved entries have more than one sense. 
	# 
	# resolv_xref() returns a list of erefs.  Each eref item
	# is a ref to a 3-element hash:
	#
	#   {typ} -- Integer XREF keyword id.
	#
	#   {entr} -- Reference to a record retrieved from view
	#	esum that summerizes one entry.  It is a ref to
	#       a hash with the following fields:
	#
	#	id -- Entry id number.
	#	seq -- Entry seq. number.
	#	src -- Entry src id number.
	#	stat -- Entry status code (KW{STAT}{*}{id})
	#	notes -- Entry note.
	#	srcnote -- Entry source note.
	#	rdng -- Entry's reading texts coalesced into one string.
	#	kanj -- Entry's kanji texts coalesced into one string.
	#	gloss -- Entry's gloss texts coalesced into one string.
	#	nsens -- Total number of senses.
	#
	#   {sens} -- A reference to an array of numbers that
	#	that are the specific xref targets in this entry. 
	# 
	# Thus each eref item represents N xrefs where N is 
	# the number of elements in @{$item->{sens}}.  Coalescing
	# all the xrefs for a single entry with entry summary
	# info simplifies life for applications that need to 
	# display summaries of xrefs.
	#
	# Prohibited conditions such as resolving to multiple
	# entries when the $one_entr_only flag is true, are 
	# signalled with die().  The caller may want to call 
	# resolv_xref() within an eval() to catch these conditions.
	
	my ($sql, $r, $esums, $qlist, @erefs, $srecs, $eid, $q, $s,
	    $krtxt, @args, @argtxt, @nosens, @multsens, %shash);

	$krtxt = fmt_jitem ($kanj, $rdng, $slist);
	if (!$::KW->{XREF}{$typ}) { die "Bad xref type value: $typ.\n"; }
	if (0) { }
	else {
	    if ($kanj) { push (@args, $kanj); push (@argtxt, "k.txt=?"); }
	    if ($rdng) { push (@args, $rdng); push (@argtxt, "r.txt=?"); }
	    $sql = "SELECT DISTINCT s.* " .
		  "FROM esum s " .
		  "JOIN entr e ON e.id=s.id " .
		  ($kanj ? "LEFT JOIN kanj k ON k.entr=e.id " : "") .
		  ($rdng ? "LEFT JOIN rdng r ON r.entr=e.id " : "") .
		  "WHERE " . join (" AND ", @argtxt);
	    $esums = dbread ($dbh, $sql, \@args); }
	if (scalar(@$esums) < 1) { die "No entries found for cross-reference '$krtxt'.\n"; }
	if (scalar(@$esums) > 1 and ($one_entr_only or ($slist and @$slist))) {
	    die "Multiple entries found for cross-reference '$krtxt'.\n"; }
	foreach $r (@$esums) {
	    push (@erefs, {typ=>$typ, entr=>$r, sens=>[]}); }

	# For every target entry, get all it's sense numbers.  We need
	# these for two reasons: 1) If explicit senses were targeted we
	# need to check them against the actual senses. 2) If no explicit
	# target senses were given, then we need them to generate erefs 
	# to all the target senses.
	# The code currently compares actual sense numbers; if the database
	# could guarantee that sense numbers are always sequential from
	# one, this code could be simplified and speeded up.

	$qlist = join(",", map ("?", @erefs));
	$sql = "SELECT entr,sens FROM sens WHERE entr IN ($qlist) ORDER BY entr,sens";
	$srecs = dbread ($dbh, $sql, [map ($_->{entr}{id}, @erefs)]);
	%shash = map (("$_->{entr}_$_->{sens}",1), @$srecs);

	if ($slist && @$slist) {
	    # The submitter gave some specific senses that the xref will
	    # target, so check that they actually exist in the target entries...
	    foreach $r (@erefs) {	# For each target entry...
				        # Because of the muliple entry test above
					# there will be only one entry in @erefs
					# here (since there is a @$slist).
		$eid = $r->{entr}{id};
		@nosens = grep (!$shash{"${eid}_$_"}, @$slist);
		die "Sense(s) ".join(",",@nosens)." not in target '$krtxt'.\n" if (@nosens);
		$r->{sens} =  [@$slist]; } } 
	else {
	    # No specific senses given, so this xref(s) should target every
	    # sense in the target entry(s), unless $one_sens_only is true
	    # in which case all the xrefs must have only one sense or we 
	    # raise an error.
	    if ($one_sens_only) {
		@multsens = grep ($_->{nsens}>1, @$esums);
		if (@multsens) {
		    if (scalar (@$esums) == 1) {
		        die "The cross-reference target '$krtxt' has more than one sense.\n"; }
		    else { 
			die "One or more of the '$krtxt 'targets have more than one sense.\n"; } } }
	    foreach $r (@erefs) {
		$eid = $r->{entr}{id};
	        $r->{sens} = [map ($_->{sens}, grep ($_->{entr}==$eid, @$srecs))]; } }
	return \@erefs; } 

    sub fmtkr { my ($kanj, $rdng) = @_;
	# If string $kanji is true return a string consisting
	# of $kanji . jp-left-bracket . $rdng . jp-right-bracket.
	# Other wise return just $rdng.

	my ($txt);
	if ($kanj) { $txt = "$kanj\x{3010}$rdng\x{3011}"; }
	else { $txt = $rdng; }
	return $txt; }

    sub fmt_jitem { my ($kanj, $rdng, $slist) = @_;
	# Format a textual xref descriptor printing (typically 
	# in an error message.)

	my $krtext = ($kanj || "") . (($kanj && $rdng) ? "/" : "") . ($rdng || ""); 
	if ($slist) { $krtext .= "[" . join (",", @$slist) . "]"; }
	return $krtext; }

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