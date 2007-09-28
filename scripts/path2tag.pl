#!/usr/bin/perl
use strict;
use warnings;

my $dir = $ARGV[0];
$dir or die 'pass dir to start at';
$dir = $ENV{PWD} if $dir eq '.';
-d $dir or die "$dir: $!";
foreach my $path (`find "$dir" -type f`) {
	chomp $path;
	next if $path =~ m{/_incoming/};
	next unless $path =~ m{^.*/([^/]+)/([^/]+)/(.+?)\.(mp3|ogg|flac)$};
	my ($parent, $dir, $file, $format) = ($1, $2, $3, $4);

	my %args = ();

	if( $dir =~ m{^(.+?)\.([0-9]{4}[a-z]?)\.(.+)$} or
		$dir =~ m{^(.+?)\.([0-9]{4}-[0-9]{2,4})\.(.+)$} )
	{
		$args{artist} = $1;
		$args{year} = $2;
		$args{album} = $3;
	}
	elsif( $dir =~ m{^(.+?)\.\.(.+)$} ) {
		$args{artist} = $1;
		$args{album} = $2;
	}
	else {
		$args{artist} = $dir;
	}

	if( $file =~ m{^([0-9]{2,3})\.(.+)$} ) {
		$args{track} = $1;
		$args{song} = $2;
	}
	elsif( not $args{album} ) {
		$args{album} = $args{artist};
		if( $file =~ m{^(.*?)(\.\.|::)(.+)$} ) {
			$args{artist} = $1;
			$args{song} = $3;
		}
		else {
			$args{song} = $file;
		}
	}
	else {
		$args{song} = $file;
	}

	#$args{artist} = "$parent:$args{artist}";
	$args{genre} = $parent;
	$args{album} = "$args{year}:$args{album}"  if $args{year};

	sub x(@) {
		my $cmd = join ' ', @_;
		print "$cmd\n"        if     $ENV{NOP}||$ENV{VERBOSE};
		system $cmd || last   unless $ENV{NOP};
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

		x $r->{cmd}, ( map { $r->{arg}."\"$m2v{$_}=$args{$_}\"" } keys %args ), "\"$path\"";
	}
}

