#!/bin/bash

function my_osd_cat()
{
	osd_cat \
		-p middle -A center -s 3 \
		-d 1 \
		-c yellow \
		-f '-bitstream-bitstream vera sans-bold-r-normal--24-0-0-0-p-0-iso8859-1'
}

function osd()
{
	if test -n "$1"; then
		echo "$@" | my_osd_cat
	else
		my_osd_cat
	fi
}

