#!/bin/sh

./configure \
	--enable-perlinterp \
	--enable-gui=no \
	--disable-nls \
	--without-x \
&& make clean && nice make -j2  && ldd src/vim
