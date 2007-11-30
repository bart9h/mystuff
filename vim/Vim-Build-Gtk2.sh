#!/bin/sh

./configure \
	--enable-perlinterp \
	--enable-gui=gtk2 \
	--disable-nls \
&& make clean && nice make -j2  && ldd src/vim
