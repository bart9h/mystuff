#!/bin/bash
eval $(xdotool getmouselocation --shell)
xdotool mousemove 20 $(( $(xwininfo -root|grep Height:|cut -d : -f 2|sed s/\ //g) - 10 ))
xdotool click 1
xdotool mousemove $X $Y
