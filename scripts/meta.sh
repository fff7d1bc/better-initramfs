#!/bin/bash
# -*- mode: shell-script; coding: utf-8-emacs-unix; sh-basic-offset: 8; indent-tabs-mode: t -*-

set -e

workdir="$(readlink -f $(dirname $0))"
. $workdir/core.sh || exit 1

if [[ -z $1 ]]; then
	die "You shouldn't run this."
fi

ver="$(cat $workdir/../VERSION)"

einfo "better-initramfs v${ver} - home page: http://slashbeast.github.com/better-initramfs/"
ewarn "Remember to check ChangeLog file after every update.\n"

bin() {
	einfo 'Preparing binary files...'
	dobin /bin/busybox && ( cd $initramfs_root/bin && if [ ! -h sh ]; then ln -s busybox sh; fi )
	dobin /sbin/cryptsetup
	dobin /sbin/lvm.static lvm
	dobin /sbin/mdadm
}

image() {
	doimage
}

case $1 in
	bin|image|clean)
		$1
	;;
	all)
		bin && image
	;;
esac
