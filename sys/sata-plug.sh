#!/bin/sh
if mount | grep -q ' on /wd '; then
	echo '/wd already mounted'
	exit
fi

echo "- - -" > /sys/class/scsi_host/host2/scan || exit
sync
sleep 2
mount /wd
