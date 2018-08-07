#!/bin/bash
source "$ETC"/bash/waitfor.sh

if test -x `which transmission-remote`; then
	if test pidof transmission-gtk >/dev/null 2>/dev/null; then
		transmission-remote --exit
		local timeout_seconds=15
		echo "Waiting for transmission-gtk to exit (with a $timeout_seconds seconds timeout)."
		waitfor -t $timeout_seconds transmission-gtk
	else
		echo "transmission-gtk was not running."
	fi
else
	echo "No transmission-remote command found."
fi
