#!/usr/bin/env python3

"""Replace leading tabs with spaces and remove trailing
space/tabs in argument files.  Print names of changed files.
This file is a modified version on the untabify.py script
distributed with Python."""

__version__ = ('$Revision$'[11:-2],
               '$Date$'[7:-11]);

import sys, os, re

def main (args, opts):
        changed = errors = 0
        for filename in args:
            try: stat = process (filename, opts.tabsize, opts.alltabs,
                                 opts.noaction, opts.backup)
            except IOError as exc:
                print ("%r: I/O error: %s" % (filename, exc), file=sys.stderr)
                errors += 1;  stat = 0
            if stat and (opts.noaction or not opts.quiet):  print (filename)
            changed += stat
        return 2 if errors else (changed > 0)  # Exit status code

def process (filename, tabsize, alltabs, noaction, suffix):
        # Parameters:
        #   filename -- Name of file to process.
        #   tabsize -- Number of spaces for each tab.
        #   alltabs -- If true expand all tabs.  If false expand
        #       only leading tabs.
        #   noaction -- Check file but don't make any changes to it.
        #   suffix -- Append this string to 'filename' to generate
        #       the backup filename.
        # Returns:
        #   1 if file was (or would have been) modified.
        #   0 if not.

        f = open (filename, 'rb')
        bytes = f.read()
        f.close()
        newbytes = bytes
        if b'\t' in newbytes:  # Skip slow .sub() if no tabs.
            if alltabs: newbytes = newbytes.expandtabs (tabsize)
            else: newbytes = re.sub (rb'(^[ \t]+)',   # Expand only leading tabs.
                                     lambda x: x.group(0).expandtabs(tabsize),
                                     bytes, 0, re.M)
          # Remove trailing spaces and tabs.
        newbytes = re.sub (rb'[ \t]+$', lambda x:b'', newbytes, 0, re.M)
        if newbytes == bytes: return 0
        if not noaction:
            s = os.stat (filename)
            backup = filename + suffix
            try: os.unlink (backup)
            except os.error: pass
            os.rename (filename, backup)
            with open (filename, "wb") as f: f.write (newbytes)
            os.chmod (filename, s.st_mode)
        return 1

import argparse

def parse_cmdline ():
        v = sys.argv[0][max (0,sys.argv[0].rfind('\\')+1):] \
                + " Rev %s (%s)" % __version__
        p = argparse.ArgumentParser (description=
            "Replace tabs with spaces and remove trailing whitespace "
            "in files.")
        p.add_argument ("filename", nargs='*',
            help="Name(s) of file(s) to be checked.")
        p.add_argument ("-t", "--tabsize", default=8,
            help="Number of spaces to tab stop.")
        p.add_argument ("-a", "--alltabs", action="store_true", default=False,
            help="Expand all tabs to spaces.  If not given, only leading "
                "tabs (those before any non-whitespace characters on a "
                "line) will be expanded.")
        p.add_argument ("-q", "--quiet", action="store_true", default=False,
            help="Don't print names of files that have been  modified.")
        p.add_argument ("-n", "--noaction", action="store_true", default=False,
            help="Don't actually change any files but print names "
                "of files that would have been modified.")
        p.add_argument ("-b", "--backup", metavar='SUFFIX', default='~',
            help='Backup filename suffix.  Default is "~"')
        p.add_argument ('--version', action='version', version=v)
        p.epilog = ("\nExit status is 0 if no files modified, 1 if "
            "one or more files were modified, on 2 on other errors.")
        opts = p.parse_args ()
        return opts.filename, opts

if __name__ == '__main__':
        args, opts = parse_cmdline()
        sys.exit (main (args, opts))

