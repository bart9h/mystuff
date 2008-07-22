#!/bin/bash

function s()
{
	which screen >/dev/null || return

	# if no arg, list existing screens
	if test "$1" == ""; then
		screen -wipe | grep '([AD][te]tached)'
		return
	fi

	local name="$(echo "$1" | sed 's/\/$//')"; shift
	local escape=""

	# if arg is _, create "meta" screen
	if test "$name" == "_"; then
		escape="-e ^Bb"
		if test -n "$1"; then
			name="$1"; shift
		fi
	fi

	local is_dot=0
	if test "$name" == "."; then
		is_dot=1
		name="$(basename "$PWD")"
	fi

	# if arg is existing screen, attach
	if test -z "$1" && screen -ls | grep "\<[0-9]*\.$name\>"; then
		test -n "$WINDOW" && screen -X title "$name"
		screen -x "$name"

	else  # create screen
		local session_name

		# if arg is existing dir, cd into, else arg is session name
		test $is_dot == 0 -a -d "$name" && cd "$name" || session_name="$name"

		# defult session name is $PWD
		test -z "$session_name" -o "$session_name" == "." \
		&& session_name="`basename "$PWD"`"

		test -n "$WINDOW" && screen -X title "$session_name"
		TERM=xterm screen $escape -S "$session_name"

		# Forcing TERM=xterm is a workaround to support 256-colors
		# in a screen inside another screen.
		# (Looks like screen only supports 256-colors if TERM=xterm).
		#
		# But what if you open a screen in the text console?
		# Even if there is a check for that, it won't solve the problem,
		# as one can open a screen in one environment,
		# then re-attach in another.
	fi
}

