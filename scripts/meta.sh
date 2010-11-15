#!/bin/bash

set -e

workdir="$(readlink -f $(dirname $0))"
. $workdir/core.sh || exit 1

ewarn "New better-initramfs is not backward compatible, read ChangeLog file.\n"

bin() {
	einfo 'Preparing binary files...'
	$workdir/dobin /bin/busybox && \
		( cd $initramfs_root/bin && if [ ! -h sh ]; then ln -s busybox sh; fi && if [ ! -h bb ]; then ln -s busybox bb; fi)
	$workdir/dobin /sbin/cryptsetup
	$workdir/dobin /sbin/lvm.static lvm
	# add
	$workdir/dobin /usr/bin/dbclient
	$workdir/dobin /usr/bin/dbscp
	$workdir/dobin /sbin/modprobe
	$workdir/dobin /sbin/modinfo
	$workdir/dobin /sbin/update-modules
	$workdir/dobin /sbin/depmod
	$workdir/dobin /sbin/rmmod
	$workdir/dobin /sbin/lsmod
	$workdir/dobin /sbin/insmod
	
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
