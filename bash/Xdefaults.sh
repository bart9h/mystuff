#!/bin/bash

function Xdefaults() {
	local global="Xdefaults"

	local local
	case "$HOSTNAME" in
		doti-lap)
			local='small'
			;;
		*)
			local='default'
			;;
	esac

	local dir="$HOME/etc/x11"
	cat "$dir/$global" "$dir/$global.$local" \
	| sed ';s/^[\ \t]\+//;/^\#/d' \
	| xrdb
}

