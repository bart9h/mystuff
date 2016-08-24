#!/bin/bash

function v()
{
	if test "$1"; then
		vim -o "$@"
	elif git rev-parse --git-dir >/dev/null 2>&1 \
	&&   git status --porcelain --untracked-files=no | grep '^.M' >/dev/null
	then
		(
			pwd="$(sed 's/\ /\\\ /g' <<< $PWD)"
			cd "$(git rev-parse --git-dir)/.." &&
			git status --porcelain --untracked-files=no |
				grep '^.M' |
				cut -c 4- |
				exec xargs -d '\n' $ETC/bash/vim_tty +"chdir $pwd" -o
		)
	elif find -maxdepth 1 -type f | grep . >/dev/null 2>&1; then
		vim "$(
			find -maxdepth 1 -type f -not -name '.*' -print0 |
			xargs -0 file |
			grep ':.*\<text\>' |
			cut -d : -f 1 |
			xargs ls -1t |
			head -1
		)"
	else
		vim .
	fi
}
