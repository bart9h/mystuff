#!/bin/sh
set -e
fsb="/proc/eee/fsb"
test -e $fsb
for i in 75 80 85 90 95 100; do
	echo $i 24 0 >$fsb
	test $i -eq 100 || sleep 1s
done
