#!/bin/bash

_emg_cachefile="$HOME/.local/emg.cache"

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
	) >| "$_emg_cachefile"
	echo "... done."
}

function _emg_emerge()
{
	sudo nice -15 ionice -c 3 emerge -v --ask --ask-enter-invalid "$@"
}

function emg()
{

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

NOTE: emerge always called as:
sudo nice ionice -c 3 emerge -v --ask --ask-enter-invalid
EOF
		;;

	s)
		shift
		test -s "$_emg_cachefile" || _emg_update_cache
		grep --color=yes -i "$*" "$_emg_cachefile" | less --quit-if-one-screen
		;;

	d)
		sudo dispatch-conf
		;;

	n)
		sudo eselect news read
		;;

	u)
		_emg_emerge --sync &&
		_emg_update_cache
		;;

	w)
		_emg_emerge --update --deep --newuse @world
		;;

	c)
		sudo eclean distfiles
		;;

	*)
		_emg_emerge "$@"
		;;

	esac
}

