#!/usr/bin/perl
#
# Subtitle (.srt format) filter to remove all the [NOISE] (DESCRIPTIONS).
#
# FIXME:
# (THIS DON'T
# WORK YET)
#

use strict;
use warnings;
use v5.10;

my $st = 0;
my $line;
my $line_nr = 0;
my $sub_nr = 0;
my $timeslice;
my @text = ();

foreach $line (<>) {
	$line =~ s/^\s+//;
	$line =~ s/\s+$//;
	++$line_nr;
	if ($st == 0) {
		if ($line =~ m/^(\X*)\d+$/) {
			print $1;
			$st = 1;
		}
		else { die "Erro 1 na linha $line_nr:\n$line\n" }
	}
	elsif ($st == 1) {
		my $timestamp_format = qr/\d{2}:\d{2}:\d{2},\d{3}/;
		if ($line =~ m/^${timestamp_format} --> ${timestamp_format}$/u) {
			$timeslice = $line;
			$st = 2;
		}
		else { die "Erro 2 na linha $line_nr:\n$line\n" }
	}
	elsif ($st == 2) {
		if ($line eq '') {
			if (@text) {
				print join "\n", ++$sub_nr, $timeslice, @text;
				print "\n\n";
				@text = ();
			}
			$st = 0;
		}
		else {
			$line =~ s/\(.+?\)//g;
			$line =~ s/\[.+?\]//g;
			$line =~ s/^\s+//;
			$line =~ s/\s+$//;
			push @text, $line  if $line ne '';
		}
	}
}

if (@text) {
	print join "\n", ++$sub_nr, $timeslice, @text;
	print "\n\n";
	@text = ();
}
