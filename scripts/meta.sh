#!/bin/bash
# -*- mode: shell-script; coding: utf-8-emacs-unix; sh-basic-offset: 8; indent-tabs-mode: t -*-

set -e

workdir="$(readlink -f $(dirname $0))"
. $workdir/core.sh || exit 1

ver="$(cat $workdir/../VERSION)"

einfo "better-initramfs v${ver}"
ewarn "Remember to check ChangeLog file after every update.\n"

bin() {
	einfo 'Preparing binary files...'
	$workdir/dobin /bin/busybox && ( cd $initramfs_root/bin && if [ ! -h sh ]; then ln -s busybox sh; fi )
	$workdir/dobin /sbin/cryptsetup
	$workdir/dobin /sbin/lvm.static lvm
}

image() {
	einfo 'Building image...'
	$workdir/doimage.sh
}

clean() {
	if [ -n "$(ls $initramfs_root/bin/)" ]; then
		for file in $initramfs_root/bin/*; do
			einfo "Cleaning ${file##*/}..."
			rm -f $file
		done
	else
		ewarn "Nothing to clean."
	fi
}

case $1 in
	bin|image|clean)
		$1
	;;
	all)
		bin && image
	;;
esac
