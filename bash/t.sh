#!/bin/bash

function t()
{
	# check archive type (by filename's extension)
	if echo "$1" | grep -q ".tar.gz$\|.tgz$"; then
		arg="z"
	elif echo "$1" | grep -q ".tar.bz2$\|.tbz$\|.tbz2"; then
		arg="j"
	elif echo "$1" | grep -q ".tar$"; then
		arg=""
	else
		echo unknown archive type
		return
	fi

	local d="$1_contents"
	mkdir "$d" ||return

	if tar -C "$d" -xv$arg -f "$1"; then
		local count=$(ls -A "$d" 2>/dev/null| wc -l)
		case $count in
		1)
			local d2=$(basename "$d"/*)
			mv "$d"/* . ||return
			rmdir "$d" ||return
			cd "$d2"
			;;

		0)
			echo "empty"
			rmdir "$d"
			return
			;;

		*)
			cd "$d"
			;;
		esac
		ls
	else
		rmdir "$d"
	fi
}

