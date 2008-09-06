#!/usr/bin/perl
use strict;
use warnings;
$\ = "\n";

sub autoincrement_filename_suffix()
{#
	my $a = "filename";
	print $a;
	#while (-e $a)
	foreach (1 .. 3) {
		$a =~ s/^(.*?)(-([0-9]+))?$/$1."-".($2?$3+1:1)/e;
		print "$a";
	}
}#

autoincrement_filename_suffix();

# vim600:fdm=marker:fmr={#,}#:
