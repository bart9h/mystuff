#!/bin/bash
max_dist=8
location_delay=5
click_delay=10
last_click=-9999
verbose=0

echo 'Move the mouse pointer to the clicky location.'
for i in `seq $location_delay -1 1`; do
	echo -n "$i ... "
	sleep 1s || exit
done

eval $(xdotool getmouselocation --shell)
OX=$X
OY=$Y
echo "Got ($X,$Y)."

while sleep 1; do
	eval $(xdotool getmouselocation --shell)
	DX=$(($OX-$X))
	DY=$(($OY-$Y))
	dx=$( sed 's/-//' <<< $DX )
	dy=$( sed 's/-//' <<< $DY )
	if [[ $dx -le $max_dist && $dy -le $max_dist ]]; then
		if [[ $(( $SECONDS - $last_click )) -ge $click_delay ]]; then
			test "$verbose" == "1" && echo "click"
			xdotool click 1
			last_click=$SECONDS
		else
			test "$verbose" == "1" && echo -n "$(( $click_delay - $SECONDS + $last_click )) "
		fi
	else
		test "$verbose" == "1" && echo "($DX,$DY)"
		last_click=-9999
	fi
done