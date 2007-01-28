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

1;
