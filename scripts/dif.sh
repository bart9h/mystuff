#!/bin/bash
#{{{1 description
#
#  This is a frontend for diff.
#  Usage:   dif <object1> <object2>
#  where the objects can be a file, a directory, or a tar archive.
#  Uses vim to view the output, if available.
#

#{{{1 configurable variables

diff='/usr/bin/diff -U 5 -rpbB --ignore-all-space --ignore-blank-lines --exclude=.git --exclude=.svn --exclude=CVS --exclude=.depend'


#{{{1 argument handling

GVIM=0
if test "$1" == "-g"; then
	GVIM=/u/nttx/usr/bin/gvim
	shift
fi

verbose=
test "$VERBOSE" -a "$VERBOSE" != "no" -a "$VERBOSE" != "0" && verbose='-v'
#TODO: function bool() {}

nargs=$#
test $nargs -eq 2 || { echo 'use: dif <object1> <object2>'; exit; }

first=true
while test "$1"; do
#echo loop "$1"
	x="$1"
	dir=

	if test -f "$1" && echo "$1" | grep -q -E -e '\.tar$|\.tar\.gz$|\.tgz$|\.tar\.xz$|\.tar$\.bz2$|\.tar\.bz$'; then
		target="/tmp/`basename "$1"`"
		test -d "$target" && target="${target}-2"
		mkdir $verbose "$target" || exit
		dir="$target"
		test -n "$verbose" && echo "untaring \"$1\" to \"$target\""
		tar -C "$target" $verbose -x -f "$1" || exit
		# check if it has a single directory (or file):
		if test `ls -A "$target" | wc -l` -eq 1; then
			x="$target/`ls -A $target`"
		else
			x="$target"
		fi
	fi

	$first && a="$x" || b="$x"
	$first && adir="$dir" || bdir="$dir"
	first=false
	shift
done


#{{{1 do the diff

output=/tmp/dif
echo "$diff \"$a\" \"$b\""
$diff "$a" "$b" | sed "s/\r//" > $output


#{{{1 view the output

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


#{{{1 cleanup temporary data

test -n "$verbose" && echo "cleaning up..."
test "$adir" && rm $verbose -rf "$adir"
test "$bdir" && rm $verbose -rf "$bdir"
rm $verbose -rf $output


#}}}
# vim600:fdm=marker:
