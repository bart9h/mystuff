#!/bin/sh

test -d "$PREFIX" || PREFIX=/usr/local

case "$1" in
	''|'text'|'no-gui'|'nogui')
		./configure \
			--prefix="$PREFIX" \
			--disable-nls \
			--enable-multibyte \
			--enable-perlinterp \
			--enable-pythoninterp \
			--enable-gui=no \
			--without-x \
			|| exit
	;;
	'gui')
		./configure \
			--prefix="$PREFIX" \
			--disable-nls \
			--enable-multibyte \
			--enable-perlinterp \
			--enable-pythoninterp \
			--enable-gui=gtk2 \
			|| exit
	;;
	*)
		echo '?'
		exit
	;;
esac

make clean && nice make -j2  && ldd src/vim

