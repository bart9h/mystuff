#!/usr/bin/perl
#{#1          comments

=description

# retrieve photos and videos from camera
# uses gphoto2 as backend

=todo

- Check existence of required external tools.

- Fix ufraw rotation+scale order.

- GUI, or at leasst OSD.

- Show post-processing ETA.

- Run gphoto2 in interactive shell mode, show download progress, ETA.

- Parallel post-processing.

=cut


#{#1          parameters

use strict;
use warnings;
$|=1;
$\="\n";

my %args = (
		files => [],
		sudo => 'sudo',

		basedir => '/home/fotos',
		nop => 0,

		res => '1024x768',
		jpeg_quality => 80,

		#gui_mode => 0,
		#file_managers => [ 'nautilus', 'Thunar', 'pcmanfm', 'ROX-Filer' ],
		#file_manager => undef,
);

#{#1          code
sub TODO { die; }

#{#2           system utils

sub x($)
{#
	my $cmd = shift;
	print $cmd;
	system $cmd  unless $args{nop};
}#

sub file_read($;$)
{#
	my( $filename, $die ) = @_;

	unless( open F, $filename ) {
		my $msg = "open($filename): $!";
		$die ? die $msg : warn $msg;
		return undef;
	};

	if( wantarray ) {
		my @a = <F>;
		close F;
		return @a;
	}
	else {
		local $/;
		my $s = <F>;
		close F;
		return $s;
	}
}#

sub file_ok($)
{#
	my $file = shift;
	my( undef, undef, undef, undef, undef, undef, undef, $bytes )
			= stat( $file->{name} )  or die "stat( $file->{name} ): $!";
	return( (1024*$file->{size_kb} - $bytes) < 1024 );
}#

sub do_mkdir($)
{#
	-d $_[0]  and return $_[0];
	my $cmd = "mkdir -p $_[0]";
	x $cmd;
	-d $_[0]  or die "$cmd: $!"  unless $args{nop};
	return $_[0];
}#

#}#

sub default_args()
{#
	sub cached_resolution {
		#TODO:  "cache in ~/etc/var/screen-pixels
		'1024x768'
	}

	#TODO: use xdpyinfo instead
	$args{res} =
		`xwininfo -root` =~ /\bWidth:\s+(\d+)\b.*\bHeight:\s+(\d+)\b/s
		? "$1x$2"
		: cached_resolution();
}#

sub read_args (@)
{#
	my $process_args = 1;
	foreach (@_) {
		if ($process_args) {
			if (/^--$/) {
				$process_args = 0;
				next;
			}
			elsif ($_ eq '--help') {
				#{#
				#TODO: better %args, to contain description
				#      (borrow from other script I wrote..)
				my $max_len = 0;
				foreach (keys %args) {
					$max_len = length $_
						if length $_ > $max_len;
				}
				print "arguments".(' ' x ($max_len - 7))."[defaults]:\n";
				foreach (sort keys %args) {
					my $arg = defined $args{$_} ? $args{$_} : '<empty>';
					print $_.(' ' x (2 + $max_len - length $_))."[$arg]"
				}
				exit 0;
				#}#
			}
			elsif (m/^--(.*?)(=(.*))?$/) {
				my ($arg, $has_val, $val) = ($1, $2, $3);
				$arg =~ s/-/_/g;
				if (exists $args{$arg}) {
					$args{$arg} = $has_val ? $val : 1;
					next;
				}
				else {
					print STDERR "unknown arg ($_)";
					exit 1;
				}
			}
		}

		push @{$args{files}}, $_;
	}
	1;
}#

sub move_file ($)
{#
	# get timestamp from EXIF data
	my ($year, $mon, $mday, $hour, $min, $sec) =
		`exiv2 $_[0]`
		=~ /^Image timestamp : (\d{4}):(\d{2}):(\d{2}) (\d{2}):(\d{2}):(\d{2})$/m
		or die "no exif info for file $_[0]";

	# basedir/shot/YYYY/MM/DD/
	my $dir = $args{basedir}.'/shot/'
		.sprintf '%04d/%02d/%02d', $year, $mon, $mday;
	do_mkdir $dir;

	my $path = "$dir/"
		#.sprintf ('%04d%02d%02d-', $year, $mon, $mday)
		.sprintf ('%02d:%02d:%02d-', $hour, $min, $sec)
		.lc $_[0];

	# move the file to it's new place/name
	my $msg = "mv $_[0] $path";
	if ($args{nop}) {
		print $msg;
	}
	else {
		rename $_[0], $path  or die "mv $_[0] $path: $!";
	}

	return $path;
}#

sub download()
{#
	{# check if disk has enough free space

		my $total_kb = 0;
		foreach (split /\n/, `$args{sudo} gphoto2 -L | grep '^\#'`) {
			chomp;
			my ($num, $name, $size_kb) =
				/\A\#(\d+)\s+([^\s]+)\s+(\d+).*/
				or next;
			$total_kb += $size_kb;
		}

		my @df = split /\s+/, `df -k $args{basedir} | tail -1`;
		my $free_space_kb = $df[3];
		if ($total_kb > 2*$free_space_kb) {
			print "NOT ENOUGH DISK SPACE!";
			return ();
		}
	}#

	# make and change to temporary dir to download files into
	use File::Temp;
	my $download_dir = tempdir (DIR => $args{basedir})  or die $!;
	chdir $download_dir  or die "chdir $download_dir: $!";


	x "$args{sudo} gphoto2 -P";
	my @files = glob '*.*';
	x "$args{sudo} chown $ENV{USER} ".join(' ', @files);

	@files = map { "$download_dir/$_" } @files;
	return \@files;
}#

sub post_process ($)
{#
	my ($count, $total) = (0, scalar @{$_[0]});
	foreach (@{$_[0]}) {
		++$count;
		my $path = $_;

		if (-e $path  or  $args{nop}) {
			my $shot = move_file ($path);
			next if $args{mv};

			if ($shot =~ /^(.*)\.([^\.]+)$/) {
				my ($base, $ext) = ($1, $2);
				my $view = "$base.jpg";
				$view =~ s{/shot/}{/$args{res}/};

				print "$count/$total\n";
				if ($ext eq 'cr2') {
					my $dir = `dirname "$view"`;
					chomp $dir;
					do_mkdir $dir;
					x "nice ufraw-batch --wb=camera --exposure=auto --size=$args{res} --out-type=jpeg --compression=$args{jpeg_quality} --out-path=\"$dir\" \"$shot\"";
				}
				elsif ($ext eq 'jpg') {
					x "nice convert -quality $args{jpeg_quality} -resize $args{res} \"$shot\" \"$view\"";
				}
				elsif ($ext eq 'mpg') {
					if (!$args{nop}) {
						symlink $shot, $view;
					}
					else {
						print "ln -s $shot $view";
					}
				}
				else {
					print "warning: $shot: unknown file type";
				}
			}
		}
		else {
			print STDERR "$path not found";
		}
	}
}#

=nao
sub browse_results (@)
{#
	my %files = @_;

	my %dirs = ();
	$dirs{$files{$_}{dir}} = 1
		foreach keys %files;

	my $common_dir = eval
	{#
		if (scalar keys %dirs == 1) {
			return $dirs{(keys %dirs)[0]};
		}
		else {
			#TODO: find common dir, if any
			return $args{base_dir};
		}
	}#
	;
	if ($common_dir) {
		print "cd \"$common_dir\"";
		$ENV{DISPLAY} and x("$args{file_manager} \"$common_dir/..\" &");
	}
}#
=cut

sub main (@)
{#
	$ENV{DISPLAY} = ':0'  unless defined $ENV{DISPLAY};
	default_args();
	read_args (@ARGV);
	-d $args{basedir}  or die "$args{basedir}: $!";

	my $files = $args{files};
	scalar @{$args{files}}  or $files = download();
	post_process ($files);
	#browse_results $files  if $args{gui_mode};
}#

main(@ARGV);

#}#1
# vim600:fdm=marker:fmr={#,}#:
