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
	$sql = "SELECT DISTINCT e.* FROM esum e " .
		 "LEFT JOIN rdng r ON r.entr=e.id " .
		 "LEFT JOIN kanj k ON k.entr=e.id " .
		 "WHERE " . $whr;
	$rs = dbread ($dbh, $sql, \@args);
	return $rs; }

    sub cgientr { my ($dbh, $cgi) = @_;

	# Read cgi parameters and create an entry structure from them.
	# Returns a reference to the entry structure and a refernence 
	# to a (possibly empty) array of messages reporting and invalid 
	# information or missing information found.

	my ($who, $hist,
	    $entr, @kanj, @rdng, @sens, $glos, @engl, @pos, @misc, 
	    $name, $email, $comment, $reference, $xrefs, $now,
	    $snum, $x, $i, $t, $e, $s, @errs, $txt, $first, $hw,
	    $nrdng, $nkanj, $nsens, $ngloss, $xtxt, $erefs, $slist);

	$first = 1;  $nkanj = 1; $nrdng = 1;

	# Get the headwords...

	foreach $x ($cgi->param("headw"))  { 
	    $txt = decode_utf8($x);
	    $hw = jstr_classify ($txt);	# Is the field kanji or kana?
	    if ($first) {
		# The first headword field can be either kanji or kana.
		$first = 0;
		if (!($hw & ($jmdict::KANJI | $jmdict::KANA))) { 
		     push (@errs, "Headword has no kanji or kana: $txt"); next; } }
	    else { 
		# But subsequent fields must be kanji.
		next if (!$txt); 
		if (!($hw & $jmdict::KANJI)) { 
		     push (@errs, "Alternate headword has no kanji: $txt"); next; } }
	    # In the database, all kana fields *must* go in 
	    # table rdng, and all kanji *must* go in table kanj.
	    # Since we canhave either here, make sure we put it
	    # in the right table. 
	    if ($hw & $jmdict::KANJI) { push (@kanj, {id=>0, kanj=>$nkanj++, txt=>$txt}) if ($txt); } 
	    else { push (@rdng, {id=>0, ord=>$nrdng++, txt=>$txt}) if ($txt); } }

	# Get the readings...

	foreach $x ($cgi->param("kana")) { 
	    $txt = decode_utf8($x);  next if (!$txt); 
	    $hw = jstr_classify ($txt);	# Is the field kanji or kana?
	    # All these fields *must* be kana.
	    if (!($hw & $jmdict::KANA)) { push (@errs, "Reading has no kana: $txt"); next; }
	    if ($hw & $jmdict::KANJI) { push (@errs, "Reading contains kanji: $txt"); next;}
	    push (@rdng, {entr=>0, rdng=>$nrdng++, txt=>$txt}) if ($txt); }
	if (!@rdng) { push (@errs, "At least one reading required"); }

	$snum = 1;  @sens = ();  $glos = [];  $nsens = 1;  $ngloss = 1; 
	foreach $x ($cgi->param("english")) {
	    $txt = decode_utf8($x);  next if (!$txt);  
	    if (! ($txt =~ m/^\s*(\((\d+)\))?\s*([^(].*)\s*$/)) {
		push (@errs, "Bad format in english line: $txt"); next; }
	    if (defined($2)) {
		$t = int ($2); 
		if ($t < $snum) { push(@errs, "Out of sequence sense number: $txt"); next; }
		if ($t > $snum) { 
		    push (@sens, {id=>0, entr=>0, sens=>$nsens++, _gloss=>$glos, 
				   _stag=>[]}) if (@$glos); 
		    $snum = $t; $glos = []; $ngloss = 1;} }
	    push (@$glos, {entr=>0, sens=>$nsens, gloss=>$ngloss++, lang=>1, txt=>$3}) if ($3); }
	push (@sens, {entr=>0, sens=>$nsens++, _gloss=>$glos, _stag=>[]}) if (@$glos); 
	if (!@sens) { push (@errs, "At least one gloss required"); }

	# The Add Entry form has no provision for assigning pos, misc
	# or xrefs to specific sense, so the best we can do is to assign
	# any given to all senses.

	foreach $x ($cgi->param("pos")) { 	# Process pos params.
	    next if ($x =~ m/^\s*$/);		# Skip empty fields.
	    if (!$::KW->{POS}{$x}{id}) {	# Validate received value.
	         push (@errs, "Bad \"pos\" value: $x"); }
	    else { 
		foreach $s (@sens) { 		# Create pos records for each sense.
		    if (!$s->{_pos}) { $s->{_pos} = []; }
		    push (@{$s->{_pos}}, {entr=>0, sens=>$s->{sens}, kw=>$x}); } } }

	foreach $x ($cgi->param("misc")) { 	# Process misc params.
	    next if ($x =~ m/^\s*$/);		# Skip empty fields.
	    if (!$::KW->{MISC}{$x}{id}) {	# Validate received value.
	         push (@errs, "Bad \"misc\" value: $x"); }
	    else { 
		foreach $s (@sens) { 		# Create misc records for each sense.
		    if (!$s->{_misc}) { $s->{_misc} = []; }
		    push (@{$s->{_misc}}, {entr=>0, sens=>$s->{sens}, kw=>$x}); } } }

	$txt = decode_utf8($cgi->param("crossref"));	# Process xref param.
	if ($txt) {
	    # Separate the xref text from any target senses that were given. 
	    ($xtxt, $slist) = parse_xref ($txt, \@errs); }
	if ($xtxt) {
	    # Find the xref in the database, verfify that any senses
	    # given actually exist.  Structure returned is a list of
	    # "eref"s (for description, see jmdict::eref2xref()) which
	    # is easier to display than a list of raw xref's. 
	    $erefs = resolv_xref ($dbh, $txt, $slist, $::KW->{XREF}{see}{id}, \@errs); }
	if ($erefs) {
	    # Apply the resolved xref(s) to each of our senses (since the 
	    # form provides no way to resrict to particular source senses.)
	    foreach $s (@sens) {  
		if (!$s->{_erefs}) { $s->{_erefs} = []; }
		push (@{$s->{_erefs}}, (@$erefs)); 
		# Create xrefs from the erefs since that is what will be loaded
		# into the database.  The erefs are just for web page display.
		$s->{_xref} = erefs2xrefs ($s->{_erefs}); } } 

	# The name and email address are combined into a single 
	# database field.

	$name = $cgi->param("name") || "";
	$email = $cgi->param("email") || "";
	if (!($email =~ m/^[A-Z0-9._%-]+@(?:[A-Z0-9-]+\.)+[A-Z]{2,4}$/io)) {
	    push (@errs, "Missing or invalid email address: $email"); }
	$who = $name . "<" . $email . ">";

	# The ccomment and references info are also combined into
	# a single database field.

	$comment = decode_utf8($cgi->param("comment"));
	$reference = decode_utf8($cgi->param("reference"));
	if ($comment) { $comment = "Comment:\n$comment"; }
	if ($reference) {
	    if ($comment) { $comment .= "\n\n"; }
	    $comment .= "References:\n$reference"; }

	# Create a history record for display.  A real record will 
	# be recreated with the entry is actually comitted to the 
	# database.

	$now = strftime "%Y-%m-%d %H:%M:%S", localtime;
	$hist = {id=>0, entr=>0, stat=>1, dt=>$now, 
		  who=>\$who, diff=>'', notes=>\$comment };

	# Tie all the pieces together to make an entry structure to
	# give back to the caller, along with any errors we encountered.
	# (If there were errors, there is no garuantee that the entry
	# structure is valid.)

	$entr = {id=>0, seq=>0, stat=>1, src=>1,
		  _rdng=>\@rdng, _kanj=>\@kanj, _sens=>\@sens,
		  _hist=>[$hist], _xref=>$xrefs};

	return ($entr, \@errs); }

    sub parse_xref { my ($txt, $errs) = @_;
	my ($xrefstr, $sensstr, @sens);
	if (!($txt =~ m/^(.+?)\s*(\(([\d, ]+)\))?\s*$/o)) {
	    push (@$errs, <<EOT
Bad syntax in cross-reference.  You may enter a single reading
string, kanji string, or sequence number to identify an existing
entry.  If the cross-reference is to only some of the senses in
the target word you may give those senses as a comma-separated
list of sense numbers enclosed in parenthesis.  E.g. "(1,3,4)".
EOT
	        ); return ("",[]); }
	$xrefstr = $1;  $sensstr = $3;
	if ($sensstr) { @sens = split (/[ ,]+/, $sensstr); }
	return ($xrefstr, \@sens); }
	
    sub resolv_xref { my ($dbh, $txt, $slist, $typ, $errs) = @_;
	# $dbh -- Handle to open database connection.
	# $txt -- Text of xref that will be resolved (kanji or kana).
	# $sens -- Ref to array of sense numbers.  Resolved xrefs
	#   will be limited to these target senses.
	# $typ -- (int) Type of reference per $::KW->{XREF}.
	# $errs -- Ref to array of text strings.  If any user-sourced
	#   occur in resolv_xref(), we will add the eror message onto
	#   @$errs with the expectation that the caller will display
	#   the accumulated errors to the user at a later time.
	
	my ($sql, $r, $esums, $qlist, @erefs, $srecs, $eid, $q, $s, $found);

	if (!$::KW->{XREF}{$typ}) { 
	    push (@$errs, "Bad xref type value: $typ."); 
	    return undef; }
	if ($txt =~ m/^\d+$/o) {
	    $sql = "SELECT * FROM esum WHERE seq=?";
	    $esums = dbread ($dbh, $sql, [$txt]); }
	else {
	    $sql = "SELECT DISTINCT s.* " .
		  "FROM esum s " .
		  "JOIN entr e ON e.id=s.id " .
		  "LEFT JOIN kanj k ON k.entr=e.id " .
		  "LEFT JOIN rdng r ON r.entr=e.id " .
		  "WHERE k.txt=? OR r.txt=? ";
	    $esums = dbread ($dbh, $sql, [$txt, $txt]); }
	if (scalar(@$esums) < 1) {
	    push (@$errs, "No entries found for cross-reference \"$txt\"."); 
	    return undef; }
	if (scalar(@$esums) > 1 and $slist and @$slist) {
	    push (@$errs, <<EOT
The cross-reference text \"$txt\" resolved to multiple 
jmdict entries but you specified explicit senses for the cross-references.  
Explicit senses may be given only when the text resolves to a single entry.
EOT
		); return undef; }
	foreach $r (@$esums) {
	    push (@erefs, {typ=>$typ, entr=>$r, sens=>[]}); }

	# For every target entry, get all it's sense numbers.  We need
	# these for two reasons: 1) If explicit senses were targeted we
	# need to check them against the actual senses. 2) If no explicit
	# targte senses were given, then we need them to generate erefs 
	# to all the target senses.

	$qlist = join(",", map ("?", @erefs));
	$sql = "SELECT entr,sens FROM sens WHERE entr IN ($qlist) ORDER BY entr,sens";
	$srecs = dbread ($dbh, $sql, [map ($_->{entr}{id}, @erefs)]);

	if (@$slist) {
	    # The submitter gave some specific senses that the xref will
	    # target, so check that they actually exist in the target entries...
	    foreach $r (@erefs) {		# For each target entry...
		$eid = $r->{entr}{id};
		foreach $s (@$slist) {		# For each given sense
		    $found = 0;
		    foreach $q (@$srecs) {	# Check against each actual sense.
			if ($q->{entr} != $eid and $q->{sens} == $s) {
			    $found = 1; last; } }
		    if (!$found) { 
		        push (@$errs, "Cross-ref: there is no sense $s in entry(s) $txt"); } }
		$r->{sens} =  [@$slist]; } } 
	else {
	    # No specific senses given, so this xref(s) should target every
	    # sense in the target entry(s).
	    foreach $r (@erefs) {
		$eid = $r->{entr}{id};
	        $r->{sens} = [map ($_->{sens}, grep ($_->{entr}==$eid, @$srecs))]; } }
	return \@erefs; } 

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
