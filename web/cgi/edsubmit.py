#!/usr/bin/env perl
#######################################################################
#  This file is part of JMdictDB. 
#  Copyright (c) 2008 Stuart McGraw 
# 
#  JMdictDB is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published 
#  by the Free Software Foundation; either version 2 of the License, 
#  or (at your option) any later version.
# 
#  JMdictDB is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
# 
#  You should have received a copy of the GNU General Public License
#  along with JMdictDB; if not, write to the Free Software Foundation,
#  51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
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
#	A serialized representation of the edited object
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
# submission permitted by non-editors), the serialized entry
# parameter is desserialized to a python entry object and is
# used to create a new database object.  If the user submits
# a new entry: 
#	stat=N, dfrm=NULL, unap=T
# If it is edited version of an existing entry:
#	stat=A, dfrm=<previous entr.id>, unap=T
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

__version__ = ('$Revision$'[11:-2],
	       '$Date$'[7:-11]);

import sys, cgi, datetime
sys.path.extend (['../lib','../../python/lib','../python/lib'])
import jdb, jmcgi, cgitb, json

def main( args, opts ):
	cgitb.enable()
	form = cgi.FieldStorage(); fv = form.getfirst
	errs = []
	svc = jmcgi.safe (form.getfirst ('svc'))
	dbh = jmcgi.dbOpenSvc (svc)

	disp = fv ('disp') or ''  # '': User submission, 'a': Approve. 'r': Reject;
	if not is_editor() and disp:
	    errs.append ("Only registered editors can approve or reject entries")
	if not errs:
	    entrs = json.unserialize (fv ("entr"))
	    added = []
	    dbh.connection.commit()
	    dbh.execute ("START TRANSACTION ISOLATION LEVEL SERIALIZABLE");
	    for entr in entrs:
		added.append (submission (dbh, svc, entr, disp, errs))
	if not errs: 
	    dbh.connection.commit()
	    jmcgi.gen_page ("tmpl/submitted.tal", output=sys.stdout, added=added, svc=svc)
	else: 
	    dbh.connection.rollback()
	    jmcgi.gen_page ("tmpl/url_errors.tal", output=sys.stdout, errs=errs, svc=svc);
	dbh.close()

def submission (dbh, svc, entr, disp, errs):

	KW = jdb.KW
	merge_rev = False
	if not entr.dfrm:	# This is new entry. 
	    entr.stat = KW.STAT['N'].id
	    entr.id = None
	    entr.seq = None  # Force addentr() to assign seq number. 
	else:	# Modification of existing entry.
	    if entr.stat == KW.STAT['N'].id:
		errs.append ("Bad entry, stat=KW.STAT['N'].kw") 
		return
	    if entr.stat == KW.STAT['D'].id:
		  # If this is a deletion, set $merge_rev.  When passed
		  # to function merge_hist() it will tell it to return the 
		  # edited entry's parent, rather than the edited entry
		  # itself.  The reason is that if we are doing a delete,
		  # we do not want to make any changes to the entry, even
		  # if the submitter has done so. 
		merge_rev = True

	  # Merge_hist() will combine the history entry in the submitted
	  # entry with the all the previous history records in the 
	  # parent entry, so the the new entry will have a continuous
	  # history.  In the process it checks that the parent entry
	  # exists -- it might not if someone else has approved a 
	  # different edit in the meantime.
	entr = merge_hist (dbh, entr, merge_rev)
	if not entr:
	    errs.append (
		"The entry you are editing has been changed by " 
		"someone else.  Please check the current entry and " 
		"reenter your changes if they are still applicable.")

	if not errs:
	    if not disp:
		entr.unap = True
		added = submit (dbh, svc, entr, errs)
	    elif disp == "a":
		added = approve (dbh, svc, entr, errs)
	    elif disp == "r":
		added = reject (dbh, svc, entr, errs)
	    else:
		errs.append ("Bad url parameter (disp=%s) % disp")
	return added

def submit (dbh, svc, entr, errs):

	KW = jdb.KW
	if not entr.dfrm and entr.stat != KW.STAT['N'].id:
	    errs.append ("Bad url parameter, no dfrm");  return
	if entr.stat == jdb.KW.STAT['R'].id: 
	    errs.append ("Bad url parameter, stat=R");  return
	entr.unap = True
	res = jdb.addentr (dbh, entr)
	return res

def approve (dbh, svc, entr, errs):

	KW = jdb.KW
	dfrmid = entr.dfrm
	if dfrmid:
	      # Since $dfrmid is not undef, this is an edit of an
	      # existing entry.  We need to make sure there is a
	      # single edit chain back to the root entry, i.e., 
	      # there are no other pending edits which would get
	      # discarded if we blindly apply our edit.
	      # First, make sure the edit tree root still exists.  
 	    sql = "SELECT * FROM find_edit_root(%s)"
	    rs = jdb.dbread (dbh, sql, [dfrmid])
	    edroot = rs[0].id
	    if not edroot:
		errs.append (
		    "The entry you are editing has been changed by " 
		    "someone else.  Please check the current entry and " 
		    "reenter your changes if they are still applicable.")

	      # Second, find all tree leaves.  These are the current 
	      # pending edits.  If there is only one, it must be ours.
	      # If there are more than one, then they need to be rejected
	      # before the current entry can be approved. 
	    sql = "SELECT * FROM find_edit_leaves(%s)"
	    rs = jdb.dbread (dbh, sql, [edroot])
	    if len (rs) > 1:
		t = "<a href=\"entr.py?svc=%s&e=%s\">%s</a>";
		ta = [t % (svc,x,x) for x in [y for y in [z.id for z in rs] 
					  if y != dfrmid]]
		errs.append (
		    "There are other submitted edits (" 
		    + ", ".join (ta) + ").  They must be " 
		    "rejected before your edit can be approved.")
		return

	      # We may not find even our own edit if someone else rejected 
	      # the edit we are working on.
	    elif len (rs) < 1:
		errs.append (
		    "The entry you are editing has been changed by " 
		    "someone else.  Please check the current entry and " 
		    "reenter your changes if they are still applicable.")
		return
	  # Check stat.  May be N, A or D, but not R.  If it is N, 
	  # change it to A.
	if entr.stat == KW.STAT['N'].id:
	    entr.stat = KW.STAT['A'].id
	if entr.stat == KW.STAT['R'].id:
	    errs.append ("Bad url parameter, stat=R"); return 

	  # The entr value for an approved, root entry and write it to
	  # the database..
	entr.dfrm = None
	entr.unap = False
	res = jdb.addentr (dbh, entr)
	  # Delete the old root if any.  Because the dfrm foreign key is
	  # specified with "on delete cascade", deleting the root entry
	  # will also delete all it's children. 
	if edroot: delentr (dbh, edroot)
	  # If we managed to do everything above without errors then
	  # we can commit the changes and we're done.
	dbh.connection.commit()
	return res

def reject (dbh, svc, entr, errs):
	  # Stored procedure 'find_chain_head()' will  follow the
	  # dfrm chain from entr->{dfrm} back to it's head (the entry
	  # immediately preceeding a non-chain entry.  A non-chain
	  # entry is one with a NULL dfrm value or referenced (via
	  # dfrm) by more than one other entry. 

	KW = jdb.KW
	sql = "SELECT id FROM find_chain_head (%d)" % entr.dfrm;
	rs = jdb.dbread (dbh, sql)
	chhead = rs[0].id
	if not chhead:
	    errs.append (
		"The entry you are editing has been changed by "
		"someone else.  Please check the current entry and " 
		"reenter your changes if they are still applicable.")
	    return
	entr.stat = KW.STAT['R'].id
	entr.dfrm = None
	entr.unap = False
	res = jdb.addentr (dbh, entr)
	delentr (dbh, chhead)
	dbh.connection.commit()
	return res

def merge_hist (dbh, entr, rev):
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

	hist = [];
	if entr.dfrm:
	    old = jdb.entrList (dbh, [entr.dfrm])
	    if len (old) != 1: return 0
	    old = old[0]
	    hist = old._hist
	newest = entr._hist.pop()
	newest.dt = datetime.datetime.utcnow().replace(microsecond=0)
	hist.append (newest)
	if not rev:
	    entr._hist = hist
	    return entr
	else:
	    old.stat = entr.stat
	    old.dfrm = entr.dfrm
	    old._hist = hist
	    return old

def delentr (dbh, id):
	# Delete entry $id (and by cascade, any edited entries
	# based on this one).  This function deletes the entire
	# entry, including history.  To delete the entry contents
	# but leaving the entr and hist records, use database 
	# function delentr.

	sql = "DELETE FROM entr WHERE id=%s";
	dbh.execute (sql, None, id)

def is_editor():
	return 1

if __name__ == '__main__': 
	args, opts = jmcgi.args()
	main (args, opts)
