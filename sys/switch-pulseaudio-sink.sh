#!/bin/bash
dir="$HOME/.cache/switch-pulseaudio-sink"
case "$(cat "$dir/current.index")" in
	1)
		pacmd set-default-sink 0
		echo 0 > "$dir/current.index"
		ln -s -f "/usr/share/icons/mate/48x48/devices/audio-card.png" "$dir/current.png"
		;;
	*)
		pacmd set-default-sink 1
		echo 1 > "$dir/current.index"
		ln -s -f "/usr/share/icons/mate/48x48/devices/video-display.png" "$dir/current.png"
		;;
esac
