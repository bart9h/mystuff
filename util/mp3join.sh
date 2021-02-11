#!/bin/bash

tmp_dir=
input_list=
output_file=
i=1000

function usage() {
	echo "usage: $0 -o <output-file> <input-file-1> <input-file-2> [... <input-file-n>]"
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
				if test -z "$tmp_dir"; then
					tmp_dir="$(mktemp -d -p .)"
					input_list="$tmp_dir/list"
					echo "Created temporary dir \"$tmp_dir\"."
					trap "rm -v -f -r \"$tmp_dir\"" EXIT
				fi
				echo "Adding \"$1\" to input list."
				ln "$1" "$tmp_dir/$i"
				echo "file '$i'" >> "$input_list"
				let i=i+1
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
