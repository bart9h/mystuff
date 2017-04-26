#!/bin/bash

function waitfor() {
	if [[ ( -z "$1" ) || ( "$1" == "--help" ) || ( -n "$2" && -z "$3" ) ]]; then
		echo 'usage:  waitfor  [ -t <timeout> ]  <program-name>'
		return 2
	fi

	local timeout
	local progname

	if test -n "$2"; then
		if test "$1" == "-t"; then
			timeout="$2"
			progname="$3"
		elif test "$2" == "-t"; then
			timeout="$3"
			progname="$1"
		else
			echo 'invalid arguments'
			return 2
		fi
	else
		progname="$1"
	fi

	while pidof "$progname" >/dev/null; do
		if test -n "$timeout"; then
			test "$timeout" == "0" && return 1
			let timeout=timeout-1
		fi
		sleep 1
	done

	return 0
}
