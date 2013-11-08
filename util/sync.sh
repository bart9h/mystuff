#!/bin/sh
ionice -c2 -n7 \
sudo rsync \
	--archive \
	--verbose \
	--delete \
	--delete-excluded \
	--one-file-system \
	--exclude-from="$ETC/etc/exclude-pattern" \
	"$@"
