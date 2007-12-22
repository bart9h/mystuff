#!/usr/bin/perl
use strict;
use warnings;

#
#  IMPORTANT NOTICE:
#  This is modeled based on the way I arrange my music:
#  genre/artist.year.album/tracknr.songtitle.ext
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

	#  Artist.1900.Album/
	if( $dir =~ m{^(.+?)\.([0-9]{4}[a-z]?)\.(.+)$} or
		$dir =~ m{^(.+?)\.([0-9]{4}-[0-9]{2,4})\.(.+)$} )
	{
		$args{artist} = $1;
		$args{year} = $2;
		$args{album} = $3;
	}
	#  Artist..Album/
	elsif( $dir =~ m{^(.+?)\.\.(.+)$} ) {
		$args{artist} = $1;
		$args{album} = $2;
	}
	#  Artist/
	else {
		$args{artist} = $dir;
	}

	#  01.Title
	if( $file =~ m{^([0-9]{2,3})\.(.+)$} ) {
		$args{track} = $1;
		$args{song}  = $2;
	}
	elsif( not defined $args{album} ) {

		$args{album} = $args{artist};

		#  Artist..Title  or  Artist::Title
		if( $file =~ m{^(.*?)(\.\.|::)(.+)$} ) {
			$args{artist} = $1;
			$args{song}   = $3;
		}
		#  Title
		else {
			$args{song} = $file;
		}
	}
	else {
		#  Title
		$args{song} = $file;
	}

	if( ! $has_genre_field ) {
		$args{artist} = "$args{genre}:$args{artist}";
	}

	if( ! $has_year_field ) {
		$args{album} = "$args{year}:$args{album}"  if $args{year};
	}

	sub x(@) {
		my $cmd = join ' ', @_;
		print "$cmd\n"        if     $ENV{NOP}||$ENV{VERBOSE};
		if(!$ENV{NOP}) {
			system($cmd) == 0  or die;
		}
	}

	if( $format eq 'mp3' ) {
		#x "id3v2 -D \"$path\"" unless $ENV{NOP};
		x 'id3v2', ( map { "--$_=\"$args{$_}\"" } keys %args ), "\"$path\"";
	}
	elsif( $format =~ /(ogg|flac)/ ) {

		my %m2v = (  # translate mp3 tag names to vorbis
			artist => 'ARTIST',
			year   => 'DATE',
			album  => 'ALBUM',
			track  => 'TRACKNUMBER',
			song   => 'TITLE',
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
				grep( defined $args{$_}, keys %args )
			),
			"\"$path\"";
	}
}

