#!/usr/bin/perl
use strict;
use warnings;
use v5.10;

sub generate_anagrams
{
	sub mix {
		my @a = @_;
		return @a if scalar(@a) <= 1;

		my @rc = ();
		for (my $i = 0;  $i < scalar(@a);  ++$i) {
			my $head = $a[$i];
			my @tail = grep { defined } ( @a[0 .. $i-1], @a[$i+1 .. $#a] );
			foreach (mix(@tail)) {
				push @rc, $head.$_;
			}
		}
		return @rc;
	}

	my @rc = mix split //, $_[0];

	# filter out duplicated results
	my @sorted = sort @rc;
	my $last = '';
	my @uniq = ();
	while (@sorted) {
		my $s = shift @sorted;
		push @uniq, $s  if $s ne $last;
		$last = $s;
	}
	return @uniq;
}

foreach my $arg (@ARGV) {
	foreach my $ana (generate_anagrams ($arg)) {
		#say "\"$arg\" => \"$ana\"";
		say $ana;
	}
}
