#!/usr/bin/env perl
#######################################################################
#   This file is part of JMdictDB. 
#   Copyright (c) 2007 Stuart McGraw 
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

use strict; use warnings; 
use CGI; use Encode; use DBI; 
use Petal; use Petal::Utils; 
use POSIX qw(strftime);


BEGIN {push (@INC, "../lib");}
use jmdict; use jmdictcgi; use jmdicttal; use jbparser;

$|=1;
binmode (STDOUT, ":utf8");
eval { binmode($DB::OUT, ":encoding(shift_jis)"); };

    main: {
	my ($dbh, $cgi, $tmpl, $entr, $entrs, @errs, $serialized, $perrs,
	    $kanj, $rdng, $sens, $intxt, $chklist, $nochk, $eid, 
	    $comment, $refs, $name, $email, $seq, $src, $stat, $notes,
	    $srcnote);

	$cgi = new CGI;
	print "Content-type: text/html\n\n";
	$dbh = dbopen ();  $::KW = Kwds ($dbh);

	  # $eid will be an integer if we are editing an existing 
	  # entry, or undefined if thisis a new entry.
	$eid = $cgi->param ('id');

	  # New status is M for edit entry, N for new entry.
	$stat = $eid ? $::KW->{STAT}{M}{id} : $::KW->{STAT}{N}{id};

	  # These will only have values when editig an entry. 
	$seq = $cgi->param ('seq');
	$src = $cgi->param ('src');
	$notes = $cgi->param ('notes');
	$srcnote = $cgi->param ('srcnote');

	  # These are the JEL (JMdict Edit Language) texts which
	  # we will concatenate into a string that is fed to the
	  # JEL parser which will create an entry object.
	$kanj = decode ('utf8', $cgi->param ('kanj')) || "";
	$rdng = decode ('utf8', $cgi->param ('rdng')) || "";
	$sens = decode ('utf8', $cgi->param ('sens')) || "";
	$intxt = join ("\n", ($kanj, $rdng, $sens));

	  # Get the meta-edit info which will go into the history
	  # record for this change.
	$comment = decode ('utf8', $cgi->param ('comment')) || "";
	$refs = decode ('utf8', $cgi->param ('reference')) || "";
	$name = decode ('utf8', $cgi->param ('name')) || "";
	$email = decode ('utf8', $cgi->param ('email')) || "";
	if (!$email) { push (@errs, "Missing email address"); }
	elsif (!($email =~ m/^[A-Z0-9._%-]+@(?:[A-Z0-9-]+\.)+[A-Z]{2,4}$/io)) {
	    push (@errs, "Invalid email address: $email"); }

	  # Parse the entry data.  Problems will be reported
	  # by messages in @$perrs.
	($entr,$perrs) = jbparser->parse_text ($intxt, 7);
	push (@errs, @$perrs);

	  # The code in the "if" assumes we have a valid entr
	  # object from jbparser.  If there were parse errors
	  # that's not true.
	if (!@$perrs) {

	      # If this is a new entry, look for other entries that
	      # have the same kanji or reading.  These will be shown
	      # as cautions at the top of the confirmation form in
	      # hopes of reducing submissions of words already in 
	      # the database.
	    if (!$eid and 0) {
		$chklist = find_similar ($dbh, $entr->{_kanj}, $entr->{_rdng}); }
	    else { $chklist = []; }

	      # If ant xrefs were given, resolve them to actual entries
	      # here since that is the form used to store them in the 
	      # database.  If any are unresolvable, an approriate error 
	      # is saved and will reported later.
	    if (grep ($_->{_XREF}, @{$entr->{_sens}})) {
		$dbh = dbopen ();  
		  # resolv_xrefs() will die on errors so trap them in an eval. 
	        eval {jbparser::resolv_xrefs ($dbh, $entr);}; 
		  # An save the errors for later reporting.
		if ($@) { push (@errs, $@); } } 

	      # Migrate the entr details to the new entr object
	      # which to this point had only the kanj/rdng/sens
	      # info provided by jbparser.  
	    $entr->{id} = $eid; $entr->{seq} = $seq; $entr->{stat} = $stat;
	    $entr->{src} = $src, $entr->{notes} = $notes, $entr->{srcnote} = $srcnote; 

	      # Append a new hist record details this edit.
	    if (!$entr->{_hist}) { $entr->{_hist} = []; }
	    push (@{$entr->{_hist}}, newhist ($entr, $stat, $comment, $refs,
					      $name, $email, \@errs)); 
#######     chk_entr ($entr, \@errs);
	    $entrs = [$entr]; }

	if (!@errs) {
	    $serialized = serialize ($entr);
	    $tmpl = new Petal (file=>'../lib/tal/edconf.tal', 
			   decode_charset=>'utf-8', output=>'HTML' );
	    print $tmpl->process (entries=>$entrs, 
				chklist=>$chklist,
				serialized=>$serialized); }
	else { errors_page (\@errs); }
	$dbh->disconnect if ($dbh); } 

    sub newhist { my ($entr, $stat, $comment, $refs, $name, $email, $errs) = @_;
	my ($who, $hist, $now);

	  # Name and email addy are combined into a single
	  # field in the database.

	$who = $name . "<" . $email . ">";

	  # The comment and references info are also combined into
	  # a single database field.  We preserve line structure.

	if ($comment) { $comment = "Comment:\n$comment"; }
	if ($refs) {
	    if ($comment) { $comment .= "\n\n"; }
	    $comment .= "References:\n$refs"; }

	  # Create a history record for display.  A real record 
	  # will be recreated when the entry is actually committed
	  # to the database.

	$now = strftime "%Y-%m-%d %H:%M:%S", localtime;
	$hist = {entr=>0, hist=>0, dt=>$now, stat=>$stat,
		  who=>$who, diff=>'', notes=>$comment };

	return $hist; }

    sub find_similar { my ($dbh, $kanj, $rdng, $src) = @_;
	# Find all entries that have a kanj in the set @$kanj,
	# or a reading in the set @$rdng, and return a list of
	# esum view records of such entries.  Either $kanj or
	# $rdng, but not both, may be undefined or empty.
	# If $src is given, search will be limited to entries
	# with that entr.src id number.
	#
	# FIXME: the query is currently way too slow.
	
	my ($whr, @args, $sql, $rs);
	$whr = join (" OR ", (map ("r.txt=?", @$rdng), map ("k.txt=?", @$kanj)));
	if ($src) { $whr = "($whr) AND e.src=$src"; }
	@args = map ("$_->{txt}", (@$rdng,@$kanj));
	$sql = "SELECT DISTINCT e.* FROM esum e " .
		 "LEFT JOIN rdng r ON r.entr=e.id " .
		 "LEFT JOIN kanj k ON k.entr=e.id " .
		 "WHERE " . $whr;
	$rs = dbread ($dbh, $sql, \@args);
	return $rs; }

    sub errors_page { my ($errs) = @_;
	my $err_details = join ("\n    <br/>", @$errs);
	print <<EOT;
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
  <title>Invalid parameters</title>
  </head>
<body>
  <h2>Form data errors</h2>
	Your submission cannot be processed due to the following errors:
  <p>$err_details
  <hr>
  Please use your brower's "back" button to return to your form,
  correct the errors above, and resubmit it.
  </body>
</html>
EOT
	}
