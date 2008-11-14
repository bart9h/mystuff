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

		basedir => $ENV{HOME}.'/fotos',
		dir_fmt => '%04d/%02d-%02d',
		nop => 0,
		sudo => 'sudo',
		max_tasks => 1,
		mv => 0,
		gui_mode => 0,

		self => $0,
		fifo_name => 'download-fifo',

		#file_managers => 'nautilus,Thunar,pcmanfm,ROX-Filer',
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
{#  calculated default values for %args

	#{# res = root window size

	sub cached_resolution {
		#TODO:  "cache in ~/etc/var/screen-pixels
		'1024x768'
	}

	#TODO: use xdpyinfo instead
	$args{res} =
		`xwininfo -root` =~ /\bWidth:\s+(\d+)\b.*\bHeight:\s+(\d+)\b/s
		? "$1x$2"
		: cached_resolution();

	#}#

	#{# max_tasks = number of CPUs

	my $cpu_count = 0;
	foreach (file_read ('/proc/cpuinfo')) {
		++$cpu_count  if /^processor\s*:\s*\d+$/;
	}
	$args{max_tasks} = $cpu_count ? $cpu_count : 1;

	#}#

	# make sure $args{self} is not a relative path,
	# for we'll chdir later (gphoto2 don't have option for that)
	my $pwd = `pwd`;  chomp $pwd;
	$args{self} =~ s{^(\.\.?/)}{$pwd/$1};

	# default file_manager is the first in list
	#$args{file_manager} = (split /,/,$args{file_managers})[0];
}#

sub usage()
{#
	#TODO: better %args, to contain description
	#      (borrow from other script I wrote..)
	print 'arguments and their defaults:';
	foreach (sort keys %args) {
		my $val = $args{$_};
		s/_/-/;
		print '--'.$_.(defined $val ? "=$val" : '');
	}
	exit 0;
}#

sub read_args (@)
{# read cmdline parameters into %args

	my $process_args = 1;
	foreach (@_) {
		if ($process_args) {
			if (/^--$/) {
				$process_args = 0;
				next;
			}
			elsif ($_ eq '--help') {
				usage;
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
		}
		else {
			print "WARNING: $_[0] != $path\n";
		}
		return undef;
	}

	# move the file to it's new place/name
	my $msg = "mv $_[0] $path";
	if ($args{nop}) {
		print $msg;
	}
	else {
		rename $_[0], $path  or die "mv $_[0] $path: $!";
		chmod 0444, $path;
	}

	return $path;
}#

sub process_file ($)
{#
	#  move photo to dir based on exif data
	if (-e $_[0]  or  $args{nop}) {
		my $shot = move_file ($_[0]);
	}
	return if $args{mv};

	{#  convert original photo to jpeg of screen size

		my $shot = $_[0];
		if ($shot =~ /^(.*)\.([^\.]+)$/) {
			my ($base, $ext) = ($1, $2);
			my $view = "$base.jpg";
			$view =~ s{/shot/}{/$args{res}/};

			sub exif ($)
			{#
				local $_ = `exiv2 "$_[0]"`;
				s/$_[0]//m;
				$_;
			}#

			next if -e $view and ($ext eq 'mpg' or exif $shot eq exif $view);

			my $dir = `dirname "$view"`;
			chomp $dir;
			do_mkdir $dir;

			if ($ext eq 'cr2') {
				x "nice ufraw-batch --wb=camera --exposure=auto --size=$args{res} --out-type=jpeg --compression=$args{jpeg_quality} --out-path=\"$dir\" \"$shot\"";
			}
			elsif ($ext eq 'jpg') {
				x "nice gm convert -quality $args{jpeg_quality} -resize $args{res} \"$shot\" \"$view\""
					." && exiv2 insert -l\"`dirname \"$shot\"`\" -S.jpg \"$view\"";
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

}#

sub download_and_post_process()
{#
	{# `gphoto2 -L` to check if disk has enough free space

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

	# create FIFO to comunicate with gphoto2 hook
	x "mkfifo $args{fifo_name}";
	-p $args{fifo_name}  or die "$args{fifo_name}: no such FIFO";

	# call gphoto2 in background
	x "$args{sudo} gphoto2 --hook-script $args{self} -P &";


	chdir $args{_pwd}    or die "chdir $args{_pwd}: $!";
	rmdir $download_dir  or die "rmdir $download_dir: $!";
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

sub gphoto2_hook()
{# handle gphoto2 hook actions

	if ($ENV{ACTION} eq 'download') {

		my $file = $ENV{ARGUMENT};
		x "chown $ENV{USER} \"$file\"; chmod ugo-r \"$file\"";
		my $pipe = $args{fifo_name};
		-p $pipe  or die "$pipe: not a fifo"; #TODO: uncomment

		open PIPE, ">$pipe"  or die "open $pipe: $!";
		print PIPE "`pwd`/$file\n"  or die "write $pipe: $!";
		close PIPE;
	}
}#

my $task_count = 0;
sub process_pipe()
{#  manage $args{max_tasks} parallel mkview() tasks

	sub signal_handler($) { --$task_count  if $_[0] eq 'CHLD' }
	$SIG{CHLD} = \&signal_handler;

	my ($count, $total) = (0, scalar @files);

	open PIPE, $args{fifo_name}  or die "open $args{fifo_filename}: $!";
	while (!eof PIPE) {
		while ($task_count < $args{max_tasks}) {
			local $_ = <>;
			chomp;
			my $file = "$download_dir/$_";

			++$count;
			print "\n$count/$total: $_";

			# launch new task
			++$task_count;
			if (fork == 0) {
				mkview ($file);
				exit 0;
			}
		}
		wait;
	}
	close PIPE;

	wait while ($task_count);

}#

sub import_files()
{#  import files from camera or cmdline

	if (fork == 0) {
		process_pipe();
		exit 0;
	}

	if (exists $args{files}) {
		my $count = scalar @{$args{files}};
		foreach (@{$args{files}}) {
			if (-e $_) {
				post_process ($_);
			}
			else {
				print STDERR "$_ not found";
			}
		}
	}
	else {
	}
}#

sub main (@)
{#
	if (scalar @ARGV == 0 and $ENV{ACTION}) {
		gphoto2_hook();
	}
	else {
		#$ENV{DISPLAY} = ':0'  unless defined $ENV{DISPLAY};
		default_args();
		read_args (@ARGV);
		if ($args{gui_mode}) {
			main_gui();
		}
		else {
			-d $args{basedir}  or die "$args{basedir}: $!";
			import_files();
		}
	}
}#

main(@ARGV);

#}#1
# vim600:fdm=marker:fmr={#,}#:
