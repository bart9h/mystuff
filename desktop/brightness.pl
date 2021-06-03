#!/usr/bin/perl
use strict;
use warnings;
use v5.10;

my $increment_by = 0.1;

#
#  Parse `xrandr --verbose` output
#

my $brightness;
my $output_argument;

foreach (`xrandr --verbose`) { # | grep 'Brightness:' | cut -d : -f 2`) {
	if (m{^(.*?)\ connected\ primary\ }) {
		$output_argument = $1;
	}
	elsif (m{^\s*Brightness:\s+([0-9]+\.?[0-9]*)$}) {
		$brightness = 0 + $1;
	}
}

if ((not defined $output_argument) or (not defined $brightness)) {
	say "Error parsing xrandr output.";
	exit;
}


#
#  Parse arguments
#

my $increment = 0;
if (not $ARGV[0]) {
	say "Brightness = $brightness";
	exit;
}
elsif ($ARGV[0] eq 'up') {
	$increment += $increment_by;
}
elsif ($ARGV[0] eq 'down') {
	$increment -= $increment_by;
}
else {
	say "use $0 <up|down>";
}


#
#  Change brightness
#

$brightness += $increment;
if ($brightness < 0.1) {
	$brightness = 0.1;
}
elsif ($brightness > 1) {
	$brightness = 1;
}

`xrandr --output $output_argument --brightness $brightness`;


#
#  OSD feedback
#

my $bar = int($brightness*20);
my $msg = 'birghtness ['.('=' x $bar).('-' x (20-$bar)).']';
`echo "$msg" | /usr/bin/dzen2 -p 1 -fn "-*-courier-*-r-*-*-24-*-*-*-*-*-*-*"`;
