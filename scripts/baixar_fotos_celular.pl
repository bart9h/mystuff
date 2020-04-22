#!/usr/bin/perl
use strict;
use warnings;
use v5.10;

# find ~/fotos/ -name '*.jpg' | sort | xargs exiftool -Model -DateTimeOriginal | less

#my $source_path = '/sdcard/DCIM/Camera';
my $source_path = '/storage/3930-6232/DCIM/Camera';
my $ultima_baixada = '20200207';

my @files;
foreach (`adb shell ls $source_path`) {
	chomp;
	m{((?:IMG|VID)_(\d\d\d\d\d\d\d\d)_.*)} or next;
	my ($file, $data) = ($1, $2);
	next if $data <= $ultima_baixada;
	push @files, $source_path.'/'.$file;
}

my $cmd = 'sudo adb pull '.join(' ', @files).' .';
say $cmd;
system $cmd;
