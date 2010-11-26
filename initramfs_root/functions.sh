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

resolve_device() {
	device=$(eval echo \$$1)

	case $device in
		LABEL\=*|UUID\=*)
			eval $1=$(findfs $device)
		;;
	esac
	
	if [ -z "$(eval echo \$$1)" ]; then
		eerror "Wrong UUID/LABEL."
		droptoshell
	fi
}

use() {
	name="$(eval echo \$$1)"
	if [ -n "$name" ] && [ "$name" = 'true' ]; then
		return 0
	else
		return 1
	fi
}

dodir() {
	for dir in $*; do
		mkdir -p $dir
	done
}

initluks() {
	if [ ! -f /bin/cryptsetup ]; then
		eerror "There is no cryptsetup binary into initramfs image."
		droptoshell
	fi

	if [ -z $enc_root ]; then
		eerror "You have enabled luks but your \$enc_root variable is empty."
		droptoshell
	fi
	
	einfo "Opening encrypted partition and mapping to /dev/mapper/enc_root."
	resolve_device enc_root
	if [ -z $enc_root ]; then
        	eerror "\$enc_root variable is empty. Wrong UUID/LABEL?"
	        droptoshell
	fi

	# Hack for cryptsetup which trying to run /sbin/udevadm.
	run echo -e "#!/bin/sh\nexit 0" > /sbin/udevadm
	run chmod 755 /sbin/udevadm

	run cryptsetup luksOpen "${enc_root}" enc_root
}

initlvm() {
	einfo "Scaning all disks for volume groups."
	run lvm vgscan
	run lvm vgchange -a y
}

initmdadm() {
	einfo "Scaning for software raid arrays."
	mdadm --assemble --scan
	mdadm --auto-detect
}

dotuxonice() {
	if [ ! -z $resume ]; then
		if [ ! -f /sys/power/tuxonice/do_resume ]; then
			ewarn "Your kernel do not support TuxOnIce.";
		else
			einfo "Sending do_resume signal to TuxOnIce."
			run echo 1 > /sys/power/tuxonice/do_resume
		fi
	else
		ewarn "resume= variable is empty, not cool, skipping tuxonice."
	fi
}

mountdev() {
	einfo "Initiating /dev (devtmpfs)."
	if ! mount -t devtmpfs devtmpfs /dev 2>/dev/null; then
	ewarn "Unable to mount devtmpfs, missing CONFIG_DEVTMPFS? Switching to busybox's mdev."
	mdev_fallback="true"
	einfo "Initiating /dev (mdev)."
	run touch /etc/mdev.conf # Do we really need this empty file?
	run echo /sbin/mdev > /proc/sys/kernel/hotplug
	run mdev -s
	fi
}

mountroot() {
	mountparams="-o ro"
	if [ -n "$rootfstype" ]; then mountparams="$mountparams -t $rootfstype"; fi
	einfo "Mounting rootfs to /newroot."
	resolve_device root
	run mount $mountparams "${root}" /newroot
}
