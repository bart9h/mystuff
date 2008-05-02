#!/bin/sh
#
# switch-kbmap
# by Rodolfo Borges <barrett@9hells.org>
# last updated 2005/01/05
#
# Switch between X keyboard maps (atm only us and us_intl, hardcoded),
# updating the status of a trayicon (Gkrellm plugin),
# and notifying with XOSD.
#


#----- USER SETTINGS

#trayicon_file=$HOME/var/run/trayicons/kbmap/br

#----- END OF USER SETTINGS


which setxkbmap > /dev/null || exit

if test "$*"; then
	kbmap="$*"
	shift
elif setxkbmap -print | grep -q intl; then
	kbmap="-layout us"
else
	kbmap="-variant intl"
fi

setxkbmap $kbmap || exit

if test "$HOSTNAME" == "lambda"; then
	xmodmap "$HOME"/etc/etc/Xmodmap.sun
elif test "$HOME" == "/u/nttx"; then
	xmodmap "$HOME"/etc/etc/Xmodmap.br
else
	xmodmap -e "remove Lock = Caps_Lock" -e "keysym Caps_Lock = Escape"
fi

if test "$trayicon_file"; then
	if test $kbmap == "-variant intl"; then
		true #false && echo -ne "\e[H\e[2J" > $trayicon_file
		touch $trayicon_file
	else
		touch $trayicon_file
	fi
fi

if which osd_cat &>/dev/null; then
	printf "setxkbmap %s\n" "$kbmap" | osd_cat \
		-p middle -A center -d 1 -s 3 -c yellow \
		-f "-*-helvetica-bold-r-*-*-24-*-*-*-*-*-*-*" &
else
	echo "setxkbmap $kbmap"
fi

