#!/usr/bin/perl
sub TODO { die; }
#{#1          comments

=description

# retrieve photos and videos from camera
# uses gphoto2 as backend

=todo

- remove all globals; option to run over existing photos

- ETA

- die if available_disk_space < 2*files_size

- Check existence of required external tools.

- Download to a fixed spool dir, move to right dir later.
  Get date for dir name from exif info (exiv2).

- OSD (maybe external lib to manage output messages in general).

- Optimize by running gphoto2 in interactive shell mode,
  instead of calling it multiple times.
  (Must check if it will release memory after each download.)

=cut


use strict;
use warnings;
$|=1;
$\="\n";


#{#1          parameters

my %args = (

		files => [],
		tag => undef,
		sudo => 'sudo',
		do_gray => 0,

		basedir => '/home/fotos/archive',
		tempdir => '/home/fotos/tmp',
		max_block_mb => 256,
		max_file_mb => 600,
		gray_dir => '../gray',
		keep_temp_files => 1,
		nop => 0,

		width => 1024,
		height => 768,
		jpeg_quality => 80,

		file_managers => [ 'nautilus', 'Thunar', 'pcmanfm', 'ROX-Filer' ],
		file_manager => undef,
);

#{#1          code

#{#2           system utils

sub x($)
{#
	my $cmd = shift;
	print $cmd;
	system( $cmd )  unless $args{nop};
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

	my $msg = "mkdir ($_[0])";
	if ($args{nop}) {
		print $msg;
	}
	else {
		mkdir $_[0]  or die "$msg: $!";
	}
}#

#}#

sub default_args()
{#
	{#  max_block_mb and max_file_mb

		# Guess nice values for memory usage limit based on avaiable memory:
		# max block size (soft limit) = 1/4 system memory
		# max file size (hard limit) = 3/4 system memory
		#TODO: check also if it will fit on available mem+swap

		my $mem_total_kb = 0;
		foreach( file_read( '/proc/meminfo' ) ) {
			if( m/^MemTotal:\s+(\d+)\s+kB$/ ) {
				$mem_total_kb = $1;
				last;
			}
		}

		if( $mem_total_kb ) {
			$args{max_block_mb} = int( (1/4)*$mem_total_kb/1024 );
			$args{max_file_mb}  = int( (3/4)*$mem_total_kb/1024 );
		}
	}#

	{#  width, height

		sub cached_resolution {
			#TODO:  "width %d height %d"  in  ~/etc/var/screen-pixels
			(1024, 768)
		}
		($args{width}, $args{height}) =
			`xwininfo -root` =~ /\bWidth:\s+(\d+)\b.*\bHeight:\s+(\d+)\b/s
			? ($1, $2)
			: cached_resolution();

	}#
}#

sub read_args(@)
{#
	if( scalar @_ == 1 ) {
		$args{source} = shift;
	}
	else {
		while( $_ = shift ) {
			s/^--//;
			if (exists $args{$_}) {
				if (not defined ($args{$_} = shift)) {
					print STDERR "missing argument for $_";
					exit 1;
				}
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
			else {
				print STDERR "unknown arg ($_)";
				exit 1;
			}
		}
	}
	1;
}#

sub file_mkdir($)
{#
	my ($file) = @_;
	-d $args{basedir}  or die "$args{basedir}: $!";

	my ($year, $mon, $mday) =
		`exiv2 $file->{path}`
		=~ /^Image timestamp : \d{4}:\d{2}:\d{2} \d{2}:\d{2}:\d{2}$/
		or die "no exif info for file $file->{path}";

	my $dir = $args{basedir};
	$dir .= '/'.sprintf '%04d-%02d-%02d', $year+1900, $mon+1, $mday;
	$dir .= '.'.$args{tag}  if $args{tag};

	$file->{dir} = $dir;

	do_mkdir $dir;
	$dir .= '/shot';
	do_mkdir $dir;
}#

sub download()
{#
	my ($files, $ranges, $total_kb)  = eval
	{#
		my %files = ();
		my @ranges = ();
		my $total_kb = 0;

		my $range_itr = '';
		my $range_kb = 0;

		my @file_list = eval
		{#
			print "getting file list";

			my $temp_file = '/tmp/foto.pl.list';
			my $cmd;
			if( ! $args{nop} ) {
				$cmd = "$args{sudo} gphoto2 -L | grep '^\#'";
				if( $args{keep_temp_files} ) {
					$cmd .= " | tee /tmp/foto.pl.list";
				}
			}
			else {
				$cmd = "cat $temp_file";
			}

			print $cmd;
			`$cmd`  or die;
		}#
		;

		foreach( split /\n/, @file_list )
		{#  populate @ranges

			chomp;
			my( $num, $name, $size_kb ) =
				/\A\#(\d+)\s+([^\s]+)\s+(\d+).*/
				or next;

			$files{$num} = {
				name => $name,
				size_kb => $size_kb
			};

#TODO

			$total_kb += $size_kb;

			if(-e $name) { # check existing files
				if( file_ok( $files{$num} ) ) {
					print "skiping $name: file exists";

					# skipping breaks ranges
					if($range_itr) {
						#aki
						push @ranges, $range_itr;
						$range_itr = '';
						$range_kb = 0;
					}
					next;
				}
				else { # not ok (too small?), re-download
					print "overwriting $name";
				}
			}

			if( $range_kb + $size_kb > 1024*$args{max_block_mb} ) { # se passou do limite
				if( $range_itr ) {
					#aki
					push @ranges, $range_itr;

					$range_itr = $num; # .'-'.$num ?
					$range_kb = $size_kb;
				}
				else {
					if( $size_kb > 1024*$args{max_file_mb} and not $ENV{FOTO_FORCE} ) {
						print "WARNING: won't download big file $name ($size_kb kb). limit=$args{max_file_mb}MB";
					}
					else {
						print "warning: file $name too big ($size_kb kb)";
						push @ranges, "$num-$num";
					}
					$range_itr = '';
					$range_kb = 0;
				}
			}
			else {
				$range_kb += $size_kb;
				$range_itr = $num;
			}
		}#

		#aki
		push @ranges, $range_itr
			if $range_itr;

		return \%files, \@ranges, $total_kb;
	}#
	;

	{# check if disk has enough free space

		my @df = split /\s+/, `df -k $args{base_dir} | tail -1`;
		my $free_space_kb = $df[3];
		if( $total_kb > 2*$free_space_kb ) {
			print "NOT ENOUGH DISK SPACE!";
			return ();
		}

	}#

	my $count = 0;
	my $step = 0;

	foreach my $range_itr (@$ranges) {
		my ($first, $last) = $range_itr =~ /(\d+)-(\d+)/  or die;
		++$step;
		print "downloading $range_itr of ".(scalar keys %$files)." files, step $step of ".(scalar @$ranges);
		x "$args{sudo} gphoto2 -p $range_itr";
		my @files_to_chown = ();
		for ($first .. $last) {
			my $name = $files->{$_}{name};
			if (-e $name) {
				push @files_to_chown, $name;
				if (file_ok ($files->{$_})) {
					++$count;
					$files->{$_}{path} = "$ENV{PWD}/$name";
				}
				else {
					print "warning: $name too small"
				}
			}
			else {
				print "warning: $name: $!";
			}
		}
		x "$args{sudo} chown $ENV{USER}.users ".join(' ', @files_to_chown);
	}

	return $files;
}#

sub post_process ($)
{#
	my ($files) = @_;

	my ($count, $total) = (0, scalar keys %$files);
	foreach (sort keys %$files) {
		++$count;
		my $name = $files->{$_}{name};
		if (-e $name  or  $args{nop}) {
			if ($name =~ /^(.*)\.([^\.]+)$/) {
				my ($base, $ext) = ($1, lc $2);
				my $shot = "$base.$ext";

				if ($name ne $shot) {
					if(!$args{nop}) {
						rename $name, $shot  or die;
						x "chmod -w $shot";
					}
					else {
						print "mv $name $shot";
					}
				}

				print "$count/$total\n";
				if ($ext eq 'cr2') {
					x "nice ufraw-batch --wb=camera --exposure=auto --size=$args{width}x$args{height} --out-type=jpeg --compression=$args{jpeg_quality} --out-path=\"$args{temp_dir}/..\" \"$shot\"";
				}
				elsif ($ext eq 'jpg') {
					x "nice convert -quality $args{jpeg_quality} -resize $args{width}x$args{height} \"$shot\" \"../$base.jpg\"";
					if ($args{do_gray}) {
						#TODO: move this after this if's, to make gray version of raw images
						do_mkdir $args{gray_dir};
						x "nice convert -colorspace gray -quality 80 -resize $args{width}x$args{height} \"$shot\" \"$args{gray_dir}/$base.jpg\"";
					}
				}
				elsif ($ext eq 'mpg') {
					if (!$args{nop}) {
						symlink "shot/$shot", "../$shot";
					}
					else {
						print "ln -s shot/$shot ../$shot";
					}
				}
				else {
					print "warning: $name: unknown file type";
				}
			}
		}
	}
}#

sub browse_results($)
{#
	my ($files) = @_;

	my %dirs = ();
	$dirs{$files->{$_}{dir}} = 1
		foreach keys %$files;

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

sub main(@)
{#
	$ENV{DISPLAY}  or  $ENV{DISPLAY} = ':0';
	default_args();
	read_args (@ARGV);
	my $files = download();
	post_process ($files);
	browse_results ($files);
}#

main(@ARGV);

#}#1
# vim600:fdm=marker:
