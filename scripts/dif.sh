#!/bin/bash

##########
# configurable variables

diff='/usr/bin/diff -U 5 -rpbB --ignore-all-space --ignore-blank-lines --exclude=.svn --exclude=CVS'


##########
# handle arguments

GVIM=0
if test "$1" == "-g"; then
	GVIM=/u/nttx/usr/bin/gvim
	shift
fi

verbose=
test "$VERBOSE" -a "$VERBOSE" != "no" -a "$VERBOSE" != "0" && verbose='-v'

nargs=$#
test $nargs -eq 2 || { echo 'use: dif <object1> <object2>'; exit; }

first=true
while test "$1"; do
#echo loop "$1"
	x="$1"
	dir=
	tar_type=
	if test -f "$1" && echo "$1" | grep -q "\.tar\.gz$\|\.tgz$"; then
		tar_type='xz'
	elif test -f "$1" && echo "$1" | grep "\.tar\.bz2$\|\.tbz$"; then
		tar_type='xj'
	elif test -f "$1" && echo "$1" | grep "\.tar$"; then
		tar_type='x'
	fi

	if test -n "$tar_type"; then
		target="/tmp/""`basename "$1"`"
		mkdir $verbose "$target" || exit
		dir="$target"
		test -n "$verbose" && echo "untaring \"$1\" to \"$target\""
		tar -C "$target" $verbose -$tar_type -f "$1" || exit
		# check if it has a single directory (or file):
		if test `ls -A "$target" | wc -l` -eq 1; then
			x="$target/`ls -A $target`"
		else
			x="$target"
		fi
	fi

	test "$first" && a="$x" || b="$x"
	test "$first" && adir="$dir" || bdir="$dir"
	first=
	shift
done


##########
# do the diff

output=/tmp/dif
echo "$diff \"$a\" \"$b\""
$diff "$a" "$b" | sed "s/\r//" > $output


##########
# view the output

if test -s $output; then
	if test -x "$GVIM"; then
		"$GVIM" --nofork +'set filetype=diff' +'map <c-x> :q!<cr>' $output
	elif test "`which vim`"; then
		vim +'set filetype=diff' +'map <c-x> :q!<cr>' $output
	elif test "$EDITOR"; then
		$EDITOR $output
	elif test "`which less`"; then
		less $output
	elif test "`which more`"; then
		more $output
	else
		cat $output
	fi
fi


##########
# cleanup temporary data

test -n "$verbose" && echo "cleaning up..."
test "$adir" && rm $verbose -rf "$adir"
test "$bdir" && rm $verbose -rf "$bdir"
rm $verbose -rf $output

