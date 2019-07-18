#!/usr/bin/perl
use strict;
use warnings;
use v5.10;
use Data::Dumper;
use File::Find;

my %F;

find(
	{
		no_chdir => 1,
		wanted => sub {
			unless (-d) {
				if (m/^(.[^.]+)\.(.*)\.([^.]+)$/) {
					my ($ep, $name, $ext) = ($1, $2, $3);
					$F{$ep} //= {};
					$F{$ep}->{$ext} = $name;
				}
				else {
					say "$_ nao deu match";
				}
			}
		}
	},
	'.'
);

#print Dumper \%F;

sub get_exts
{
	my @rc;
	if (scalar(keys %{$_[0]}) == 2) {
		foreach my $ext (keys %{$_[0]}) {
			my $idx;
			if ($ext eq 'srt') {
				$idx = 0;
			}
			elsif ($ext eq 'mkv') {
				$idx = 1;
			}
			$rc[$idx] = $ext  if defined $idx;
		}
	}
	@rc;
}

foreach my $ep (sort keys %F) {
	#say "vai $ep";
	my @exts = get_exts($F{$ep});
	#print Dumper \@exts;
	if (@exts) {
		my $name0 = $F{$ep}->{$exts[0]};
		my $name1 = $F{$ep}->{$exts[1]};
		if ($name0 ne $name1) {
			system "mv -i -v \"$ep.$name0.$exts[0]\" \"$ep.$name1.$exts[0]\"";
		}
		else {
			say "skip \"$ep.$name0\"";
		}
	}
}

