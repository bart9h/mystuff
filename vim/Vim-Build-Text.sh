#!/bin/sh

./configure \
	--prefix=$PREFIX \
	--enable-perlinterp \
	--enable-multibyte \
	--enable-gui=no \
	--disable-nls \
	--without-x \
&& make clean && nice make -j2  && ldd src/vim
