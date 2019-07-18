#!/bin/bash

if mount | grep -q ' on /wd '; then
	zenity --warning --text='O HD está montado.'
else
	sudo pm-suspend
fi
