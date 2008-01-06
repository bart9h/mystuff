#!/bin/bash

# xrdb don't accept '#' comments anymore
sed \
		';s/^[\ \t]\+//;/^\#/d' \
		"$HOME/src/etc/Xdefaults" \
| xrdb

