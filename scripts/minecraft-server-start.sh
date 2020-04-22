#!/bin/bash
set -e
if test -n "$1" -a "$1" == "f"; then
	echo "Skipping backup!"
else
	world="$(grep '^level-name=' server.properties | cut -d = -f 2-)"
	if test -z "$world"; then
		echo "Couldn't find \"level-name=\" line in server.properties."
		exit
	fi
	echo "World is \"$world\""
	if test -e "$world-1.tar"; then
		test -e "$world-2.tar" && rm -v "$world-2.tar"
		mv -v "$world"-1.tar "$world"-2.tar
	fi
	test -e "$world-0.tar" && mv -v "$world-0.tar" "$world-1.tar"
	test -e "$world" && tar cf "$world-0.tar" "$world"/
fi
exec java -Xmx1024M -Xms1024M -jar server.jar nogui "$@"
