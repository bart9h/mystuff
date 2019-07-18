#!/bin/sh
if false && test "$UID" != "0"; then
	echo 'Must run as root.'
	exit
fi

#FIXME
test -z "$ETC" && export ETC="/home/doti/etc"

"$ETC"/sys/transmission_stop.sh

umount -v /wd && echo 1 > /sys/bus/scsi/devices/2:0:0:0/delete
