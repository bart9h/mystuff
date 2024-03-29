#!/bin/bash

cd "$HOME"  || exit 1

test -z "$XDG_CONFIG_HOME" && XDG_CONFIG_HOME="$HOME/.config"
test -z "$XDG_STATE_HOME" && XDG_STATE_HOME="$HOME/.local/state"

test -z "$ETC" && ETC="$HOME/etc"
if ! test -d "$ETC"; then
	echo "no directory \"$ETC\""
	exit 1
fi

for cmd in git vim; do
	if test -z "`which $cmd`"; then
		echo "$cmd not found."
		exit
	fi
done

LINK() {
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
	ln -s "$from" "$to"  || exit 1
	echo "new link $from -> $to"
}

L() {
	LINK "$ETC/$1" "$HOME/$2"
}

has() {
	which "$1" >/dev/null 2>/dev/null
}

if has nvim; then
	mkdir -p "$XDG_CONFIG_HOME/nvim"
	L nvim/init.vim "$XDG_CONFIG_HOME/nvim/"
	L nvim/lua      "$XDG_CONFIG_HOME/nvim/"
fi

if has zsh; then
	L zsh/zshrc    .zshrc
	mkdir -p "$XDG_CONFIG_HOME/zsh"
	mkdir -p "$XDG_STATE_HOME/zsh"
elif has bash; then
	L bash/bashrc  .bashrc
else
	L etc/profile  .profile
fi
L etc/inputrc      .inputrc
L etc/tmux.conf    .tmux.conf
L etc/tigrc        .tigrc
L vim              .vim
L etc/tridactylrc  .tridactylrc

if has xinit; then
	L x11/xsession   .xsession
	has mplayer && L mplayer .mplayer
fi

mkdir -p "$XDG_CONFIG_HOME/tmux"
tmux_local="$XDG_CONFIG_HOME/tmux/local"
test -e "$tmux_local" || touch "$tmux_local" # TODO: skel

git_dir="$XDG_CONFIG_HOME/git"
if ! test -d "$git_dir"; then
	echo "creating directory \"$git_dir\""
	mkdir -p "$git_dir"
fi
LINK "$ETC/etc/gitconfig"  "$git_dir/config"

vundle_dir="$HOME/.vim/bundle/vundle"
if test -e "$vundle_dir"; then
	echo "$vundle_dir already exists, skipping."
else
	git clone https://github.com/gmarik/vundle.git "$vundle_dir" \
		&& vim +PluginInstall +qall
fi
