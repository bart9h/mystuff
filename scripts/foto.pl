#!/usr/bin/perl
# {{{1        heading

=description

# retrieve photos and videos from camera
# uses gphoto2 as backend

=todo

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


# {{{1        parameters

my %args = (

		dir_desc => undef,
		sudo => 'sudo',
		do_gray => 0,

		basedir => '/home/fotos/archive',
		max_block_mb => 256,
		max_file_mb => 600,
		gray_dir => '../gray',
		keep_temp_files => 1,
		nop => 0,
		file_manager => 'Thunar',

		width => 1024,
		height => 768,
);

$args{dir_desc} = shift  if scalar @ARGV == 1;
sub read_args(@) {
	foreach( @_ ) {
		if( exists $args{$_} ) {
			$args{$_} = shift;
		}
		else {
			print STDERR "unknown arg ($_)";
			exit 1;
		}
	}
}

# Guess nice values for memory usage limit based on avaiable memory:
# max block size (soft limit) = 1/4 system memory
# max file size (hard limit) = 3/4 system memory
#TODO: check also if it will fit on available mem+swap
{
	sub file_read($;$);
	my $mem_total = 0;
	foreach( file_read( '/proc/meminfo' ) ) {
		if( m/^MemTotal:\s+(\d+)\s+kB$/ ) {
			$mem_total = $1;
			last;
		}
	}

	if( $mem_total ) {
		$args{max_file_mb} = int( 3*$mem_total/(4*1024) );
		$args{max_block_mb} = int( $mem_total/(4*1024) );
	}
}

read_args @ARGV;


# {{{1        globals

my $g_list;         # output of gphoto2 -L
my @g_ranges = ();  # list of ranges to download
my %g_files = ();   # file information table (num: name, kb)
my $g_dir;          # dir to save files to


# {{{1        utils

sub file_read($;$)
{
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
}

sub x($)
{
	my $cmd = shift;
	print $cmd;
	system( $cmd )  unless $args{nop};
}

sub file_ok($)
{
	my $file = shift;
	my( undef, undef, undef, undef, undef, undef, undef, $bytes )
			= stat( $file->{name} )  or die "stat( $file->{name} ): $!";
	return( (1024*$file->{size_kb} - $bytes) < 1024 );
}

sub do_mkdir($)
{
	-d $_[0]  and return;

	my $msg = "mkdir( $_[0] )";
	if( $args{nop} ) {
		print $msg;
	}
	else {
		mkdir $_[0]  or die "$msg: $!";
	}
}

sub mkchdir()
{
	-d $args{basedir} or die "$args{basedir}: $!";
	my( undef, undef, undef, $mday, $mon, $year )= localtime;
	$g_dir = sprintf '%s/%04d-%02d-%02d', $args{basedir}, $year+1900, $mon+1, $mday;
	$g_dir .= '.'.$args{dir_desc}  if $args{dir_desc};
	do_mkdir $g_dir;
	$g_dir .= '/shot';
	do_mkdir $g_dir;
	chdir $g_dir  or die "chdir( $g_dir ): $!";
}


# {{{1        gphoto2 interface

sub get_file_list()
{
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
	$g_list = `$cmd`  or die;
}


sub download()
{
	my $count = 0;
	my $step = 0;

	foreach my $range (@g_ranges) {
		my ($first, $last) = $range =~ /(\d+)-(\d+)/  or die;
		++$step;
		print "downloading $range of ".( scalar keys %g_files )." files, step $step of ".(scalar @g_ranges);
		x "$args{sudo} gphoto2 -p $range";
		my @files_to_chown = ();
		for( $first .. $last ) {
			my $name = $g_files{$_}->{name};
			if( -e $name ) {
				push @files_to_chown, $name;
				if( file_ok( $g_files{$_} ) ) {
					++$count;
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
	return $count > 0;
}


# {{{1        collect

sub collect()
{
	my $first = -1;
	my $last;
	my $range_kb = 0;
	my $total_kb = 0;

	foreach( split /\n/, $g_list ) {
		chomp;
		my( $num, $name, $size_kb ) = /\A\#(\d+)\s+([^\s]+)\s+(\d+).*/
			or next;

		$g_files{$num} = { name => $name, size_kb => $size_kb };

#TODO

		my @tmp = split( /\s+/, `df -k $g_dir | tail -1` );
		my $free_space_kb = $tmp[3];

		if( ( $total_kb += $size_kb ) > 2*$free_space_kb ) {
			print "NOT ENOUGH DISK SPACE!";
			@g_ranges = ();
			last;
		}

		if(-e $name) { # check existing files
			if( file_ok( $g_files{$num} ) ) {
				print "skiping $name: file exists";
				if($first != -1) {
					push @g_ranges, "$first-$last";
					$first = -1;
					$range_kb = 0;
				}
				next;
			}
			else { # too small, re-download
				print "overwriting $name";
			}
		}

		if( $range_kb + $size_kb > 1024*$args{max_block_mb} ) { # se passou do limite
			if( $first != -1 ) {
				push @g_ranges, "$first-$last";
				$first = $num;
				$last = $num;
				$range_kb = $size_kb;
			}
			else {
				if( $size_kb > 1024*$args{max_file_mb} and not $ENV{FOTO_FORCE} ) {
					print "WARNING: won't download big file $name ($size_kb kb). limit=$args{max_file_mb}MB";
				}
				else {
					print "warning: file $name too big ($size_kb kb)";
					push @g_ranges, "$num-$num";
				}
				$first = -1;
				$range_kb = 0;
			}
		}
		else {
			$range_kb += $size_kb;
			$first = $num if $first == -1;
			$last = $num;
		}
	}

	push @g_ranges, "$first-$last"
		if( $first != -1 );

	return( @g_ranges ? 1 : 0 );
}


# {{{1        post_process

sub post_process()
{
	my( $width, $height ) = ( 1024, 768 );
#TODO keep cache of this value, in case of xwininfo failing
#     (that is: no X running => use previous geometry)
#     "width %d height %d"  in  ~/var/screen-pixels
	$ENV{DISPLAY}  or  $ENV{DISPLAY} = ':0';
	if( `xwininfo -root` =~ /\bWidth:\s+(\d+)\b.*\bHeight:\s+(\d+)\b/s ) {
		( $width, $height ) = ( $1, $2 );
	}

	my( $count, $total ) = ( 0, scalar keys %g_files );
	foreach( sort keys %g_files ) {
		++$count;
		my $name = $g_files{$_}->{name};
		if( -e $name  or  $args{nop} ) {
			if( $name =~ /^(.*)\.([^\.]+)$/ ) {
				my( $base, $ext ) = ( $1, lc( $2 ) );
				my $shot = "$base.$ext";

				if( $name ne $shot ) {
					if( ! $args{nop} ) {
						rename $name, $shot  or die;
						x "chmod -w $shot";
					}
					else {
						print "mv $name $shot";
					}
				}

				print "$count/$total\n";
				if( $ext eq 'cr2' ) {
					x "nice ufraw-batch --wb=auto --exposure=auto --size=${width}x${height} --out-type=jpeg --out-path=\"$g_dir/..\" \"$shot\"";
				}
				elsif( $ext eq 'jpg' ) {
					x "nice convert -quality 80 -resize ${width}x${height} \"$shot\" \"../$base.jpg\"";
					if( $args{do_gray} ) {
						do_mkdir $args{gray_dir};
						x "nice convert -colorspace gray -quality 80 -resize ${width}x${height} $shot $args{gray_dir}/$base.jpg";
					}
				}
				elsif( $ext eq 'mpg' ) {
					if( ! $args{nop} ) {
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
}


# {{{1        main

sub main()
{
	get_file_list() &&
	mkchdir() &&
	collect() &&
	download() &&
	post_process();
}

main();
print "cd \"$g_dir\"" if $g_dir;
$ENV{DISPLAY} and x("$args{file_manager} \"$g_dir\" &");


#}}}
# vim600:fdm=marker:
