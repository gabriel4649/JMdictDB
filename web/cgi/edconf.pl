#!/usr/bin/env perl

# Copyright (c) 2007 Stuart McGraw 
@VERSION = (substr('$Revision$',11,-2), \
	    substr('$Date$',7,-11));

use strict; use warnings; 
use CGI; use Encode 'decode_utf8'; use DBI; 
use Petal; use Petal::Utils; 
use POSIX qw(strftime);


BEGIN {push (@INC, "../lib");}
use jmdict; use jmdictcgi; use jmdicttal;

$|=1;
binmode (STDOUT, ":utf8");
eval { binmode($DB::OUT, ":encoding(shift_jis)"); };

    main: {
	my ($dbh, $cgi, $dbname, $username, $pw, $tmpl, $entr, 
	    $entrs, $errs, $serialized, $chklist);
	$cgi = new CGI;

	print "Content-type: text/html\n\n";

	open (F, "../lib/jmdict.cfg") or die ("Can't open database config file\n");
	($dbname, $username, $pw) = split (' ', <F>); close (F);
	$dbh = DBI->connect("dbi:Pg:dbname=$dbname", $username, $pw, 
			{ PrintWarn=>0, RaiseError=>1, AutoCommit=>0 } );
	$dbh->{pg_enable_utf8} = 1;
	$::KW = Kwds ($dbh);

	($entr, $errs) = cgientr ($dbh, $cgi);
	$entrs = [$entr];
	$chklist = find_similar ($dbh, $entr->{_kanj}, $entr->{_rdng});

	if (!@$errs) {
	    $serialized = serialize ($entr);
	    $tmpl = new Petal (file=>'../lib/tal/nwconf.tal', 
			   decode_charset=>'utf-8', output=>'HTML' );
	    print $tmpl->process (entries=>$entrs, 
				chklist=>$chklist,
				serialized=>$serialized); }
	else { errors_page ($errs); }
	$dbh->disconnect; } 

    sub find_similar { my ($dbh, $kanj, $rdng) = @_;
	my ($whr, @args, $sql, $rs);
	$whr = join (" OR ", (map ("r.txt=?", @$rdng), map ("k.txt=?", @$kanj)));
	@args = map ("$_->{txt}", (@$rdng,@$kanj));
	$sql = "SELECT DISTINCT * FROM entr_summary e " .
		 "LEFT JOIN rdng r ON r.entr=e.id " .
		 "LEFT JOIN kanj k ON k.entr=e.id " .
		 "WHERE " . $whr;
	$rs = dbread ($dbh, $sql, \@args);
	return $rs; }

    sub resolv_xref { my ($dbh, $txt, $typ, $notes) = @_;
	my ($sql, $r, $sth);
	# The following query creates a psuedo-xref hash.  It
	# does not contain any .xref member because we want only
	# one record corresponding to the target entry, not (possibly)
	# multiple records for each target sense.  When nwsub.pl
	# processes the data, it will genereate xrefs for all senses
	# if the target entry.  
	$sql = "SELECT DISTINCT 0 AS sens,'$typ' AS typ,? AS notes," .
		     "e.id AS eid,es.seq,es.rdng,es.kanj,es.gloss " .
		  "FROM entr_summary es " .
		  "JOIN entr e ON e.id=es.id " .
		  "LEFT JOIN kanj k ON k.entr=e.id " .
		  "LEFT JOIN rdng r ON r.entr=e.id " .
		  "WHERE k.txt=? OR r.txt=? ";
	$r = dbread ($dbh, $sql, [$notes, $txt, $txt]);
	return $r; }

    sub cgientr { my ($dbh, $cgi) = @_;

	# Read cgi parameters and create an entry structure from them.
	# Returns a reference to the entry structure and a refernence 
	# to a (possibly empty) array of messages reporting and invalid 
	# information or missing information found.

	my ($who, $hist,
	    $entr, @kanj, @rdng, @sens, $glos, @engl, @pos, @misc, 
	    $name, $email, $comment, $reference, $xrefs, $now,
	    $snum, $x, $i, $t, $e, @errs, $txt, $first, $hw);

	$first = 1;
	foreach $x ($cgi->param("headw"))  { 
	    $txt = decode_utf8($x);
	    $hw = jstr_classify ($txt);
	    if ($first) {
		$first = 0;
		if (!($hw & ($::KANJI | $::KANA))) { 
		     push (@errs, "Headword has no kanji or kana: $txt"); next; } }
	    else { 
		next if (!$txt); 
		if (!($hw & $::KANJI)) { 
		     push (@errs, "Alternate headword has no kanji: $txt"); next; } }
	    if ($hw & $::KANJI) { push (@kanj, {id=>0, ord=>0, txt=>$txt}) if ($txt); } 
	    else { push (@rdng, {id=>0, ord=>0, txt=>$txt}) if ($txt); } }

	foreach $x ($cgi->param("kana")) { 
	    $txt = decode_utf8($x);  next if (!$txt); 
	    $hw = jstr_classify ($txt);
	    if (!($hw & $::KANA)) { push (@errs, "Reading has no kana: $txt"); next; }
	    if ($hw & $::KANJI) { push (@errs, "Reading contains kanji: $txt"); next;}
	    push (@rdng, {id=>0, ord=>0, txt=>$txt}) if ($txt); }
	if (!@rdng) { push (@errs, "At least one reading required"); }

	foreach $x ($cgi->param("pos")) { 
	    next if ($x =~ m/^\s*$/);
	    if (!$::KW->{POS}{$x}{id}) {
	         push (@errs, "Bad \"pos\" value: $x"); }
	    else { push (@pos,  {sens=>0, kw=>$x}); } }

	foreach $x ($cgi->param("misc")) { 
	    next if ($x =~ m/^\s*$/);
	    if (!$::KW->{MISC}{$x}{id}) {
	         push (@errs, "Bad \"misc\" value: $x"); }
	    else { push (@misc, {sens=>0, kw=>$x}); } }

	$snum = 1;  @sens = ();  $glos = [];
	foreach $x ($cgi->param("english")) {
	    $txt = decode_utf8($x);  next if (!$txt);  
	    if (! ($txt =~ m/^\s*(\((\d+)\))?\s*([^(].*)\s*$/)) {
		push (@errs, "Bad format in english line: $txt"); next; }
	    if (defined($2)) {
		$t = int ($2); 
		if ($t < $snum) { push(@errs, "Out of sequence sense number: $txt"); next; }
		if ($t > $snum) { 
		    push (@sens, {id=>0, entr=>0, ord=>0, _gloss=>$glos, 
				   _stag=>[]}) if (@$glos); 
		    $snum = $t; $glos = []; } }
	    push (@$glos, {id=>0, sens=>0, ord=>0, lang=>1, txt=>$3}) if ($3); }
	push (@sens, {id=>0, entr=>0, ord=>0, _gloss=>$glos, _stag=>[]}) if (@$glos); 
	if (!@sens) { push (@errs, "At least one gloss required"); }

	$txt = decode_utf8($cgi->param("crossref"));
	if ($txt) {
	    $xrefs = resolv_xref ($dbh, $txt, $::KW->{XREF}{see}{id});
	    if (!@$xrefs) { push (@errs, "Cross reference doesn't exist: $txt"); } }

	foreach $x (@sens) {  
	    ($x->{_pos} = [@pos]) if (@pos);  
	    ($x->{_misc} = [@misc]) if (@misc); 
	    ($x->{_xref} = $xrefs) if ($xrefs); }

	$name = $cgi->param("name") || "";
	$email = $cgi->param("email") || "";
	if (!($email =~ m/^[A-Z0-9._%-]+@(?:[A-Z0-9-]+\.)+[A-Z]{2,4}$/io)) {
	    push (@errs, "Missing or invalid email address: $email"); }
	$who = $name . "<" . $email . ">";
	$comment = decode_utf8($cgi->param("comment"));
	$reference = decode_utf8($cgi->param("reference"));
	if ($comment) { $comment = "Comment:\n$comment"; }
	if ($reference) {
	    if ($comment) { $comment .= "\n\n"; }
	    $comment .= "References:\n$reference"; }
	$now = strftime "%Y-%m-%d %H:%M:%S", localtime;
	$hist = {id=>0, entr=>0, stat=>1, dt=>$now, 
		  who=>\$who, diff=>'', notes=>\$comment };
	$entr = {id=>0, seq=>0, stat=>1, src=>1,
		  _rdng=>\@rdng, _kanj=>\@kanj, _sens=>\@sens,
		  _hist=>[$hist], _xref=>$xrefs};

	return ($entr, \@errs); }

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
