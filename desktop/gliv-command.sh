#!/bin/bash

command="$1"; shift
dir="$1"; shift
file="$1"; shift

VERBOSE=1
dbg() { test -n "$VERBOSE" -a "$VERBOSE" != "0" && echo "$*" |tee -a /tmp/gliv-command.log; }
dbg "command($command), dir($dir), file($file)"

path="$dir/shot/$( dbg "$file" | sed 's/\.[^.]\+$/.cr2/' )"
dbg "trying($path)"
if ! test -f "$path"; then
	path="$dir/shot/$file"
	dbg "trying($path)"
	if ! test -f "$path"; then
		path="$dir/$file"
		dbg "trying($path)"
	else
		dbg "file not found"
		exit
	fi
fi

dbg "$command -- \"$path\""
exec $command -- "$path"
