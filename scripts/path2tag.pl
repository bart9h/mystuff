#!/usr/bin/perl
use strict;
use warnings;
use v5.10;
use Data::Dumper;

#
#  IMPORTANT NOTICE:
#  This is modeled based on the way I arrange my music:
#  genre/artist__year__album/tracknr__songtitle.ext
#

#TODO: check if external tools are installed

my $has_genre_field = 1;
#  If this is false, store genre in artist name, like "genre::artist".

my $has_year_field = 1;

#  must receive base for collection dir as first argument
defined $ARGV[0] or die 'pass dir to start at';
my $collection_dir = $ARGV[0];

$collection_dir = $ENV{PWD} if $collection_dir eq '.';

#  check if dir exists
-d $collection_dir or die "$collection_dir: $!";

#  process each file inside
foreach my $path (`find "$collection_dir" -type f`) {
	chomp $path;

	#  skip "_incoming" dir
	next if $path =~ m{/_incoming/};
	next unless $path =~ m{^.*/([^/]+)/([^/]+)/(.+?)\.(mp3|ogg|flac)$};
	my ($parent, $dir, $file, $format) = ($1, $2, $3, $4);

	my %args = ();

	$args{genre} = $parent;

	#  Artist__1900__Album/  ou  Artist__1900b__Album/
	if( $dir =~ m{^(.+?)__([0-9]{4}[a-z]?)__(.+)$} or
		$dir =~ m{^(.+?)__([0-9]{4}-[0-9]{2,4})__(.+)$} )
	{
		$args{artist} = $1;
		$args{year} = $2;
		$args{album} = $3;
	}
	#  Artist__Album/
	elsif( $dir =~ m{^(.+?)__(.+)$} ) {
		$args{artist} = $1;
		$args{album} = $2;
	}
	#  Artist/
	else {
		$args{artist} = $dir;
	}

	#  01-04__Title
	if( $file =~ m{^([0-9]{2,3})(-[0-9]{2,3})__(.+)$} ) {
		$args{track} = $1;
		$args{song}  = $3;
	}
	#  01__Title
	elsif( $file =~ m{^([0-9]{2,3})__(.+)$} ) {
		$args{track} = $1;
		$args{song}  = $2;
	}
	elsif( not defined $args{album} ) {

		$args{album} = $args{artist};

		#  Artist__Title
		if( $file =~ m{^(.*?)__(.+)$} ) {
			$args{artist} = $1;
			$args{song}   = $2;
		}
		#  Title
		else {
			$args{song} = $file;
		}
	}
	#  Title
	else {
		$args{song} = $file;
	}

	$args{track} =~ s/^0+//  if exists $args{track};

	if( ! $has_genre_field ) {
		$args{artist} = "$args{genre}:$args{artist}";
	}

	if( ! $has_year_field ) {
		$args{album} = "$args{year}:$args{album}"  if $args{year};
	}

	sub x {
		my $cmd = join ' ', @_;
		print "$cmd\n"        if     $ENV{NOP}||$ENV{VERBOSE};
		if(!$ENV{NOP}) {
			system($cmd) == 0  or die;
		}
	}

	if( $format eq 'mp3' ) {
		my %rfc2t = (  # translate mp3 tag names to vorbis
			TPE1 => 'artist',
			TYER => 'year',
			TALB => 'album',
			TRCK => 'track',
			TIT2 => 'song',
			TCON => 'genre',
		);

		my %cur;
		foreach (`id3v2 -R \"$path\"`) {
			if (m/^([A-Z0-9]{4}): (.*)$/) {
				my ($tag, $value) = ($1, $2);
				if (exists $rfc2t{$tag}) {
					$tag = $rfc2t{$tag};
					if ($tag eq 'genre') { # remove (255)
						if ($value =~ m{^(.*) \(\d+\)$}) {
							$value = $1;
						}
					}
					$cur{$tag} = $value;
				}
			}
		}

		my $needs_update = 0;
		foreach my $key (keys %args) {
			if (not defined $cur{$key} or $cur{$key} ne $args{$key}) {
				$needs_update = 1;
				last;
			}
		}

		#x "id3v2 -D \"$path\"" unless $ENV{NOP};
		if ($needs_update) {
			x 'id3v2', ( map { "--$_=\"$args{$_}\"" } keys %args ), "\"$path\"";
		}
		else {
			say "Skipping \"$path\"."  if $ENV{VERBOSE};
		}
	}
	elsif( $format =~ /(ogg|flac)/ ) {

		my %v2m = (  # translate mp3 tag names to vorbis
			ARTIST      => 'artist',
			DATE        => 'year',
			ALBUM       => 'album',
			TRACKNUMBER => 'track',
			TITLE       => 'song',
			GENRE       => 'genre',
		);

		my %cur;
		foreach (`vorbiscomment \"$path\"`) {
			if (m/^([A-Z]+)=(.*)$/) {
				my ($tag, $value) = ($1, $2);
				if (exists $v2m{$tag}) {
					$tag = $v2m{$tag};
					$cur{$tag} = $value;
				}
			}
		}

		my $needs_update = 0;
		foreach my $key (keys %args) {
			if (not defined $cur{$key} or $cur{$key} ne $args{$key}) {
				#print Dumper $path, \%args, \%cur; exit;
				$needs_update = 1;
				last;
			}
		}

		if (not $needs_update) {
			say "Skipping \"$path\"."  if $ENV{VERBOSE};
			next;
		}

		my %m2v = (  # translate mp3 tag names to vorbis
			artist => 'ARTIST',
			year   => 'DATE',
			album  => 'ALBUM',
			track  => 'TRACKNUMBER',
			song   => 'TITLE',
			genre  => 'GENRE',
		);

		my %f = (  # how to set vorbis metadata for each format
			ogg  => { cmd => 'vorbiscomment -w', arg => '-t '        },
			flac => { cmd => 'metaflac',         arg => '--set-tag=' },
		);
		my $r = $f{$format};

		#FIXME: do not include empty fields (the grep approach is not working)
		x
			$r->{cmd},
			(
				map { $r->{arg}."\"$m2v{$_}=$args{$_}\"" }
				grep { defined $args{$_} and $args{$_} ne '' }
				keys %args
			),
			"\"$path\"";
	}
}

