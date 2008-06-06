#!/bin/bash

function s()
{
	which screen >/dev/null || return

	# if no arg, list existing screens
	if test "$1" == ""; then
		screen -wipe | grep '([AD][te]tached)'
		return
	fi

	local name="$1"
	local ctrlB=""
	shift

	# if arg is _, create "meta" screen
	if test "$name" == "_"; then
		ctrlB="-e ^Bb"
		if test -n "$1"; then
			name="$1"
			shift
		fi
	fi

	if test "$name" == "."; then
		name="$(basename "$PWD")"
	fi

	# if arg is existing screen, attach
	if test -z "$1" && screen -ls | grep "\<[0-9]*\.$name\>"; then
		test -n "$WINDOW" && screen -X title "$name"
		screen -x "$name"

	else  # create screen
		local session_name

		# if arg is existing dir, cd into, else arg is session name
		test -d "$name" && cd "$name" || session_name="$name"

		# defult session name is $PWD
		test -z "$session_name" -o "$session_name" == "." \
		&& session_name="`basename "$PWD"`"

		test -n "$WINDOW" && screen -X title "$session_name"
		screen $ctrlB -S "$session_name"
	fi
}

