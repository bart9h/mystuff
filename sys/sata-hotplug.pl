#!/bin/sh
echo "- - -" > /sys/class/scsi_host/host2/scan
#!/bin/sh
if test "$UID" != "0"; then
	echo 'Must run as root.'
	exit
fi

umount /wd && echo 1 > /sys/block/sdd/device/delete
#umount /wd && echo 1 > /sys/bus/scsi/devices/<n>:0:0:0/delete
