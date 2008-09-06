#!/usr/bin/perl
use strict;
use warnings;
$\ = "\n";

sub increment_suffix($;$)
{#
	my ($ref, $sep) = @_;
	defined $sep or $sep = '-';
	$$ref =~ s/^(.*?)(${sep}([0-9]+))?(\.[^.]+)?$/$1.$sep.($2?$3+1:1).(defined $4?$4:'')/e;
	$$ref;
}#

sub autoincrement_filename_suffix
{#
	print "auto-incrementing a filename suffix:";
	my $a = "\tfilename.ext";
	print $a;
	foreach (1 .. 3) {
		print increment_suffix \$a;
	}
}#

autoincrement_filename_suffix;

# vim600:fdm=marker:fmr={#,}#:
