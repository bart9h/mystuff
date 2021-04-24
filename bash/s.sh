#!/bin/bash

function s()
{
	which tmux >/dev/null || return

	if test "$1" == "--help" -o "$1" == "-h"; then
		cat <<EOF
(no args)       list existing tmux sessions
name            attach to named session if it exists, otherwise creates
_               create a second-level session named "_"
_ name          create a second-level session named "name"

If name is ".", name is basename of current directory.
If name is an existing directory, chdir into it and starts tmux there.
If directory ends in "src" or "build", use parent dir as label (no chdir is done).
EOF
		return
	elif test "$1" == ""; then
		tmux list-sessions
		return
	fi

	local name="$(sed 's/\/$//' <<< "$1")"; shift
	local escape=""

	# if arg is _, create "meta" tmux session
	if test "$name" == "_"; then
		escape="set-option -g prefix C-s \; "
		if test -n "$1"; then
			name="$1"; shift
		fi
	fi

	local is_dot=0
	if test "$name" == "."; then
		is_dot=1
		name="$(basename "$PWD")"
	fi

	# if arg is existing session, attach
	if test -z "$1" && tmux list-sessions -F '#{session_name}' | grep "^${name}$"; then
		tmux attach-session -t $name

	else  # create session
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

		tmux $escape new-session -s "$session_name"
	fi
}
