#!/bin/sh
# -*- mode: shell-script; coding: utf-8-emacs-unix; sh-basic-offset: 8; indent-tabs-mode: t -*-
# This code is under Simplified BSD License, see LICENSE for more info
# Copyright (c) 2010, Piotr Karbowski
# All rights reserved.

einfo() { echo -ne "\033[1;30m>\033[0;36m>\033[1;36m> \033[0m${@}\n" ;}
ewarn() { echo -ne "\033[1;30m>\033[0;33m>\033[1;33m> \033[0m${@}\n" ;}
eerror() { echo -ne "\033[1;30m>\033[0;31m>\033[1;31m> ${@}\033[0m\n" ;}

droptoshell() {
	if [ $rescueshell = 'false' ]; then
		ewarn "Dropping to rescueshell because of above error."
	fi
	ewarn "Rescue Shell (busybox's /bin/sh)"
	ewarn "To reboot, press 'control-alt-delete'."
	ewarn "If you wish continue booting process, just exit from this shell."
	/bin/sh
	}

run() { "$@" || ( eerror $@ 'failed.' ; droptoshell ) ;}

get_opt() {
	echo "$@" | cut -d "=" -f 2,3
}

get_device() {
	device=$1
	case $device in
		LABEL\=*|UUID\=*)
			findfs $device
		;;
		*)
			echo $device
		;;
	esac
}

dodir() {
	for dir in $*; do
		mkdir -p $dir
	done
}

dolvm() {
	if [ ! -f /bin/lvm ]; then
		eerror "There is no lvm binary into initramfs image."
		droptoshell
	fi
	einfo "Scaning all disks for volume groups."
	lvm vgscan && lvm vgchange -a y
}

