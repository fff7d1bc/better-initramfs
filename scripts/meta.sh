#!/bin/bash
# -*- mode: shell-script; coding: utf-8-emacs-unix; sh-basic-offset: 8; indent-tabs-mode: t -*-

set -e

workdir="$(readlink -f $(dirname $0))"
. $workdir/core.sh || exit 1

ewarn "New better-initramfs is not backward compatible, read ChangeLog file.\n"

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

case $1 in
	bin)
		bin
	;;
	image)
		image
	;;
	all)
		bin && image
	;;
esac
