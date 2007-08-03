#######################################################################
#   This file is part of JMdictDB. 
#   Copyright (c) 2006,2007 Stuart McGraw 
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


use strict; use warnings;
use Encode 'decode_utf8'; 
use Storable qw(freeze thaw); use MIME::Base64;
use HTML::Entities;
use POSIX qw(strftime);

BEGIN {push (@INC, "../lib");}
use jmdict;

*esc = \&CGI::escapeHTML;

    sub serialize { my ($struct) = @_;
	my $s = freeze ($struct);
	$s = encode_base64 ($s);
	$s = encode_entities ($s);
	$s; }

    sub unserialize { my ($str) = @_;
	my $s = decode_entities ($str);
	$s = decode_base64 ($s);
	$s = thaw ($s);
	$s; }

    sub fmt_restr { my ($entrs) = @_;

	# In the database we store the invalid combinations of readings
	# and kanji, but for display, we want to show the valid combinations.
	# So we subtract the former set which we got from the database from
	# from the full set of all combinations, to get the latter set for
	# display.  We also set a HAS_RESTR flag on the entry so that the 
	# display machinery doesn't have to search all the readings to 
	# determine if any restrictions exist for the entry.

	my ($e, $nkanj, $r);
	foreach $e (@$entrs) {
	    next if (!$e->{_kanj});
	    $nkanj = scalar (@{$e->{_kanj}});
	    foreach $r (@{$e->{_rdng}}) {
		next if (!$r->{_restr});
		$e->{HAS_RESTR} = 1;
		if (scalar (@{$r->{_restr}}) == $nkanj) { $r->{_RESTR} = 1; }
		else {
		    my @rk = map ($_->{txt}, 
			@{filt ($e->{_kanj}, ["kanj"], $r->{_restr}, ["kanj"])});
		    $r->{_RESTR} = \@rk; } } } }

    sub fmt_stag { my ($entrs) = @_; 

	# Combine the stagr and stagk restrictions into a single
	# list, which is ok because former show in kana and latter
	# in kanji so there is no interference.  We also change
	# from the "invalid combinations" stored in the database
	# to "valid combinations" needed for display.

	my ($e, $s);
	foreach $e (@$entrs) {
	    foreach $s (@{$e->{_sens}}) {
		my @stag;
		if ($s->{_stagk} and @{$s->{_stagk}}) {
		    push (@stag, map ($_->{txt},
		      @{filt ($e->{_kanj}, ["kanj"], $s->{_stagk}, ["kanj"])})); }
		if ($s->{_stagr} and @{$s->{_stagr}}) {
		    push (@stag, map ($_->{txt},
		      @{filt ($e->{_rdng}, ["rdng"], $s->{_stagr}, ["rdng"])})); }
		$s->{_STAG} = @stag ? \@stag : undef; } } }

    sub set_audio_flag { my ($entrs) = @_; 

	# The display template shows audio records at the entry level 
	# rather than the reading level, so we set a HAS_AUDIO flag on 
	# entries that have audio records so that the template need not
	# sear4ch all readings when deciding if it should show the audio
	# block.
	# [Since the display template processes readings prior to displaying
	# audio records, perhaps the template should set its own global
	# variable when interating the readings, and use that when showing
	# an audio block.  That would eliminate the need for this function.]
 
	my ($e, $r, $found);
	foreach $e (@$entrs) {
	    $found = 0;
	    foreach $r (@{$e->{_rdng}}) {
		if ($r->{_audio}) { $found = 1; last; } }
	    $e->{HAS_AUDIO} = $found; } }


1;
