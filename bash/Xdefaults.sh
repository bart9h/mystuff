#!/bin/bash

case "$HOSTNAME" in
	doti-lap)
		hostfile='small'
		;;
	*)
		hostfile='default'
		;;
esac

test -n "$hostfile" &&
files="$HOME/etc/x11/Xdefaults.$hostfile"
files="$HOME/etc/x11/Xdefaults $files"
cat $files | sed ';s/^[\ \t]\+//;/^\#/d' | xrdb

