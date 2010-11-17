#!/bin/bash

set -e

workdir="$(readlink -f $(dirname $0))"
. $workdir/core.sh || exit 1

ewarn "New better-initramfs is not backward compatible, read ChangeLog file.\n"

bin() {
	einfo 'Preparing binary files...'
	[ -d ${initramfs_root}/bin ] && \
		(ewarn "cleanup binary files"; rm -fr ${initramfs_root}/bin; mkdir -p ${initramfs_root}/bin) || mkdir -p ${initramfs_root}/bin 
	$workdir/dobin /bin/busybox && \
		( cd $initramfs_root/bin && if [ ! -h sh ]; then ln -s busybox sh; fi && if [ ! -h bb ]; then ln -s busybox bb; fi)
	$workdir/dobin /sbin/cryptsetup
	$workdir/dobin /sbin/lvm.static lvm
	# add
	$workdir/dobin /usr/bin/strace
	cp -p /usr/sbin/dropbear ${initramfs_root}/bin
	cp -p /usr/bin/dropbearkey ${initramfs_root}/bin
	
}

etc() {
	einfo 'Preparing etc files...'
	[ -d ${initramfs_root}/etc ] && \
		(ewarn "cleanup etc files"; rm -fr ${initramfs_root}/etc; mkdir -p ${initramfs_root}/etc) || mkdir -p ${initramfs_root}/etc 
	cp -p /etc/hosts ${initramfs_root}/etc
	cp -p /etc/localtime ${initramfs_root}/etc
	cp -p /etc/nsswitch.conf ${initramfs_root}/etc
	grep -e "^root" /etc/group > ${initramfs_root}/etc/group
	grep -e "^root" /etc/passwd | sed s/\\/bash/\\/sh/ > ${initramfs_root}/etc/passwd
	echo -n > ${initramfs_root}/etc/shadow
	sudo grep -e "^root" /etc/shadow > ${initramfs_root}/etc/shadow
}

lib() {
	einfo 'Preparing library files...'
	[ -d ${initramfs_root}/lib ] && \
		(ewarn "cleanup library files"; rm -fr ${initramfs_root}/lib; mkdir -p ${initramfs_root}/lib) || mkdir -p ${initramfs_root}/lib 
	cp -flp /lib/ld-* ${initramfs_root}/lib
	cp -flp /lib/libc-* ${initramfs_root}/lib
	cp -flp /lib/libc.* ${initramfs_root}/lib
	cp -flp /lib/libpam_* ${initramfs_root}/lib
	cp -flp /lib/libdl* ${initramfs_root}/lib
	cp -flp /lib/lib*compat* ${initramfs_root}/lib
	cp -flp /lib/libutil* ${initramfs_root}/lib
	cp -flp /lib/libz.* ${initramfs_root}/lib
	cp -flp /lib/libcrypt* ${initramfs_root}/lib
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
		bin && etc && lib && image
	;;
esac
