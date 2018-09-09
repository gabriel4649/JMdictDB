#!/usr/bin/env python3
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
#  51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
#######################################################################

# This program will process a file of wwwjdict submission data
# and turn it into a set of files, one per submission, that can
# be opened by cgi script jbedit.py to present an html Edit Entry
# page with the edit boxes initialized with the submission's
# data, ready for review and submission.

# WARNING: this file was converted for Python3 but not tested yet.

import sys, os, inspect, pdb
_ = os.path.abspath(os.path.split(inspect.getfile(inspect.currentframe()))[0])
_ = os.path.join (os.path.dirname(_), 'python', 'lib')
if _ not in sys.path: sys.path.insert(0, _)

import re, collections, datetime, os.path, json
import jdb, jmcgi, fmtjel, edparse
from edparse import ParseError as eParseError

Input_encoding = 'utf-8'
Output_encoding = 'utf-8'

# FIXME: we import edparse's ParseError.  Can we use that instead
#  of defining our own?

class ParseError (ValueError):
    def __init__(self, msg, line=None, linenum=None):
        self.msg = msg; self.line=line; self.linenum=linenum
    def __str__(self):
        return self.msg
          #+ (" in submission starting at line %d" % (self.linenum)) if self.linenum else ''\
          #+ ("  at line '%s'." % (self.line)) if self.line else ''

def main (args, opts):
        process_file (args[0], opts.outdir, opts.prefix,
                      opts.verbose, opts.start, opts.count, opts.force)

def process_file (inpname, outdir, prefix='', verbose=False,
                  start_at=1, max_subs=0, overwrite=False):
        # impname -- Name of the input file to process. (str)
        # outdir -- Path to directory where output and log files
        #       will be written.
        # prefix -- Names of all editdata and log output files
        #       will be prefixed with this string, if given.
        # verbose -- If false, only print a line to stdout for
        #       submissions that failed conversion and that did
        #       not produce an editdata file.  If true, a line
        #       for each submission sucessfully parsed is written
        #       as well.
        # start_at -- Number of the submission (numbering starts
        #       at 1) to start processing.  Submissions before that
        #       will be ignored.
        # max_subs -- Maximum number of submissions to process.
        #       If 0, there is no limit.
        # overwrite -- If true, output file will be (over-)written
        #       if it already exists.  If false, the output file will
        #       not be overwritten, an error message generated, and
        #       this input file skipped.

        in_f = open (inpname, "r", encoding=Input_encoding)
        bad_f = open (os.path.join (outdir, prefix+"bad.log"), "a", encoding=Output_encoding)
        good_f = open (os.path.join (outdir, prefix+"ok.log"), "a", encoding=Output_encoding)
        startmsg = "# %s: processing %s" %\
                (datetime.datetime.now().ctime(), inpname)
        print (startmsg, file=bad_f)
        print (startmsg, file=good_f)
        subnum = count = badcnt = 0

          # Process each submission in open file 'inp_f'.
          # If there is a problem parsing a submission, it is
          # appended to the 'bad_f' file and an appropriate
          # error message generated.  Otherwise, it is reformated
          # to JEL and written to a newly created. per-submission
          # file in directory 'outdir', where a cgi script page
          # will later (independently of this program) read it
          # and submit it under human supervision.

        for r in incremental_scanner (in_f):
            lines, linenum = r
            subnum += 1
            if subnum < start_at: continue
            count += 1
            if max_subs and count > max_subs: break

            out_fn = prefix + "%0.5d.dat" % subnum
            try:
                parsed = parse_submission (lines)
                ovwt = write_data (parsed, os.path.join (outdir, out_fn), overwrite)
                if ovwt and verbose:
                    print ("Overwriting output file %s" % out_fn)
            except ParseError as excep:
                msg = "Failed on submission %d (line %d): %s" \
                       % (subnum, linenum, str(excep))
                write_bad (bad_f, lines, msg)
                badcnt += 1
                continue
            write_good (good_f, lines, "Parsed submission %d (line %d), wrote to %s"\
                                        % (subnum, linenum, out_fn), verbose)
        print ("%s total submissions processed, %d good, %d bad" % (count, count-badcnt, badcnt))
        in_f.close();  bad_f.close();  good_f.close()

def write_bad (bad_f, lines, msg):
        print (msg)
        msg = '# ' + msg.replace('\n', '\n# ')
        print (msg, file=bad_f)
        print ('\n'.join (lines), file=bad_f)

def write_good (good_f, lines, msg, verbose):
        if verbose: print (msg)
        msg = '# ' + msg.replace('\n', '\n# ')
        print (msg, file=good_f)
        print ('\n'.join (lines), file=good_f)

def write_data (parsed, fn, force=False):
        # parsed -- a dict containing parsed wwwjdic form data as
        #       returned by parse_submission().
        # fn -- The name (with path) of the filename to write the
        #       editdata to.
        # force -- If true, output file will be overwritten if it
        #       exists.  If not true, an exception will be raised
        #       if the output file already exists.
        #
        # Returns: True if the output file existed and was overwritten,
        #       or False otherwise.

        s = json.dumps (parsed, indent=2)
          # Dirty and unreliable test to avoid accidentily
          # over-writing an existing file...
        try: open (fn)
        except IOError: ovwt = False
        else:
              #FIXME: this is not really a parse error, is it?
            if force: ovwt = True
            else: raise ParseError ("File exists, won't overwrite: %s" % fn)
        with open (fn, "w") as f: f.write (s)
        return ovwt

def write_msg (errmsg, lines, err_f=None):
        print (errmsg)
        if err_f:
            print ('# ' + errmsg.replace('\n', '\n# '), file=err_f)
            if lines: print ('\n'.join (lines), file=err_f)

def incremental_scanner (f):
          # This function is an iterator and thus may be used in a "for"
          # statement where it will repeatedly supply 2-tuples consisting
          # of:
          #   * A list of the lines of the submission (including the
          #     S-SUB and E-SUB lines.
          #   * The line number in 'f' of the first line of the
          #     submission.
          # Lines in 'f' that begin with '#' (no whitespace preceeding
          # it) are treated as comment lines and are are ignored other
          # than being counted for maintaining the linenumber.  Lines
          # are returned with trailing whitespace (including the EOL
          # character) removed.

        lines = [];  base_linenum = None
        for line_num, line in enumerate (f):
            if line_num == 0 and line.startswith('\uFEFF'):
                line = line[1:]                 # Remove BOM.
              # FIXME? it is possible the multi-line fields could
              #  contain lines starting with "#".
            if line.startswith ('#'): continue  # Skip comment lines.
            line = line.rstrip()                # Remove trailing whitespace.
            if base_linenum is None: base_linenum = line_num + 1
            lines.append (line)
            if line == "E-SUB":
                yield lines, base_linenum
                lines = []; base_linenum = line_num + 2
        if lines: yield lines, base_linenum

def parse_submission (lines):
        # Parse a list of lines extracted from a wwwjdic submission
        # form data file.  The lines must constitute a single submission
        # starting with a "======= Date" or "S-SUB" line and ending with
        # a "E-SUB" line.  Errors encountered during parsing are signalled
        # by raising a ParseError exception.
        # If there are no errors, a dict is returned having keys
        # corresponding to the fields of the form data, with sequenced
        # fields like "english1", "english2", ... coalesced into a single
        # key, "english", with a value is a list of the field values.

        collect = collections.defaultdict (list)
        known_keywds = 'origentry headw kana pos misc english crossref reference '\
                        'comment entlangnam entlangf name email subtype sendNotJS date'\
                        .split()

          # Following fields have values that can span multiple lines.
        multi_line = 'reference comment'.split()

          # Following fields may occur more than once, e.g. headw1, headw2,...
        multi_field = 'headw kana pos misc english crossref   '.split()

          # NOTE: multi-line and multi-field are mutually exclusive; don't
          #  list the same field in both.

        n = 0;  ln = lines[n]
        if ln.startswith ('======= Date: '):
            try: date = datetime.datetime.strptime (ln[14:], '%a %b %d %H:%M:%S %Y')
            except ValueError:
                raise ParseError ("Bad date", ln)
              # Don't save the datetime object 'date' because we are prepared
              # to handle only strings in 'collect' below (i.e. we call join()).
            collect['date'].append (ln[14:])
            n += 1;  ln = lines[n]
        if ln != 'S-SUB':
            raise ParseError ("Missing S-SUB", ln)
        n += 1;  got_esub = False;  kw = None
        for lnnum, ln in enumerate (lines[n:]):
            if ln == ' (0)': continue
            if got_esub:
                raise ParseError ("Lines following E-SUB", ln)
            if ln == "E-SUB":
                got_esub = True; break
            mo = re.match (r'\(([a-zA-Z]+)([0-9]+)?\)\t(.*)', ln)
            if mo:
                maybe_kw, cntr, val = mo.groups()
                  #FIXME? we ignore 'cntr'.  Should we check it?  use it?
                if maybe_kw in known_keywds:
                    kw = maybe_kw
                    collect[kw].append (val)
                else: mo = None
            if not mo:
                  # 'kw' here is from previous line(s) -- the last
                  # one that was validated in 'known_keywds'.  If
                  # None, then it was never set above which means
                  # we got a continuation line with no preceeding
                  # keyword line.
                if not kw:
                    raise ParseError ("Missing expected keyword line", ln)
                if kw not in multi_line:
                    raise ParseError ("Got multiple lines for '%s' keyword" % kw, ln)
                collect[kw].append (ln)

        if not got_esub:
            raise ParseError ("Missing E-SUB line")

          # Turn 'collect' back into an ordinary dict so we can attempt
          # to access keys without magically instantiating them (as a
          # defaultdict does.)
        collect = dict (collect)

        for kw in list(collect.keys()):
            if kw not in multi_field:
                  # All items in 'collect' were created as lists.
                  # Except for those that are intended to have multiple
                  # items (listed in multi_field), we convert the lists
                  # of lines back to a single line.
                collect[kw] = '\n'.join (collect[kw])
        if 'name'  in collect and collect['name']  == 'Name':          del collect['name']
        if 'email' in collect and collect['email'] == 'Email address': del collect['email']

          # Sanity check to make sure we didn't accidently misplace something...
        for kw in list(collect.keys()): assert kw in known_keywds

          # "subtype" field is required...
        if 'subtype' not in collect or collect['subtype'] not in ('new', 'amend'):
            raise ParseError ("Missing or bad 'subtype' field")

          # If an amendment, extract the seq number of the original entry...
        if collect['subtype'] == 'amend':
            if 'origentry' not in collect:
                raise ParseError ("subtype 'amend' but no 'origentry' field")
            origentry = collect['origentry']
            mo = re.search (r'/ \(([0-9]{7})\)', origentry)
            if not mo:
                raise ParseError ("Can't find seq num in 'origentry' value", origentry)
            collect['seqnum'] = mo.group(1)

          # To process a non-english submission, jbedit.py would have to
          # figure out which glosses were changed (taking into account
          # order changes) and insert a ginf tag into those glosses.
          # Since we don't parse glosses, this seems too complex for now...
        if collect.get ('entlangnam') not in (None, 'eng'):
            raise ParseError ("Can't process non-english (%s) submission" % collect['entlangnam'],
                              collect['entlangnam'])

        return collect


from optparse import OptionParser

def parse_cmdline ():
        u = \
"""\n\t%prog [options] input-file

  This program reads an input file containing raw wwwjdic submission
  form data, and creates a number of output files, one for each
  submission in the input file, that can be subesequently read by
  cgi script jbedit.py to present a jmdict edit form, initialized
  with the submission data which can be reviewed and submitted as
  a jmdict database entry.

  The output files are named "nnnnn.dat" where "nnnnn" is a five-
  digit number that is the ordinal position of the submission in
  the input file.  The filename may prefixed with an arbitrary text
  string by using the option "--prefix".  The directory these files
  are created in is given by --outdir which defaults to the current
  directory.

  Also produced (in --outdir, and prefixed with --prefix) are two
  log files, ok.log and bad.log.  [TBD... finish this description]

Arguments:  Name of input file containing raw submission data."""

        p = OptionParser (usage=u)

        p.add_option ("-o", "--outdir", default='.',
            help="Path to directory in which to create output files "
                "including the \"bad\" and \"ok\" log files.  Default "
                "is the current directory.")
        p.add_option ("-p", "--prefix", default='',
            help="Text that will be used to prefix the files created in OUTDIR.")
        p.add_option ("-s", "--start", type="int", default=1,
            help="Skip submissions at beginning of file and start processing "
                "at submission START.  Default is 1 (skip none).")
        p.add_option ("-c", "--count", type="int", default=0,
            help="Process at most COUNT submissions.  Default is 0 (no limit).")
        p.add_option ("-f", "--force", default=False, action="store_true",
            help="Force the overwriting of the output file if it already exists.  "
                "If not given, jbsubs will refuse to overwrite the file, generate "
                "an error message to that effect and go on to the next submission "
                "in the input file.")
        p.add_option ("-v", "--verbose", default=False, action="store_true",
            help="Print message for each sucessfully parsed submission.")

        opts, args = p.parse_args ()
        if len(args) < 1: p.error ("Need argument")
        if len(args) > 1: p.error ("Expected only one argument")
        return args, opts

if __name__ == '__main__':
        args, opts = parse_cmdline ()
        main (args, opts)
