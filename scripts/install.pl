#!/usr/bin/perl
#{# header
# vim600:fdm=marker:fmr={#,}#:

use strict;
use warnings;
use Data::Dumper;

#}#

#{# global data

my %reqs =
(	#{# required external tools

	# X11
	xosd => { bin => 'osd_cat', deb => 'xosd-bin' },
	xwit => {},

	# tag
	id3v2 => {},
	vorbis => { bin => 'vorbiscomment', deb => 'vorbis-tools' },
	flac => { bin => 'metaflac' },

	# image
	gphoto2 => {},
	ufraw => { bin => 'ufraw-batch' },
	imagemagick => { bin => 'convert' },

);	#}#

my %files =
(	#{#
	'bash/Xdefaults.sh' => 'bin/Xdefaults.sh',
	'bash/bashrc' => '.bashrc',
	'etc/Xdefaults' => '.Xdefaults',
	'etc/fluxbox/keys' => '.fluxbox/keys',
	'etc/fluxbox/menu' => '.fluxbox/menu',
	'etc/fluxbox/styles' => '.fluxbox/styles',
	'etc/inputrc' => '.inputrc',
	'etc/rtorrent.rc' => '.rtorrent.rc',
	'etc/screenrc' => '.screenrc',
	'etc/xorg.conf' => '/etc/X11/xorg.conf',
	'scripts/dif.sh' => 'bin/dif',
	'scripts/path2tag.pl' => 'bin/path2tag.pl',
	'scripts/vimv.sh' => 'bin/vimv',
	'scripts/web.pl' => 'bin/web',
	'util/foto.pl' => 'bin/foto.pl',
	'vim/colors' => '.vim/colors',
	'vim/vimrc' => '.vimrc',
);	#}#

#}#

sub install_files($)
{#
	my $files = shift;
	foreach(sort keys %$files) {
		print "TODO: ln -s $_ $files->{$_}";
	}
}#

sub install_packages(@)
{#
	my $cmd;
	if(-e '/etc/debian_version') {
		my $cmd = `which apt-get`
			or die 'apt-get not found';
		chomp $cmd;
		foreach(@_) {
			$cmd = "sudo $cmd install $_";
			print "$cmd\n";
			system $cmd or die;
		}
	}
	else {
		print "\nYou have to install the following packages:\n".
				join("\n", @_)."\n";
	}
}#

sub missing_packages()
{#
	my @rc;
	foreach(sort keys %reqs) {
		my $bin = ($reqs{$_}->{bin} or $_);
		my $deb = ($reqs{$_}->{deb} or $_);
		my $cmd = `which $bin`;
		if($cmd) {
			print "$deb is ok\n";
			$reqs{$_}->{cmd} = $cmd;
		}
		else {
			push @rc, $_;
		}
	}
	return @rc;
}#

install_files( \%files );
install_packages( missing_packages() );

