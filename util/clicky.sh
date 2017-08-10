#!/bin/bash
max_dist=8
location_delay=5
delay0=5
delay1=10

echo 'Move the mouse pointer to the clicky location.'
for i in `seq $location_delay -1 1`; do
	echo -n "$i ... "
	sleep 1s || exit
done

eval $(xdotool getmouselocation --shell)
OX=$X
OY=$Y
echo "Got ($X,$Y)."

while sleep $delay0; do
	for i in `seq $delay1`; do
		echo -n .
		sleep 1 || break
	done
	eval $(xdotool getmouselocation --shell)
	DX=$(($OX-$X))
	DY=$(($OY-$Y))
	dx=$( sed 's/-//' <<< $DX )
	dy=$( sed 's/-//' <<< $DY )
	if [[ $dx -le $max_dist && $dy -le $max_dist ]]; then
		echo "click"
		xdotool click 1
	else
		echo "($DX,$DY)"
	fi
done
