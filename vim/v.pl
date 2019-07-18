#!/usr/bin/perl
use strict;
use warnings;
use v5.10;
use Data::Dumper;

if (@ARGV) {
	say 'vim -o '.join('"', @ARGV);
}
else {
	my $gitdir = `git rev-parse --git-dir 2>/dev/null`;
	if ($gitdir) {
		my @files =
			map { s/^.. (.*)$/$1/; $_ }
			grep { m/^.M/ }
			split '\n', `git status --porcelain --untracked-files=no`;
		print Dumper \@files;
		exit;
	}
	else {
		print Dumper $gitdir;
	}
}
