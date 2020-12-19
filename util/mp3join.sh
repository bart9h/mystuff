#!/bin/bash

input_list=
output_file=

function usage() {
	echo "usage: $0 <output-file> <input-file-1> <input-file-2> [<input-file-n> ...]"
	exit 1
}

while test -n "$1"; do
	case "$1" in

		-h|--help)
			usage
			;;

		-o)
			shift
			test -z "$1" && usage
			output_file="$1"
			if test -s "$output_file"; then
				echo "ERROR: Refusing to overwrite existing file: \"$output_file\"."
				usage
			fi
			case "$output_file" in
				*.mp3)
					true
					;;
				*)
					echo "ERROR: Unsupported output file extension."
					exit 1
					;;
			esac
			;;

		*)
			if test -f "$1"; then
				if test -z "$input_list"; then
					input_list="$(mktemp -p .)"
					echo "Created temporary input list file \"$input_list\"."
					trap "rm -v \"$input_list\"" EXIT
				fi
				echo "Adding \"$1\" to input list."
				echo "file '$1'" >> "$input_list"
			else
				echo "ERROR: Not an existing file: \"$1\"."
				exit 1
			fi
			;;

	esac 
	shift
done

echo "Joining to \"$output_file\" with ffmpeg."
ffmpeg -f concat -safe 0 -i "$input_list" -c copy "$output_file"
