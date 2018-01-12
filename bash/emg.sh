#!/bin/bash

function _emg_update_cache()
{
	echo "Updating emg quick search (emg s) cache..."
	ionice -c 3 find /usr/portage/ -type f -name '*.ebuild' | sort | (
		while read a; do
			echo -n "$a  " | \
			sed 's/^\/usr\/portage\///;s/\/[^/]\+\//\//;s/\.ebuild  $/  /'
			grep -m 1 'DESCRIPTION' "$a" | \
			sed 's/^DESCRIPTION=//'
		done
	) >| "$cachefile"
	echo "... done."
}

function emg()
{
	local cachefile="$HOME/.local/emg.cache"

	case "$1" in

	"")
		cat << EOF
            s:  quick search
            d:  fix /etc conflicts (dispatch-conf)
            n:  read the news (eselect news read)
            u:  update package info (emerge --sync; update quick search cache)
            w:  upgrade all (emerge --deep --newuse @world)
			c:  clean (eclean disfiles)
anything else:  emerge ...
EOF
		;;

	s)
		shift
		test -s "$cachefile" || _emg_update_cache
		grep -i "$*" "$cachefile" | less --quit-if-one-screen
		;;

	d)
		sudo dispatch-conf
		;;

	n)
		sudo eselect news read
		;;

	u)
		shift
		sudo ionice -c 3 emerge --sync &&
		_emg_update_cache
		;;

	w)
		sudo emerge --ask --ask-enter-invalid --update --deep --newuse @world
		;;

	c)
		sudo eclean distfiles
		;;

	m)
		fluxbox-generate_menu -is -ds
		;;

	*)
		sudo nice ionice -c 3 emerge -v --ask --ask-enter-invalid "$@"
		;;

	esac
}

