#!/bin/bash

function job()
{
	local spool_dir="/tmp/jobs"

	if test "$1" == "wait"; then
		while test $( ls "$spool_dir" | wc -l ) -ge 1; do
			sleep 1s
		done
		return
	fi

	if test -z "$*"; then
		ls "$spool_dir"
		return
	fi

	local max_jobs=
	if test "$MAX_JOBS" != ""; then
		max_jobs="$MAX_JOBS"
	else
		max_jobs=$(( $( show cpus ) + 1 ))
	fi

	test -d "$spool_dir" || mkdir "$spool_dir" || exit

	while test $( ls "$spool_dir" | wc -l ) -ge $max_jobs; do
		sleep 1s
	done

	(
		job=$( mktemp "$spool_dir"/job.XXXXXX )
		test -f "$job" || exit
		nice "$@"
		rm "$job"
	)&
}

if test -n "$1" -a -z "$job_function_loaded"; then
	job "$@"
else
	job_function_loaded=1
fi
