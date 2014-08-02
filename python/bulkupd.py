#!/usr/bin/env python
#######################################################################
#  This file is part of JMdictDB.
#  Copyright (c) 2010 Stuart McGraw
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
#  51 Franklin Street, Fifth Floor, Boston, MA  02110#1301, USA
#######################################################################

__version__ = ('$Revision$'[11:-2],
               '$Date$'[7:-11]);

import sys, copy
sys.path.append ('../web/cgi')
import jdb
from edsubmit import submission
from jmcgi import logw

def main (args, opts):
        logw ("Starting bulkupd.py", pre='\n')

          # Open a database connection.
        cur = jdb.dbOpen (opts.database, **jdb.dbopts(opts))
        KW = jdb.KW

          # Open the input file if any, or stdin if not.
        if args: modfile = open (args[0])
        else: modfile = sys.stdin

          # Convert the corpus option to an integer id number.
        corp = KW.SRC[opts.corpus].id

          # Create a history record that will be applied to
          # every entry processed.
        hist = jdb.Hist (notes="Added additional PoS via batch update.",
                         name="Jim Breen", email="jimbreen@gmail.com")
        userid = "jwb"

          # Go through the full list first so that we can
          # check for obvious syntax errors.  Collect the
          # parsed seq number and pos in list, 'updlist'.
        updlist = []
        for ln in modfile:
            seq, ktxt, verb = ln.split()
            verbid = KW.POS[verb].id
            updlist.append ((seq, verbid))

          # Now go through 'updlist' and made the requested
          # change to each entry.  Changes are commited individually
          # and any failed attempts will result in some flavor of
          # UpdateError, which we catch and print, then continue
          # with the next entry.
        for seq, verbid in updlist:
            try: update (cur, seq, corp, verbid, hist,
                         userid, opts.noaction)
            except UpdateError as e: print(e)

def update (cur, seq, src, verbid, hist, userid, noaction):
        # Update a single entry.
        #
        # cur -- An open DBAPI cursor to a JMdictDB database.
        # seq -- Sequence number of entry to update.
        # src -- Id number of corpus of entry.
        # verbid -- Id number of verb to add.
        # hist -- A Hist object with initialized 'name', 'email',
        #       and 'note" fields.
        # userid -- userid string of a editor listed in jmsess.

        logw ("update(): modifying seq# %s, src %s" % (seq, src))
        KW = jdb.KW

          # Start a transaction so we can rollback if there is
          # a problem,
        cur.execute ("BEGIN")

          # Read the entry.  If we get more than one, bail
          # and let the user fix the right version manually.
          # And the same of course if we find no entry.  We
          # ignore antries that are rejected, or are deleted-
          # approved.
        sql = "SELECT id FROM entr WHERE seq=%%s AND src=%%s "\
                "AND (stat=%s OR (stat=%s and unap))"\
                % (KW.STAT['A'].id, KW.STAT['D'].id)
        entries, raw = jdb.entrList (cur, sql, (seq, src), ret_tuple=True)
        jdb.augment_xrefs (cur, raw['xref'])
        if len(entries) > 1:
            logw ("update(): multiple entries for seq number found")
            raise MultipleError (seq)
        if len(entries) == 0:
            logw ("update(): entry for seq number not found")
            raise MissingError (seq)
        entr = entries[0]
        if entr.dfrm:
            logw ("update(): entry has a parent")
            raise ChildError (seq)

        #=============================================================
          # This is the code that makes the actual changes to an
          # entry and could be replaced for other kinds of updates.

          # Add the new PoS to each sense, skipping (with
          # warning message) senses where the PoS is already
          # present.
        changed = False
        for n, s in enumerate (entr._sens):
              # Is the PoS to be added already on the entry?
            if verbid in [x.kw for x in s._pos]:
                  # Yes...
                print("Entry %s sense %s already has pos %s, skipped." \
                    % (seq, n+1, KW.POS[verbid].kw), file=sys.stderr)
            else:
                  # No...
                changed = True
                s._pos.append (jdb.Pos (kw=verbid))
        #=============================================================

          # Skip any entries that weren't changed.
        if changed:

              # Maintain the same approval state in the updated entry
              # as existed in the original entry.  'action' is passed
              # to submission() below.
            action = "" if entr.unap else "a"

              # Provide comments and submitter info for the update.
            entr._hist.append (hist)

            entr.dfrm = entr.id   # This tells submission(): not a new entry.

              # Call the edsubmit's submission() function to make
              # the change to the entry in the database.  This will
              # take care of generating the history record and
              # removing the supercedded entry properly.

            errs = []
            logw ("update(): submitting entry with userid='%s'" % userid)
            submission (cur, entr, action, errs, is_editor=True, userid=userid)
            if errs:
                logw ("submission failed, rolling back")
                cur.execute ("ROLLBACK")
                errmsg = '\n'.join (errs)
                raise SubmitError (seq, errmsg)

            if noaction:
                logw ("main(): rolling back transaction in noaction mode")
                cur.execute ("ROLLBACK")
            else:
                logw ("main(): doing commit")
                cur.execute("COMMIT")
        else:
            logw ("update(): no change made to entry so no db update")

class UpdateError (Exception): pass
class MissingError (UpdateError):
    def __str__(self): return "%s: Seq number not found" % self.args[0]
class MultipleError (UpdateError):
    def __str__(self): return "%s: Seq number has multiple entries" % self.args[0]
class ChildError (UpdateError):
    def __str__(self): return "%s: Seq number has a parent entry" % self.args[0]
class SubmitError (UpdateError):
    def __str__(self): return "%s: Submit error: \n" % (self.args[0], self.args[1])

#-----------------------------------------------------------------------

from optparse import OptionParser

def parse_cmdline ():
        u = \
"""\n\t%prog [options]

%prog will read a text file consistiing of three, white-space
separated fields: seq-number, kanji, pos-keyword.  For each
line, entry 'seq-number' will be looked up in the database and
if only one entri of that seq number exists, 'pos-keyword' will
be added to it if not already present.  The 'kanji' field is
ignored.  If more than one entry exists for a seq  number (e.g.,
a pending edit"), a message will be printed and no action taken
on that entry.

Arguments: filename
    filename -- Name of input file containing entry sequence
        numbers and Pos keywords."""

        v = sys.argv[0][max (0,sys.argv[0].rfind('\\')+1):] \
                + " Rev %s (%s)" % __version__
        p = OptionParser (usage=u, version=v, add_help_option=False)

        p.add_option ("--help",
            action="help", help="Print this help message.")

        p.add_option ("-n", "--noaction", default=False,
            action="store_true",
            help="Perform the actions but make no changes to the "
                "database by rolling back the transaction.")

        p.add_option ("-c", "--corpus", default='jmdict',
            help="Limit entries to CORPUS (which may be given by either "
                "id number or keyword.  Default is \"jmdict\".")

        p.add_option ("-d", "--database",
            type="str", dest="database", default="jmdict",
            help="Name of the database to load.")
        p.add_option ("-h", "--host", default=None,
            type="str", dest="host",
            help="Name host machine database resides on.")
        p.add_option ("-u", "--user", default=None,
            type="str", dest="user",
            help="Connect to database with this username.")
        p.add_option ("-p", "--password", default=None,
            type="str", dest="password",
            help="Connect to database with this password.")

        p.epilog = """\
This program will write entries to a submit log file just as the
subbmit web page does.  The log file will be opened in the current
directory so if you wish the updates made by this program to be
entered in the web page log file, run this program while cd'ed
to the web cgi directory."""

        opts, args = p.parse_args ()
        if len (args) > 1: p.error ("Expected at most one argument (filename)")
        return args, opts

if __name__ == '__main__':
        args, opts = parse_cmdline()
        main (args, opts)
