#!/bin/bash

function s()
{
	which screen >/dev/null || return

	# if no arg, list existing screens
	if test "$1" == ""; then
		screen -wipe | grep '([AD][te]tached)'

	# if arg is existing screen, attach
	elif test "$1" != "." \
	&& screen -ls | grep "\<[0-9]*\.$1\>"; then
		screen -x "$1"

	# if arg is _, create "meta" screen
	elif test "$1" == "_" \
	&& ! screen -ls | grep "\<[0-9]*\.$1\>"; then
		screen -e ^Bb -S _

	else  # create screen
		local session_name

		# if arg is existing dir, cd into, else arg is session name
		test -d "$1" && cd "$1" || session_name="$1"

		# defult session name is $PWD
		test -z "$session_name" -o "$session_name" == "." \
		&& session_name="`basename "$PWD"`"

		screen -S "$session_name"
	fi
}

