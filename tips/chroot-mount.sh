#!/bin/sh
test -n "$1" && chroot_dir="$1" || chroot_dir="/mnt"
if test -d "$chroot_dir"; then
	mount --types proc /proc "$chroot_dir"/proc &&
	mount --rbind /sys "$chroot_dir"/sys &&
	mount --rbind /dev "$chroot_dir"/dev
else
	echo "$0: $chroot_dir: no dir"
fi
