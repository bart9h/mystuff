#!/bin/bash
/home/sft/firefox/firefox --new-window -window-size 972,1200 'http://web.whatsapp.com' &
until xwininfo -root -tree | grep -q WhatsApp; do
	sleep 1
done
xwit -move 96 908     -names 'WhatsApp' '('
xwit -resize 972 1200 -names 'WhatsApp' '('
