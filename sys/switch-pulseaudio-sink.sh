#!/bin/bash
#
# Switches pulseaudio sink output,
# updating a png image to be displayed with gkrellkam.
#

dir="$HOME/.cache/switch-pulseaudio-sink"
sink_inputs="$( pacmd list-sink-inputs | grep 'index:' | cut -d : -f 2 )"
sink_output=

case "$( cat "$dir/current.index" )" in
	1)
		sink_output=0
		ln -s -f "/usr/share/icons/mate/48x48/devices/audio-card.png" "$dir/current.png"
		;;
	*)
		sink_output=1
		ln -s -f "/usr/share/icons/mate/48x48/devices/video-display.png" "$dir/current.png"
		;;
esac

echo "$sink_output" > "$dir/current.index"
pacmd 'set-default-sink' "$sink_output"
for i in $sink_inputs; do
	pacmd 'move-sink-input' "$i" "$sink_output"
done
