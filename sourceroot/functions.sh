#!/bin/sh
# -*- mode: shell-script; coding: utf-8-emacs-unix; sh-basic-offset: 8; indent-tabs-mode: t -*-
# This code is under Simplified BSD License, see LICENSE for more info
# Copyright (c) 2010, Piotr Karbowski
# All rights reserved.

einfo() { echo -ne "\033[1;30m>\033[0;36m>\033[1;36m> \033[0m${@}\n" ;}
ewarn() { echo -ne "\033[1;30m>\033[0;33m>\033[1;33m> \033[0m${@}\n" >&2;}
eerror() { echo -ne "\033[1;30m>\033[0;31m>\033[1;31m> ${@}\033[0m\n" >&2 ;}

InitializeBusybox() {
	einfo "Create all the symlinks to /bin/busybox."
	run /bin/busybox --install -s
}

rescueshell() {
	if [ "$rescueshell" != 'true' ]; then
		# If we did not forced rescueshell by kernel opt, print additional message.
		ewarn "Dropping to rescueshell because of above error."
	fi

	ewarn "Rescue Shell (busybox's /bin/sh)"
	ewarn "To reboot, press 'control-alt-delete'."
	ewarn "If you wish resume booting process, run 'resume-boot'."
	/bin/sh --login
	echo
	rm /rescueshell.pid
	}

run() {
	if "$@"; then
		echo "Executed: '$@'" >> /init.log
	else
		eerror "'$@' failed."
		echo "Failed: '$@'" >> /init.log
		rescueshell
	fi
}

get_opt() {
	echo "$@" | cut -d "=" -f 2-
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
		run mkdir -p "$dir"
	done
}

loadkeymap() {
	if [ -f /keymap ]; then
		loadkmap < /keymap
	fi
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
	if ! [ -f '/etc/mdadm.conf' ]; then
		run mdadm --examine --scan > /etc/mdadm.conf
	fi
	run mdadm --assemble --scan
	run mdadm --auto-detect
}

TuxOnIceResume() {
	musthave resume
	if [ -f '/sys/power/tuxonice/do_resume' ]; then
		einfo "Sending do_resume signal to TuxOnIce."
		run echo 1 > /sys/power/tuxonice/do_resume
	else
		ewarn "Apparently this kernel does not support TuxOnIce."
	fi
}

setup_sshd() {
	musthave sshd_ipv4 sshd_interface

	einfo "Setting ${sshd_ipv4} on ${sshd_interface} ..."
	run ip addr add "${sshd_ipv4}" dev "${sshd_interface}"
	run ip link set up dev "${sshd_interface}"
	
	# Prepare /dev/pts.
	einfo "Mounting /dev/pts ..."
	if ! [ -d /dev/pts ]; then run mkdir /dev/pts; fi
	run mount -t devpts none /dev/pts

	# Prepare dirs.
	dodir /etc/dropbear /var/log /var/run /root/.ssh

	# Generate host keys.
	einfo "Generating dropbear ssh host keys ..."
	run dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key > /dev/null
	run dropbearkey -t dss -f /etc/dropbear/dropbear_dss_host_key > /dev/null

	# Prepare root account.
	run echo 'root:x:0:0:root:/root:/bin/sh' > /etc/passwd

	if [ -f /authorized_keys ]; then
		run cp /authorized_keys /root/.ssh/authorized_keys
	else
		eerror "Missing /autorized_keys file, you will be no able login via sshd."
		rescueshell
	fi

	if [ -n "${sshd_port}" ]; then
		# append : to the begin of port.
		# Todo: make check for numeric value of port.
		sshd_port=":${sshd_port}"
	fi

	einfo 'Starting dropbear sshd ...'
	run dropbear -s -j -k -p "${sshd_ipv4%/*}${sshd_port}"

	if use sshd_wait; then
		# sshd_wait exist, now we should sleep for X sec.
		if [ "${sshd_wait}" -gt 0 2>/dev/null ]; then
			einfo "Waiting ${sshd_wait}s (sshd_wait)"
				run sleep "${sshd_wait}"
		else
			ewarn "\$sshd_wait variable must be numeric and greater than zero. Skipping sshd_wait."
		fi
	fi

}

cleanup() {
	if use sshd; then
		if [ -f '/remote-rescueshell.lock' ]; then
			ewarn "The lockfile at '/remote-rescueshell.lock' exist."
			ewarn "The boot process will be paused until the lock is removed."
			while true; do
				if [ -f '/remote-rescueshell.lock' ]; then
					sleep 1
				else
					break
				fi
			done
		fi
		einfo "Cleaning up, killing dropbear and bringing down the network ..."
		run pkill -9 dropbear > /dev/null 2>&1
		run ip addr del "${sshd_ipv4}" dev "${sshd_interface}" > /dev/null 2>&1
	fi
}

boot_newroot() {
	if [ -x "/newroot/${init:-/sbin/init}" ]; then
		einfo "Switching root to /newroot and executing /sbin/init."
		exec switch_root /newroot "${init-/sbin/init}"
	fi
}

emount() {
	# All mounts into one place is good idea.
	while [ "$#" -gt 0 ]; do
		case $1 in
			'/newroot')
				einfo "Mounting /newroot..."
				if [ -n "${rootfstype}" ]; then local mountparams="${rootfsmountparams} -t ${rootfstype}"; fi
				resolve_device root
				run mount -o ${root_rw_ro:-ro} ${mountparams} "${root}" '/newroot'
			;;

			'/newroot/usr')
				if ! [ -f '/newroot/etc/fstab' ]; then
					eerror "Missing /newroot/etc/fstab!"
					rescueshell
				fi

				if ! [ -d '/newroot/usr' ]; then
					eerror "Missing /newroot/usr mount point!"
					rescueshell
				fi

				while read device mountpoint fstype fsflags _; do
					if [ "${mountpoint}" = '/usr' ]; then
						einfo "Mounting /newroot/usr..."
						run mount -o "${fsflags},${root_rw_ro:-ro}" -t "${fstype}" "${device}" '/newroot/usr'
					fi
				done < '/newroot/etc/fstab'
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
	while [ "$#" -gt 0 ]; do
		case "$1" in
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
	if mountpoint -q /dev/pts; then umount /dev/pts; fi
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
