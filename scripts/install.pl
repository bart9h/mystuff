#!/usr/bin/perl
use strict;
use warnings;

#{#  global data

my %g_files = (
	'bash/bashrc' => '.bashrc',
	'bash/Xdefaults.sh' => 'bin/Xdefaults.sh',
	'etc/fluxbox/styles' => '.fluxbox/styles',
	'etc/fluxbox/keys' => '.fluxbox/keys',
	'etc/fluxbox/menu' => '.fluxbox/menu',
	'etc/Xdefaults' => '.Xdefaults',
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
);

#}#

sub main()
{#
	foreach(sort keys %g_files) {
		print "don't know how to install $_\n";
	}
}#

main();

# vim600:fdm=marker:fmr={#,}#:
