# /bin/bash
# vim600:foldmethod=marker:foldmarker=)#,;;#:

function timer()
{
	local sleep_arg
	local repeat

	for arg in "$@"; do
		case "$arg" in
			-r)
				repeat=1
				;;
			*)
				sleep_arg="$sleep_arg $arg"
				;;
		esac
	done

	while sleep "$sleep_arg"; do
		zenity --warning --text="passou $sleep_arg"
		test "$repeat" == "1" || break
		echo "repeating the timer, press <Ctrl-C> to break"
	done
}

if test -n "$1" -a -z "$timer_function_loaded"; then
	timer "$@"
else
	timer_function_loaded=1
fi
