#!/bin/sh
cd "$HOME" || exit
test -z "$ETC" && ETC='etc'

function L() {
	ln -sv "$ETC/$1" "$2"
}

L bash/bashrc    .bashrc
L etc/gitconfig  .gitconfig
L etc/inputrc    .inputrc
L mplayer        .mplayer
L etc/screenrc   .screenrc
L etc/tigrc      .tigrc
L vim/vimrc      .vimrc
L vim            .vim

