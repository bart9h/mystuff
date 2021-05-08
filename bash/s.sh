#!/bin/bash

function s()
{
	which tmux >/dev/null || return

	if [[ "$1" == "--help" || "$1" == "-h" ]]; then
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
	elif [[ "$1" == "" ]]; then
		tmux list-sessions \; list-clients
		return
	fi

	local name="$(sed 's/\/$//' <<< "$1")"; shift
	local second_level=""

	# if arg is _, create "meta" tmux session
	if [[ "$name" == "_" ]]; then
		second_level=1
		if [[ -n "$1" ]]; then
			name="$1"; shift
		fi
	fi

	local is_dot=0
	if [[ "$name" == "." ]]; then
		is_dot=1
		name="$(basename "$PWD")"
	fi

	# if arg is existing session, attach
	if [[ -z "$1" ]] && tmux list-sessions -F '#{session_group}' | grep "^${name}$"; then
		local first_detached_line="$(tmux ls | grep "(group $name)$" | head -1)"
		if [[ -n "$first_detached_line" ]]; then
			# there is a non-attached session group, attach to the first one
			detached=$( cut -d : -f 1 <<< $first_detached_line )
			tmux attach-session -t $detached
		else
			# all sessions are attached, create new session
			tmux -2u new-session -t $name
		fi

	else  # create session
		local session_name

		# if arg is existing dir, cd into, else arg is session name
		[[ $is_dot == 0 && -d "$name" ]] && cd "$name" || session_name="$name"

		# defult session name is $PWD
		[[ -z "$session_name" || "$session_name" == "." ]] \
		&& session_name="`basename "$PWD"`"

		if [[ "$session_name" == "src" ]]; then
			local p="$(cd .. && basename "$PWD")"
			[[ "$p" != "/" ]] && session_name="$p"
		fi

		if [[ -z $second_level ]]; then
			tmux -2u new-session -t $session_name
		else
			tmux -2u new-session -t $session_name \; set-option -g prefix C-s
		fi
	fi
}

if test -n "$1" -a -z "$s_function_loaded"; then
	s "$@"
else
	s_function_loaded=1
fi
