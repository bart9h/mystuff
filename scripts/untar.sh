#!/bin/bash

# check archive type (by filename's extension)
if echo "$1" | grep -q ".tar.gz$\|.tgz$"; then
	arg="z"
elif echo "$1" | grep -q ".tar.bz2$\|.tbz$\|.tbz2"; then
	arg="j"
elif echo "$1" | grep -q ".tar$"; then
	arg=""
else
	echo unknown archive type
	arg="?"
fi

if [ "$arg" != "?" ]; then
	# get the first filename from the archive
	first=`tar tf$arg "$1" | head -1`

	# if there's a path, extract right here
	if echo $first | grep -q "/" && echo $first | grep -qv "^./[^/]*"; then
		dir=`echo $first | cut -d \/ -f 1`
		tar xvf$arg "$1" && cd "$dir" && ls
	# if not, create a dir with the first part of the name of the archive
	else
		dir="`echo $1 | cut -d . -f 1`"
		mkdir "$dir" && \
		cd "$dir" && \
		tar xfv$arg "../$1" && \
		ls
	fi
fi

