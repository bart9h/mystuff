#!/usr/bin/perl
#{#1          comments

=description

# retrieve photos and videos from camera
# uses gphoto2 as backend

=todo

- Check existence of required external tools
  (gphoto2, exiv2, ufraw-batch, convert (or gm), xwininfo).

- Fix ufraw rotation+scale order.

- GUI, or at leasst OSD.

- Show post-processing ETA.

- Run gphoto2 in interactive shell mode, show download progress, ETA.

=cut


#{#1          parameters

use strict;
use warnings;
$|=1;
$\="\n";

my %args = (

		res => '1024x768',
		jpeg_quality => 80,

		basedir => '/home/fotos',
		dir_fmt => '%04d/%02d-%02d',
		nop => 0,
		sudo => 'sudo',
		max_tasks => 1,
		mv => 0,
		gui_mode => 0,

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
	my ($filename, $die) = @_;

	unless (open F, $filename) {
		my $msg = "open($filename): $!";
		$die ? die $msg : warn $msg;
		return undef;
	};

	if (wantarray) {
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


	my $cpu_count = 0;
	foreach (file_read ('/proc/cpuinfo')) {
		++$cpu_count  if /^processor\s*:\s*\d+$/;
	}
	$args{max_tasks} = $cpu_count ? $cpu_count : 1;
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
				print 'arguments and their defaults:';
				foreach (sort keys %args) {
					my $val = $args{$_};
					s/_/-/;
					print '--'.$_.(defined $val ? "=$val" : '');
				}
				exit 0;
				#}#
			}
			elsif (m/^--(..*?)(=(.*))?$/) {
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

		$args{files} = []  if not exists $args{files};
		push @{$args{files}}, $_;
	}
	1;
}#

sub exif2path ($)
{#
	# get timestamp from EXIF data
	my ($year, $mon, $mday, $hour, $min, $sec) =
		`exiv2 $_[0]`
		=~ /^Image timestamp : (\d{4}):(\d{2}):(\d{2}) (\d{2}):(\d{2}):(\d{2})$/m
		or die "no exif info for file $_[0]";

	# basedir/shot/YYYY/MM/DD/
	my $dir = $args{basedir}.'/shot/'
		.sprintf $args{dir_fmt}, $year, $mon, $mday;
	do_mkdir $dir;

	my $name = lc $_[0];  $name =~ s{^.*/([^/]+)$}{$1};
	return "$dir/"
		#.sprintf ('%04d%02d%02d-', $year, $mon, $mday)
		.sprintf ('%02d:%02d:%02d-', $hour, $min, $sec)
		.$name;
}#

sub move_file ($)
{#
	my $path = exif2path ($_[0]);

	# check for duplicated files
	if (-e $path) {
		if (0 == system "cmp \"$_[0]\" \"$path\"") {
			print "skipping $_[0] == $path\n";
			unlink $_[0];
			return $path;
		}
		else {
			print "WARNING: $_[0] != $path\n";
			return '';
		}
	}

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

		if ($total_kb == 0) {
			print "nothing found from the camera";
			return ();
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
	my $download_dir = File::Temp::tempdir ('download-XXXXX', DIR => $args{basedir})  or die $!;
	chdir $download_dir  or die "chdir $download_dir: $!";

	x "$args{sudo} gphoto2 -P";
	my @files = glob '*.*';
	x "$args{sudo} chown $ENV{USER} ".join(' ', @files);

	@files = map { "$download_dir/$_" } @files;
	return ($download_dir, \@files);
}#

my $task_count = 0;
sub post_process ($)
{#

	my @files = ();
	foreach (@{$_[0]})
	{#  move photos to dir based on exif data

		my $path = $_;

		if (-e $path  or  $args{nop}) {
			my $shot = move_file ($path);
			if ($shot) {
				chmod 0444, $shot;
				push @files, $shot;
			}
		}
		else {
			print STDERR "$path not found";
		}
	}#
	return if $args{mv};

	sub mkview($)
	{#  convert original photo to jpeg of screen size

		my $shot = $_[0];
		if ($shot =~ /^(.*)\.([^\.]+)$/) {
			my ($base, $ext) = ($1, $2);
			my $view = "$base.jpg";
			$view =~ s{/shot/}{/$args{res}/};

			next if -e $view and ($ext eq 'mpg' or `exiv2 "$shot"` eq `exiv2 "$view"`);

			my $dir = `dirname "$view"`;
			chomp $dir;
			do_mkdir $dir;

			if ($ext eq 'cr2') {
				x "nice ufraw-batch --wb=camera --exposure=auto --size=$args{res} --out-type=jpeg --compression=$args{jpeg_quality} --out-path=\"$dir\" \"$shot\"";
			}
			elsif ($ext eq 'jpg') {
				x "nice gm convert -quality $args{jpeg_quality} -resize $args{res} \"$shot\" \"$view\""
					." && exiv2 insert -l\"`basename \"$shot\"`\" -S.jpg \"$view\"";
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
	}#

	#{#  manage $args{max_tasks} parallel mkview() tasks

	sub signal_handler($) { --$task_count  if $_[0] eq 'CHLD' }
	$SIG{CHLD} = \&signal_handler;

	my ($count, $total) = (0, scalar @files);
	while (@files) {
		while ($task_count < $args{max_tasks}) {
			++$count;
			print "\n$count/$total";

			# launch new task
			++$task_count;
			my $file = shift @files;
			my $pid = fork;
			if ($pid eq 0) {
				mkview ($file);
				exit 0;
			}
		}
		my $child = wait;
	}

	wait while ($task_count);

	#}#
}#

sub browse_results (@)
{#
=nao
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
=cut
}#

sub main_gui()
{#
	use Gtk2 '-init';

	my $window = Gtk2::Window->new;
	$window->signal_connect (delete_event => sub {Gtk2->main_quit; 1});
	$window->set_title ("foto.pl");
	$window->add (Gtk2::Label->new ('This is starting to get too big for my taste  :('));
	$window->show_all();

	Gtk2->main();
}#

sub main (@)
{#
	$ENV{DISPLAY} = ':0'  unless defined $ENV{DISPLAY};
	default_args();
	read_args (@ARGV);
	if ($args{gui_mode}) {
		main_gui();
	}
	else {
		-d $args{basedir}  or die "$args{basedir}: $!";

		if (exists $args{files}) {
			post_process ($args{files});
		}
		else {
			my ($dir, $files) = download();
			if ($dir) {
				post_process ($files);
				rmdir $dir  or die "rmdir $dir: $!";
			}
		}
	}
}#

main(@ARGV);

#}#1
# vim600:fdm=marker:fmr={#,}#:
