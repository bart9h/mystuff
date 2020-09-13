# /bin/bash
# vim600:foldmethod=marker:foldmarker=)#,;;#:

function get_xwininfo()
{
	local key="$1"; shift

	if test -z "$DISPLAY"; then
		echo "no X display set" >/dev/stderr
	else
		if test -x "$(which xwininfo)"; then
			echo $(xwininfo -root|grep "$key":|cut -d : -f 2)
		else
			echo "xwininfo not available" >/dev/stderr
		fi
	fi
}

function show()
{
	local what="$1"; shift
	case "$what" in

	ip)#                 : external IP address (via checkip.dyndns.org)
		wget -O - checkip.dyndns.org 2>/dev/null |
		sed 's/^.*IP Address: \([^<]*\).*$/\1/'
	;;#

	colors)#             : system colors
		for b in 0 1; do
			for j in 3 4; do
				i=0
				while test $i -le 7; do
					printf "\x1b[${b};${j}${i}m [$b;$j$i] "
					let i=i+1
				done
				echo -e "\e[0;0m"
			done
		done
	;;#

	256)#                : 256-color cube

		local i red green blue fmt="%02x" reset="\x1b[0m\x1b[38;5;16m"
		test "$1" && fmt="%03d"
		printf "$reset"

		# system
		for (( color=0; color<16; color++ )); do
			printf "\x1b[48;5;${color}m ${fmt} " $color
			test $color == 7 && printf "$reset\n"
		done
		printf "$reset"
		printf "\n\n"

		# colorcube
		for (( i=0; i<2; i++ )); do
			for (( green=0; green<6; green++ )); do
				for (( red=$i*3; red<$(( ($i+1)*3 )); red++ )); do
					for (( blue=0; blue<6; blue++ )); do
						color=$(( 16 + $red*36 + $green*6 + $blue ))
						printf "\x1b[48;5;${color}m ${fmt} " $color
					done
					printf "$reset "
				done
				printf " \n"
			done
			printf "\n"
		done

		# grayscale
		for (( color=232; color<256; color++ )); do
			printf "\x1b[48;5;${color}m ${fmt} " $color
			test $color == 243 && printf "$reset\n"
		done

		printf "\x1b[0m\n"
	;;#

	cpus)#               : number of CPUs
		case $OSTYPE in
			darwin*)
				sysctl -n hw.ncpu
				;;
			linux*)
				cat /proc/cpuinfo | grep '^processor\>' | wc -l
				;;
			*)
				echo 1
				;;
		esac
	;;#

	width)
		get_xwininfo Width
	;;

	height)
		get_xwininfo Height
	;;

	resolution|res)#  : resolution of the X display
		echo $(get_xwininfo Width)x$(get_xwininfo Height)
	;;#

	termsize|rez)#    : resolution of the text terminal
		echo ${COLUMNS}x${LINES}
	;;#

	sizeof)# <C-type>    : size of C type (calls gcc)
		test -z "$1" && echo "sizeof what?" && return
		local arg
		while true; do
			case "$1" in
			-*)
				arg="$arg $1"
				shift
				;;
			*)
				break
				;;
			esac
		done
		echo -e "#include <stdio.h>\n#include <time.h>\nint main() { printf(\"%zd\\\n\", sizeof($*)); return 0; }" | crun $arg
	;;#

	*)# help
		echo "options:"
		grep ')#' "$ETC/bash/show.sh" |sed 's/)\?#//g;s/|/\ or\ /g' |grep -v 'help\|foldmarker' #;;#
	;;#

	esac
}

if test -n "$1" -a -z "$show_function_loaded"; then
	show "$@"
else
	show_function_loaded=1
fi
