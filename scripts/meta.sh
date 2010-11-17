#!/bin/bash

set -e

workdir="$(readlink -f $(dirname $0))"
. $workdir/core.sh || exit 1

ewarn "New better-initramfs is not backward compatible, read ChangeLog file.\n"

bin() {
	[ -d ${initramfs_root}/bin ] && \
		(ewarn "cleanup binary files"; rm -fr ${initramfs_root}/bin; mkdir -p ${initramfs_root}/bin) || mkdir -p ${initramfs_root}/bin 
	[ -d ${initramfs_root}/lib ] && \
		(ewarn "cleanup library files"; rm -fr ${initramfs_root}/lib; mkdir -p ${initramfs_root}/lib) || mkdir -p ${initramfs_root}/lib 

	einfo 'Preparing binary files...'
	$workdir/dobin /bin/busybox && \
		( cd $initramfs_root/bin && if [ ! -h sh ]; then ln -s busybox sh; fi && if [ ! -h bb ]; then ln -s busybox bb; fi)
	$workdir/dobin /sbin/cryptsetup
	$workdir/dobin /sbin/lvm.static lvm
	$workdir/dobin /usr/bin/strace
        $workdir/dobin /usr/sbin/dropbear
        $workdir/dobin /usr/bin/dropbearkey
}

etc() {
	[ -d ${initramfs_root}/etc ] && \
		(ewarn "cleanup etc files"; rm -fr ${initramfs_root}/etc; mkdir -p ${initramfs_root}/etc) || mkdir -p ${initramfs_root}/etc 

	einfo 'Preparing etc files...'
	cp -p /etc/hosts ${initramfs_root}/etc
	cp -p /etc/host.conf ${initramfs_root}/etc
	cp -p /etc/localtime ${initramfs_root}/etc
	cp -p /etc/nsswitch.conf ${initramfs_root}/etc
	cp -p /etc/resolv.conf ${initramfs_root}/etc
	cp -pr /etc/pam.d ${initramfs_root}/etc
	grep -e "^root" /etc/group > ${initramfs_root}/etc/group
	grep -e "^root" /etc/passwd | sed s/\\/bash/\\/sh/ > ${initramfs_root}/etc/passwd
	sudo grep -e "^root" /etc/shadow > ${initramfs_root}/etc/shadow
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
	image)
		image
	;;
	all)
		bin && etc && image
	;;
esac
