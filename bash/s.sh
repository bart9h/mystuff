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
	shift
	if test "$name" == "."; then
		name="$(basename "$PWD")"
	fi

	# if arg is existing screen, attach
	if screen -ls | grep "\<[0-9]*\.$name\>"; then
		test -n "$WINDOW" && screen -X title "$session_name"
		screen -x "$name"

	# if arg is _, create "meta" screen
	elif test "$name" == "_" \
	&& ! screen -ls | grep "\<[0-9]*\.$name\>"; then
		test -n "$1" && name="$1" || name="_"
		screen -e ^Bb -S "$name"

	else  # create screen
		local session_name

		# if arg is existing dir, cd into, else arg is session name
		test -d "$name" && cd "$name" || session_name="$name"

		# defult session name is $PWD
		test -z "$session_name" -o "$session_name" == "." \
		&& session_name="`basename "$PWD"`"

		test -n "$WINDOW" && screen -X title "$session_name"
		screen -S "$session_name"
	fi
}

