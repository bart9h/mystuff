#!/bin/bash

command="$1"; shift
dir="$1"; shift
file="$1"; shift

VERBOSE=1
dbg() {
	test -n "$VERBOSE" -a "$VERBOSE" != "0" && echo "$*" |
	tee -a /tmp/gliv-command.log
}

dbg "command($command), dir($dir), file($file)"

cr2="$( echo "$file" | sed 's/\.[^.]\+$/.cr2/' )"

try() {
	dbg "trying($1)"
	if test -f "$1"; then
		dbg "$command -- \"$1\""
		exec $command -- "$1"
		exit
	fi
}

try "$dir/shot/$cr2"
try "$dir/../shot/$cr2"
try "$dir/shot/$file"
try "$dir/../shot/$file"
try "$dir/$file"

