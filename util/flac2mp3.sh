#!/bin/bash
set -e

case "$1" in
	""|--help)
		echo "$0  [--mono]  <source-dir>  [<destination-basedir> (default=/tmp)]"
		exit
		;;
	--mono)
		mono="-m s -a"
		shift
		;;
esac

folder="$(basename "$1")"
if test -z "$2"; then dest="/tmp"; else dest="$2"; fi

echo "Convert these files to mp3 in folder \"$dest/$folder\":"
ls "$1"/*.flac
echo -n "Enter to proceed..."
read

mkdir -pv "$dest/$folder"

for flac in "$1/"*.flac; do

	base="$(basename "$flac" | sed 's/.flac$//')"
	wav="/tmp/${base}.wav"
	mp3="${dest}/${folder}/${base}.mp3"

	flac -d "$flac" -o "$wav"
	#nice lame $mono -q -v -V 5 "$wav" "$mp3"
	if test -z "$LAMEOPTS"; then
		echo "nice lame $mono -h -v \"$wav\" \"$mp3\""
		nice lame $mono -h -v "$wav" "$mp3"
	else
		echo "nice lame $LAMEOPTS \"$wav\" \"$mp3\""
		nice lame $LAMEOPTS "$wav" "$mp3"
	fi
	rm -f -v "$wav"

done
cp -v "$1/"*.jpg "$dest/$folder/"
