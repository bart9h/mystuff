#!/bin/bash

#my_osd_font='-*-helvetica-*-r-*-*-34-*-*-*-*-*-*-*'
#my_osd_font='-bitstream-bitstream vera sans-bold-r-normal--24-0-0-0-p-0-iso8859-1'
my_osd_font='9x15'

function my_osd_cat()
{
	osd_cat \
		-p middle -A center -s 3 \
		-d 1 \
		-c yellow \
		-f "$my_osd_font"
}

function osd()
{
	if test -n "$1"; then
		echo "$@" | my_osd_cat
	else
		my_osd_cat
	fi
}

if test -n "$1" -a -z "$osd_function_loaded"; then
	osd "$@"
else
	osd_function_loaded=1
fi

