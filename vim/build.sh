#!/bin/sh

case "$1" in
	''|'text')
		./configure \
			--prefix="$PREFIX" \
			--disable-nls \
			--enable-multibyte \
			--enable-perlinterp \
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
			--enable-gui=gtk2 \
			|| exit
	;;
	*)
		echo '?'
	;;
esac

make clean && nice make -j2  && ldd src/vim

