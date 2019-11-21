#!/bin/bash
test -z "$click_delay" && click_delay=60
max_dist=8
location_delay=5
last_click=-9999
verbose=0

echo '(note: you can use $click_delay to customize the interval (in seconds) between clicks)'
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
		if test -z "$clicky"; then
			if [[ $(( $SECONDS - $last_click )) -ge $click_delay ]]; then
				test "$verbose" == "1" && echo "click"
				active_window=$(xdotool getactivewindow)
				xdotool click 1
				xdotool windowactivate $active_window
				last_click=$SECONDS
			else
				test "$verbose" == "1" && echo -n "$(( $click_delay - $SECONDS + $last_click )) "
			fi
		else
			while sleep 1; do
				xdotool click --repeat 999 --delay 1 1
			done
		fi
	else
		test "$verbose" == "1" && echo "($DX,$DY)"
		last_click=-9999
	fi
done
