#!/bin/bash

function t()
{
	# check archive type (by filename's extension)
	if grep -q ".tar.gz$\|.tgz$" <<< "$1"; then
		arg="z"
	elif grep -q ".tar.bz2$\|.tbz$\|.tbz2 <<< "$1""; then
		arg="j"
	elif grep -q ".tar$" <<< "$1"; then
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

