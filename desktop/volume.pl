#!/usr/bin/perl
use strict;
use warnings;
use v5.10;

my $steps = 32;


#
#  Parse arguments
#

my $direction;
if (defined $ARGV[0]) {
	if ($ARGV[0] eq 'up') {
		$direction = +1;
	}
	elsif ($ARGV[0] eq 'down') {
		$direction = -1;
	}
}
if (not defined $direction) {
	say "usage: $0 <up|down>";
	exit;
}


#
#  Change volume
#

my $new_vol;
foreach (`pacmd dump`) {
	if (m{^(set-sink-volume\ \S+)\ (0x[0-9a-fA-F]+)$}) {
		my ($set_sink, $vol) = ($1, hex($2));
		$new_vol = int($vol + $direction * 0x10000 / $steps);
		if ($new_vol < 0) {
			$new_vol = 0;
		}
		elsif ($new_vol > 0x10000) {
			$new_vol = 0x10000;
		}
		my $cmd = sprintf 'pacmd %s 0x%x', $set_sink, $new_vol;
		system $cmd;
	}
}


# BUG: will only report the volume of the last sink set from the loop above


#
#  OSD feedback
#

my $msg;
if (defined $new_vol) {
	my $bar = int($steps*$new_vol/0x10000);
	$msg = 'volume ['.('=' x $bar).('-' x ($steps - $bar)).']';
}
else {
	$msg = '`pacmd dump` failed to list "set-sink-volume" lines';
}

`echo "$msg" | /usr/bin/dzen2 -p 1 -fn "-*-courier-*-r-*-*-24-*-*-*-*-*-*-*"`;
