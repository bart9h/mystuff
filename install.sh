#!/bin/bash

cd "$HOME"  || exit 1

test -z "$ETC" && ETC='etc'
if ! test -d "$ETC"; then
	echo "no directory \"$ETC\""
	exit 1
fi

function L() {
	ln -sv "$ETC/$1" "$2"  || exit 1
}

L bash/bashrc    .bashrc
L etc/gitconfig  .gitconfig
L etc/inputrc    .inputrc
L mplayer        .mplayer
L etc/screenrc   .screenrc
L etc/tigrc      .tigrc
L vim/vimrc      .vimrc
L vim            .vim

git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle \
	&& vim +BundleInstall +qall
