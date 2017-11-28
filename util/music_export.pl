#!/usr/bin/perl
use strict;
use warnings;
use v5.10;
use Data::Dumper;

my @audio_extensions = qw/mp3 ogg flac wav ac3 m4a/;

if (scalar @ARGV != 2) {
	say "usage: $0  <input-dir>  <output->dir>";
	exit 1;
}

my ($input_dir, $output_dir) = @ARGV;
foreach (\$input_dir, \$output_dir) {
	-d $$_  or die "$$_: not a directory.\n";
	$$_ =~ s{/$}{};
}

foreach my $genre (glob "$input_dir/*") {
	if (-d $genre and not $genre =~ m{/_[^/]*$}) {
		say "genre($genre)";
		$genre =~ m{^.*/([^/]*)$}  or die;
		my $genre_basename = $1;
		mkdir "$output_dir/$genre_basename"  or die;

		foreach my $album (glob "$genre/*") {
			if (-d $album) {
				say "album($album)";
				$album =~ m{^.*/([^/]*)$}  or die;
				my $album_basename = $1;

				my $output_genre = "$output_dir/$genre_basename";
				if (`ls "$album"/*.flac 2>/dev/null` ne '') {
					system "\"$ENV{ETC}/util/flac2mp3.sh\" --dont-ask \"$album\" \"$output_genre\"";
				}
				else {
					system "cp -v -R \"$album\"/ \"$output_genre\"";
				}
			}
			else {
				say "skipping($album)";
			}
		}
	}
	else {
		say "skipping($genre)";
	}
}
