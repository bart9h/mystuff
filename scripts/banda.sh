#!/bin/bash
#
# banda
# inacuratedly monitors network bandwidth
#
# Rodolfo Borges  aka barrett9h
# (C)2005 under GPL  http://www.gnu.org/copyleft/gpl.html
#
# TODO: better measure of time
# 

format='Kb/s'
divider=1024
tx_trigger=
rx_trigger=
trigger_count_max=8

#=options:
while [ "$1" ]; do
	case "$1" in
		-u|--upload-trigger)
			#=    <-u|--upload-trigger> | <-d|--download-trigger> $n
			#=        set triggers to exit if value goes bellow the trigger
			if expr match "$2" "[0-9]" >/dev/null; then
				let tx_trigger="$2"*1024
				shift
			else
				let tx_trigger=12*1024
			fi
		;;
		-d|--download-trigger)
			if expr match "$2" "[0-9]" >/dev/null; then
				let rx_trigger="$2"*1024
				shift
			else
				let rx_trigger=16*1024
			fi
		;;
		-t|--trigger-count)
			#=    <-t|--trigger-count> $n
			#=        activate trigger only after $n consecutive hits
			shift
			trigger_count_max="$1"
		;;
		-b|--bits-per-second)
			#=    <-b|--bits-per-second>
			#=        use Kbits/s instead of the default Kbytes/s
			format='Kbps'
			divider=128
		;;
		-v|--verbose)
			#=    <-v|--verbose>
			#=        show bandwidth even if waiting for trigger
			verbose=1
		;;
		-h|--help)
			# take help text from lines starting with '#=' in this program
			cat "$0" | sed 's/[\ \t]*//' | grep '^#=' | cut -d '=' -f '2-'
			exit
		;;
		*)
			echo unknown arg \"$1\"
			exit
		;;
	esac
	shift
done

rxa=-1
txa=-1
trigger_count=0

while true; do

	# get current totals of transmitted and received bytes
	proc_output=$(cat /proc/net/dev | grep eth0 | cut -d ':' -f 2)
	rx=$(echo $proc_output | cut -d ' ' -f 1)
	tx=$(echo $proc_output | cut -d ' ' -f 9)

	if [ $rxa != -1 ]; then

		let txd=$tx-$txa
		let rxd=$rx-$rxa

		if [ "$verbose" -o ! \( "$rx_trigger" -o "$tx_trigger" \) ]; then
			# show values if not in wait mode
			echo -n \
				tx $(( $txd / $divider )) $format \
				rx $(( $rxd / $divider )) $format
			for t in "$tx_trigger" "$rx_trigger"; do
				test "$t" && echo -n " (tx-t:$(( $t / $divider ));$(($trigger_count_max - $trigger_count)))"
			done
			echo
		fi

		# check trigger
		brk=-1
		if [ "$rx_trigger" ]; then
			if [ $rxd -lt $rx_trigger ]; then
				brk=1
			else
				brk=0
				trigger_count=0
			fi
		fi
		if [ "$tx_trigger" ]; then
			if [ $brk != 0 -a $txd -lt $tx_trigger ]; then
				brk=1
			else
				brk=0
				trigger_count=0
			fi
		fi

		# activate trigger
		if [ $brk == 1 ]; then
			let trigger_count=$trigger_count+1
			[ $trigger_count -ge $trigger_count_max ] && break
		fi

	fi

	rxa=$rx
	txa=$tx
	sleep 1s
done

