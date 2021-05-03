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
	[[ "$name" == "src" || "$name" == "build" ]] && name="`basename $(cd ..; echo $PWD)`"

	local args
	if [[ -d 'CVS' ]]; then
		args="--pkgversion=cvs-$date"
	elif [[ -d '.svn' ]]; then
		local rev=$( svn info | grep '^Revision:\ \+[0-9]\+$' | cut -d ' ' -f 2 )
		local ver
		if [[ "$rev" -ge 1 ]]; then
			ver="$rev"
		else
			ver="$date"
		fi
		args="--pkgversion=$ver-svn"
	elif [[ -d '.git' ]]; then
		args="--pkgversion=$date-git"
	else
		name="`echo "$name" | cut -d - -f 1`"
	fi

	local cmd
	if [[ -f SConstruct || -f Sconstruct || -f sconstruct ]]; then
		cmd="scons install"
	elif [[ -f build.ninja ]]; then
		cmd="ninja install"
	elif [[ -f waf ]]; then
		cmd="./waf install"
	else
		cmd="make install"
	fi

	local t
	if [[ -e /etc/slackware-version ]]; then
		t=slackware
	elif [[ -e /etc/debian_version || -e /etc/devuan_version ]]; then
		t=debian
	else
		echo 'nope'; false; return
	fi

	cmd="sudo checkinstall --fstrans=no --type=$t --nodoc --pkgname=\"$name\" $args $CHECKINSTALL_ARGS $cmd"
	echo "$cmd"
#	if [[ -n "$BASH" ]]; then
#		echo bash
#		read -p "proceed ([y]/n)? " answer
#	elif [[ -n "$ZSH_VERSION" ]]; then
#		echo zsh
#		read answer?'proceed ([y]/n)? '
#	fi
#	[[ "$answer" == "y" || "$answer" == "" ]] || return
	$cmd
	;;
	esac
}

