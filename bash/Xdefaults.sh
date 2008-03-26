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
files="$HOME/etc/etc/Xdefaults.$hostfile"
files="$HOME/etc/etc/Xdefaults $files"
cat $files | sed ';s/^[\ \t]\+//;/^\#/d' | xrdb

