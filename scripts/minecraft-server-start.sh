#!/bin/bash

# Refuse to run if not inside a screen(1).
if test -z "$STY"; then
	echo "No screen."
	exit
fi

# Function to create and rotate a backup.
backup() {
	world="$1"
	sufix="$2"
	if test -e "${world}-${sufix}-1.tar"; then
		test -e "${world}-${sufix}-2.tar" && rm -v "${world}-${sufix}-2.tar"
		mv -v "${world}-${sufix}-1.tar" "${world}-${sufix}-2.tar"
	fi
	test -e "${world}-${sufix}-0.tar" && mv -v "${world}-${sufix}-0.tar" "${world}-${sufix}-1.tar"
	echo "Creating \"${world}-${sufix}-0.tar\""
	tar cf "${world}-${sufix}-0.tar" "${world}"/
}

sleep_if_stop_exit() {
	seconds="$1"
	for i in `seq 1 $seconds`; do
		test -e ".stop" && exit
		sleep 1
	done
}

# Automatic world backup thread.
if test "$1" == "--backup-thread"; then
	world="$2"
	sty="$3"
	window="$4"
	mc_cmd() {
		screen -S "$sty" -p "$window" -X stuff "$2$(printf '\r')"
		sleep_if_stop_exit "$1"
	}
	mc_cmd 45 "say §1Iniciando loop de backup automático"
	while true; do
		sleep_if_stop_exit 1500
		mc_cmd 45 "say §2backup iniciando 1 minuto"
		mc_cmd 10 "say §2backup iniciando 15 segundos"
		mc_cmd 4 "say §abackup em 5s..."
		mc_cmd 1 "say §abackup em 1s..."
		mc_cmd 0 "say §6FAZENDO BACKUP..."
		mc_cmd 1 "save-off"
		mc_cmd 1 "save-all"
		sleep_if_stop_exit 5
		backup "$world" "auto"
		mc_cmd 0 "save-on"
		mc_cmd 0 "say §1backup pronto."
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
	backup "$world" "start"
fi

# Start the automatic world backup thread.
rm -f ".stop"
"$0" --backup-thread "$world" "$STY" "$WINDOW" &

# Finally, start the server.
java -Xmx1024M -Xms1024M -jar server.jar nogui "$@"

# Finish the automatic world backup thread.
touch ".stop"
