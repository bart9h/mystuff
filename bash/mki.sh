#!/bin/bash

function mki()
{
	case "$1" in
	NVIDIA-Linux-*|*/NVIDIA-Linux-*)
		sudo sh "$1" \
				--silent \
				--no-network
	;;

	*)
	local date=`date +%Y%m%d`
	local name="`basename $PWD`"
	[ "$name" == "src" ] && name="`basename $(cd ..; echo $PWD)`"

	local args
	if test -d 'CVS'; then
		args="--pkgversion=cvs-$date"
	elif test -d '.svn'; then
		local rev=$( svn info | grep '^Revision:\ \+[0-9]\+$' | cut -d ' ' -f 2 )
		local ver
		if test "$rev" -ge 1; then
			ver="r$rev"
		else
			ver="$date"
		fi
		args="--pkgversion=svn-$ver"
	elif test -d '.git'; then
		args="--pkgversion=git-$date"
	else
		name="`echo "$name" | cut -d - -f 1`"
	fi

	local cmd
	if test -f SConstruct -o -f Sconstruct -o -f sconstruct; then
		cmd="scons install"
	else
		cmd="make install"
	fi

	local t
	if test -e /etc/slackware-version; then
		t=slackware
	elif test -e /etc/debian_version; then
		t=debian
	else
		echo 'nope'; false; return
	fi

	cmd="sudo checkinstall --fstrans=no --type=$t --nodoc --pkgname=\"$name\" $args $CHECKINSTALL_ARGS $cmd"
	echo "$cmd"
	read -p "proceed ([y]/n)? " answer
	test "$answer" == "y" -o "$answer" == "" || return
	$cmd
	;;
	esac
}

