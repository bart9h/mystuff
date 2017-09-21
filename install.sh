#!/bin/bash

cd "$HOME"  || exit 1

test -z "$ETC" && ETC='etc'
if ! test -d "$ETC"; then
	echo "no directory \"$ETC\""
	exit 1
fi

function L() {
	local from="$ETC/$1"
	local to="$HOME/$2"

	if test -e "$to"; then
		if test "`readlink "$to"`" == "$from"; then
			echo "$to already points to $from, skipping."
			return
		fi
		local bk="${to}.before-install"
		if test -e "$bk"; then
			echo "$bk already exists, aborting."
			exit 1
		fi
		mv -v "$to" "$bk"
	fi
	ln -sv "$from" "$to"  || exit 1
}

L bash/bashrc    .bashrc
L etc/gitconfig  .gitconfig
L etc/inputrc    .inputrc
L mplayer        .mplayer
L etc/screenrc   .screenrc
L etc/tigrc      .tigrc
L vim            .vim
L x11/xsession   .xsession

vundle_dir="$HOME/.vim/bundle/vundle"
if test -e "$vundle_dir"; then
	echo "$vundle_dir already exists, skipping."
else
	git clone https://github.com/gmarik/vundle.git "$vundle_dir" \
		&& vim +BundleInstall +qall
fi
