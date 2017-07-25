#!/bin/bash

dir="$HOME/.cache/switch-pulseaudio-sink"
sink_input="$( pacmd list-sink-inputs | grep 'index:' | head -1 | cut -d : -f 2 )"
sink_output=

case "$(cat "$dir/current.index")" in
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
test -n "$sink_input" && pacmd 'move-sink-input' "$sink_input" "$sink_output"
