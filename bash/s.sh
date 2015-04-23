#!/bin/bash

function s()
{
	which screen >/dev/null || return

	if test "$1" == "--help" -o "$1" == "-h"; then
		cat <<EOF
(no args)       list existing screens
name            attach to named screen if it exists, otherwise creates
_               create a second-level screen named "_"
_ name          create a second-level screen named "name"

If name is ".", name is basename of current directory.
If name is an existing directory, chdir into it and starts screen there.
If directory ends in "src" or "build", use parent dir as label (no chdir is done).
EOF
		return
	elif test "$1" == ""; then
		screen -wipe | \grep '([AD][te]tached)'
		return
	fi

	local name="$(sed 's/\/$//' <<< "$1")"; shift
	local escape=""

	# if arg is _, create "meta" screen
	if test "$name" == "_"; then
		escape="-e ^Ss"
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
	if test -z "$1" && screen -ls | \grep "\<[0-9]*\.$name\>"; then
		test -n "$WINDOW" && screen -X title "$name"
		screen -x "$name"

	else  # create screen
		local session_name

		# if arg is existing dir, cd into, else arg is session name
		test $is_dot == 0 -a -d "$name" && cd "$name" || session_name="$name"

		# defult session name is $PWD
		test -z "$session_name" -o "$session_name" == "." \
		&& session_name="`basename "$PWD"`"

		if test "$session_name" == "src"; then
			local p="$(cd .. && basename "$PWD")"
			test "$p" != "/" && session_name="$p"
		fi

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

