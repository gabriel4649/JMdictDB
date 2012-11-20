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
# - Patches are files with numeric basename and extension of ".sql"
#    in a common directory.
# - The numeric value of the files' basenames correspond to the patch
#    level the database will be at after application of the patch.
# - This program applies the patches sequentially in numeric order to
#    bring database from current patch level to latest patch level.
# - Database has a table, "dbpatch" (created in 009.sql aka patchlevel 9)
#    that records the current patch level (aka number of the highest
#    numbered patch) applied to date.  Patches, as part of the other
#    changes they make, update this level value.
#
# Patch files are executed with Postgresql's psql command and can
# contain any commands any such file may contain.  They should however
# start with:
#
#   \set ON_ERROR_STOP
#   BEGIN;
#
# and end with:
#
#   INSERT INTO dbpatch(level) VALUES(<N>);
#   COMMIT;
#
# where <N> is the numeric patch level that this file brings the
# database to (and should match the patch file's name.)
#
#######################################################################

__version__ = ('$Revision$'[11:-2],
               '$Date$'[7:-11]);

import sys, os, re, shlex, subprocess
import psycopg2, psycopg2.extensions

def main (args, opts):
        dbconn = psycopg2.connect (**extract_dbopts (opts, 'keywords'))
        psycopg2.extensions.register_type (psycopg2.extensions.UNICODE)
        current_patch_level = get_patch_level (dbconn)
        if not opts.start and current_patch_level == 0:
            error ("Unable to determine the database patch level.\n"
                   "Please use the --start option.")
        if opts.start and current_patch_level > 0 \
                      and opts.start != current_patch_level + 1:
            if not opts.force:
                error ("--start at %d requested but database not at level %d (is at %d).\n"
                       "If you really want to do this, the --force option is required."
                      % (opts.start, opts.start-1, current_patch_level, ))
        startat = opts.start or current_patch_level + 1
          # Scan the patch directory for patchfiles.  get_patches() checks
          # for gaps between patchfile numbers, or duplicate numbers (eg
          # "9.sql" and "009.sql") and returns the number of the lowest
          # numbered patch, and a list of the filenames of all the patches.
          # Thus, if 'first_patchnum' is 7, then the first item in 'patches'
          # will be patch #7 and patches[15] (assuming it exists will be
          # patch #12.
        try: first_patchnum, patches = get_patches (opts.patchdir)
        except OSError:
            error ("Unable to open %s" % patchdir)
        if not patches: error ("No patches found in directory '%s'" % patchdir)
        if opts.stop is None: opts.stop = first_patchnum + len (patches) - 1
        for patch_number in range (startat, opts.stop+1):
            stat = apply_patch (extract_dbopts (opts, 'psql'),
                                patch_number, patches[patch_number-first_patchnum],
                                opts.apply, opts.verbose)
            if stat: break  # 'stat' will be 0 if patch applied ok, non-zero if not.

def get_patch_level (dbconn):
        sql = "SELECT 1 FROM information_schema.tables " \
                 "WHERE table_schema='public' AND table_name='dbpatch'"
        rs = dbread (dbconn, sql)
        if not rs: return 0
          # If no such table, then this is a pre-patchlevel 8 database.
        sql = "SELECT MAX(level) FROM dbpatch"
        rs = dbread (dbconn, sql)
        if not rs: return 0
        return rs[0][0]

def get_patches (patchdir):
        ('Scan file system directory \'patchdir\' for patch files '
         'identified by having names matching the pattern "[0-9]+.pat" '
         'and return a list of those names, sorted by numeric value.  '
         'An exception is raised if the numbers (after the lowest) '
         'are not contiguous or if any are duplicated.  ')

          # Scan the patch directory for patch files.  'patches' will be
          # set to a list of 2-tuples of (int patch number, patch file name).
        patches = [(int(x[:x.index ('.')]), x)
                   for x in os.listdir (patchdir)
                   if re.match ('^[0-9]+.sql$', x, re.I)]
        patches.sort()

          # Set 'patchlist' to a list, in order, of the [patchfile names,
          # and while doing so, make sure there are no gaps in the numeric
          # sequence, nor are there any duplicates.
        patchlist = [];  first_pnum = last_pnum = None;  missing = [];  duplicate = []
        for pnum, pfile in patches:
            if last_pnum is None:
                first_pnum = pnum
            else:
                if pnum == last_pnum: duplicates.append (last_pfile)
                if pnum != last_pnum + 1: missing.append (last_pfile)
            patchlist.append (os.path.normpath (os.path.join (patchdir, pfile)))
            last_pnum = pnum

          # If there were any patches missing from the sequence or any
          # duplicates, complain now.
        m1 = m2 = ""
        if missing or duplicate:
            if missing:   m1 = "Missing patch files after: %s" % (', '.join (missing))
            if duplicate: m2 = "Duplicate patch files: %s" % (', '.join (duplicate))
            msg = m1 + ('\n' if (m1 and m2) else '') + m2
            raise IndexError ("msg")

        return first_pnum, patchlist

def apply_patch (dbopts, patchnum, patchfile, apply, verbose):
        summary = get_patch_summary (patchnum, patchfile)
        print (summary)
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

def get_patch_summary (patchnum, patchfile):
        with open (patchfile) as f:
            firstline = f.readline().strip(' -\r\n')
        summary = ("=" * 72) + '\n' + \
                  "Patch %d -- %s\n" % (patchnum, firstline) + \
                  ("-" * 72)
        return summary

def dbread (dbconn, sql, args=[]):
        c = dbconn.cursor()
        if not args: args = None
        c.execute (sql, args)
        rs = c.fetchall()
        c.close()
        return rs

def extract_dbopts (opts, type):
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

def parse_cmdline ():
        v = sys.argv[0][max (0,sys.argv[0].rfind('\\')+1):] \
                + " Rev %s (%s)" % __version__
        p = argparse.ArgumentParser (add_help=False, description=
            "Apply patches to a JMdictDB database.")
        p.add_argument ("patchdir", default="patches",
            help="Directory containing patch files.")
        p.add_argument ("--stop", type=int, default=None,
            help="Stop after patching to the given patch level. Default "
                "is to apply patches up through the last available.")
        p.add_argument ("-a", "--apply", action="store_true", default=False,
            help="Actually apply the patches to the database.  Without "
                "this option actions that would be taken are printed "
                "but not executed.")
        p.add_argument ("--start", type=int, default=None,
            help="Patch number to start patching at.  This is intended "
                "for use when applying patches to databases that predate "
                "patch level 9 and for which this script cannot determine "
                "what patch level the database is at.  If used with a "
                "post- patch level 8 database and the --start value is "
                "different than the database's current patch level plus "
                "one, the --force option must be given to proceed. ")
        p.add_argument ("--force", action="store_true", default=False,
            help="Insist that updates be applied starting with --start "
                "even though the database's current patch level is not "
                "at the preceeding patch level.")
        p.add_argument ("-v", "--verbose", action="store_true", default=False,
            help="Print the patches as they are applied.")

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
        return opts.patchdir, opts

if __name__ == '__main__':
        args, opts = parse_cmdline()
        sys.exit (main (args, opts))


