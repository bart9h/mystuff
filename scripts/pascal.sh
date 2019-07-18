#!/bin/bash

max="$1"
test -n "$max" || max=$(( $LINES - 3 ))
test -n "$max" || max=20

n=0
for i in `seq $max`; do 
	n=$(( $n + $i ))
	echo $n
done
