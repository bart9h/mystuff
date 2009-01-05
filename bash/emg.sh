#!/bin/bash

function emg()
{
	local db="$HOME/var/portage.db"

	case "$1" in

	s)
		shift
		grep -i "$*" "$db" | less --quit-if-one-screen
		;;

	u)
		shift
		sudo ionice -c 3 emerge --sync &&
		ionice -c 3 find /usr/portage/ -type f -name '*.ebuild' | sort | (
			while read a; do
				echo -n "$a  " | \
				sed 's/^\/usr\/portage\///;s/\/[^/]\+\//\//;s/\.ebuild  $/  /'
				grep -m 1 'DESCRIPTION' "$a" | \
				sed 's/^DESCRIPTION=//'
			done
		) >| "$db"
		;;
	
	m)
		fluxbox-generate_menu -is -ds
		;;

	*)
		sudo nice ionice -c 3 emerge -v --ask "$@"
		;;

	esac
}

