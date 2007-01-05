# This module contains user-defined modifiers for Petal and 
# used in the jmdict Petal templates.

package jmdicttal;
# Copyright (c) 2007 Stuart McGraw 
@VERSION = (substr('$Revision$',11,-2), \
	    substr('$Date$',7,-11));

use strict;  use warnings;

$Petal::Hash::MODIFIERS->{'kwabbr:'} = sub { my ($hash, $args) = @_;
	my ($typ, $expr, $x, $a);
	($typ, $expr) = split (/ /, $args);
	$x = $hash->fetch ($expr);
	$a = $::KW->{$typ}{$x}{kw};
	return $a; };

$Petal::Hash::MODIFIERS->{'kwabbrs:'} = sub { my ($hash, $args) = @_;
	my ($typ, $delim, $expr, $x, @a);
	($typ, $delim, $expr) = split (/\s+'(.*?)'\s+/, $args);
	$x = $hash->fetch ($expr);
	@a = map ($::KW->{$typ}{$_->{kw}}{kw}, @$x);
	$delim =~ s/[\\]([^\\])/$1/go;
	return join ($delim, @a); };

$Petal::Hash::MODIFIERS->{'kwfulls:'} = sub { my ($hash, $args) = @_;
	my ($typ, $delim, $expr, $x, @a);
	($typ, $delim, $expr) = split (/\s+'(.*?)'\s+/, $args);
	$x = $hash->fetch ($expr);
	@a = map ($::KW->{$typ}{$_->{kw}}{descr}, @$x);
	$delim =~ s/[\\]([^\\])/$\1/go;
	return join ($delim, @a); };

$Petal::Hash::MODIFIERS->{'freqs:'} = sub { my ($hash, $args) = @_;
	my ($typ, $delim, $expr, $x, @a);
	($typ, $delim, $expr) = split (/\s+'(.*?)'\s+/, $args);
	$x = $hash->fetch ($expr);
	@a = map ($::KW->{$typ}{$_->{kw}}{kw}.($_->{value}), @$x);
	$delim =~ s/[\\]([^\\])/$1/go;
	return join ($delim, @a); };

1;