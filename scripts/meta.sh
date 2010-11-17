#!/bin/bash

set -e

workdir="$(readlink -f $(dirname $0))"
. $workdir/core.sh || exit 1

ewarn "New better-initramfs is not backward compatible, read ChangeLog file.\n"

bin() {
	[ -d ${initramfs_root}/bin ] && \
		(ewarn "cleanup binary files"; $sudo rm -fr ${initramfs_root}/bin; mkdir -p ${initramfs_root}/bin) || mkdir -p ${initramfs_root}/bin 
	[ -d ${initramfs_root}/lib ] && \
		(ewarn "cleanup library files"; $sudo rm -fr ${initramfs_root}/lib; mkdir -p ${initramfs_root}/lib) || mkdir -p ${initramfs_root}/lib 

	einfo 'Preparing binary files...'
	$sudo $workdir/dobin /bin/busybox && \
		( cd $initramfs_root/bin && if [ ! -h sh ]; then $sudo ln -s busybox sh; fi && if [ ! -h bb ]; then $sudo ln -s busybox bb; fi)
	$sudo $workdir/dobin /sbin/cryptsetup
	$sudo $workdir/dobin /sbin/lvm.static lvm
	$sudo $workdir/dobin /usr/bin/strace
        $sudo $workdir/dobin /usr/sbin/dropbear
        $sudo $workdir/dobin /usr/bin/dropbearkey
        $sudo $workdir/dobin /bin/login
        $sudo $workdir/dobin /usr/bin/passwd
}

etc() {
	[ -d ${initramfs_root}/etc ] && \
		(ewarn "cleanup etc files"; $sudo rm -fr ${initramfs_root}/etc; mkdir -p ${initramfs_root}/etc) || mkdir -p ${initramfs_root}/etc 

	einfo 'Preparing etc files...'
	$sudo cp -p /etc/hosts ${initramfs_root}/etc
	$sudo cp -p /etc/host.conf ${initramfs_root}/etc
	$sudo cp -p /etc/localtime ${initramfs_root}/etc
	$sudo cp -p /etc/nsswitch.conf ${initramfs_root}/etc
	$sudo cp -p /etc/resolv.conf ${initramfs_root}/etc
	$sudo cp -pr /etc/pam.d ${initramfs_root}/etc
	$sudo grep -e "^root" /etc/group > ${initramfs_root}/etc/group
	$sudo grep -e "^root" /etc/passwd | sed s/\\/bash/\\/sh/ > ${initramfs_root}/etc/passwd
	$sudo grep -e "^root" /etc/shadow > ${initramfs_root}/etc/shadow
	$sudo chown root:root ${initramfs_root}/etc/group
	$sudo chown root:root ${initramfs_root}/etc/passwd
	$sudo chown root:root ${initramfs_root}/etc/shadow
	$sudo chmod 0600 ${initramfs_root}/etc/shadow

}

image() {
	einfo 'Building image...'
	$workdir/doimage.sh
}

clean() {
	einfo 'Cleanup image...'
	$sudo rm -fr ${initramfs_root}/bin ${initramfs_root}/lib ${initramfs_root}/etc initramfs.cpio.gz
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
	clean)
		clean
	;;
esac
