#!/usr/bin/env perl
use strict; use warnings;

$::hdr = "-- This file is recreated during the database build process.\n" .
	 "-- See Makefile for details.\n";
    main: {
	my ($typ, @i, @fk);
	$typ = shift (@ARGV);
	die ("Argument must be \"c\" or \"d\"\n") if ($typ ne "d" and $typ ne "c");
	while (<STDIN>) {
	    if ($typ eq "c") {
		if (s/^--CREATE/CREATE/) { push (@i, $_); }
		if (s/^--ALTER TABLE/ALTER TABLE/) { push (@fk, $_); } }
	    else {
		if (m/^--CREATE\s+(UNIQUE\s+)?INDEX/) {
		    s/^--CREATE\s+(UNIQUE\s+)?INDEX/DROP/;
		    s/ ON [^;]*//;
		    push (@i, $_); }
		if (m/^--ALTER TABLE/) {
		    s/^--//;s/ FOREIGN[^;]*//;
		    s/ ADD / DROP /; 
		    push (@fk, $_); } } }
	print ("$::hdr\n", @i, @fk); }

