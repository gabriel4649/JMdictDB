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

use lib ("../lib", "./lib", "../perl/lib", "../../perl/lib");
use jmdict; use jmdictcgi; use jmdicttal; use jbparser;

$|=1;
binmode (STDOUT, ":utf8");
{no warnings 'once';
    eval { binmode($DB::OUT, ":encoding(shift_jis)"); }; }

    main: {
	my ($dbh, $cgi, $tmpl, $entr, $entrs, @errs, $serialized, $perrs,
	    $kanj, $rdng, $sens, $intxt, $chklist, $nochk, $eid, $svc,
	    $comment, $refs, $name, $email, $seq, $src, $stat, $notes,
	    $srcnote, $delete, $disp);

	$cgi = new CGI;
	print "Content-type: text/html\n\n";
	$svc = clean ($cgi->param ("svc"));
	$dbh = dbopen ($svc);  $::KW = Kwds ($dbh);

	  # $eid will be an integer if we are editing an existing 
	  # entry, or undefined if this is a new entry.
	$eid = $cgi->param ('id') || undef;

	  # Desired disposition: 'a':approve, 'r':reject, undef:submit.
	$disp = $cgi->param ('disp');

	  # New status is A for edit of existing entry, N for new 
	  # entry, D for deletion of existing entry.
	$delete = $cgi->param ('delete');
	$stat = $eid ? ($delete ? $::KW->{STAT}{D}{id}
			        : $::KW->{STAT}{A}{id})
		     : $::KW->{STAT}{N}{id};

	  # These will only have values when editing an entry. 
	$seq = $cgi->param ('seq') || undef;
	$src = $cgi->param ('src') || undef;
	$notes = $cgi->param ('notes')||undef;
	$srcnote = $cgi->param ('srcnote') || undef;

	  # These are the JEL (JMdict Edit Language) texts which
	  # we will concatenate into a string that is fed to the
	  # JEL parser which will create an entry object.
	$kanj = decode ('utf8', $cgi->param ('kanj')) || "";
	$rdng = decode ('utf8', $cgi->param ('rdng')) || "";
	$sens = decode ('utf8', $cgi->param ('sens')) || "";
	$intxt = join ("\n", ($kanj, $rdng, $sens));

	  # Get the meta-edit info which will go into the history
	  # record for this change.
	$comment = decode ('utf8', $cgi->param ('comment')) || undef;
	$refs = decode ('utf8', $cgi->param ('reference')) || undef;
	$name = decode ('utf8', $cgi->param ('name')) || undef;
	$email = decode ('utf8', $cgi->param ('email')) || undef;
	if (!$email) { push (@errs, "Missing email address"); }
	elsif (!($email =~ m/^[A-Z0-9._%-]+@(?:[A-Z0-9-]+\.)+[A-Z]{2,4}$/io)) {
	    push (@errs, "Invalid email address: $email"); }

	  # Parse the entry data.  Problems will be reported
	  # by messages in @$perrs.  We do the parse even if 
	  # the request is to delete the entry (is this right
	  # thing to do???) since on the edconf page we want
	  # to display what the entry was.  The edsubmit page
	  # will do the actual deletion. 
	($entr,$perrs) = jbparser->parse_text ($intxt, 7);
	push (@errs, @$perrs);

	  # The code in the "if" below assumes we have a valid entr
	  # object from jbparser.  If there were parse errors that's
	  # not true so we don't go there.
	if (!@$perrs) {

	      # If any xrefs were given, resolve them to actual entries
	      # here since that is the form used to store them in the 
	      # database.  If any are unresolvable, an approriate error 
	      # is saved and will reported later.
	    if (grep ($_->{_XREF}, @{$entr->{_sens}})) { 
		  # resolv_xrefs() will die on errors so trap them in an eval. 
	        eval {jbparser::resolv_xrefs ($dbh, $entr);}; 
		  # An save the errors for later reporting.
		if ($@) { push (@errs, $@); } } 

	      # Migrate the entr details to the new entr object
	      # which to this point had only the kanj/rdng/sens
	      # info provided by jbparser.  
	    $entr->{dfrm} = $eid; $entr->{seq} = $seq;  $entr->{stat} = $stat; 
	    $entr->{src} = $src; $entr->{notes} = $notes; $entr->{srcnote} = $srcnote; 
	    $entr->{unap} = 1;

	      # Append a new hist record details this edit.
	    if (!$entr->{_hist}) { $entr->{_hist} = []; }
	    push (@{$entr->{_hist}}, newhist ($entr, $stat, $comment, $refs,
					      $name, $email, \@errs)); 
	    chkentr ($entr, \@errs);

	      # If this is a new entry, look for other entries that
	      # have the same kanji or reading.  These will be shown
	      # as cautions at the top of the confirmation form in
	      # hopes of reducing submissions of words already in 
	      # the database.
	    if (!$eid && !$delete) {
		$chklist = find_similar ($dbh, $entr->{_kanj}, $entr->{_rdng}, $entr->{src}); }
	    else { $chklist = []; }
	    $entrs = [$entr]; }

	if (!@errs) {
	    $serialized = serialize ($entr);
	    fmt_restr ($entrs); 
	    fmt_stag ($entrs); 
	    set_audio_flag ($entrs);
	    $tmpl = new Petal (file=>find_in_inc("tal")."/tal/edconf.tal", 
			   decode_charset=>'utf-8', output=>'HTML' );
	    print $tmpl->process (entries=>$entrs, chklist=>$chklist, 
				is_editor=>1, svc=>$svc, disp=>$disp,
				method=>"post", serialized=>$serialized); }
	else { errors_page (\@errs); }
	$dbh->disconnect if ($dbh); } 

    sub newhist { my ($entr, $stat, $comment, $refs, $name, $email, $errs) = @_;
	my ($hist, $now);
	  # Create a history record for display.  A real record 
	  # will be recreated when the entry is actually committed
	  # to the database.
	$now = strftime "%Y-%m-%d %H:%M:%S", localtime;
	$hist = {entr=>0, hist=>0, dt=>$now, stat=>$stat, name=>$name, 
		 email=>$email, diff=>'', refs=>$refs, notes=>$comment};
	return $hist; }

    sub find_similar { my ($dbh, $kanj, $rdng, $src) = @_;
	# Find all entries that have a kanj in the set @$kanj,
	# or a reading in the set @$rdng, and return a list of
	# esum view records of such entries.  Either $kanj or
	# $rdng, but not both, may be undefined or empty.
	# If $src is given, search will be limited to entries
	# with that entr.src id number.
	
	my ($rwhr, $kwhr, @args, $sql, $rs);
	$rwhr = join (" OR ", map ("txt=?", @$rdng));
	$kwhr = join (" OR ", map ("txt=?", @$kanj));
	push (@args, $src);
	push (@args, map ("$_->{txt}", (@$rdng,@$kanj)));

	$sql = "SELECT DISTINCT e.* " . 
		"FROM esum e " .
		"WHERE e.src=? AND e.stat<4 AND e.id IN (" .
  		($rwhr ? "SELECT entr FROM rdng WHERE $rwhr " : "") .
		($rwhr && $kwhr ? "UNION " : "") .
		($kwhr ? "SELECT entr FROM kanj WHERE $kwhr " : "") .
		")";
	$rs = dbread ($dbh, $sql, \@args);
	return $rs; }

    sub chkentr { my ($e, $errs) = @_;
	# Do some validation of the entry.  This is nowhere near complete 
	# Yhe database integrity rules will in principle catch all serious
	# problems but deciphering db errors and presenting a reasonable
	# user-oriented message is difficult so we try to catch the obvious
	# stuff here. 
	my ($s, $scntr);
	if (!$e->{src}) { 
	    push (@$errs, "No Corpus specified.  Please select the corpus that this entry will be added to."); }
	if ((!$e->{_rdng} || !@{$e->{_rdng}}) && (!$e->{_kanj} || !@{$e->{_kanj}})) { 
	    push (@$errs, "Both the Kanji and Reading boxes are empty.  You must provide at least one of them."); }
	if (!$e->{_sens} || !@{$e->{_sens}}) {
	    push (@$errs, "No senses given.  You must provide at least one sense."); }
	foreach $s (@{$e->{_sens}}) {
	    ++$scntr;
	    if (!$s->{_gloss} || !@{$s->{_gloss}}) {
		push (@$errs, "Sense $scntr has no glosses.  Every sense must have at least one regular gloss, or a [lit=...] or [expl=...] tag."); } } }

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
