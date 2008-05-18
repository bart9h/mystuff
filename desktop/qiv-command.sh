#!/bin/sh
#####################################################################
#
#    Keys that can be used from "qiv":
#
#    1    show this help
#    2    edit the script
#    3    execute the script, passing current file as first arg
#
#####################################################################
#{{{ code

key="$1"
file="$2"
action_script="$HOME/var/qiv-action"

case "$key" in
1)
	xterm -e "vi \"$0\""
	;;
2)
	xterm -e "vi \"$action_script\""
	;;
3)
	chmod +x "$file" &&
	exec "$action_script" "$file"
	;;
esac

#}}}
# vim600:fdm=marker:
