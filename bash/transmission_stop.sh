#!/bin/bash
function transmission_stop() {
	if test -x `which transmission-remote` && pidof transmission-gtk >/dev/null 2>/dev/null; then
		transmission-remote --exit
		local timeout_seconds=15
		echo "Waiting for transmission-gtk to exit (with a $timeout_seconds seconds timeout)."
		waitfor -t $timeout_seconds transmission-gtk
	fi
}
