#!/usr/bin/env python


import sys, re

def main (args, opts):
        """
        This function will extract the comment lines that provide
        index and foreign key definitions in mktables.sql (expected
        to be supplied on stdin), and turn them into real definitions
        which are written to stdout.

        It expects a single command line argument:

          c -- Generate lines that create indexes and foreign keys.
          d -- Generate lines that drop indexes and foreign keys.

        """
        if (len (args) != 1 or args[0] != 'd' and args[0] != 'c'):
            print ('Expected one argument which must be "c" or "d"', file=sys.syserr)
            sys.exit (1)
        index =[];  fk = []
        for line in sys.stdin:
            line = line.rstrip()
            if args[0] == 'c':
                if line.startswith (r'--CREATE'): index.append (line[2:])
                if line.startswith (r'--ALTER TABLE'): fk.append (line[2:])
            else: # args[0]== 'd'
                mo = re.search (r'^--CREATE\s+(UNIQUE\s+)?INDEX', line)
                if mo:
                    line = re.sub (r'^--CREATE\s+(UNIQUE\s+)?INDEX', 'DROP INDEX IF EXISTS', line)
                    line = re.sub (r' ON [^;]*', '', line)
                    index.append (line)
                elif line.startswith ('--ALTER TABLE'):
                    line = re.sub (r' FOREIGN[^;]*', '', line[2:])
                    line = line.replace (' ADD ', ' DROP ')
                    line = line.replace (' CONSTRAINT ', ' CONSTRAINT IF EXISTS ')
                    fk.append (line)
        print ('''\
-- This file is recreated during the database build process.
-- See pg/Makefile for details.

\set ON_ERROR_STOP 1''')

        print ('\n'.join (index))
        print ('\n'.join (fk))

if __name__ == '__main__':
        main (sys.argv[1:], None)
