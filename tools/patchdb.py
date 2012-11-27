#!/usr/bin/env python3
#######################################################################
#  This file is part of JMdictDB.
#  Copyright (c) 2012 Stuart McGraw
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
#  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA
#######################################################################
#
# Apply patches to a JMdictDB database.
# - Run this program with the --help option for more info.
# - Database has a table, "dbpatch" (created in 009.sql aka patch
#    level 9) that records the current patch level.  Patches, as
#    part of the other changes they make, update this level value.
# - Patches are files with an extension of ".sql" in a common directory.
# - Each patch file has a header comment line that says what patch
#    level the database must be at to apply the patch, and what level
#    it will be at after application.
# - This program will use the before/after patch levels to find a
#    sequence of patches that will move the database from its current
#    level to the requested level.
#
# Patch files are executed with Postgresql's psql command and can
# contain any commands acceptable to psql.  They should start with
# two comment lines that give a one-line description of the patch
# and what the initial and final patch levels are.  They must end
# with an INSERT statement to actually set the final patch level.
# For example:
#
#   -- Descr: {One-line summary of changes that patch makes}
#   -- Trans: {N}->{M}
#   \set ON_ERROR_STOP
#   BEGIN;
#   {...
#    psql commands needed to implement the patch
#   ...}
#   INSERT INTO dbpatch(level) VALUES({M});
#   COMMIT;
#
# where the text in curly brackets should be replaced appropriately
# WITHOUT the curly brackets.  {N} is the patch level the database
# must be at for patchdb.py to apply the patch; {M} will be the patch
# level the database will be at after the patch is applied.  Blank
# lines, comments, etc are of course permitted.
#
#######################################################################

__version__ = ('$Revision$'[11:-2],
               '$Date$'[7:-11]);

import sys, os, inspect, pdb
_ = os.path.abspath(os.path.split(inspect.getfile(inspect.currentframe()))[0])
_ = os.path.join (os.path.dirname(_), 'python', 'lib')
if _ not in sys.path: sys.path.insert(0, _)

import re, collections, shlex, subprocess
import psycopg2, psycopg2.extensions
sys.path.append ('/home/stuart/devel/pylib')
from pylib import dijkstra

class PatchError         (Exception):  pass
class FileFormatError    (PatchError): pass
class MultiplePatchError (PatchError): pass
class NoUpgradePathError (PatchError): pass
class UnknownLevelError  (PatchError): pass

def main (args, opts):
        if not opts.list:
            dbconn = psycopg2.connect (**extract_dbopts (opts, 'keywords'))
            psycopg2.extensions.register_type (psycopg2.extensions.UNICODE)
            current_patch_level = get_patch_level (dbconn)
            if current_patch_level is None and opts.start is None:
                error ("Unable to determine the database patch level.\n"
                       "Please use the --start option.")
            if opts.start and current_patch_level is not None \
                          and opts.start != current_patch_level:
                if not opts.force:
                    error ("--start at %s requested but database not at level %s (is at %s).\n"
                           "If you really want to do this, the --force option is required."
                          % (opts.start, opts.start, current_patch_level))
            startat = opts.start or current_patch_level
            if startat == opts.tolevel:
                error ("The starting level and target level are the same: %s" % opts.tolevel)
        try: patches = read_patches (opts.patchdir)
        except OSError:
            error ("Unable to open %s" % opts.patchdir)
        if not patches:
            error ("No patch files found in directory '%s'" % opts.patchdir)
        if opts.list:
            list_patches (patches, opts.verbose)
        else:
            try: upgrade_path = find_upgrade_path (patches, startat, opts.tolevel)
            except PatchError as e: error (str(e))
            do_upgrade (upgrade_path, opts.apply, opts.verbose)

def find_upgrade_path (patches, from_level, to_level):
        transmap = {}
        graph = dijkstra.Graph()
        for patchfile, description, translist in patches:
            for fromlvl, tolvl in translist:
                graph.add_edge (fromlvl, tolvl, 1)
                if (fromlvl,tolvl) in transmap:
                    raise MultiplePatchError ("Multiple patches exist for %s->%s upgrade"
                                             % (fromlvl,tolvl))
                transmap[(fromlvl,tolvl)] = [patchfile, description]
        try: path = dijkstra.shortest (graph, from_level, to_level)
        except ValueError as e:
            raise UnknownLevelError ("Unknown patch level '%s'\n" % (e.args[1]))
        if not path:
            raise NoUpgradePathError ("No upgrade path from level '%s' to level '%s' exists"
                                     % (from_level, to_level))
        upgrade_path = []
        for n, tolvl in enumerate (path):
            if n>0: upgrade_path.append ([fromlvl,tolvl]+transmap[(fromlvl,tolvl)])
            fromlvl = tolvl
        return upgrade_path

def list_patches (patches, verbose):
        for patchfile, description, translist in sorted (patches):
            descr = "" if verbose else ("  Descr: %s" % description)
            transtxt = ', '.join(["%s->%s"%(f,t) for f,t in translist])
            summary = "%s\n%s: Upgrades level(s) %s\n%s" \
                      % ("="*72, patchfile, transtxt, descr)
            print (summary)
            if verbose:
                with open (patchfile) as f: text = f.read()
                print (text)

def do_upgrade (upgrade_path, apply, verbose):
        for fromlvl, tolvl, patchfile, descr in upgrade_path:
            summary = "%s\nPatch level '%s' to '%s': %s\nDescr: %s" \
                      % ("="*72, fromlvl, tolvl, patchfile, descr)
            print (summary)
            stat = apply_patch (extract_dbopts (opts, 'psql'),
                                patchfile, apply, verbose)
            if stat: break  # 'stat' will be 0 if patch applied ok, non-zero if not.

def get_patch_level (dbconn):
        sql = "SELECT 1 FROM information_schema.tables " \
                 "WHERE table_schema='public' AND table_name='dbpatch'"
        rs = dbread (dbconn, sql)
        if not rs: return None
          # If no such table, then this is a pre-patchlevel 8 database.
        sql = "SELECT MAX(level) FROM dbpatch"
        rs = dbread (dbconn, sql)
        if not rs: return None
          # Currently, the database patch level is stored in the database
          # as a number, but this script treats patch levels as strings,
          # so return a string.
        level = rs[0][0]
        if level is None:  # Table is there but is empty, something's busted.
            error ("dbpatch table found in database but is empty.")
        return str (level)

def read_patches (patchdir, quiet=False):
        patchfiles = [];  nonpatchfiles = []
        for fname in os.listdir (patchdir):
            if not re.match (r'.+\.sql$', fname): continue
            fullname = os.path.normpath (os.path.join (patchdir, fname))
            try: descr, translist = read_patch_file (fullname)
            except (FileFormatError,OSError): nonpatchfiles.append (fullname)
            else: patchfiles.append ((fullname, descr, translist))
        if not quiet and nonpatchfiles:
            print ("Ignoring non-patch files: %s\n  "
                   % ' '.join ([shlex.quote(x) for x in nonpatchfiles]))
        return patchfiles

def read_patch_file (filename):
        with open (filename) as f:
                descr = transtxt = None
                for n, ln in enumerate (f):
                    if not descr:
                        mo = re.search (r'Descr:\s*(.*)', ln, re.I)
                        if mo: descr = mo.group(1)
                    if not transtxt:
                        mo = re.search (r'Trans:\s*(?P<t>[0-9a-z_]+\s*->\s*[0-9a-z_]+)(\s*,\s*(?P=t))*', ln, re.I)
                        if mo: transtxt = mo.group(1)
                    if n > 100: break
        if not descr: raise FileFormatError ("No description line found")
        if not transtxt: raise FileFormatError ("No trans line found")
        translist = re.findall (r'([0-9a-z_]+)\s*->\s*([0-9a-z_]+)', transtxt, re.I)
        return descr, translist

def apply_patch (dbopts, patchfile, apply, verbose):
        command = ['psql'] + dbopts + (['-a'] if verbose else []) + ['-f', patchfile]
        if not apply:
            print (' '.join ([shlex.quote(x) for x in command]))
            if verbose:
                with open (patchfile) as f: text = f.read()
                print (text)
        else:
            try: subprocess.check_call (command)
            except subprocess.CalledProcessError as e: return e.returncode
        return 0

def dbread (dbconn, sql, args=[]):
        c = dbconn.cursor()
        if not args: args = None
        c.execute (sql, args)
        rs = c.fetchall()
        c.close()
        return rs

def extract_dbopts (opts, type):
        # Extract database-specific options from an argparse
        # namespace ('opts') and return them in a format determined
        # by the value of 'type':
        #   "keywords" -- return as a dict suitable for passing
        #      to the psycopg2.connect() function.
        #   "psql" -- Return as a list suitable for starting a
        #      psql subprocess with.

        kw = {}
        if opts.database: kw['database'] = opts.database
        if opts.host: kw['host'] = opts.host
        if opts.user: kw['user'] = opts.user
        if type == 'keywords': return kw
        if type == 'psql':
            optsmap = {'database':'-d', 'host':'-h', 'user':'-U'}
            optslist = []
            for k,v in kw.items(): optslist.extend ([optsmap[k], v])
            return optslist
        raise ValueError ("Invalid 'type' argument")

def error (msg):
        print (msg, file=sys.stderr)
        sys.exit(1)

import argparse
from pylib.argparse_formatters import ParagraphFormatter

def parse_cmdline ():
        v = sys.argv[0][max (0,sys.argv[0].rfind('\\')+1):] \
                + " Rev %s (%s)" % __version__
        p = argparse.ArgumentParser (add_help=False,
            formatter_class=ParagraphFormatter,
            description=
                "Apply a series of patches to a JMdictDB database.",
            epilog=
                "JMdictDB databases (at least after patch level 9) have a table, "
                "'dbpatch', that contains the current patch level of the database.  "
                "This level is a number that represents a series of updates that "
                "have been made to the database to make its structure the same as "
                "a database installed from scratch from the currect source code "
                "the time of the update was produced.  \n\n"
                ""
                "Each patch file contains a single logical change, not cummulative "
                "changes, so to go from level 2 to level 5, all the patches between "
                "those two levels must be applies, not just level 5.\n\n"
                ""
                "Patch files are .sql files that contain commands to be executed "
                "by the Postgresql 'psql' command.  The last command executed will "
                "update the patch level number in the 'dbpatch' table.  The psql "
                "commands are normally bracketed by BEGIN and COMMIT commands so "
                "the patch is applied entirely or not at all.  This script will "
                "stop if a patch fails and not apply any further ones until the "
                "problem is corrected and the failing patch sucessfully applied." )
        p.add_argument ("patchdir", default=None,
            help="Directory containing patch files.")
        p.add_argument ("-t", "--tolevel", default=None,
            help="Upgrade to the given patch level.  This is required unless "
                "--list is given.")
        p.add_argument ("-l", "--list", action="store_true", default=False,
            help="List all the patches available in PATCHDIR and exit.")
        p.add_argument ("-a", "--apply", action="store_true", default=False,
            help="Actually apply the patches to the database.  Without "
                "this option actions that would be taken are printed "
                "but not executed.  Use with --vebose to print more detail.")
        p.add_argument ("--start", default=None,
            help="Patch level to assume database is at.  Normally this "
                "option is not needed and the script will query the "
                "database for its current patch level.  This option is "
                "intended for use when applying patches to databases prior "
                "to patch level 9 for which this script cannot determine "
                "the current patch level.  If used with a patch level 9 "
                "or later database and the --start value is different "
                "than the database's current patch level, the --force "
                "option must be given to proceed. ")
        p.add_argument ("--force", action="store_true", default=False,
            help="Insist that updates be applied starting with --start "
                "even though the database's current patch level is not "
                "at the preceeding patch level.")
        p.add_argument ("-v", "--verbose", action="store_true", default=False,
            help="Print the patch commands as they are applied.")

        p.add_argument ("-d", "--database", default="jmdict",
            help="Name of the database to load.  Default is \"jmdict\".")
        p.add_argument ("-h", "--host", default=None,
            help="Name host machine database resides on.")
        p.add_argument ("-u", "--user", default=None,
            help="Connect to database with this username.")

        p.add_argument ('--help', action='help', \
            help="Print this help text and exit.")
        p.add_argument ('--version', action='version', version=v,
            help="Show program's version number and exit.")
        opts = p.parse_args ()
        if not opts.tolevel and not opts.list:
            p.error ("The following arguments are required: --tolevel")
        return [opts.tolevel, opts.patchdir], opts

if __name__ == '__main__':
        args, opts = parse_cmdline()
        sys.exit (main (args, opts))


