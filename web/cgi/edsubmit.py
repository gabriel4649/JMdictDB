#!/usr/bin/env python
#######################################################################
#  This file is part of JMdictDB. 
#  Copyright (c) 2008-2010 Stuart McGraw 
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
import cgitbx; cgitbx.enable()
import jdb, jmcgi, fmtxml, serialize

def main( args, opts ):
	errs = []; dbh = svc = None
	try: form, svc, host, dbh, sid, sess, parms, cfg = jmcgi.parseform()
	except StandardError, e: jmcgi.err_page ([unicode (e)])

	fv = form.getfirst
	dbg = fv ('d'); meth = fv ('meth')
	disp = fv ('disp') or ''  # '': User submission, 'a': Approve. 'r': Reject;
	if not sess and disp:
	    errs.append ("Only registered editors can approve or reject entries")
	if errs: jmcgi._err_page (errs)
	try: entrs = serialize.unserialize (fv ("entr"))
	except StandardError:
	    jmcccgi.err_page (["Bad 'entr' parameter, unable to unserialize."])

	added = []
	dbh.connection.commit()
	dbh.execute ("START TRANSACTION ISOLATION LEVEL SERIALIZABLE");
	  # FIXME: we unserialize the entr's xref's as they were resolved
	  #  by the edconf.py page.  Should we check them again here? 
	  #  If target entry was deleted in meantime, attempt to add 
	  #  our entr to db will fail with obscure foreign key error. 
	  #  Alternatively an edited version of target may have been 
	  #  created which wont have our xref pointing to it as it should. 
	for entr in entrs:
	    e = submission (dbh, entr, disp, errs, jmcgi.is_editor (sess), 
			    sess.userid if sess else None)
	      # The value returned by submission() is a 3-tuple consisting 
	      # of (id, seq, src) for the added entry.
	    if e: added.append (e)

	if errs: 
	    dbh.connection.rollback()
	    jmcgi.err_page (errs)

	dbh.connection.commit()
	if not meth: meth = 'get' if dbg else 'post'
	jmcgi.gen_page ("tmpl/submitted.tal", macros='tmpl/macros.tal',
			added=added, parms=parms, meth=meth,
			svc=svc, host=host, sid=sid, session=sess, cfg=cfg, 
			output=sys.stdout, this_page='edsubmit.py')

def submission (dbh, entr, disp, errs, is_editor=False, userid=None):
	# Add a changed entry, 'entr', to the jmdictdb database accessed 
	# by the open DBAPI cursor, 'dbh'.
	#
	# dbh -- An open DBAPI cursor
	# entr -- A populated Entr object that defines the entry to
	#   be added.  See below for description of how some attribute
	#   control the submission.
	# disp -- Disposition, one of three string values:
	#   '' -- Submit as normal user.
	#   'a' -- Approve this submission.
	#   'r' -- Reject this submission.
	# errs -- A list to which an error messages will be appended.
	# is_editor -- True is this submission is being performed by
	#   a logged in editor.  Approved or Rejected dispositions will
	#   fail if this is false.  Its value may be conveniently 
	#   obtained from jmcgi.is_editor().  False if a normal user.
	# userid -- The userid if submitter is logged in editor or
	#   None if not.
	#
	# The following attributes in 'entr' control how the entry
	# is added:
	#   entr.dfrm -- If None, this is a new submission.  Otherwise,
	#	it must be the id number of the entry this submission 
	#	is an edit of.
	#   entr.stat -- Must be consistent with changes requested. In
	#	particular, if it is 4 (Delete), changed made in 'entr'
	#	will be ignored, and the parent entry will be submitted 
	#	with stat D.
	#
	# The following entry attributes need not be set:
	#   entr.id -- Ignored (reset to None).
	#   entr.unap -- Ignored (reset based on 'disp').

	KW = jdb.KW
	oldid = entr.id
	entr.id = None		# All submissions will produce a new entry.
	entr.unap = not disp
	merge_rev = False
	if not entr.dfrm:	# This is new entry. 
	    entr.stat = KW.STAT['A'].id
	    entr.seq = None	# Force addentr() to assign seq number. 
	    pentr = None	# No parent entr.
	else:	# Modification of existing entry.
	      # Get the parent entry and augment the xrefs so when hist diffs are
	      # generated, they will show xref details.
	    pentr, raw = jdb.entrList (dbh, None, [entr.dfrm], ret_tuple=True)
	    if len (pentr) != 1: 
		errs.append (
		    "The entry you are editing has been deleted or changed " 
		    "by someone else.  Please check the current entry and " 
		    "reenter your changes if they are still applicable.")
		return
	    pentr = pentr[0]
	    jdb.augment_xrefs (dbh, raw['xref'])

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
	  # merge_hist also returns an entry.  If 'merge_rev' is false,
	  # the entry returned is 'entr'.  If 'merge_rev' is true,
	  # the entry returned is the entr pointed to by 'entr.dfrm'
	  # (i.e. the original entry that the submitter edited.)
	  # This is done when a delete is requested and we want to 
	  # ignore any edits the submitter may have made (which 'entr'
	  # will contain.)

	  # Before calling merge_hist() check for a condition that would
	  # cause merge_hist() to fail.
	if entr.stat==KW.STAT['D'].id and not getattr (entr, 'dfrm', None):
	    errs.append ("Delete requested but entry is new (has no 'dfrm' value.)")

	if disp == 'a' and has_xrslv (entr):
	    errs.append ("Can't approve because entry has unresolved xrefs")

	if not errs:
	      # If this is a submission buy a non-editor, restore the
	      # original entry's freq items which non-editors are not
	      # allowed to change.
	    if not is_editor:
		if pentr: 
		    jdb.copy_freqs (pentr, entr, replace=True)
		  # Note that non-editors can provide freq items on new
		  # entries.  We expect an editor to vet this when approving.

	      # Entr contains the hist record generate by the edconf.py
	      # but it is not trustworthy since it could be modified or
	      # created from scratch before we get it.  So we extract
	      # the unvalidated info from it (name, email, notes, refs)
	      # and recreate it.
	    h = entr._hist[-1]
	    entr = jdb.add_hist (entr, pentr, userid, 
				 h.name, h.email, h.notes, h.refs, merge_rev)
	    if not entr:
		errs.append (
		    "The entry you are editing has been changed by " 
		    "someone else.  Please check the current entry and " 
		    "reenter your changes if they are still applicable.")
	if not errs:
	    if not disp:
		added = submit (dbh, entr, errs)
	    elif disp == "a":
		added = approve (dbh, entr, errs)
	    elif disp == "r":
		added = reject (dbh, entr, errs)
	    else:
		errs.append ("Bad url parameter (disp=%s) % disp")
	if not errs: return added
	return None

def submit (dbh, entr, errs):

	KW = jdb.KW
	if not entr.dfrm and entr.stat != KW.STAT['A'].id:
	    errs.append ("Bad url parameter, no dfrm");  return
	if entr.stat == jdb.KW.STAT['R'].id: 
	    errs.append ("Bad url parameter, stat=R");  return
	res = addentr (dbh, entr)
	return res

def approve (dbh, entr, errs):

	KW = jdb.KW
	dfrmid = entr.dfrm
	edroot = None
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
		ta = [str(z.id) for z in rs if z.id != dfrmid]
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
	  # Check stat.  May be A or D, but not R.
	if entr.stat == KW.STAT['R'].id:
	    errs.append ("Bad url parameter, stat=R"); return 

	  # The entr value for an approved, root entry and write it to
	  # the database..
	entr.dfrm = None
	entr.unap = False
	res = addentr (dbh, entr)
	  # Delete the old root if any.  Because the dfrm foreign key is
	  # specified with "on delete cascade", deleting the root entry
	  # will also delete all it's children. 
	if edroot: delentr (dbh, edroot)
	  # If we managed to do everything above without errors then
	  # we can commit the changes and we're done.
	dbh.connection.commit()
	return res

def reject (dbh, entr, errs):
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
	res = addentr (dbh, entr)
	delentr (dbh, chhead)
	dbh.connection.commit()
	return res

def addentr (dbh, entr):
	entr._hist[-1].unap = entr.unap
	entr._hist[-1].stat = entr.stat
	res = jdb.addentr (dbh, entr)
	return res

def delentr (dbh, id):
	# Delete entry 'id' (and by cascade, any edited entries
	# based on this one).  This function deletes the entire
	# entry, including history.  To delete the entry contents
	# but leaving the entr and hist records, use database 
	# function delentr.  'dbh' is an open dbapi cursor object.

	sql = "DELETE FROM entr WHERE id=%s";
	dbh.execute (sql, (id,))

def has_xrslv (entr):
	for s in entr._sens:
	    if getattr (s, '_xrslv', None): return True
	return False

if __name__ == '__main__': 
	args, opts = jmcgi.args()
	main (args, opts)
