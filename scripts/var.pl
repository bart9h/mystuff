#!/usr/bin/perl
use strict;
use warnings;

while (<>) {
	foreach my $key (keys %ENV) {
		my $val = $ENV{$key};
		next if $val =~ /(\[|\]|\|)/;
		s/$val/\${$key}/g if length $val > length $key;
	}
	print;
}

