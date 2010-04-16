#!/bin/bash
#
#  Asks confirmation before removing multiple files.
#  Unlike `/bin/rm -i`, this version:
#  -  Only asks if there's more than one file to be rm'ed.
#  -  Show the list of files to be rm'ed, and asks just once.
#  -  First if checks if all files exists, aborting otherwise.
#
if [ "$OSTYPE" == "linux-gnu" ]; then

function rm()
{

	# count and check files
	local file_count=0
	local ok=true
	local dashdash=false  # "--" ends options parsing
	for i in "$@"; do
		if $dashdash || ! expr match "$i" "\-*" > /dev/null; then
			if test -e "$i"; then
				let file_count++
			else
				/bin/rm "$i"
				ok=false
			fi
		elif test "$i" == "--"; then
			dashdash=true
		fi
	done; unset i

	# if there's any missing file, abort
	if ! $ok; then
		if test $file_count -gt 0; then
			echo "and $file_count more item(s) not rm'ed"
		fi
		return
	fi

	# if more than one file, ask first
	if test $file_count -gt 1; then
		ls -d "$@"
		read -p "remove $file_count items (y/n) [y]? " answer
		test "$answer" == "y" -o "$answer" == "" || return
	elif test $file_count -eq 0; then
		echo "no files" > /dev/stderr
		return
	fi

	# finally, call /bin/rm with original arguments
	# ie:  grep -v 'shift' rm.sh  || die
	$(which rm) "$@"

}

fi
