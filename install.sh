#!/bin/bash

cd "$HOME"  || exit 1

test -z "$XDG_CONFIG_HOME" && XDG_CONFIG_HOME="$HOME/.config"

test -z "$ETC" && ETC="$HOME/etc"
if ! test -d "$ETC"; then
	echo "no directory \"$ETC\""
	exit 1
fi

for cmd in git vim; do
	if test "$(which $cmd)" == ""; then
		echo "$cmd not found."
		exit
	fi
done

function LINK() {
	local from="$1"
	local to="$2"

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

function L() {
	LINK "$ETC/$1" "$HOME/$2"
}

L bash/bashrc    .bashrc
L etc/inputrc    .inputrc
L mplayer        .mplayer
L etc/screenrc   .screenrc
L etc/tigrc      .tigrc
L vim            .vim
L x11/xsession   .xsession

git_dir="$XDG_CONFIG_HOME/git"
test -d "$git_dir" || mkdir -v -p "$git_dir"
LINK "$ETC/etc/gitconfig"  "$git_dir/config"

vundle_dir="$HOME/.vim/bundle/vundle"
if test -e "$vundle_dir"; then
	echo "$vundle_dir already exists, skipping."
else
	git clone https://github.com/gmarik/vundle.git "$vundle_dir" \
		&& vim +PluginInstall +qall
fi
