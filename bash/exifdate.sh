#!/bin/bash

function exifdate()
{
	for file in "$@"; do
		local output="$(exiftool -DateTimeOriginal "$file" | cut -d : -f 2-)"
		test -z "$output" && output=' no exif date found'
		echo "$file: $output"
	done
}
