#!/usr/bin/env perl
#######################################################################
#   This file is part of JMdictDB. 
#   Copyright (c) 2008 Stuart McGraw 
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

@VERSION = (substr('$Revision$',11,-2), \
	    substr('$Date$',7,-11));

# This program will read a JMdict.xml file and create
# an output file containing postgresql data COPY commands.
# The file can be loaded into a Postgresql jmdict database
# after subsequent processing with jmload.pl.

use strict; 
use Encode;
use Getopt::Std ('getopts');

BEGIN {push (@INC, ("perl/lib", "../perl/lib"));}
use jmdictxml ('%JM2ID'); # Maps xml expanded entities to kw* table id's.

    main: {
	my ($kwlangfn, $jmdictfn, @a, $ln, $lnnum, %kwlangs, $kwlang, $lang, $seq,
	    $xmlmod, $unkcnt, $badxmlcnt, @newlangs, $dtd_skipped, $r, $badidcnt);
	getopts ("k:h", \%::Opts) || usage (1);
	if ($::Opts{h}) { usage (0); }
	$kwlangfn = $::Opts{k} || "pg/data/kwlang.csv";
	$jmdictfn = shift (@ARGV) || "jmdict.xml";

	open (F, "<:utf8", $kwlangfn) || die ("Unable to open file '$kwlangfn': $!\n");
	while ($ln = <F>) {
	    my (@a) = split ("\t", $ln);
	    $kwlangs{$a[1]} = \@a; }
	open (F, "<:utf8", $jmdictfn) || die ("Unable to open file '$jmdictfn': $!\n");
	while ($ln = <F>) {
	    ++$lnnum;
	    if (!$dtd_skipped) {
		if (substr ($ln, 0, 7) eq "<entry>") {
		    $dtd_skipped = 1; }
		next; }
	    if ($ln =~ m/<ent_seq>([0-9]+)</) {
		$seq = $1;  next; }
	    if (!($ln =~ m/xml\s*:\s*lang/)) { next; }
	    if ($ln =~ m/xml:lang="(\w+)?"/) {
		$lang = $1;
		$kwlang = $kwlangs{$lang};
		if (!$kwlang) {
		    print "Unknown language '$lang' at line $lnnum (seq: $seq)\n";
		    ++$unkcnt;  next; }
		$xmlmod = $JM2ID{LANG}{$lang};
		if (!$xmlmod) {
		    #print "New language '$lang' at line $lnnum (seq: $seq)\n";
		    push (@newlangs, $kwlang); 
		    $JM2ID{LANG}{$lang} = int ($kwlang->[0]);
		    next; }
		if ($xmlmod != $kwlang->[0]) {
		    ++$badidcnt;
		    printf ("xmlmod id '%d' does not match kwlang '%d' for lang '%s'\n",
			     $xmlmod, $kwlang->[0], $lang); } }
	    else {
		print "Bad \"xml:lang\" attribute at line $lnnum (seq: $seq)"; 
		++$badxmlcnt; }
	    }
	printf ("\nSummary:\nBad xml lang attrs: %d\nUnknown langs: %d\nBad id's: %d\nNew langs: %d\n", 
			($badxmlcnt || 0), ($unkcnt || 0), ($badidcnt || 0), scalar(@newlangs));
	if (@newlangs) {
	    @newlangs = sort {$a->[1] cmp $b->[1]} @newlangs;
	    foreach $r (@newlangs) {
		printf ("\t    '%s' => %d,\t# %s", $r->[1], $r->[0], $r->[2]); }
	    }
	}


    sub usage { my ($exitstat) = @_;
	print <<EOT;
This program reads a jmdict xml file such as JMdict or JMnedict and
identifies any "xml:lang" attribute values that do not exist in the
kwlang table data (which indicates an error in the jmdict xml file),
or in the jmdictxml module (which means the missing languages need 
to be added to that module).

Usage: langscan.pl [-k kwlang-file] [xml-filename]

Arguments:
	xml-filename -- Name of input jmdict xml file.  Default 
	  is "./jmdict.xml".
Options:
	-h -- (help) print this text and exit.
	-k -- (kwlang) name of the kwlang.csv file.  Default is
	  pg/data/kwlang.csv.

EOT
	exit $exitstat; }