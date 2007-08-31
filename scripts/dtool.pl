#!/usr/bin/perl
#TODO: move search progress status on stderr
#TODO: ordenar colunas no output do search (interface html?)

# ///1  HEADER
##!/usr/bin/perl -U

use strict;
select STDERR; $|=1;
select STDOUT; $|=1;

my $script = readlink($0) or $0;
my $root = $ENV{MLNET_HOME} || '/var/lib/mldonkey';


package dec;
use Socket;
use Data::Dumper;
$Data::Dumper::Terse=1;
$Data::Dumper::Indent=1;


# ///1  LOW LEVEL

my %verbose = (raw=>0, url=>0, load=>0, status=>1, );

#my $stream = [];
#sub stream($) { @$stream = unpack "C*", shift }
#sub b($) { splice @$stream, 0, shift }

my $stream = '';
my $stream_offset = 0;
sub stream($) {
	$stream = shift;
	#print STDERR "stream ", length($stream), " bytes\n";
	$stream_offset=0
}
sub b($) {
	my $off = $stream_offset;
	my $len = shift;
	$stream_offset+=$len;
	unpack "C*", substr $stream, $off, $len if $len>0;
}


sub bin($) { pack "C*", b(shift) }
sub i32() { unpack "i", pack "C*", b(4) }
sub i16() { unpack "s", pack "C*", b(2) }
sub i8() { (b(1))[0] }
sub str() { bin(i16) } #size16,string #TODO check size (as len below)
sub h128() { join "", map {sprintf "%02x", $_} b(16) }

sub addr($) {
	my ($paddr) = @_;
	my($port, $iaddr) = sockaddr_in($paddr);
	my $host = inet_ntoa($iaddr);
	($host, $port)
}


# ///1  MID LEVEL

our %tag_name = (
	0x01  => 'name',
	0x02  => 'size',
	0x03  => 'type',
	0x04  => 'format',
	0x08  => 'transfered',
	0x09  => 'gap_start',
	0x0A => 'gap_end',
	0x0B => 'description',
	0x0C => 'ping',
	0x0E => 'priority',
	0x0F => 'port',
	0x11 => 'client', #version
	0x12 => 'temp',
	0x15 => 'availability'
);

#my $debug=0;
sub tag(;$) {
	my $meta = shift || {};
	my $type     = i8;
	my $name     = str;
	my $value;

	($type == 1) && ($value = h128);
	($type == 2) && ($value = str);
	($type == 3) && ($value = i32);

	my $code = ord($name);
	$name = exists($tag_name{$code}) ? $tag_name{$code} : sprintf("0x%02x", $code) if($code<32);

	$meta->{$name} = $value;
	$meta
}


sub tag_list(;$) {
	my $meta = shift || {};
	my $len = i32;
	if($len > 64 || $len < 0) { #bail out
		warn sprintf "abnormal tag count %d (%08x) [file offset %d]",
			$len, $len, $stream_offset;
	} else {
		foreach  (1..$len) {
			tag $meta;
		}
	}
	$meta
}

sub server(;$) {
	my $meta = shift || {};
	$meta->{addr} = inet_ntoa bin 4;
	$meta->{port} = i16;
	tag_list $meta;
	$meta
}

sub server_list() {
	my @server;
	my $len = i32;
	foreach  (1..$len) {
		push @server, server;
	}
	scalar [@server]

}

sub filehash(;$) {
	my $meta = shift || {};
	i32; #?? maybe a date(30 a7 2f 3d), sometimes zeroed (0000 0000)
	$meta->{hash} = h128;
	my $len = i16;
	if($len > 90 || $len < 0) { #bail out
		die sprintf "abnormal chunk count %d (%08x) [file offset %d]",
			$len, $len, $stream_offset;
	}
	my $id = 0;
	foreach  (0..$len-1) {
		$meta->{chunkhash}->{$_} = h128;
	}
	tag_list $meta;
	$meta
}

sub filehash_list() {
	my @hash;
	my $len = i16;
	if($len > 100000 || $len < 0) { #bail out
		die sprintf "abnormal file count %d (%08x) [file offset %d]",
			$len, $len, $stream_offset;
	}
	i16; #?? 00 00
	my $bak;
	foreach  (0..$len-1) {
		$bak = $stream_offset;
		start:
		eval {
			push @hash, filehash;
		};
		if($@) {
			$stream_offset = ++$bak;
			print STDERR "ERROR: rescanning at offset $stream_offset\n";
			goto start;
		}

#		print STDERR "$_/$len $hash[$_]->{name}\n";
#		$debug=1 if $_ == 160 ;

#		print Dumper($hash[$_]);
	}
	scalar [@hash]

}


# ///1  TOP LEVEL

sub ext_result_udp(;$) {
	my $meta = shift || {};
	b(2); # magic "e3" + cmd "99"
	$meta->{hash} = h128;
	b(6); # unknow
	tag_list $meta;
	$meta
}


sub server_met() {
	b(1); #magic "e0"?
	server_list
}

sub known_met() {
	b(1); #magic "e0"?
	eval { filehash_list } || []
}

#FIXME this function uses different interface. its bad.
#FIXME dec:: => $meta   = func($meta,$stream)
#FIXME cod:: => $stream = func($meta,$stream)
sub p(%) {
	my %opt = @_;
	my $default='meta';
	$opt{meta}   ||= {};
	$opt{stream} ||= $stream;
	foreach  (grep {$_ ne 'meta' && $_ ne 'stream'} keys %opt) {
		$opt{$default}->{$_} = $opt{$_}
	}
	($opt{meta}, $opt{stream})
}

sub url_server(%) {
	my ($m,$s) = p(@_);
	m!ed2k\:/{0,2}\|server\|(.*?)\|(.*?)\|!;
	$m->{addr}=$1;
	$m->{port}=$2;
	$m
}


# ///1  package cod
#############################################################

package cod;
use Socket;

my $stream = [];
sub stream($) {
	my $data = shift;
	if($data) {
		@$stream = unpack "C*", $data;
	} else {
		return pack "C*", 	@$stream;
	}
}

sub b($) { push @$stream, $_[0]; $_[0] }

sub bin(@) { b pack "C*", @_ }
sub i32($) { b pack "i", shift }
sub i16($) { b pack "s", shift }
sub i8($)  { b chr(shift) }
sub str($)  { local $_=shift; b i16(length $_).$_  } #size16,string
sub h128($) { local $_=shift; s/[a-f0-9]{2}/chr hex $&/ige; b $_ }

#TODO gather this xdump with UNIVERSAL debug and make a cool Debug.pm
sub hexdump($) {
	my @dump;
	my $word_pattern = '[ \w\.\-\_]{3,}';
	foreach  (split /($word_pattern)/, shift) {
		if(/$word_pattern/) {
			push @dump, "'$_'";
		} else {
			push @dump, map {sprintf "%02X", $_} unpack "C*", $_;
		}
	}
	"@dump"
}

sub addr($$) {
	my ($host, $port) = @_;
	my $iaddr = inet_aton($host)    || die "unknown host";
	my $paddr = sockaddr_in($port, $iaddr);
	$paddr;
}

our %tag_code = reverse %dec::tag_name;

#TODO meta tag type=0?
sub tag($$$) {
	my %tag_type = (
		'hash'   => 1,
		'h128'   => 1,
		'string' => 2,
		'str'    => 2,
		'int'    => 3,
		'int32'  => 3,
		'i32'    => 3,
	);

	my $type  = shift; #str
	my $name  = shift;
	my $value = shift;

	$type = exists($tag_type{$type}) ? $tag_type{$type} : $type;
	$name = exists($tag_code{$name}) ? chr($tag_code{$name}) : $name;

	($type == 1) && ($value = h128($value));
	($type == 2) && ($value = str($value));
	($type == 3) && ($value = i32($value));

	i8($type).str($name).$value
}

sub tag_list($) {
	my $meta = shift;
	my $len = scalar keys %$meta;
	my $data = i32($len);
	foreach  (keys %$meta) {
		$data .= tag(
			$meta->{$_}->{type},
			$_, $meta->{$_}->{value}
		);
	}
	$data
}

#usr/sbin/tcpdump -c 100 -l -xa -s 2048 udp port 32771|tee -a dump
#usr/sbin/tcpdump -c 100 -l -xa -s 2048 udp port 4665|tee -a dump
#194.97.40.162:4227 <- E3 98 01 0A 00 'Ashes Time' 02 05 00 'video' 01 00 03

sub udp_ext($;$) {
	my ($search,$type) = @_;
	unless($type) { #Any
		bin(0xe3,0x98).
		bin(0x01).str($search);
	} else {
		$type =~ s/^(.)(.*)$/uc($1).lc($2)/e; # Video
		bin(0xe3,0x98).
		bin(0x00,0x00).tag('str',$type,bin(3)).
		bin(0x01).str($search);
	}
}
sub url_escape($) {
	local $_ = shift;
	s/[^a-z0-9]/sprintf "%%%02x", (ord $&)/gie; $_
}

sub url_file($) {
	my $meta = shift;
	#sprintf "ed2k://|file|%s%s|%d|%s|", (
	sprintf "ed2k://|file|%s|%d|%s|", (
		#url_escape($meta->{name}),
		$meta->{name},
		$meta->{size},
		$meta->{hash},
	);
}

sub url_server($) {
	my $meta = shift;
	sprintf "ed2k://|server|%s|%d|", (
		$meta->{addr},
		$meta->{port},
	);
}

sub _label($@) {
	my $wildcard = shift;
	my $label = "";
	while(scalar(@_) >= 2) {
		my $type    = lc shift;
		my $keyword = lc shift;
		$keyword =~ s/[\s\.]+/_/g;

		unless($wildcard) {
			$label .= "$keyword" . ($type =~ /^Any/i ? "" : "-$type") . ",";
		} else {
			$label .= "*".$keyword."*" . ($type =~ /^Any/i ? "" : "-$type") . ",";
			# FIXME this expression may fail (keyword*-type may overlap other types)
		}
	}

	unless($wildcard) {
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
		$label .= sprintf "%4d%02d%02d_%02d%02d", 1900+$year,$mon+1,$mday,$hour,$min;
		$label .= ".txt";
	} else {
		$label .= "*";
	}

	$label
}

sub label(@) { _label(0,@_) }
sub label_wildcard(@) { _label(1,@_) }


# ///1  package main
#############################################################
package main;

my $quit = 0;
use POSIX qw(tcgetpgrp isatty setgid setuid);
sub can_output() { getpgrp(0) == tcgetpgrp(1) }
sub can_output_pipe() { !isatty(fileno(STDOUT)) || getpgrp(0) == tcgetpgrp(1) }
sub isbatch() { !isatty(fileno(STDOUT)) }

use Data::Dumper;
$Data::Dumper::Terse=1;
$Data::Dumper::Indent=1;

# FIXME lock, to avoid multiple instances mixing results

use IO::Socket;
use IO::Select;
my ($udp, $sel);
sub get_udpsel() {
	unless($udp) {
		$udp = IO::Socket::INET->new(
		Proto    => "udp",
		#LocalPort => "4666", #should be any
		Reuse=>1
		) || die "udp: $!\n";
		$sel = IO::Select->new;
		$sel->add($udp);
	}
	($udp,$sel)
}
sub udp() { (get_udpsel())[0] }
sub sel() { (get_udpsel())[1] }


sub calc_hash($) {
	my $file = shift;
	my $meta = {
		name => $file,
		size => -s $file,
	};
	require Digest::MD4;

	open F, $file or die "open: $file: $!";
	binmode F;
	my $metabuf;
	my $buf;
	my $len = 9728000;
	my $id=0;
	my $last_id=(-s $file)/$len;
	my $r;
#	printf STDERR "calculating hash: $file\n";
	local $|; $|=1;
	do {
		$r = read F, $buf, $len;
		$meta->{chunkhash}->{$id} = Digest::MD4::md4_hex($buf);
#		printf STDERR "chunk %04d: %32s  %7d bytes\n",
#			$id, $meta->{chunkhash}->{$id}, length($buf);
		printf STDERR "%3d%%\r", 100*$id/$last_id if $last_id;
		$metabuf .= Digest::MD4::md4($buf);
		$id++;
	} while($r == $len);
	$meta->{hash} = scalar(keys %{$meta->{chunkhash}}) == 1 ?
		$meta->{chunkhash}->{0} : Digest::MD4::md4_hex($metabuf);
#	printf STDERR "file md4 hash: %32s\n", $meta->{hash};

	$meta
}

sub load_server_met(;$) {
	my $file = shift || "server.met";
	print STDERR "loading serverlist from '$file' ...\n" if($verbose{load});
	open(SV, $file) or die "open: $file: $!\n";
		binmode SV;
		local $/; undef $/;
		dec::stream(scalar <SV>);
	close SV;

	dec::server_met;
}

sub load_server_ini(;$) {
	my $file = shift || "servers.ini";
	my $sv = [];
	print STDERR "loading serverlist from '$file' ...\n" if($verbose{load});
	open(SV, $file) or die "open: $file: $!\n";
		local $/; undef $/;
		local $_ = scalar <SV>;
		#HACK to fix servers with 2ips!
		s/66\.111\.54\.51/66\.111\.54\.50/msg;
		s/212\.122\.69\.246/212\.122\.68\.66/msg;
		#FIXME check if server_network = Donkey
		s/server_addr = \("?(\d+\.\d+\.\d+\.\d+)"?, (\d+)\)/push @$sv, {addr=>$1,port=>$2}; $&/msgie;
	close SV;

	$sv;
}

sub load_known_met(;$) {
	my $file = shift || "known.met";
	print STDERR "loading known hashes from '$file' ...\n" if($verbose{load});
	open(KN, $file) || die "open: $file: $!\n";
		binmode KN;
		local $/; undef $/;
		dec::stream(scalar <KN>);
	close KN;

	dec::known_met;
}


my $min_status_print_interval = .5;
my $last_status_print_time = 0;
sub print_status_bar($$;$) {
	return unless ($verbose{status} && can_output());
	my ($result, $response_count, $force_print) = @_;

	my $time = time;
	return if($last_status_print_time+$min_status_print_interval>$time);
	$last_status_print_time = $time;

	# TODO dont recalc every time, make global and move to recv callback
	my $max_resp_per_sv = 0;
	my $num_sv_resp = 0;
	foreach my $a (grep /^[^\*]/, keys %$response_count) {
	foreach my $p (keys %{$response_count->{$a}}) {
		$num_sv_resp ++;
		$max_resp_per_sv = $response_count->{$a}->{$p}
			if $max_resp_per_sv < $response_count->{$a}->{$p};
	} }

	printf STDERR "[%d/%d%s(%d) sv:%d/%d/%d(%d)]\r", (
		scalar %$result,
		$response_count->{'*'},
		$response_count->{'*max'} ? "/$response_count->{'*max'}" : "",
		%$result ? $result->{(sort {$result->{$b}->{av} <=> $result->{$a}->{av}} keys %$result)[0]}->{av} : 0,

		$num_sv_resp,
		scalar keys %{$response_count->{'*sv'}},
		$response_count->{'*svmax'},
		$max_resp_per_sv,
	);
}

sub send_search_ext($$;$) {
	my ($sv, $search, $type) = @_;
	my ($host, $port) = ($sv->{addr}, $sv->{port}+4); # udp: tcp_port+4

	my $req  = cod::udp_ext $search,$type;

	defined(udp->send($req, 0, cod::addr($host,$port))) || warn "send $host:$port: $!";
	printf STDERR "%s:%d <- %s\n", (
		$host,$port, cod::hexdump($req) ) if($verbose{raw});
}

my $listen_block_count=0;
sub listen_search_ext_result($$$$) {
	my ($type, $response_count, $result, $timeout) = @_;

	my $min_timeout = .01;
	if($timeout < $min_timeout) {
		$timeout = ($listen_block_count % int($min_timeout / $timeout)) == 0 ?  $min_timeout : 0;
	}

	$listen_block_count++;
	while(sel->can_read($timeout)) {
		my $resp;
		my $resp_len =  2048;
		udp->recv($resp, $resp_len);
		printf STDERR "%s:%d -> %s\n", (
			dec::addr(udp->peername),
			cod::hexdump($resp)) if($verbose{raw});


		dec::stream($resp);

		my $meta = dec::ext_result_udp;

		@{$meta}{qw{addr port}} = (dec::addr(udp->peername));
		$meta->{port} -= 4; #tcp: udp-4


#		if($type && lc $meta->{type} ne lc $type) {
#			# why doe this happen? buggy server?
#			# i missed something at the protocol?
#			print STDERR "wrong type! ($meta->{type} != $type)";
#			return
#		}


		my $r = $result->{$meta->{hash}} ||= {};
		my $av = $meta->{availability};
		$r->{hash} = $meta->{hash};
		$r->{size} = $meta->{size};
		$r->{server}->{$meta->{addr}}->{$meta->{port}} += $av;
		$r->{name}->{$meta->{name}} += $av;
		$r->{av} += $av;

		$response_count->{$meta->{addr}}->{$meta->{port}}+=$av;
		$response_count->{'*'}+=$av;

#		$result
#			->{$meta->{hash}}
#			->{$meta->{name}}
#			->{$meta->{addr}}
#			->{$meta->{port}}
#				 = $meta;

#			push @{
#				$result
#					->{$meta->{hash}}
#					->{$meta->{name}}
#				}, $meta;


		print STDERR cod::url_server($meta),
			($response_count->{$meta->{addr}}->{$meta->{port}} > 1 ?
			" ($response_count->{$meta->{addr}}->{$meta->{port}})":""),
			"           \n" if($verbose{url});
		print STDERR cod::url_file($meta),"\n" if($verbose{url});

		print_status_bar($result, $response_count, 1);

	}
}

sub default($$$) {
	my ($hash, $key, $default) = @_;
	exists($hash->{$key}) ? $hash->{$key} :
		(ref($default) eq 'CODE' ? &$default() : $default)
}

sub extended_search(%) {
	my %opt = @_;
	my $text               = $opt{text};
	my $type               = $opt{type} =~ /^(?:any|all|ever)/i ? undef : $opt{type};
	my $result             = $opt{result} || {};
	my $server_list        = $opt{'server_list'};
	my $delay_per_server   = default(\%opt, 'delay_per_server', 5);
	my $delay_at_end       = default(\%opt, 'delay_at_end', 90);
	my $max_response_count = default(\%opt, 'max_response', 100);
	my $max_server_retry   = default(\%opt, 'max_retry', 5);
	my $min_users          = default(\%opt, 'min_users', 0);
	my $allow_no_users     = default(\%opt, 'allow_no_users', 1);

	# server list
	eval { $server_list = load_server_met($server_list) }
		if(!ref($server_list) and (!$server_list or $server_list =~ /\.met$/i));
	eval { $server_list = load_server_ini($server_list) }
		if(!ref($server_list) and (!$server_list or $server_list =~ /\.ini$/i));
	die "no server list available (use server_list=>'my.server.met')"
		unless(ref($server_list));


	my $response_count={'*'=>0, '*max'=>$max_response_count,
	                    '*sv'=>{}, '*svmax'=>scalar @$server_list};


	#print "\n##################################################\n";
	#print "SEARCH servers=",(scalar @$server_list),"; type=$type; text=$text;\n";

	my $active;
	do {
		$active=0;
		foreach my $sv (sort {$b->{users} <=> $a->{users}} @$server_list) {
			return if $quit;

			$sv->{retry}++;
#			print Dumper $sv;
			next if(exists $response_count->{$sv->{addr}}->{$sv->{port}}); #retry if no response
			next if($sv->{retry} > $max_server_retry); # give up if retried too much
			next if($min_users && $sv->{users} && $sv->{users} < $min_users); # bypass small servers
			next unless($allow_no_users || $sv->{users}); # if no users specified, allow or not?
			last if($max_response_count && $response_count->{'*'} >= $max_response_count); # quit if enough responses

			print STDERR
				cod::url_server($sv),
				($sv->{retry}>1?" (#$sv->{retry})":""),
				($sv->{users} || $sv->{files}?" [users=$sv->{users}; files=$sv->{files}; ]":""),
				"           \r" if($verbose{url});

			$response_count->{'*sv'}->{$sv}=undef; #HACK

			send_search_ext($sv, $text, $type);

			listen_search_ext_result($type, $response_count, $result, $delay_per_server);

			print_status_bar($result, $response_count);

			$active = 1;
		}
	} while($active);

	print_status_bar($result, $response_count, 1);

	listen_search_ext_result($type, $response_count, $result, $delay_at_end)
		unless($max_response_count && $response_count->{'*'} >= $max_response_count);

	print_status_bar($result, $response_count, 1);


	$result;
}

sub do_chdir($)
{
	my $dir = shift;
	#print STDERR "chdir($dir)\n";
	chdir $dir or die "chdir($dir): $!";
}


# ///1  MAIN
###########################################################################

warn "usage: \n" unless @ARGV;
my $cmd = shift;
$cmd = '' if $cmd =~ /^-/;


# ///2  search

my $type_pattern = 'any|video|audio|image|pro|doc|col'; #program, document, collection
warn <<EOF unless $cmd;
    search <type> '<keyword> [<keyword> ...]' [<type> '<keywords>']  >> links.txt
    <type> <keyword>[.<keyword>] [<type> <keyword>[.<keyword>]]  >> links.txt
        the types are $type_pattern
	keywords may be dot-separated to avoid quotings
        a record is stored in ./search/ for future reference
        WARN: the 1st keyword is whole-word the others are substrings (?!)
EOF

if($cmd =~ /^s(earch)|$type_pattern/i) { # search on multiple servers
	do_chdir $root;
	my $fast = shift @ARGV if $ARGV[0] =~ /^-(?:fast|quick|nodelay)$/; # HACK undocumented
	unshift @ARGV, $cmd if($cmd =~ /^$type_pattern$/i);

	my $label = cod::label(@ARGV);

	$SIG{'INT'} = sub { $quit = 1 };

	my $result = {};
	while (@ARGV >= 2)
	{
		last if $quit;

		my $type = shift(@ARGV);
		my $text = shift(@ARGV); $text =~ s/\./ /g; #dot to space
		extended_search(
			result=>$result,
			type=>$type,
			text=>$text,
			max_retry=>isbatch() || $fast ? 1 : 2,
			delay_per_server=>!isbatch() || $fast ? .02 : .2,
			delay_at_end=>$fast ? 5 : 15,
			max_response=>0,
		);

	}

	$$SIG{'INT'} = 'DEFAULT';

	unless($fast) { # HACK
		print STDERR "\n$0: search $label\n  finished in background (fg to see results)...\n\n" unless (can_output_pipe());
		until(can_output_pipe()) { sleep 1; }
	}

	#print "\n\n",('#' x 60),"\n\n";

	if(values %{$result}) {
		mkdir "search", 0777;
		open F, ">search/$label" or die "open: search/$label: $!";
		print F "{\n";
		foreach my $r (sort {$a->{av} <=> $b->{av}} values %{$result}) {
			next if $r->{av} >= 1000;
			print F "'$r->{hash}' => ",Dumper($r),",\n";
			$r->{name} = (
				#sort { length($b) <=> length($a) }
				sort {$r->{name}->{$b} <=> $r->{name}->{$a}}
				keys %{$r->{name}}
			)[0];
			printf "%s %.2fMb |%d\n", cod::url_file($r), $r->{size}/1024/1024, $r->{av};
		}
		print F "}\n";
		close F;
	}

	#TODO make constants with the appropriate values for type (TYPE_VIDEO, TYPE_AUDIO)
	#TODO write results in a log, each result in a Dump {}, later process for hashes
	#TODO get % online and availability of the most common, most rare, and average part
}


# ///2  result

warn <<EOF unless $cmd;
    result ./search/keyword*.txt  > ed2k_links.txt
    result search <type> '<search>' [<type> '<search>']  > ed2k_links.txt
    r <type> '<search>' [<type> '<search>']  > ed2k_links.txt
        convert perl structure with search results into ed2k links
EOF

if($cmd =~ /^r(esult)?/i) { # merge and convert search result into ed2k links
	my $out = {};

	my @file = ();
	if($ARGV[0] =~ /^s(earch)?|$type_pattern/i) {
		shift if($ARGV[0] =~ /^s(earch)?/i);
		do_chdir $root;
		push @file, glob("search/".cod::label_wildcard(@ARGV));
	} elsif(@ARGV) {
		push @file,
			map {-f $_ ? $_ : ()}
			map {( glob("$_"), glob("search/$_") )} @ARGV;
	} else {
		my $f = `ls --sort=time $root/search/ | head -1`;
		chomp $f;
		push @file, $f;
	}

	foreach my $file (@file) {
		print STDERR "merging $file ...\n";
		my $in = do $file;
		foreach my $hash (keys %$in) {
			my $i = $in->{$hash};
			my $o = $out->{$hash} ||= {};
			$o->{hash} = $i->{hash};
			$o->{size} = $i->{size};
			$o->{av} += $i->{av}; # should i average availability?
			foreach my $name (keys %{$i->{name}}) {
				$o->{name}->{$name} +=
					$i->{name}->{$name};
			}
			foreach my $host (keys %{$i->{server}}) {
			foreach my $port (keys %{$i->{server}->{$host}}) {
				$o->{server}->{$host}->{$port} +=
					$i->{server}->{$host}->{$port};
			} }
		}
	}
	foreach my $r (sort {$a->{av} <=> $b->{av}} values %$out) {
		print F "'$r->{hash}' => ",Dumper($r),",\n";
		$r->{name} = (
			#sort { length($b) <=> length($a) }
			sort {$r->{name}->{$b} <=> $r->{name}->{$a}}
			keys %{$r->{name}}
		)[0] if ref($r->{name}) eq 'HASH';
		printf "%s %.2fMb |%d\n", cod::url_file($r), $r->{size}/1024/1024, $r->{av};
	}
}


warn "\n" unless $cmd; ############################

# ///2  hash

warn <<EOF unless $cmd;
    hash <1.part> [<2.part>]  > hash.txt
        generate the md4 hashs for the segments and the whole file
EOF

if($cmd =~ /^hash/i) { # calculate hash of .part files
	#print Dumper calc_hash('/data/a.zed.and.two.noughts.dvdivx5.(1985).square.avi');
	print "[\n";
	foreach (@ARGV) {
		my $hash = calc_hash($_);
		print "  ", Dumper($hash),",\n";
		print STDERR cod::url_file($hash),"\n";
	}
	print "]\n";
}


# ///2  known

warn <<EOF unless $cmd;
    known <known.met> [<known.met.2>]  > known.txt
        read and recover known.met, then output a perl structure [DEPRECATED]
EOF

if($cmd =~ /^known/i) { # recover known met
	my $known={};
	foreach my $f (@ARGV) {
		foreach my $k (@{load_known_met($f)}) {
			next if exists $known->{$k->{hash}};
			$known->{$k->{hash}} = $k;
		}
	}
	printf STDERR "%d unique hashes on known met\n", scalar keys %$known;

	$Data::Dumper::Indent=0;
	print "[\n";
	foreach my $k (	values %$known ) {
		print "  ", Dumper($k), ",\n";
	}
	print "]\n";
}


# ///2 match

warn <<EOF unless $cmd;
    match known.txt hash.txt
        cross the output of the previous cmds (TODO gen .part.met) [DEPRECATED]
EOF

if($cmd =~ /^match/i) { # match .part hashs with known.met data
	my $known = do shift(@ARGV);
	my $hash  = do shift(@ARGV);
	#foreach  (sort {$a->{name} cmp $b->{name}} @$known) {
	#	printf "%32s %4d %s \n", $_->{hash}, $_->{size}/1024/1024, $_->{name};
	#}
	foreach my $h (@$hash) {
		foreach my $k (@$known) {
			foreach my $i (keys %{$h->{chunkhash}}) {
				#$h->{candidate}->{$k} ++ if $k->{chunkhash}->{$i} eq $h->{chunkhash}->{$i};
				$h->{candidate}->{$k} = $k if $k->{chunkhash}->{$i} eq $h->{chunkhash}->{$i};
			}
		}
		printf "%32s %4d %s\n", $h->{hash}, $h->{size}/1024/1024, $h->{name};
		foreach my $k (values %{$h->{candidate}}) {
			printf "%32s %4d %s\n", $k->{hash}, $k->{size}/1024/1024, $k->{name};
		}
	}

	# TODO rebuild .part.met files
}

warn "\n" unless $cmd; ############################


# ///2  fetch

use LWP::UserAgent;
use HTTP::Cookies;
use URI::URL;
use HTTP::Request::Common;

#    filenexus [<user> [<pass>]] < thread_links.txt  > ed2k_links.txt # old
warn <<EOF unless $cmd;
    fetch < thread_links.txt  > ed2k_links.txt
        fetch ed2k links from filenexus/sharereactor release urls [DEPRECATED]
EOF

if($cmd =~ /^fetch/i) { # login and fetch ed2k links from filenexus thread links
#	my $fn_oldsite = "http://www.filenexus.com/forum";
	my $fn_site = "http://www1.filenexus.com:81/forum";
	my $sr_site = "http://www.sharereactor.com";
	my $ua = LWP::UserAgent->new(
#			cookie_jar=>HTTP::Cookies->new,  # not required anymore?
			agent=>'Mozilla/5.001 (windows; U; NT4.0; en-us) Gecko/25250101',
			timeout=>45,
	);

	if(0) { # not required anymore?
		$|=1;
		my $user = shift(@ARGV);
		my $pass = shift(@ARGV);
		<>; # ? cygwin bug?
		unless ($pass) {
			print STDERR "pass: ";
			$pass = <>;
			chomp $pass;
		}
		print STDERR "login ($user:$pass)...\n";
	#	my $r = $ua->request(POST "$old_site/login.php", [ #old
		my $r = $ua->request(POST "$fn_site/index.php?act=Login&CODE=01", [
				username=>$user,
				password=>$pass,
				login=>'Login',
				autologon=>'',
				redirect=>'',
			]);
		die "login failed: ",$r->code," ",$r->message
			unless $r->code == 200 || $r->code == 302;
	}

	print STDERR "waiting for urls to fetch...\n";
	my %visited;
	sub print_new($) { print "$_[0]\n" unless $visited{$_[0]}++; }
	sub fetch_url($);
	sub fetch_url($) {
		my $url = shift;
		my $retry=10;
		do {
			print_new $url;
			my $r = $ua->request(GET (URI::URL->new($url)));
			if($r->code == 200) {
				my $all=0;
				for(split /\n/, $r->content) {
					s{&#(\d+);}{chr $1}gie;
					s{ed2k:/*\|file\|[^\|]{1,256}\|\d+\|[a-f0-9]{1,32}\|}{print_new $&; $&}gie;
					s{http:/*(?:\w+\.)?imdb.com/[\/\_\-\?\=\&a-z0-9]+}{print_new $&; $&}gie;
					s{javascript:downloadrelease\((\d+)\);}{$all=1; fetch_url "$sr_site/downloadrelease.php?id=$1"; $&}gie;
					s{download\.php\?id=(\d+)}{fetch_url "$sr_site/download.php?id=$1"; $&}gie unless $all;
				}
				return;
			} else {
				warn $r->code, " ", $r->message if $retry==1;
			}
		} while (--$retry>0);
	}
	while(<>) { #<DATA>
		chomp;
		next unless s/^\s*(http\S+).*?$/$1/; #url only
		sleep 1; # aesthetic
		fetch_url $_;
		print "\n";
	}

	if(0) { # not required anymore?
		print STDERR "logout...\n";
		$ua->request(GET
				(URI::URL->new('$fn_site/login.php?logout=true')));
	}

	print STDERR "\n";
}


# ///2  vd / view / dl / down / temp

warn <<EOF unless $cmd;
    vd [<ini-backup.tar.gz> ...] [mini|med|full] [all] [nocolor]
        view downloads. like edonkey internal command, but more [mlnet]
EOF

if($cmd =~ /^(?:vd|view|dl|down|temp)/i)
{

	my ($tar) = grep /\.(?:tar|tgz)\b/, @ARGV;
	my ($setup) = grep /^(?:mini|med|full|link)/, @ARGV;
	my ($all) =  grep /^(?:all)/, @ARGV;
	my ($nocolor) =  grep /^(?:nocolor)/, @ARGV;

	do_chdir $root unless $tar;

	#print STDERR "reading files.ini...\n";
	open F, $tar ? "tar xOzf $tar files.ini |" : 'files.ini' or die $!;
	undef $/;
	my $content = <F>;
	close F;

	my @d = ();

	die "no files" unless $content =~ /files = \[(.*)\]/s;
	$content = $1;
	while ($content =~ /{(.*?)};/gs) {
		local $_ = $1;
		s/\r//msg;
		my $id = 1+scalar(@d); # XXX NOT THE SAME AS TELNET'S
		my $hash = /file_md4 = \"?([0-9A-F]+)\"?$/ms ? $1 : '';
		my ($name,@user) = /file_filename = "(?:(.*?)\@\@)?(.*)"/ ?
			($2, split/,/, $1 || '-') : die "noname @".$id;
		my $size  = /file_size = (\d*)/       ? $1 : 0;
		my $down  = /file_downloaded = (\d*)/ ? $1 : 0;
		my $prio  = /file_priority = (\d*)/   ? $1 : 0;
		my $state = /file_state = (\w*)/      ? $1 : 0;
		my $net   = /file_network = (\w*)/    ? $1 : 0;
		my $age   = /file_age = (\d*)/        ? $1 : 0;
		my $mtime = /file_mtime = (\d*)/      ? $1 : 0;
		my @chunk = /file_chunks_age = \[(.*?)\]/ms ?
			split /;\n/, $1 : die "no chunks @".$id;

		sub age_to_time($) { $_[0] != 0 ? 1000000000+$_[0] : 0 }
		push @d, {
			user  => [@user],
			name  => $name,
			hash  => $hash,
			size  => $size,
			down  => $down,
			prio  => $prio,
			state => $state,
			net   => $net,
			age   => age_to_time $age,
			mtime => $mtime,
			chunk => [map {{age=>age_to_time $_}} @chunk],
		};
	}

=source count
	print STDERR "reading file_sources.ini...\n";
	open F, $tar ? "tar xOzf $tar file_sources.ini |" : 'file_sources.ini' or die $!;
	undef $/;
	my $content = <F>;
	close F;

	$content =~ /files = \[(.*)\]/s;
	foreach ($1 =~ /{(.*?)};/gs) {
		# TODO get source count
	}
=cut

	# TODO get telnet id

	my $mega = 1024*1024;
	my $giga = 1024*1024*1024;
	my $day  = 3600*24;

	# TODO filter rows by numeric expr or regular expr
	#      (i.e., owner=zed file=cinema percent<.2 size>100)

	my @h; #column header
	if($setup eq 'link') {
		foreach (sort {$a->{name} cmp $b->{name}} @d) {
			printf "%s\n", cod::url_file($_);
		}
	} elsif($setup eq 'full' or $cmd eq 'temp') {
		@h = qw(percent down size pri age md av eta owner hash filename); #head
	} elsif($setup eq 'mini') {
		@h = qw(percent down size eta owner filename); #head
	} else {
		@h = qw(percent down size pri age md av eta owner filename); #head
	}

	my @s = (); #col sizes
	for(my $i=0;$i<@h; $i++) { # autosize columns
		$s[$i] = length ($h[$i]);
	}
	my @r = ([@h]); #rows

	sub have($) { grep /^_?$_[0]$/, @h }

	@h = map {s/percent|owner/_$&/g; $_} @h; # hide percent for special fmt (below)

	foreach (sort {$a->{name} cmp $b->{name}} @d) { # TODO custom sort
		#next unless $all or grep {$_ eq $ENV{USER}} @{$_->{user}};

		my @c = (); #cols

		my $worst_chunk =
			(sort{$a->{age} <=> $b->{age}} @{$_->{chunk}})[0]->{age};
		$worst_chunk = $worst_chunk == 0 ? -1 : (time - $worst_chunk)/$day;
		my $age = (time - $_->{age}) / $day;
		my $mtime = $_->{down} > 0 && $_->{mtime} > $_->{age} ?
						(time - $_->{mtime}) / $day : -1;

		my $warn = $nocolor ? '' : '[01;31m';
		my $good = $nocolor ? '' : '[01;32m';
		my $blank = $nocolor ? '' : '[0m';

		my $d = $_->{down}/$_->{size}; # percent downloaded
		push @c, $d if have 'percent'; #special percent col [0]

		push @c, $_->{down} == 0 ? ['-', $warn] :
		[sprintf("%.0f", $_->{down}/$mega),
			$d<.2 && $age > 10 ? $warn :
			$d>.8 ? $good :
			$blank
		] if have 'down';

		push @c, [sprintf("%.0f", $_->{size}/$mega),
			$_->{size}/$mega > 705 ? $warn : $blank]
			if have 'size';

		sub timefmt($;$) {
			my ($t, $long) = (int(shift), shift || 30);
			return ['-', $warn] if $t == -1;
			$t >= $long ? [$t, $warn] : $t;
		}

		my $p = $_->{prio};
		push @c, [$p,
			$p >  10 ? $good :
			$p < -10 ? $warn :
			$blank
		] if have 'pri';
		push @c, timefmt($age, $mtime > 10 && $p < 50 ? 30 : 60) if have 'age';
		push @c, timefmt($mtime, 10) if have 'md';
		push @c, timefmt($worst_chunk) if have 'av';

		push @c, timefmt($d ? $age/$d - $age : -1) if have 'eta';


		if(have 'owner') {
			my $user = join(",", @{$_->{user}});
			push @c, [$user, ($user eq '-' ? $warn :
				(grep {$_ eq $ENV{USER}} @{$_->{user}}) ? $good : $blank)]
		}

 		push @c, $_->{hash} if have 'hash';
 		push @c, $_->{name} if have 'filename';

 		#print STDERR "ed2k://|file|".join(",",@{$_->{user}})."\@\@$_->{name}|$_->{size}|$_->{hash}|\n"; # debug

		push @r, [@c]; # add row

		for(my $i=0;$i<@c; $i++) { # autosize columns
			my $l = length (ref $c[$i] ? $c[$i]->[0] : $c[$i]);
			$s[$i] = $l if $s[$i] < $l;
		}
	}


	my $barlen = -1; # include separators
	for(my $i=0;$i<$#s; $i++) { # exclude last
		$barlen += $s[$i]+1;
	}

	my $count = 0;
	ITEM: foreach my $c (@r) { # print table
		# TODO progress bar in the background of the first fields
		my $on    = $nocolor ? '' : '[41m';
		my $off   = $nocolor ? '' : '[44m';
		my $blank = $nocolor ? '' : '[0m';
		my $p0 = int($barlen * $c->[0]);
		my $p1 = $barlen - $p0;

		my $r = $count ? sprintf '%02d ', $count : '   ';
		++$count;

		if( $cmd eq 'temp' ) {
			foreach( @ARGV ) {
				my $hash_col = 9; #XXX
				my $preview_idx = $_ + 1; #XXX
				if( $count == $preview_idx ) {
					printf "%s/temp/urn_ed2k_%s\n", $root, $c->[$hash_col];
					next ITEM;
				}
			}
			next;
		}

		for(my $i=0;$i<@$c; $i++) {
			next if $h[$i] =~ /^_/;
			my $fmt = $i<$#s ? "%$s[$i]s " : "%s"; #last field is free
			my $val = $c->[$i];

			($fmt, $val) = ("$val->[1]$fmt$blank", $val->[0]) if ref $val;
			 # TODO option to disable colors

			$r .= sprintf $fmt, $val;
		}
		print "$r\n"  unless $r =~ /xxx/i and $ARGV[0] ne 'all';
	}
}


# ///2  space / free

warn <<EOF unless $cmd;
    space|free [fast|quick|nosave] [queue[only]|nodu] [vs <user> [qdown|qused|qtotal|stored|disk|final]]
        calculate required space to finish downloads [mlnet]
EOF

if($cmd =~ /^(?:space|fre)/i) {
	do_chdir $root;
	my $nosave = grep /fast|quick|nosave/, @ARGV;
	my $queue  = grep /queue.*|nod.*/, @ARGV;
	my ($vs,$vs_type) = ("@ARGV" =~ /\bvs\s+(\S+)(?:\s+(\S+))?/);
	unless($nosave) {
		print STDERR "requesting ini files update...\n" unless $vs;
		my $ua = LWP::UserAgent->new( timeout=>5,);
		my $old = (stat("donkey.ini"))[9];
		$ua->request(GET (URI::URL->new("http://127.0.0.1:4080/submit?q=save")));
		foreach (1..8) {
			last if ( (stat("donkey.ini"))[9] > $old);
			sleep 1;
		}
	}

	my ($dev,$free_now) =
		`df --block-size=1 /shate/temp/ | tail -1`
			=~ /^(\S+)\s+\d+\s+\d+\s+(\d+)/;


	print STDERR "reading files.ini...\n" unless $vs;
	open F, 'files.ini' or die $!;
	undef $/;
	my $content = <F>;
	close F;

	my %t;
	$content =~ /files = \[(.*)\]/s;
	foreach ($1 =~ /{(.*?)};/gs) {
		my $user = /file_filename = \"(.*?)\@\@.*\"/ ? $1 : 'UNKNOWN';
		my $size = /file_size = (\d*)/ ? $1 : 0;
		my $down = /file_downloaded = (\d*)/ ? $1 : 0;
		sub max($$) { $_[0]>$_[1] ? $_[0] : $_[1] }
		my $used = max(
			(/file_md4 = "?([0-9a-f]+)"?/i ? (stat("/share/temp/$1"))[7] : 0),
			(/file_present_chunks = \[.*?\(\d+, (\d+)\)\]/ms ? $1 : 0)
		);

		foreach (split /,/,$user) {
			$t{$_}->{qdown} += $down;
			$t{$_}->{qused} += $used;
			$t{$_}->{qtotal} += $size;

			$t{$_}->{disk} += $used;
			$t{$_}->{final} += $size;
		}
		$t{ALL}->{qdown} += $down;
		$t{ALL}->{qused} += $used;
		$t{ALL}->{qtotal} += $size;

		$t{ALL}->{disk} += $used;
		$t{ALL}->{final} += $size;
	}

	my $mega = 1024*1024;
	my $giga = 1024*1024*1024;

	unless($queue) {
		print STDERR "performing du...\n" unless $vs;
		my $path_list = join " ", map {"'$_'"} grep {-d "$_/incoming" } glob "/media/*";
		foreach (split /\n/, `du -sch --block-size=1 $path_list 2>/dev/null`) {
			my ($s, $u) = m/^\s*(\d+).*\/(\S+)$/;
			next if $u =~ /donkey|limbo|gaveta|lost\+found/;
			$t{$u}->{stored} += $s;
			$t{$u}->{disk} += $s;
			$t{$u}->{final} += $s;

			$t{ALL}->{stored} += $s;
			$t{ALL}->{disk} += $s;
			$t{ALL}->{final} += $s;
		}
	}

	if($vs) {
		$vs_type = 'qdown' unless $vs_type =~ /qdown|qused|qtotal|stored|disk|final/;
		printf "%.0f\n%.0f\n",
			$t{ALL}->{$vs_type}/1024,
			$t{$vs}->{$vs_type}/1024,
		;
	} else {
		sub per($$) { $t{ALL}->{$_[0]} ? $t{$_[1]}->{$_[0]}/$t{ALL}->{$_[0]}*100 : 0 }
		printf "%-8s: %4s %6s %4s %6s %4s %6s %4s %6s %4s %6s %4s %6s %4s\n",
			qw(user dl% qdown dwn% qused usd% qtotal tot% stored str% disk dsk% final fin%);
		foreach  (sort {
			$t{$b}->{final}/$t{ALL}->{final} <=>
			$t{$a}->{final}/$t{ALL}->{final}
			} keys %t) {
			next unless $t{$_}->{qtotal}+$t{$_}->{stored};
			printf "%-8s: %4s %6.0f %3d%% %6.0f %3d%% %6.0f %3d%% %6.0f %3d%% %6.0f %3d%% %6.0f %3d%%\n",
				$_,
				$t{$_}->{qtotal} ?  int($t{$_}->{qdown}/$t{$_}->{qtotal}*100).'%' : '  - ',
				$t{$_}->{qdown}/$mega, per('qdown', $_),
				$t{$_}->{qused}/$mega, per('qused', $_),
				$t{$_}->{qtotal}/$mega, per('qtotal', $_),
				$t{$_}->{stored}/$mega, per('stored', $_),
				$t{$_}->{disk}/$mega, per('disk', $_),
				$t{$_}->{final}/$mega, per('final', $_),
			;
		}

		printf "%12.3fGb is free now\n", $free_now/$giga;

		my $free_end = $free_now + $t{ALL}->{disk} - $t{ALL}->{final};
		printf "%12.3fGb %s\n", abs($free_end)/$giga, $free_end < 0
			? "MUST BE FREED TO FINISH DOWNLOADS"
			: "will still be free at the end";
	}


}


# ///2  bw

warn <<EOF unless $cmd;
    bw [<secs-per-update> [<secs-per-graph-tick> [<kb/s-scale-limit>]]]
        show bandwidth utilization [mlnet]
EOF

if($cmd =~ /^(?:bw|stat)/i) {
	my $mindelay =abs(shift||3); #sec
	my $maxdelay =abs(shift||60); #sec
	$mindelay = $maxdelay if $maxdelay < $mindelay;
	my $scale_max=abs(shift||200); #kb/s
	my $ua = LWP::UserAgent->new( timeout=>10,);
	my @hist;
	my $rows = $ENV{LINES}   || 80;
	my $cols = $ENV{COLUMNS} || 80;
	while(1) {
		print "[H[J", "\n" x $rows;

		# file traffic
		my %file = ();
		sub unesc($) { local $_ = shift;
			s/&lt;/</g; s/&gt;/>/g; s/&amp;/&/g; s/&#(\d+);/chr($1)/ge; $_
		}
		for(scalar $ua->request(GET (URI::URL->new(
			"http://127.0.0.1:4080/submit?q=vd")))->content) {
			s{\[File: (\d+)\][^<>]*>(.*?)<.*?<td[^<>]*>\s*([0-9\.\-]+)\s*</td><td[^<>]*>\s*([0-9dhms\-\.\s]*?)\s*</td></tr>}
			{@{${file{$1}}}{qw(name rate eta)} = (unesc($2),$3,$4); $&}msge;

		}
		printf "  %11s %8s  %-23s ::%s\n",
			qw(rate eta name), scalar localtime;
		foreach (
			sort {$a->{rate} <=> $b->{rate}}
			grep {$_->{rate} > 0} values %file) {
			printf "  %6.1f kb/s %8s  %s\n", $_->{rate}, $_->{eta}, $_->{name};
		}
		print "\n";

		# graph history
		#if(@hist) {#}
		if($maxdelay) {
			my $period = '';
			my $w = $cols-5;
			my $t = $w*$maxdelay;
			my %p = (d=>24*60*60, h=>60*60, m=>60, s=>1);
			my $n=2;
			foreach my $k (sort {$p{$b} <=> $p{$a}} keys %p) {
				my $v = $p{$k};
				if($t > $v) {
					$period .= sprintf "%d%s", $t/$v, $k;
					$t -= int($t/$v)*$v;
					last unless --$n;
				}
			}

			my $buf = '';
			my @s = qw(. 1 2 3 a b c); #scale
			my $n=scalar @s;
			foreach my $f (1..2) { $buf .= sprintf "%1s: ", qw(T D U)[$f];
			foreach my $h (@hist[0..$w-1]) {
				$buf .= ' ' and next unless $h;
				my $b = $h->[$f]/$scale_max;
				$buf .= '>' and next if $b>1;
				$buf .= $s[int(log(($b*(2**$n))||1)/log(2))];
			} $buf .= "\n";}
			$buf .= "Scale: ";
			for(my $i=0; $i<$n; ++$i) {
				$buf .= sprintf "  %1s:%d",$s[$i], 2**$i / 2**($n-1) * $scale_max
			}
			$buf .= sprintf " kb/s   period $period\n";
			print "$buf\n";

			my $user = (getpwuid($<))[0] || 'sys';
			my $file = "/tmp/bw.$user.$period.txt";
			if(open LOG, ">$file") {
				#my $time = scalar(localtime);
				#print LOG (' ' x ($w - length($time))), "$time\n";
				print LOG $buf;
				close LOG;
				chmod 0664, $file;
			}
		}

		# instant status
		my ($n, $dd, $uu) = (0, 0,0);
		for(1..($mindelay==0?1:$maxdelay/$mindelay)) {
			for(scalar $ua->request(GET (URI::URL->new(
				"http://127.0.0.1:4080/submit?q=bw_stats")))->content) {
				my ($d,$u) = /Down: ([0-9\.]+).*Up: ([0-9\.]+)/ms;
				next unless defined $d;
				$dd += $d; $uu += $u; ++$n;
				printf "\rD:%6.1fkb/s  U:%6.1fkb/s", $d, $u;
			}
			sleep $mindelay;
		}
		unshift @hist, [time, $dd/$n, $uu/$n] if $n;
		while(scalar(@hist) > 1024) { pop @hist }
		#print "\n" x 3;

		last unless $maxdelay;
	}
}


warn "\n" unless $cmd; ############################


#\\\
# vim:set foldmarker=\/\/\/,\\\\\\:set fdm=marker:%foldc!:
