#!/bin/sh

set -e # bail out on error

file="$1"
mv -iv "$file" "$file.deaf"

rm_text_in_brackets='s/\[[^]]\+\]//g'
rm_lines_without_text='s/^[^A-Za-z0-9]\+$//'
rm_cr='s///'
strip_spaces='s/^\ //;s/\ $//'

cat "$file.deaf" |
sed -e "$rm_cr" \
	-e "$rm_text_in_brackets" \
	-e "$rm_lines_without_text" \
	-e "$strip_spaces" \
> "$file"

