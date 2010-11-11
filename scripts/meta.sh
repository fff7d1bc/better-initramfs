#!/bin/bash

set -e

workdir="$(readlink -f $(dirname $0))"
. $workdir/core.sh || exit 1

ewarn "New better-initramfs is not backward compatible, read ChangeLog file.\n"

bin() {
	$workdir/dobin /bin/busybox && ( cd $initramfs_root/bin && [ ! -h sh ] && ln -s busybox sh )
	$workdir/dobin /sbin/cryptsetup
	$workdir/dobin /sbin/lvm.static lvm
}

image() {
	$workdir/doimage.sh
}

case $1 in
	all)
		bin && image
	;;
esac
