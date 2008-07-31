#!/bin/bash

function pdfjoin()
{
	local gs="`which gs`"
	if ! test -x "$gs"; then
		echo "ghostscript (gs) not found"
		return 1
	fi

	if test "$#" -lt 3; then
		echo "usage: pdfjoin <outfile.pdf> <infile1.pdf> ... <infileN.pdf>"
		return 1
	fi

	local output="$1"
	shift
	"$gs" -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile="$output" "$@"
}

