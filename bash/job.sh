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

	local max_jobs=$( show cpus )

	test -d "$spool_dir" || mkdir "$spool_dir" || exit

	while test $( ls "$spool_dir" | wc -l ) -ge $max_jobs; do
		sleep 1s
	done

	(
		job=$( mktemp "$spool_dir"/job.XXXXXX )
		test -f "$job" || exit
		"$@"
		rm "$job"
	)&
}

