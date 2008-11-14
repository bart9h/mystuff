#!/bin/bash

function emg()
{
	local db="$HOME/var/portage.db"

	case "$1" in
	s)
		shift
		grep -i "$*" "$db"
		;;

	u)
		shift
		find /usr/portage/ -type f -name '*.ebuild' | (
			while read a; do
				echo -n "$a  " | \
				sed 's/^\/usr\/portage\///;s/\/[^/]\+\//\//;s/\.ebuild  $/  /'
				grep -m 1 'DESCRIPTION' "$a" | \
				sed 's/^DESCRIPTION=//'
			done
		) >| "$db"
		;;
	
	*)
		sudo emerge -v --ask "$@"
		;;

	esac
}

