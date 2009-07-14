#!/bin/bash
# vim600:ft=sh:foldmethod=marker:foldmarker=)#,;;#:

function show()
{
	local what="$1"; shift
	case "$what" in

	ansi|colors)#
		for b in 0 1; do
			for j in 3 4; do
				i=0
				while test $i -le 7; do
					echo -ne "\e[${b};${j}${i}m [$b;$j$i] "
					let i=i+1
				done
				echo -e "\e[0;0m"
			done
		done
	;;#

	256)#
		local i red green blue fmt="%02x" reset="\x1b[0m\x1b[38;5;16m"
		test "$1" && fmt="%03d"
		printf "$reset"

		# system
		for (( color=0; color<16; color++ )); do
			printf "\x1b[48;5;${color}m ${fmt} " $color
			test $color == 7 && printf "$reset\n"
		done
		printf "\n\n"

		# colorcube
		for (( i=0; i<2; i++ )); do
			for (( green=0; green<6; green++ )); do
				for (( red=$i*3; red<($i+1)*3; red++ )); do
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

	processors|cpus)#
		cat /proc/cpuinfo | grep '^processor\>' | wc -l
	;;#

	resolution|res|rez)#
		echo $(xwininfo -root|grep Width:|cut -d : -f 2)x$(xwininfo -root|grep Height:|cut -d : -f 2|sed s/\ //g)
	;;#

	sizeof)#
		shift
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
		echo -e "#include <stdio.h>\n#include <time.h>\nint main() { printf(\"%d\\\n\", sizeof($*)); return 0; }" | crun $arg
	;;#

	*)# help
		echo "things to show: colors, cpus, resolution, sizeof"
	;;#

	esac
}

