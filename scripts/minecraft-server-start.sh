#!/bin/bash

# Refuse to run if not inside a screen(1).
if test -z "$STY"; then
	echo "No screen."
	exit
fi

# Automatic world backup thread.
if test "$1" == "--backup-thread"; then
	world="$2"
	sty="$3"
	window="$4"
	mc_cmd() {
		test -e ".stop" && exit
		screen -S "$sty" -p "$window" -X stuff "$2$(printf '\r')"
		sleep "$1"
	}
	while true; do
		sleep 1200
		mc_cmd 45 "say backup iniciando 1 minuto"
		mc_cmd 10 "say backup iniciando 15 segundos"
		for i in $(seq 5 -1 1); do
			mc_cmd 1 "say backup em ${i}s..."
		done
		mc_cmd 0 "say FAZENDO BACKUP..."
		mc_cmd 1 save-off
		mc_cmd 1 save-all
		tar cf "$world-auto.tar" "$world"/
		mc_cmd 0 save-on
		mc_cmd 0 "say BACKUP PRONTO."
	done
fi

# Get world name from server.properties file.
world="$(grep '^level-name=' server.properties | cut -d = -f 2-)"

# Sanity check
if test -z "$world"; then
	echo "Couldn't find \"level-name=\" line in server.properties."
	exit
fi
if test ! -d "$world"; then
	echo "Couldn't find directory \"$world\"."
	exit
fi
echo "World is \"$world\""

# Make a backup of the world before starting the server.
set -e
if test -n "$1" -a "$1" == "f"; then
	echo "Skipping backup!"
else
	if test -e "$world-1.tar"; then
		test -e "$world-2.tar" && rm -v "$world-2.tar"
		mv -v "$world"-1.tar "$world"-2.tar
	fi
	test -e "$world-0.tar" && mv -v "$world-0.tar" "$world-1.tar"
	test -e "$world" && tar cf "$world-0.tar" "$world"/
fi

# Start the automatic world backup thread.
rm -f ".stop"
"$0" --backup-thread "$world" "$STY" "$WINDOW" &

# Finally, start the server.
java -Xmx1024M -Xms1024M -jar server.jar nogui "$@"

# Finish the automatic world backup thread.
touch ".stop"
