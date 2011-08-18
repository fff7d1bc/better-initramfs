#!/bin/sh
# -*- mode: shell-script; coding: utf-8-emacs-unix; sh-basic-offset: 8; indent-tabs-mode: t -*-
# This code is under Simplified BSD License, see LICENSE for more info
# Copyright (c) 2010, Piotr Karbowski
# All rights reserved.

einfo() { echo -ne "\033[1;30m>\033[0;36m>\033[1;36m> \033[0m${@}\n" ;}
ewarn() { echo -ne "\033[1;30m>\033[0;33m>\033[1;33m> \033[0m${@}\n" ;}
eerror() { echo -ne "\033[1;30m>\033[0;31m>\033[1;31m> ${@}\033[0m\n" ;}

InitializeBusybox() {
	einfo "Create all the symlinks to /bin/busybox."
	run busybox --install -s
}

rescueshell() {
	if [ "$rescueshell" = 'false' ]; then
		ewarn "Dropping to rescueshell because of above error."
	fi
	ewarn "Rescue Shell (busybox's /bin/sh)"
	ewarn "To reboot, press 'control-alt-delete'."
	ewarn "If you wish continue booting process, just exit from this shell."
	/bin/sh
	}

run() { "$@" || ( eerror "$@ failed." ; rescueshell ) ;}

get_opt() {
	echo "$@" | cut -d "=" -f 2,3
}

resolve_device() {
	# This function will check if variable at $1 contain LABEL or UUID and then, if LABEL/UUID is vaild.	
	device="$(eval echo \$$1)"
	case "${device}" in
		LABEL\=*|UUID\=*)
			eval $1="$(findfs $device)"
			if [ -z "$(eval echo \$$1)" ]; then
				eerror "Wrong UUID or LABEL."
				rescueshell
			fi
		;;
	esac
}

use() {
	name="$(eval echo \$$1)"
	# Check if $name isn't empty and if $name isn't set to false or zero.
	if [ -n "${name}" ] && [ "${name}" != 'false' ] && [ "${name}" != '0' ]; then
		if [ -n "$2" ]; then
			$2
		else
			return 0
		fi
	else
		return 1
	fi
}

musthave() {
	while [ -n "$1" ]; do
		# We can handle it by use() function, yay!
		if ! use "$1"; then
			eerror "The \"$1\" variable is empty, set to false or zero but shoudn't be."
			local missing_variable='true'
		fi
		shift
	done

	if [ "${missing_variable}" = 'true' ]; then
		rescueshell
	fi
}

dodir() {
	for dir in "$@"; do
		mkdir -p "$dir"
	done
}

InitializeLUKS() {
	if [ ! -f /bin/cryptsetup ]; then
		eerror "There is no cryptsetup binary into initramfs image."
		rescueshell
	fi

	musthave enc_root
	
	einfo "Opening encrypted partition and mapping to /dev/mapper/enc_root."

	resolve_device enc_root

	# Hack for cryptsetup which trying to run /sbin/udevadm.
	run echo -e "#!/bin/sh\nexit 0" > /sbin/udevadm
	run chmod 755 /sbin/udevadm

	run cryptsetup luksOpen "${enc_root}" enc_root
}

InitializeLVM() {
	einfo "Scaning all disks for volume groups."
	# We have to ensure that cache does not exist so vgchange will run 'vgscan' itself.
	if [ -d '/etc/lvm/cache' ]; then run rm -rf '/etc/lvm/cache'; fi
	run lvm vgchange -a y
}

InitializeSoftwareRaid() {
	einfo "Scaning for software raid arrays."
	mdadm --assemble --scan
	mdadm --auto-detect
}

TuxOnIceResume() {
	if [ -n "${resume}" ]; then
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


emount() {
	# All mounts into one place is good idea.
	while [ $# -gt 0 ]; do
		case $1 in
			'/newroot')
				einfo "Mounting /newroot..."
				if [ -n "${rootfstype}" ]; then local mountparams="${rootfsmountparams} -t ${rootfstype}"; fi
				resolve_device root
				run mount -o ro ${mountparams} "${root}" '/newroot'
			;;
	
			'/dev')
				local devmountopts='nosuid,relatime,size=10240k,mode=755'

				if grep -q 'devtmpfs' '/proc/filesystems' && ! use mdev; then
					einfo "Mounting /dev (devtmpfs)..."
					run mount -t devtmpfs -o ${devmountopts} devtmpfs /dev
				else
					einfo "Mounting /dev (mdev over tmpfs)..."
					run mount -t tmpfs -o ${devmountopts} dev /dev
					run touch /etc/mdev.conf
					run echo /sbin/mdev > /proc/sys/kernel/hotplug
					run mdev -s
					# Looks like mdev create /dev/pktcdvd as a file when both udev and devtmpfs do it as a dir. 
					# We will do it 'better' to avoid non-fatal-error while starting udev after switching to /newroot.
					# TODO: Can mdev.conf handle it?
					if [ -c '/dev/pktcdvd' ]; then
						run rm '/dev/pktcdvd'
						run mkdir '/dev/pktcdvd'
						run mknod '/dev/pktcdvd/control' c 10 61
					fi
				fi
			;;

			'/proc')
				einfo "Mounting /proc..."
				run mount -t proc proc /proc
			;;

			'/sys')
				einfo "Mounting /sys..."
				run mount -t sysfs sysfs /sys
			;;

			*)
				eerror "emount() does not understand \"$1\""
			;;
		esac
		shift
	done
}

eumount() {
	while [ $# -gt 0 ]; do
		case $1 in
			*)
				einfo "Unmounting ${1}..."
				run umount "$1"
			;;
		esac
		shift
	done
}	

moveDev() {
	einfo "Moving /dev to /newroot/dev..."
	run mount --move /dev /newroot/dev
}

rootdelay() {
	if [ "${rootdelay}" -gt 0 2>/dev/null ]; then
		einfo "Waiting ${rootdelay}s (rootdelay)"
		run sleep ${rootdelay}
	else
		ewarn "\$rootdelay variable must be numeric and greater than zero. Skipping rootdelay."
	fi
}
