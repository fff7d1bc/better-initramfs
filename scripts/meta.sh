#!/bin/bash

set -e

workdir="$(readlink -f $(dirname $0))"
. $workdir/core.sh || exit 1

ewarn "New better-initramfs is not backward compatible, read ChangeLog file.\n"

bin() {
	einfo 'Preparing binary files...'
    [ -d ${initramfs_root}/bin ] || mkdir -p ${initramfs_root}/bin
	$workdir/dobin /bin/busybox && \
		( cd $initramfs_root/bin && if [ ! -h sh ]; then ln -s busybox sh; fi && if [ ! -h bb ]; then ln -s busybox bb; fi)
	$workdir/dobin /sbin/cryptsetup
	$workdir/dobin /sbin/lvm.static lvm
	# add
	$workdir/dobin /usr/bin/dbclient
	$workdir/dobin /usr/bin/dbscp
	$workdir/dobin /usr/bin/dropbearkey
	$workdir/dobin /usr/sbin/dropbear
	$workdir/dobin /sbin/modprobe
	$workdir/dobin /sbin/modinfo
	$workdir/dobin /sbin/update-modules
	$workdir/dobin /sbin/depmod
	$workdir/dobin /sbin/rmmod
	$workdir/dobin /sbin/lsmod
	$workdir/dobin /sbin/insmod
	$workdir/dobin /usr/bin/strace
	
}

etc() {
    einfo 'Preparing etc files...'
    [ -d ${initramfs_root}/etc ] || mkdir -p ${initramfs_root}/etc
    cp /etc/hosts ${initramfs_root}/etc
    cp /etc/localtime ${initramfs_root}/etc
    grep -e "^root" /etc/group > ${initramfs_root}/etc/group
    grep -e "^root" /etc/passwd | sed s/\\/bash/\\/sh/ > ${initramfs_root}/etc/passwd
    echo -n > ${initramfs_root}/etc/shadow
    sudo grep -e "^root" /etc/shadow > ${initramfs_root}/etc/shadow
}

lib() {
    einfo 'Preparing lib files...'
    [ -d ${initramfs_root}/lib ] || mkdir -p ${initramfs_root}/lib
    cp -flp /lib/libnss_* ${initramfs_root}/lib
}

image() {
	einfo 'Building image...'
	$workdir/doimage.sh
}

case $1 in
	bin)
		bin
	;;
	etc)
		etc
	;;
	lib)
		lib
	;;
	image)
		image
	;;
	all)
		bin && etc && image
	;;
esac
