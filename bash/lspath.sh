#!/bin/bash

function lspath()
{
	local path="$1"
	grep -q '^/' <<< "$path" || path="$PWD/$path"

	declare -a paths
	local i=0
	while test "$path" != "/"; do
		paths[$i]="$path"
		path="$(dirname "$path")"
		let i=i+1
	done
	ls -d -l "${paths[@]}"
}
