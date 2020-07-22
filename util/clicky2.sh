#!/bin/bash
max_dist=8
location_delay=3
last_click=-9999
verbose=0
sleep=.5
count=100

echo 'Move the mouse pointer to the clicky location.'
for i in `seq $location_delay -1 1`; do
	echo -n "$i ... "
	sleep 1s || exit
done

eval $(xdotool getmouselocation --shell)
OX=$X
OY=$Y
echo "Got ($X,$Y)."

while sleep $sleep; do
	eval $(xdotool getmouselocation --shell)
	DX=$(($OX-$X))
	DY=$(($OY-$Y))
	dx=$( sed 's/-//' <<< $DX )
	dy=$( sed 's/-//' <<< $DY )
	if [[ $dx -le $max_dist && $dy -le $max_dist ]]; then
		xdotool click --repeat $count 1
	else
		test "$verbose" == "1" && echo "($DX,$DY)"
		last_click=-9999
	fi
done
