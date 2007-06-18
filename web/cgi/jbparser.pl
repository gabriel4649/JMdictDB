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
use Cwd; use CGI; use HTML::Entities;
use Encode; use utf8; 

BEGIN { push(@INC, ("../lib")); };
use jmdict; use jbparser; use jmdictfmt; 

#------------------------------------------------------------
    main: {
	my ($cgi, $intxt, $enc, $etxt, $e, $msgs, $errs,
	    $grmr, $kanj, $rdng, $sens, $dbh);

	$enc = "sjis";
	#binmode(STDOUT, ":encoding($enc)");
	#binmode(STDERR, ":encoding($enc)");
	{no warnings eval { binmode($DB::OUT, ":encoding($enc)"); }; };

	$::Debug = {};
	$cgi = new CGI;
	$kanj = decode ('utf8', $cgi->param ('kanj'));
	$rdng = decode ('utf8', $cgi->param ('rdng'));
	$sens = decode ('utf8', $cgi->param ('sens'));
	print "Content-type: text/html; charset=utf-8\n\n";
	send_head("Parser test form");
	if (!$kanj and !$rdng and !$sens) { 
	    $grmr = extract_grammar ("../lib/jbparser.yp");
	    send_form ($grmr);  
	    exit; }

	$intxt = join ("\n", ($kanj, $rdng, $sens));
	($e,$errs) = jbparser->parse_text ($intxt, 7);
	if ($e) { 
	    if (grep ($_->{_XREF}, @{$e->{_sens}})) {
		$dbh = dbopen (); 
	        eval {jbparser::resolv_xrefs ($dbh, $e);}; 
		if ($@) { push (@$errs, $@); } } }
	if (!@$errs) {
	    $etxt = fmt_entr ($e); } 
	else { 
	    $msgs = join ("<br/>\n", @$errs);
	    $etxt = "<b>parse failed:</b><br/>$msgs\n"; }
	send_results ($intxt, $etxt, $::dbgtxt);
	if ($dbh) { $dbh->disconnect(); } } 

#------------------------------------------------------------
    sub extract_grammar { my ($fn) = @_;
	my ($sec, @lines);
	open (F, $fn) || die "Can't open file $fn: $!\n";
	$sec = 0;
	while (<F>) {
	    $sec++ if (m/^\s*%%\s*$/);
	    next if ($sec) < 1;
	    last if ($sec) > 1;
	    push (@lines, $_) if (m/^[a-z]/ or m/^\s+[:|]/); }
	close F;
	return join ("", @lines); }

#------------------------------------------------------------
    sub send_head { my ($title) = @_;
	print <<EOT;
<html><body>
EOT
	}

#------------------------------------------------------------
    sub send_results { my ($intxt, $etxt, $dbgtxt) = @_;
	print <<EOT;
	    <h2>Parse results</h2>
	    <p/>Input text:<p/>
	    <pre>$intxt</pre>
	    <hr/>
	    Parsed and reformatted entry:<p/>
	    <pre>$etxt</pre>
	    <hr/>
	    Parse trace:
	    <pre>$dbgtxt</pre>
	    </body></html>
EOT
	}

#------------------------------------------------------------
    sub send_form { my ($grmrtxt) = @_;
	print <<EOT;
  <h2>Parser Test</h2>
	This form is for interactively evaluating the input language
	and parser proposed for use in wwwjdic new and edit entry 
        submission forms.  Enter a entry description (see the language
	points and example below) in the boxes, click the "Parse" button,
	and your description will be parsed and the reformatted
	entry printed, or an error message shown.  <br/>
  <form action="" method="get">
    <table border=0>
    <tr>
      <td>Kanji:</td>
      <td><textarea name="kanj" wrap="physical" COLS="60" ROWS="2"></textarea></td></tr>
    <tr>
      <td>Reading:</td>
      <td><textarea name="rdng" wrap="physical" COLS="60" ROWS="2"></textarea></td></tr>
    <tr>
      <td>Sense:</td>
      <td><textarea name="sens" wrap="physical" COLS="60" ROWS="8"></textarea></td></tr>
    <tr>
      <td></td>
      <td><input type="submit" value="Parse"/></td>
      </tr>
    </table>
    </form>

    <ul>
    <li>In the Kanji and Reading boxes, multiple kanji or readings
       should separated with a semi-colon (either
       ascii or Japanese is ok).
    <li>Each kanji or reading item can be followed with kinf, rinf,
      kprio, rprio tags in brackets.  Multiple tags can go in a single
      pair of brackets, and multiple sets of brackets can be used.
    <li>Reading items can also specify that the reading is restricted
      to one or more particular kanji using the syntax 
      [restr=kanj1;kanj2;...].  The given kanji must occur in
      the Kanji box, although this is not checked by the parser.
      "restr=..." items can be intermixed with other tags.
    <li>Sense numbers are in brackets (e.g. "[1]") and must be given
      for all senses, even the first and even if there is only one.
      No spaces allowed in the sense
      number, nor can it be mixed with other sense tags.
    <li>The numeric value in a sense number doesn't matter; the
      parser recognises the bracket-number-bracket pattern as the
      start of a new sense but ignores the number's value.
      Senses are always numbered by the parser in the order they 
      occur, starting from 1.
    <li>Newline characters ("\\n") are just another whitespace
      character.  Specifically, senses do not have to start
      on a new line: "[1] my gloss [2] another gloss" is ok.
    <li>Glosses are entered without any special syntax other than
      using semi-colon to separate multiple glosses.  To use a 
      semi-colon or left bracket within a gloss, escape it with
      a backslash character.  (There is currently no way to escape
      a backslash character itself.)
    <li>Pos, misc, domain ("fld"), kprio ("freq"), rprio ("freq"),
      kinf, and rinf tags are given inside brackets.  See the
      example below.  They may also be given with the type of
      tag explicitly specified using the form "&lt;type&gt;=&lt;tag&gt;".
      See for example sense [2] below which uses "pos=n".
      Multiple tags can go in a single
      pair of brackets, and multiple sets of brackets can be used.
      Tags can be intermixed with glosses.
    <li> Other information can be given in brackets as noted in
      the points below.  Although these are shown in their own
      sets of brackets, they can also be intermixed with other
      tags.  For examle, [vs,n,note="here is my note"] is perfectly
      fine in the Sense box.
    <li> [lit=xx:"..."] specifies text for a literal translation
      in the Sense box.  The 
      quotes are only needed if the text contain special characters
      like spaces, colon, brackets, etc.  "xx:" is a language specifier
      and may left out if it is "en:".
    <li> [expl=xx:"..." specifies text for an explanatory gloss
      in the Sense box. Same
      synax as [lit=...] above.
    <li> [note="..."] specifies text for a sense note (xml s_info)
      in the Sense box.  Same
      syntax a [lit=...] above except no language specifier allowed.
    <li> [lsrc=xx:"..."] specifies the source word and language
      in the Sense box.  
      Same syntax as [lit=...] above except the "..." text is optional.
      <i>No provision yet for specifying "wasei" or "partial" (is a to-do).</i>
    <li> [see=kanj;rdng[s1,s2,...]], [ant=kanj;rdng[s1,s2,...]],  
      specifies a cross reference or antonym respectively, in the Sense box.  
      kanj and rdng are both optional but at least one must be given.
      The list of senses is optional. 
      <i>No provision yet for specifying a seq number (is a to-do).</i>
    <li> [restr=jtxt;jtxt;...] specifies a restr restriction when used
      in the Reading box, or a stagr or stagk restriction when used 
      in the Sense box.  'jtxt' must be kanji for reading restr.
      For sense restr, can be either kanji (results in a stagk restriction)
      or kana (results in a stagr restriction).
      In the Reading box you can also say [restr=nokanji], or simply [nokanji].
    </ul>
      
    <p/>Example:
    <pre>
    Kanji: 
      舌足らず [nf45][news2]； 舌っ足らず [io]

    Reading:  
      したたらず [nf45,news2,restr=舌足らず]； したったらず [restr=舌っ足らず]

    Sense:
      [1] [adj-na,adj-no,n] lisping; speaking with a lisp
      [2] [adj-na,adj-no,pos=n] 
        inadequate linguistic ability
        [see=ろれつが回らない; 呂律/ろれつ[1]]
    </pre>

  <p/><b>Grammar:</b>
  <pre>$grmrtxt</pre>
  </body>
</html>
EOT
	}
