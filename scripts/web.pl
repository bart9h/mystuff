#!/usr/bin/perl
use strict;
use warnings;

#{#  <preferences>

# Unless set by --browser argument, or WEB_BROWSER environg variable,
# the first one avaiable from the list bellow will be used.
my @browsers = qw/ links elinks lynx firefox opera /;


# Definitions of search engines.
# The engine can be selected by arguments,
# by the WEB_ENGINE environment variable,
# or by the basename of this program.
my %engines = (
	cpan => {
		description => 'CPAN module',
		args => [ '-c',  '--cpan' ],
		url => 'http://search.cpan.org/search?mode=module&query=',
	},
	def => {
		description => 'Google Define',
		args => [ '-def', '--define' ],
		url => 'http://www.google.com/search?q=define%3A',
	},
	dict => {
		description => 'Dictionary.com',
		args => [ '-d',  '--dictionary' ],
		url => 'http://dictionary.reference.com/search?q=',
	},
	e2 => {
		description => 'Everything2',
		args => [ '-e',  '--everything2' ],
		url => 'http://everything2.com/index.pl?node=',
	},
	ext => {
		description => 'Firefox extension',
		args => [ '-x',  '--firefox-extension' ],
		url => 'https://addons.mozilla.org/search.php?app=firefox&q=',
	},
	fm => {
		description => 'Freshmeat project',
		args => [ '-fm',  '--freshmeat' ],
		url => 'http://freshmeat.net/search/?section=projects&q=',
	},
	google => {
		description => 'Google Web',
		args => [ '-g',  '--google' ],
		url => 'http://www.google.com/search?q=',
	},
	linux => {
		description => 'Google Linux',
		args => [ '-l',  '--linux' ],
		url => 'http://www.google.com/linux?q=',
	},
	imdb => {
		description => 'Wikipedia (portuguese)',
		args => [ '-i', '--imdb' ],
		url => 'http://www.imdb.com/find?s=all&q=',
	},
	img => {
		description => 'Google Images',
		args => [ '-img', '--image' ],
		url => 'http://images.google.com/images?q=',
	},
	pkg => {
		description => 'LinuxPackages.net slackware package',
		args => [ '-p',  '--linux-packages' ],
		url => 'http://www.linuxpackages.net/search_view.php?by=name&name=',
	},
	pt => {
		description => 'Google Portuguese',
		args => [ '-pt', '--google-portuguese' ],
		url => 'http://www.google.com/search?lr=lang_pt&as_q=',
	},
	sf => {
		description => 'Sourceforge project',
		args => [ '-sf', '--sourceforge' ],
		url => 'http://sourceforge.net/search/?type_of_search=soft&words=',
#		url => 'http://sourceforge.net/projects/',  # felling lucky
	},
	slack => {
		description => 'Slackware.com package',
		args => [ '-s',  '--slackware' ],
		url => 'http://slackware.it/en/pb/search.php?v=current&t=1&q=',
	},
	wiki => {
		description => 'Wikipedia (english)',
		args => [ '-w',  '--wikipedia' ],
		url => 'http://en.wikipedia.org/wiki/',  # felling lucky
	},
	wpt => {
		description => 'Wikipedia (portuguese)',
		args => [ '-wpt', '--wikipedia-pt' ],
		url => 'http://pt.wikipedia.org/wiki/',  # felling lucky
	},
);

#}#  </preferences>


sub usage()
{#
	print "Arguments:\n";
	foreach(sort keys %engines) {
		printf "\t%s\n\t\t%s  [%s]\n",
			(join ' | ', @{$engines{$_}->{args}}),
			$engines{$_}->{description},
			$_,
		;
	}
	print <<EOF;
	--browser <browser_name>
		Selects web browser to use.
	--
		Stops argument handling.
		Next arguments will be interpreted as query terms.

The web engine can also be set with the WEB_ENGINE environt variable,
or with the name of this program (make symlinks to diferent names).
Possible values are those in square brackets on the list above.

The web browser can also be set with the WEB_BROWSER environt variable.
If not specified, the first one avaiable on this list will be used:
EOF
	printf "%s\n\n", join ', ', @browsers;
	exit 1;
}#


sub main()
{#
	# parameters
	my $engine;
	my $browser_name;
	my @query;

	# auxiliary hash
	my %arg2engine;
	foreach (keys %engines) {
		foreach my $arg (@{$engines{$_}->{args}}) {
			$arg2engine{$arg} = $_;
		}
	}

	my $check_args = 1;
	while(@ARGV)
	{# interpret parameters
		my $arg = shift @ARGV;

		my $term;
		if($check_args and $arg =~ /^-/) {
			if($arg =~ /^--$/) {
				$check_args = 0;
			}
			elsif($arg =~ /^(--browser)$/) {
				$browser_name = shift @ARGV
					or die 'missing browser argument';
			}
			elsif(exists $arg2engine{$arg}) {
				$engine = $arg2engine{$arg};
			}
			else {
				usage();
			}
		}
		else {
			# build array of query terms
			if($arg =~ s/\ /%20/g) {
				# if arg has space, put " around it
				$arg = "\%22$arg\%22";
			}
			push @query, $arg;
		}
	}#

	usage()  unless @query;

	unless(defined $engine)
	{# check engine definition

		if(exists $ENV{WEB_ENGINE}) {
			$engine = $ENV{WEB_ENGINE};
		}
		else {
			$engine = `basename $0 .pl`;
		}
		exists $engines{$engine} or $engine = 'google';
	}#


	my $browser_bin;
	unless(defined $browser_name)
	{# check browser binary
		if($ENV{WEB_BROWSER}) {
			$browser_bin = `which "$ENV{WEB_BROWSER}"`
				or die;
		}
		else {
			foreach(@browsers) {
				$browser_bin = `which $_ 2> /dev/null`;
				last if $browser_bin;
			}
			unless($browser_bin) {
				die "couldn't find web browser";
			}
		}
	}#
	unless(defined $browser_bin) {
		$browser_bin = `which $browser_name`
			or die;
	}
	chomp $browser_bin;


	# call the browser
	exec $browser_bin, $engines{$engine}->{url}.(join '%20', @query);
}#


main();

# vim600:fdm=marker:fmr={#,}#:
