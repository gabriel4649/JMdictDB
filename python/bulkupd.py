#!/usr/bin/env python3
#######################################################################
#  This file is part of JMdictDB.
#  Copyright (c) 2014 Stuart McGraw
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
#######################################################################.

__version__ = ('$Revision$'[11:-2],
               '$Date$'[7:-11]);

import sys, re, logging, pdb

# Have to call basicConfig() before imports because edsubmit.py imports jmcgi.py
# imports tal.py which calls logging.basicConfig() which causes our call to have
# no effect.  Not sure best way to fix -- if we remove the basicConfig call from  
# tal.py we may have to configure in every app that uses tal.py.  Or possibly now
# in python3 the default config would be ok?
_format = '%(asctime)s %(levelname).1s %(name)s(%(process)s):%(funcName)s: %(message)s'
logging.basicConfig (level=logging.DEBUG, datefmt='%Y-%m-%d %H:%M:%S', format=_format)

import os, inspect
_ = os.path.abspath(os.path.split(inspect.getfile(inspect.currentframe()))[0])
_ = os.path.join (os.path.dirname (_), 'python', 'lib')
if _ not in sys.path: sys.path.insert(0, _)
import psycopg2
import jdb

sys.path.append ('../web/cgi')
from edsubmit import submission

L = logging.getLogger ('bulkupd.py')

def main (cmdargs=sys.argv):
          # Parse command line arguments.
        args = parse_cmdline (cmdargs)

          # Open a database connection.
        cur = jdb.dbOpen (None, **jdb.parse_pguri (args.database))

          # Parse the input command file.  The result is a list of
          #  3-tuples of seq, src, edits.  'edits' in turn is a list
          #  of Cmd() instances that describe a sequence of changes
          #  to be made to the entry identified by seq,src. 
          #  parse_cmdfile() returns None if any errors occured.  
        if not args.filename: f = sys.stdin
        else: f = open (args.filename)
        cmds = parse_cmdfile (f, args.corpus)
        if f != sys.stdin: f.close()
        if cmds is None:
            L.error ("Exiting due to errors in input file")
            return

          # Now go through 'cmds' and make the requested
          # change to each entry.  Changes are commited individually
          # and any failed attempts will result in some flavor of
          # UpdateError, which we catch and print, then continue
          # with the next entry.
        done = 0
        for seq, src, edits in cmds:
            L.info ("Modifying seq# %s, src %s" % (seq, src))
            try: entr = getentry (cur, seq, src)
            except UpdateError as e:
                L.error (e); continue
            hist = jdb.Hist (name=args.name, email=args.email, notes=args.comment,
                             refs=args.refs, userid=args.userid)
            for edit in edits:
                try: doedit (entr, hist, edit)
                except UpdateError as e: 
                    L.error (e); break
            else: # Executed if the for-loop exits normally (not via 'break').
                entr._hist.append (hist)
                try: submit (cur, entr, args.userid, args.noaction)
                except UpdateError as e: L.error (e)
                else: done += 1
        if len(cmds) != done: L.error ("%d entries not updated due to errors" 
                                        % (len(cmds)-done))
        noactmsg = "not updated due to --noaction option" if args.noaction else "updated"
        L.info ("%d entries %s" % (done, noactmsg))

def parse_cmdfile (cmdfile, initial_corpus):
        # Read and parse the file 'cmdfile' and return None is any errors were
        # encountered or a list of 3-tuples representing the parsed contents if
        # not.  Each 3-tuple consists of:
        #   seq-number -- (int) sequence number of entry to be edited.
        #   corpus-number -- (int) id number of corpus containing entry.
        #   cmds -- A list cof Cmd() instances that are the edits to be 
        #     applied to the entry.
        errors = 0
        try: src = jdb.KW.SRC[initial_corpus].id
        except KeyError: 
            L.error ("Unknown corpus: '%s'" % initial_corpus)
            return None
        cmds = [];  edits = None
        for lnnum, ln in enumerate (cmdfile, start=1):
            ln = ln.rstrip()
            if not ln: continue                 # Skip blank lines.
            if re.match (r'\s*#', ln): continue # Skip comment lines.
            try: cmdtxt, rest = ln.split (maxsplit=1)
            except ValueError: 
                L.error ("line %d: Invalid directive line" % (lnnum))
                errors += 1; continue
            if cmdtxt == 'corpus': 
                try: src = jdb.KW.SRC[rest].id
                except KeyError: 
                    L.error ("line %d: Unknown corpus: '%s'" % (lnnum, rest))
                    errors += 1; corpus = None
            elif cmdtxt == 'seq': 
                try: seq = int (rest)
                except ValueError:
                    L.error ("line %d: Bad seq number: '%s'" % (lnnum, rest))
                    errors += 1; seq = None
                edits = []
                if seq and src: cmds.append ([seq, src, edits]) 
            else: 
                try: cmd = Cmd (cmdtxt, rest)
                except ParseError as e:
                    L.error ("line %d: %s" % (lnnum, e)) 
                    errors += 1; continue
                else: edits.append (cmd)
        if errors: return None
        return cmds

class Cmd:
      # add/repl/del kanj/rdng [oldtxt] [newtxt]
      # add/repl/del gloss[sens] [oldtxt] [newtxt]
      # add/repl/del pos/misc/fld/dial[sens] [oldkw] [newkw]
      # del entr junktxt
    def __init__ (self, cmd, txt):
        # cmd -- The command directive: one of "add", "repl", "del".
        # txt -- remainder of input file line after removing directive.

        if cmd not in ('add', 'repl', 'del'): raise DirectiveError (cmd)
        self.cmd = cmd
        self.operand = None     # The part of the entry to edit ('kanj', 'pos', etc).
        self.sens = None        # Sense number (base 1). 
        self.new = None         # Value to add or use for replacement in entry.
        self.old = None         # Value to delete or replace in entry.
        pattern = r'''
          ((?:entr)|(?:kanj)|(?:rdng)|(?:gloss)|(?:pos)|(?:misc)|(?:fld)|(?:dial)|(?:comment)|(?:refs))
          \s*
          (?:\[([0-9]+)\])?    # Optional sense number (in square brackets).
          \s+
          ((?:[^"][^\s]*)              # Unquoted or...
          |(?:"(?:(?:\\")|[^"])*"))    #  quoted string.
          (?:\s+
          ((?:[^"][^\s]*)              # Optional unquoted...
          |(?:"(?:(?:\\")|[^"])*")))?  #  or quoted string.
          \s*
          $
          '''
        mo = re.match (pattern, txt, re.I|re.X)
        if not mo: raise ArgumentsError (cmd)
        self.operand = mo.group(1).lower()
        self.sens = int (mo.group(2) or 0)
        if self.cmd != 'repl':
            if mo.group(4): raise ReplValError (self.operand)
            if self.cmd == 'add': self.new = clean_quoted_string (mo.group(3))
            else: self.old = clean_quoted_string (mo.group(3))
        else:
            self.old = clean_quoted_string (mo.group(3))
            self.new = clean_quoted_string (mo.group(4))
        if self.operand in ('kanj','rdng','comment','refs'):
            if self.sens: raise SensError (self.operand)
        else: # sens number required...
            if not self.sens: self.sens = 1 #raise NoSensError (self.operand)
        if self.operand in ('comment','refs'):
            if cmd != 'add': raise NotAddError (cmd)
        if self.operand == 'entr':
            if cmd != 'del': raise NotDelError (cmd)
        if self.operand in ('pos','misc','fld','dial'):
            kwds = getattr (jdb.KW, self.operand.upper()) 
            for kw in self.old, self.new: 
                if not kw: continue
                try: kwds[kw]
                except KeyError: raise KwError (kw, self.operand)

def clean_quoted_string (s):
        if not s.startswith ('"'): return s
          # Remove enclosing quotes and unescape internal quotes.
        s = (s.replace (r'\"', '"'))[1:-1]
        return s

def getentry (cur, seq, src):
        # cur -- An open DBAPI cursor to a JMdictDB database.
        # seq -- Sequence number of entry to retrieve.
        # src -- Corpus id number of entry to retrieve.

          # Read the entry.  If we get more than one, bail
          # and let the user fix the right version manually.
          # And the same of course if we find no entry.  We
          # ignore entries that are rejected, or are deleted-
          # approved.
        KW = jdb.KW
        sql = "SELECT id FROM entr WHERE seq=%%s AND src=%%s "\
                "AND (stat=%s OR (stat=%s and unap))"\
                % (KW.STAT['A'].id, KW.STAT['D'].id)
        entries, raw = jdb.entrList (cur, sql, (seq, src), ret_tuple=True)
        jdb.augment_xrefs (cur, raw['xref'])
        if len(entries) > 1: raise MultipleError (seq)
        if len(entries) == 0: raise MissingError (seq)
        entr = entries[0]
        if entr.dfrm: raise ChildError (seq)
        return entr

def doedit (entr, hist, cmd):
        # entr -- A jdb.Entr() instance to be edited. 
        # hist --  A jdb.Hist instance that will be edited (if the edit
        #   is to add a comment of refs.)
        # cmd -- A Cmd instance that describes changes to be made to entry.
        # 
        # Apply the change described by <cmd> to <entr> and /or <hist>.
        #
        # Should return True if <entr> or <hist> were actually changed,
        # False if not, but currently always retuns True.

        new = None
        if cmd.operand in ('kanj', 'rdng'): 
            tlist = getattr (entr, '_'+cmd.operand)
            if cmd.new:
                if cmd.operand == 'kanj': new = jdb.Kanj (txt=cmd.new)
                else: new = jdb.Rdng (txt=cmd.new)
            edit (tlist, 'txt', cmd.old, new or cmd.new, cmd.operand, cmd.old, cmd.new)
        elif cmd.operand == 'gloss':
            tlist = getattr (getattr (entr, '_sens')[cmd.sens-1], '_'+cmd.operand)
            if cmd.new: new = jdb.Gloss (txt=cmd.new, lang=jdb.KW.LANG['eng'].id, 
                                                      ginf=jdb.KW.GINF['equ'].id)
            edit (tlist, 'txt', cmd.old, new or cmd.new, cmd.operand, cmd.old, cmd.new)
        elif cmd.operand in ('pos','misc','fld','dial'):
            tlist = getattr (getattr (entr, '_sens')[cmd.sens-1], '_'+cmd.operand)
            new, old = kw2id (cmd.operand, cmd.new, cmd.old)
            edit (tlist, 'kw', old, new, cmd.operand, cmd.old, cmd.new)
        elif cmd.operand == 'entr':
            if cmd.cmd == 'del': entr.stat = jdb.KW.STAT['D'].id
        elif cmd.operand == 'comment': hist.notes = cmd.new
        elif cmd.operand == 'refs': hist.refs = cmd.new
        else: raise ValueError (cmd.operand)

        return True #FIXME: how to determine if no change was made to entry?

def edit (tlist, srchattr, old, new, operand,  t_old, t_new):
        # tlist -- A _kanj, _rdng, _gloss, _pos, _misc, _fld, or _dial
        #   list from an entry.
        # srchattr -- Name of attribute to use when searching 'tlist'  
        #   for item matching 'old', ie 'txt' for _kanj, _rdng, _gloss,
        #   or 'kw' for _pos, _misc, _fld, _dial.
        # old -- None or text string or id number that identifies item
        #   to replace or delete in 'tlist'.
        # new -- None or an instance of appropriate type (Kanj(), Pos()
        #   etc.) to replace 'old' in, or append to, 'tlist'.
        # operand -- Used only as text in log messages.
        # t_old -- text form of <old> for use in log messages.
        # t_new -- text form of <new> for use in log messages.
        # 
        # If old and not new: delete item from 'tlist' that matches 'old'.
        # If not old and new: add 'new' (should be of correct type) to
        #   end of 'tlist'.
        # If old and new: replace item in 'tlist' that matches 'old'
        #   with 'new' (should be of correct type).

        if old:
            srch = [getattr (t, srchattr) for t in tlist]
            try: index = srch.index (old)
            except ValueError as e:
               raise NotFoundError (t_old, operand)
            if not new: 
                L.info ("Deleting '%s' from '%s'" % (t_old, operand))
                del tlist[index]
        if new:
            if not old: 
                L.info ("Appending '%s' to '%s'" % (t_new, operand))
                tlist.append (new)
            else: 
                L.info ("Replacing '%s' with '%s' in '%s'" % (t_old, t_new, operand))
                tlist[index] = new

def kw2id (operand, new, old):
        if   operand == 'pos':
            if new: new = jdb.Pos (kw=jdb.KW.POS[new].id)
            if old: old = jdb.KW.POS[old].id
        elif operand == 'misc':
            if new: new = jdb.Misc (kw=jdb.KW.MISC[new].id)
            if old: old = jdb.KW.MISC[old].id
        elif operand == 'fld':
            if new: new = jdb.Fld (kw=jdb.KW.FLD[new].id)
            if old: old = jdb.KW.FLD[old].id
        elif operand == 'dial':
            if new: new = jdb.Dial (kw=jdb.KW.DIAL[new].id)
            if old: old = jdb.KW.DIAL[old].id
        return new, old

def submit (cur, entr, userid, noaction):
        # cur -- An open DBAPI cursor to a JMdictDB database.
        # entr -- Modified entry that will replace current db version of entry.
        #    We assume that any desired Hist() record has already been appended. 
        # userid -- userid string of a editor listed in jmsess or None.
        #    The former implies submitting the changes as "approved" (if
        #    the parent entry was also "approved"); the latter implies
        #    submitting the entr as "unapproved".  Note that 'userid' is
        #    not valiated or checked against the jmsess database. 
        # noaction -- Boolean which will if true will rollback any changes. 

          # Maintain the same approval state in the updated entry
          # as existed in the original entry.  'action' is passed
          # to submission() below.
        action = "" if entr.unap or not bool (userid) else "a"

        entr.dfrm = entr.id   # This tells submission() that we are editing an
                              #  existing entry, not creating a new entry.

          # Call the edsubmit's submission() function to make
          # the change to the entry in the database.  This will
          # take care of generating the history record and
          # removing the superceded entry properly.

        L.info ("Submitting %s entry with userid='%s'" 
                % ("approved" if action=='a' else "unapproved", userid))
        errs = []
        cur.execute ("BEGIN")
        try: submission (cur, entr, action, errs, is_editor=bool(userid), userid=userid)
        except psycopg2.DatabaseError as e: errs.append (str(e))
        if errs:
            L.error ("Submission failed, rolling back")
            cur.execute ("ROLLBACK")
            errmsg = ('\n'.join (errs)).rstrip()
            raise SubmitError (entr.seq, errmsg)
        if noaction:
            L.info ("Rolling back transaction in noaction mode")
            cur.execute ("ROLLBACK")
        else:
            L.info ("Doing commit")
            cur.execute("COMMIT")

class ParseError (Exception): pass 
class DirectiveError (ParseError):
    def __str__(self): return "Unrecognised directive: '%s'" % self.args[0]
class ArgumentsError (ParseError):
    def __str__(self): return "Unparsable arguments to '%s' directive" % self.args[0]
class SensError (ParseError):
    def __str__(self): return "Sense number not allowed with '%s' directive" % self.args[0]
class NoSensError (ParseError):
    def __str__(self): return "Sense number required with '%s' directive" % self.args[0]
class ReplValError (ParseError):
    def __str__(self): return "Replacement value not allowed with '%s' directive" % self.args[0]
class NotAddError (ParseError):
    def __str__(self): return "Can only 'add' comments or refs, '%s' not allowed" % self.args[0]
class NotDelError (ParseError):
    def __str__(self): return "Can only 'del' entries, '%s' not allowed" % self.args[0]
class KwError (ParseError):
    def __str__(self): return "'%s' not a valid value for '%s'" % self.args

class UpdateError (Exception): pass
class MissingError (UpdateError):
    def __str__(self): return "%s: Seq number not found" % self.args[0]
class MultipleError (UpdateError):
    def __str__(self): return "%s: Seq number has multiple entries" % self.args[0]
class ChildError (UpdateError):
    def __str__(self): return "%s: Seq number has a parent entry" % self.args[0]
class NotFoundError (UpdateError):
    def __str__(self): return "'%s' not found in '%s'" % (self.args[0], self.args[1])
class SubmitError (UpdateError):
    def __str__(self): return "%s: %s" % (self.args[0], self.args[1])

#-----------------------------------------------------------------------

from argparse import ArgumentParser
from lib.pylib.argparse_formatters import ParagraphFormatter

def parse_cmdline (cmdargs):
        u = \
"Bulkupd.py will edit and submit changes to multiple entries " \
"based on an input file that describes the entries to be modified " \
"and the modifications to be made to them."

        v = cmdargs[0][max (0,cmdargs[0].rfind('\\')+1):] \
                + " Rev %s (%s)" % __version__
        p = ArgumentParser (description=u, formatter_class=ParagraphFormatter)

        p.add_argument ("filename", nargs='?', default=None,
            help="Name of file containing bulk update commands.  If omitted, "
                "the commands will be read from stdin.")

        p.add_argument ("-n", "--noaction", default=False,
            action="store_true",
            help="Perform the actions including updating the entries in the "
                "database but roll back the transaction so the changes are undone. "  
                "This allows doing a trial run to find errors but without making "
                "any permanent changes.")

        p.add_argument ("--corpus", default='jmdict',
            help="Name of corpus that entries will be looked for in, until "
                "overridden by a \"corpus\" directive in the command file.  "
                "If not given the default is \"jmdict\".")

        p.add_argument ("-c", "--comment", default=None,
            help="Text that will be used for a comment for all updated entries "
                "that don't have entry-specific comments in the command file.")

        p.add_argument ("-r", "--refs", default=None,
            help="Text that will be used for references for all updated entries "
                "that don't have entry-specific references in the command file.")

        p.add_argument ("-s", "--name", default='',
            help="Name to be used for submitter.")

        p.add_argument ("-e", "--email", default='',
            help="Submitter's email address.")

        p.add_argument ("-u", "--userid", default='',
            help="User id of editor.  If not given, the modified entries will be created "
                "in an unapproved state.  If given, the modified entries will be created "
                "in the same approval state that the original entries were in.  " 
                "This argument is not validated in any way -- write access to the "
                "database by the user executing this program is sufficient to allow "
                "any changes including approval of the updated entry.  ")

        p.add_argument ("-d", "--database", default="pg:///jmdict",
            help="URI for database to open.  The general form is: \n"
                " pg://[user[:password]@][netloc][:port][/dbname][?param1=value1&...] \n"
                "Examples: \n"
                " pg://localhost \n"
                " pg://localhost/jmdict \n"
                " pg:///jmdict \n"
                " pg://user@localhost \n"
                " pg://user:mypassword@/jmdict \n"
                " pg://remotehost.somewhere.org:8866 \n"
                "For more details see \"Connection URIs\" in the \"Connections Strings\" "
                "section of the Postgresql \"libq\" documentation. ")

        p.epilog = """\
Input file syntax:

The input file is a text file and each line contains a directive followed
by arguments.  The number and meaning of the arguments depends on the 
directive.  Blank lines and comments (lines starting with a # character, 
possibly preceeded with whitspace) are ignored. 

Directives:
    corpus <name>
        Set the "current" corpus to <name>.  This determines what corpus
        will be searched for entries given by subsequent "seq" directives.
        A corpus can be also be specified with the --corpus command line
        option and it will remain in effect until a "corpus" directive
        is encountered in the input file.
    seq <seq-number>
        Set the current entry to seq number <seq-number>.  The directives
        below will apply to this entry until a new "seq" directive is
        encountered.
    add <operand> [<sense#>] <new-value>
        <operand> may be any of:
          kanj, rdng, gloss, pos, misc, fld, dial, comment, refs
        [sense#] (including the brackets) must not be given if <operand> 
          is kanj, rdng, comment or refs.  It is optional for other operands
          and is the sense number containing the items to be acted on.
          If not given, the default is 1.
        <new-value> If operand is kanj, rdng, gloss, comment or refs, this
          is the text for the item to be added.  If it contains any white-
          space, the entire string should be enclosed in double-quote (")
          characters.  If such a quoted string also contains any double-
          quote (") characters they should be escaped with as backslash (\)
          character.  If operand is pos, misc, fld or dial, <new-value> is
          the keyword that is to be added.
    del <operand> [<sense#>] <old-value>
         <operand> and <sense#> have the same meanings as for the "add"
         directive except that "comment" and "refs" are not valid.
         <old_value> is either text or a keyword that will searched for
         in the current entry and removed.  An error will be generated and
         no changes made to the current entry if no text or keyword matching
         <old-value> is found.
    del entr xxx
         The entry with the current seq number will be deleted. "xxx" is 
         some arbitrary text required to keep the parser happy.
    repl <operand> [<sense#>] <new-value> <old-value>
         <operand> and <sense#> have the same meanings as for the "add"
         directive except that "comment" and "refs" are not valid.
         <old_value> is either text or a keyword and will be replaced by
         <new-value>.  An error will be generated and no change made to
         the current entry if no text or keyword matching <old-value> is
         found.

Usage example:
    python3 bulkupd.py -u jwb -c 'Update per edict maillist discussion' \\
        -s 'Jim Breen' -e 'jimbreen@gmail.com'
      # Following entry is 呉れる（くれる）
    seq 1269130
    repl v1 v1-ik
      # Following entry is だ
    seq 2089020
    add pos cop-da
      # Following is 良い（いい）
    seq 1605820
    repl pos[1] adj-i adj-ix
    repl pos[2] adj-i adj-ix
    repl pos[3] adj-i adj-ix
    repl pos[4] adj-i adj-ix
    seq 1882070
    add comment "deleted because ..."
    del entr xxx

Missing capabilities: 
There is no way at present to do the following:
  * Add/repl/del an entire sense.
  * Add/repl/del lsrc, rinf, kinf, freq, stagk, stagr, restr, xref, ginf, lang elements.
  * Reorder elements.
  * Use multi-line comments or refs in the command file.
"""
        args = p.parse_args (cmdargs[1:])
        return args

if __name__ == '__main__': main()
