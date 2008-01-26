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

# In the database entr table rows have three attributes that
# support entry editing:
#   dfrm -- Contains the entr.id number of the entry that the 
#	current entry was derived from.
#   unap -- Indicates the current entry is not "approved"
#   stat -- Has value corresponding to one of the kwstat kw's:
#	N -- New entry
#	A -- Active entry
#	D -- Deleted entry
#	R -- Rejected entry
#
# Basics:
# 1. When an entry is edited and submited a new entry object is
#    added to the database that represents the object as edited,
#    but leaves the original entry object in the database as well.
# 2. The edited entry contains the id number of the entry it was 
#    derived from in atttribute "dfrm".
# 3. Any entry can be edited and submitted including previously
#    edited entries.
# The result is that there can exist in the database a "tree" of
# edited entries, linked by "dfrm" values, with the original entry
# at its root.
# We define a 'chain" to be a subtree in which no branches exist,
# that is, each parent entry has only one child.  The "chain head"
# is the entry on the chain that is nearest to the root. 
#
# Parameters:
# There are two URL parameters processed by this script that 
# describe the action to be taken:
#    serialized:
#	A serialized perl representation of the edited object
#	 that was given in the edit form.
#    disp:
#	"" (or no disp param) -- Submit
#	"a" -- Approve
#	"r" -- Reject
# A submission made by this cgi script always creates a new entry
# object in the database. ("object" means an entr table row, and
# related rows in the other tables).
#
# A "submit" submission:
# ---------------------
# In the case of a "submit" entry (this is the only kind of
# submission permitted by non-editors), the unpacked entry
# is used to create a new database object.  If the user submits
# a new entry: 
#	stat=N, dfrm=NULL, unap=1
# If it is edited version ofexisting entry:
#	stat=A, dfrm=<previous entr.id>, unap=1
# Related rows are created in other table as needed to create a
# database representation of the edited entry. 
# This process adds an entry to the database but makes no changes
# to existing entries.
# The history record in the submitter's entry is combined with 
# the history records from the parent entry to form a complete
# history for the edited entry.
#
# An "approve" submission:
# -----------------------
# The root entry is found by following the dfrm links, and then
# all leaf entries are found.  Each of these is an edit that
# hasn't been itself edited.  If there is more that one, we
# refuse to allow the approval of the edit we are processing
# and require the editor to explicitly reject the other edits
# first, to ensure that edits aren't inadvertantly missed.
#
# If there is only one leaf entry, it must be our parent.
# We save it's history and then delete the chain containing
# it, bach to the root entry.
# A new entry is created as for a "submit" entry except unap=F,
# and if stat=N, it is changed to A, and dfrm is set to NULL.
#
# A "reject" submission
# ---------------------
# We make a rejection by creating an entry with stat=R, unap=F,
# and dfrm=NULL.  We delete the chain containing the parent
# entry.   This may not go back to the root entry.
#
# Concurrency:
# ------------
# A long time may pass between when an entry is read for
# editing by edform.pl and when it is submitted by edsubmit.pl.
# During this time another user may submit other edits of the
# same entry, or of one its parents.   
# An editor may approve or reject edits resulting in the 
# disappearance of the edited entry's parents.
# This situation is detected in merge_hist() when it tries 
# to merge the history records from the parent entry.
# Like other systems that permit concurrent editing (e.g.
# CVS) we report an edit conflict and require the user
# to resolve conflicts manually by reediting the entry.
# 
# It is also possible that the edit tree could change while
# edsubmit.pl is running: between the time it is checked for
# changes but before the edited entry is  written or previous
# entries deleted.  This is guarded against by doing the
# checks and updates inside a transaction run with "serializable"
# isolation.  The database state within the tranaction is
# garaunteed not to change, and if someone else makes a 
# conflicting change outside the transaction, the transaction
# will fail with an error.  [However, this is not implemented
#  yet].)

@VERSION = (substr('$Revision$',11,-2), \
	    substr('$Date$',7,-11));

use strict; use warnings;
use CGI; use Encode 'decode_utf8'; use DBI; 
use Petal; use Petal::Utils; 
use POSIX ('strftime');

use lib ("../lib", "./lib", "../perl/lib", "../../perl/lib");
use jmdict; use jmdictcgi; use jmdicttal;

$|=1;
binmode (STDOUT, ":utf8");
{no warnings 'once'; 
    eval { binmode($DB::OUT, ":encoding(shift_jis)"); }; }

    main: {
	my ($dbh, $cgi, $tmpl, $entr, $entrs, $x, $eid, $seq, $src, @added,
	    @errs, $svc, $disp);
	$cgi = new CGI;
	print "Content-type: text/html\n\n";
	$svc = clean ($cgi->param ("svc"));
	$dbh = dbopen ($svc);  $::KW = Kwds ($dbh);
	$dbh->commit();  $dbh->do ("START TRANSACTION ISOLATION LEVEL SERIALIZABLE");

	$disp = $cgi->param ('disp')||"";  # '': User submission, 'a': Approve. 'r': Reject;
	if (!is_editor () && $disp) {
	    push (@errs, "Only registered editors can approve or reject entries"); }
	if (!@errs) {
	    $entrs = unserialize ($cgi->param ("entr"));
	    foreach $entr ($entrs) {
		push (@added, submission ($dbh, $svc, $entr, $disp, \@errs)); } }
	if (!@errs) { 
	    results_page (\@added, $svc);
	    $dbh->commit (); }
	else { 
	    errors_page (\@errs, $svc);
	    $dbh->rollback (); }
	$dbh->disconnect; }

    sub submission { my ($dbh, $svc, $entr, $disp, $errs) = @_;
	my (@added, $merge_rev, $added);

	if (!$entr->{dfrm}) {	# This is new entry. 
	    $entr->{STAT} = $::KW->{STAT}{N}{id};
	    $entr->{id} = undef;
	    $entr->{seq} = undef; }  # Force addentr() to assign seq number. 
	else {			# Modification of existing entry.
	    if ($entr->{stat} == $::KW->{STAT}{N}{id}) {
		push (@$errs, "Bad entry, stat=$::KW->{STAT}{N}{kw}\n"); 
		return; } 
	    if ($entr->{stat} == $::KW->{STAT}{D}{id}) {
		  # If this is a deletion, set $merge_rev.  When passed
		  # to function merge_hist() it will tell it to return the 
		  # edited entry's parent, rather than the edited entry
		  # itself.  The reason is that if we are doing a delete,
		  # we do not want to make any changes to the entry, even
		  # if the submitter has done so. 
		$merge_rev = 1; } }

	  # Merge_hist() will combine the history entry in the submitted
	  # entry with the all the previous history records in the 
	  # parent entry, so the the new entry will have a continuous
	  # history.  In the process it checks that the parent entry
	  # exists -- it might not if someone else has approved a 
	  # different edit in the meantime.
	if (!($entr = merge_hist ($dbh, $entr, $merge_rev))) {
	    push (@$errs, 
		"The entry you are editing has been changed by " .
		"someone else.  Please check the current entry and " .
		"reenter your changes if they are still applicable."); }

	if (!@$errs) {
	    if (!$disp) {
		$entr->{unap} = 1;
		$added = submit ($dbh, $svc, $entr, $errs); }
	    elsif ($disp eq "a") {
		$added = approve ($dbh, $svc, $entr, $errs); }
	    elsif ($disp eq "r") {
		$added = reject ($dbh, $svc, $entr, $errs); }
	    else {
		push (@$errs, "Bad url parameter (disp=$disp)"); } }
	return $added; }

    sub submit { my ($dbh, $svc, $entr, $errs) = @_;
	my (@res);

	if (!$entr->{dfrm} && $entr->{stat} != $::KW->{STAT}{N}{id}) { 
	    push (@$errs, "Bad url parameter, no dfrm");  return; }
	if ($entr->{stat} == $::KW->{STAT}{R}{id}) { 
	    push (@$errs, "Bad url parameter, stat=R");  return; }
	$entr->{unap} = 1;
	@res = addentr ($dbh, $entr); 
	return \@res; }

    sub approve { my ($dbh, $svc, $entr, $errs) = @_;
	my ($editor, $sql, $rs, @res, $dfrmid, $t, @t, $edroot);

	$dfrmid = $entr->{dfrm};
	if ($dfrmid) {
	      # Since $dfrmid is not undef, this is an edit of an
	      # existing entry.  We need to make sure there is a
	      # single edit chain back to the root entry, i.e., 
	      # there are no other pending edits which would get
	      # discarded if we blindly apply our edit.
	      # First, make sure the edit tree root still exists.  
 	    $sql = "SELECT * FROM find_edit_root(?)";
	    $rs = dbread ($dbh, $sql, [$dfrmid]);
	    $edroot = $rs->[0]{id};
	    if (!$edroot) {
		push (@$errs, 
		    "The entry you are editing has been changed by " .
		    "someone else.  Please check the current entry and " .
		    "reenter your changes if they are still applicable."); }

	      # Second, find all tree leaves.  These are the current 
	      # pending edits.  If there is only one, it must be ours.
	      # If there are more than one, then they need to be rejected
	      # before the current entry can be approved. 
	    $sql = "SELECT * FROM find_edit_leaves(?)";
	    $rs = dbread ($dbh, $sql, [$edroot]);
	    if (scalar (@$rs) > 1) {
		$t = "<a href=\"entr.pl?svc=$svc&e=%s\">%s</a>";
		@t = map (sprintf ($t, $_, $_), grep ($_!=$dfrmid, map ($_->{id}, @$rs)));
		push (@$errs, 
		    "There are other submitted edits (" . 
		    join (", ", @t) . ") .  They must be " .
		    "rejected before your edit can be approved.");
		return; }

	      # We may not find even our own edit if someone else rejected 
	      # the edit we are working on.
	    elsif ( scalar (@$rs) < 1) {
		push (@$errs, 
		    "The entry you are editing has been changed by " .
		    "someone else.  Please check the current entry and " .
		    "reenter your changes if they are still applicable.");
		return; } }
	  # Check stat.  May be N, A or D, but not R.  If it is N, 
	  # change it to A.
	if ($entr->{stat} == $::KW->{STAT}{N}{id}) { 
	    $entr->{stat} = $::KW->{STAT}{A}{id}; }
	if ($entr->{stat} == $::KW->{STAT}{R}{id}) {
	    push (@$errs, "Bad url parameter, stat=R"); return; }  

	  # The entr value for an approved, root entry and write it to
	  # the database..
	$entr->{dfrm} = undef;
	$entr->{unap} = 0;
	@res = addentr ($dbh, $entr);
	  # Delete the old root if any.  Because the dfrm foreign key is
	  # specified with "on delete cascade", deleting the root entry
	  # will also delete all it's children. 
	if ($edroot) { delentr ($dbh, $edroot); }
	  # If we managed to do everything above without errors then
	  # we can commit the changes and we're done.
	$dbh->commit();
	return \@res; }

    sub reject { my ($dbh, $svc, $entr, $errs) = @_;
	my ($sql, $rs, $chhead, @res);
	  # Stored procedure 'find_chain_head()' will  follow the
	  # dfrm chain from entr->{dfrm} back to it's head (the entry
	  # immediately preceeding a non-chain entry.  A non-chain
	  # entry is one with a NULL dfrm value or referenced (via
	  # dfrm) by more than one other entry. 
	$sql = "SELECT id FROM find_chain_head ($entr->{dfrm})";
	$rs = dbread ($dbh, $sql);
	$chhead = $rs->[0]{id};
	if (!$chhead) {
	    push (@$errs, 
		"The entry you are editing has been changed by " .
		"someone else.  Please check the current entry and " .
		"reenter your changes if they are still applicable.");
	    return; }
	$entr->{stat} = $::KW->{STAT}{R}{id};
	$entr->{dfrm} = undef;
	$entr->{unap} = 0;
	@res = addentr ($dbh, $entr);
	delentr ($dbh, $chhead); 
	$dbh->commit();
	return \@res; }

    sub merge_hist { my ($dbh, $entr, $rev) = @_;
	# Merge the history from the derived-from entry
	# having id $dfrmid, into the entry object $entr.
	# Only the last hist entry of $entr is kept; all
	# earlier entries are replaced with history entries
	# from entry $dfrmid.  The timestamp in the last
	# entry is reset to the current date/time.
	# If $rev is true, then merge the new hist record
	# into the orignal entry.  This is used when processing
	# a delete entry where we want to ignore the parsed 
	# entry and use the original entr.

	my ($old, $hist, $newest);
	$hist = [];
	if ($entr->{dfrm}) {
	    $old = EntrList ($dbh, "SELECT ?::INT AS id", [int($entr->{dfrm})]);
	    if (scalar (@$old) != 1) { return 0; }
	    $old = $old->[0];
	    $hist = $old->{_hist}; }
	$newest = pop (@{$entr->{_hist}});
	$newest->{dt} = strftime ("%Y-%m-%d %H:%M:00-00", gmtime());
	push (@$hist, $newest);
	if (!$rev) {
	    $entr->{_hist} = $hist; 
	    return $entr; }
	else {
	    $old->{stat} = $entr->{stat};
	    $old->{dfrm} = $entr->{dfrm};
	    $old->{_hist} = $hist;
	    return $old; } }

    sub delentr { my ($dbh, $id) = @_;
	# Delete entry $id (and by cascade, any edited entries
	# based on this one).  This function deletes the entire
	# entry, including history.  To delete the entry contents
	# but leaving the entr and hist records, use database 
	# function delentr.
	my $sql = "DELETE FROM entr WHERE id=?";
	$dbh->do ($sql, undef, $id); }

    sub is_editor {
	return 1; }

    sub errors_page { my ($errs, $svc) = @_;
        my $err_details = join ("\n    <br/>", @$errs);
	print <<EOT;
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
  <title>Invalid parameters</title>
  </head>
<body>
  <h2>Submission data errors</h2>
        Your submission cannot be processed due to the following errors:
  <p>$err_details
  </body>
</html>
EOT
	}

    sub results_page { my ($added, $svc) = @_;
	$svc = $svc ? "svc=$svc&" : "";
	my @m = map ("\n      <a href=\"entr.pl?${svc}q=$_->[1].$_->[2]\">$_->[1]</a>", @$added);
	my $seqlnks = join ("    , " , @m);
	print <<EOT;
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
  <title>Entries added</title>
  </head>
<body>
  <h1>Entry Submitted</h1>
  <p/>Thank you for your contribution!
  <p/>Your updates have been added to the JMdict database
    as provsional entries with the following seq. numbers:
  <p/>$seqlnks
  <p/>After review by the JMdict editors, they will be accepted
    and become standard entries, or rejected for reasons that
    will be described in the Comments section.  In either case
    the seq. numbers (and links) given above will show you
    their status.
  </body>
</html>
EOT
	}
