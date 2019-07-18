#!/usr/bin/perl
use strict;
use warnings;
use v5.10;

#{# increment filename suffix

sub increment_filename_suffix($;$)
{#
	my ($ref, $sep) = @_;
	defined $sep or $sep = '-';
	$$ref =~ s/^(.*?)(${sep}([0-9]+))?(\.[^.]+)?$/$1.$sep.($2?$3+1:1).(defined $4?$4:'')/e;
	$$ref;
}#

sub increment_filename_suffix_test
{#
	say "auto-incrementing a filename suffix:";
	my $a = "\tfilename.ext";
	say $a;
	foreach (1 .. 3) {
		say increment_filename_suffix \$a;
	}
}#

#}#

#{#  Carp cheat-sheet
#
#                           DIE          WARN
#
#		FROM CALLER         croak        carp
#
#		WITH BACKTRACE      confess      cluck
#
#}#

# vim600:fdm=marker:fmr={#,}#:
