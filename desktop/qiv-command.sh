#!/bin/sh

key="$1"
file="$2"
action_script="$HOME/var/qiv-action.sh"

case "$key" in
0)
	sh "$action_script" "$file"
	;;
7)
	xterm -e "vi \"$action_script\""
	;;
esac

