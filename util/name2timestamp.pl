#!/usr/bin/perl
use strict;
use warnings;

foreach my $path (sort @ARGV) {
	my $fullpath = $path;
	$path =~ s{.*/([^/]+)$}{$1};
	if ($path =~ m{[^\d]*(\d{4}\d{2}\d{2})_(\d{2}\d{2})(\d{2})[^\d]}) {
		system "touch -c -t $1$2.$3 \"$path\"";
	}
	else {
		warn "Couldn't find timestamp in \"$fullpath\"\n";
	}
}
