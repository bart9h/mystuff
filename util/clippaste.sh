#!/bin/bash
clips_file="${ETC}/tips/clips"
if test "$1" == ""; then
	exec sakura -e "$0" "$clips_file"
fi

if ! test -s "$clips_file"; then
	echo "$clips_file is missing, or empty."
	echo -n "(press a key to close)"
	read -N 1
	exit
fi

readarray -t lines < "$clips_file"
count=${#lines[@]}
cursor="$(cat /tmp/clippaste-cursor)"
test -z "$cursor" && cursor=0
done=0
key=
echo -e '\e[?25l'
while test "$done" == "0"; do
	clear
	for i in `seq 0 $(( $count - 1 ))`; do
		if test "$i" == "$cursor"; then echo -n '>>  '; else echo -n '    '; fi
		echo "${lines[$i]}"
	done
	read -s -N 1 key
	case "$key" in
		j)
			cursor=$(( $cursor + 1 ))
			;;
		k)
			cursor=$(( $cursor - 1 ))
			;;
		l)
			echo -n "${lines[$cursor]}" | xsel -i -b
			done=1
			;;
		h|q|)
			done=1
			;;
	esac
	if test "$cursor" -lt 0; then cursor=$(( $count - 1 )); fi
	if test "$cursor" -ge $count; then cursor=0; fi
done
echo -e '\e[?25h'
echo $cursor >| /tmp/clippaste-cursor
