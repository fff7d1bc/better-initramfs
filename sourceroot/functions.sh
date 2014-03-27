#!/bin/sh
# better-initramfs project
# https://bitbucket.org/piotrkarbowski/better-initramfs
# Copyright (c) 2010-2013, Piotr Karbowski <piotr.karbowski@gmail.com>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
#    * Redistributions of source code must retain the above copyright notice,
#      this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright notice,
#      this list of conditions and the following disclaimer in the documentation
#      and/or other materials provided with the distribution.
#    * Neither the name of the Piotr Karbowski nor the names of its contributors
#      may be used to endorse or promote products derived from this software
#      without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE

einfo() { echo -ne "\033[1;30m>\033[0;36m>\033[1;36m> \033[0m${*}\n" ;}
ewarn() { echo -ne "\033[1;30m>\033[0;33m>\033[1;33m> \033[0m${*}\n" >&2;}
eerror() { echo -ne "\033[1;30m>\033[0;31m>\033[1;31m> ${*}\033[0m\n" >&2 ;}
die() { eerror "$*"; rescueshell; }


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
	if [ -c '/dev/tty1' ]; then
		setsid sh -c 'exec sh --login </dev/tty1 >/dev/tty1 2>&1'
	else
		sh --login
	fi
	echo
	:> /rescueshell.pid
}

was_shell() {
	[ -f '/rescueshell.pid' ]
	return $?
}

run() {
	if "$@"; then
		echo "Executed: '$@'" >> /init.log
	else
		eerror "'$@' failed."
		echo "Failed: '$@'" >> /init.log
		echo "$@" >> /.ash_history
		rescueshell
	fi
}

get_opt() {
	echo "${*#*=}"
}

run_hooks() {
	# Support for optional code injection via hooks placed into
	# multiple initramfs images.
	if [ -d "/hooks/$1" ]; then
		for i in /hooks/$1/*; do
			[ "$i" = "/hooks/$1/*" ] && break
			einfo "Running hook:" $i
			[ -x "$i" ] && . "$i"
		done
	fi
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

process_commandline_options() {
	for i in $(cat /proc/cmdline); do
		case "${i}" in
			initramfsdebug)
				set -x
			;;
			root\=*)
				root=$(get_opt $i)
			;;
			init\=*)
				init=$(get_opt $i)
			;;
			enc_root\=*)
				enc_root=$(get_opt $i)
			;;
			luks)
				luks=true
			;;
			lvm)
				lvm=true
			;;
			softraid)
				softraid=true
			;;
			rescueshell)
				rescueshell=true
			;;
			swsusp)
				swsusp=true
			;;
			uswsusp)
				uswsusp=true
			;;
			tuxonice)
				tuxonice=true
			;;
			resume\=*)
				resume=$(get_opt $i)
			;;
			rootfstype\=*)
				rootfstype=$(get_opt $i)
			;;
	
			rootflags\=*)
				rootfsmountparams="-o $(get_opt $i)"
			;;
	
			ro|rw)
				root_rw_ro=$i
			;;
			sshd)
				sshd=true
			;;
			sshd_wait\=*)
				sshd_wait=$(get_opt $i)
			;;
			sshd_port\=*)
				sshd_port=$(get_opt $i)
			;;
			sshd_interface\=*)
				# deprecated
				sshd_interface=$(get_opt $i)
			;;
			sshd_ipv4\=*)
				# deprecated
				sshd_ipv4=$(get_opt $i)
			;;
			sshd_ipv4_gateway\=*)
				# deprecated
				sshd_ipv4_gateway=$(get_opt $i)
			;;
			binit_net_if\=*)
				binit_net_if=$(get_opt $i)
			;;
			binit_net_addr\=*)
				binit_net_addr=$(get_opt $i)
			;;
			binit_net_gw\=*)
				binit_net_gw=$(get_opt $i)
			;;
			rootdelay\=*)
				rootdelay=$(get_opt $i)
			;;
			mdev)
				mdev=true
			;;
			luks_no_discards)
				luks_no_discards=true
			;;
		esac
	done
}

use() {
	name="$(eval echo \$$1)"
	# Check if $name isn't empty and if $name isn't set to false or zero.
	if [ -n "${name}" ] && [ "${name}" != 'false' ]; then
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
		run mkdir -m 700 -p "${dir}"
	done
}

loadkeymap() {
	if [ -f /keymap ]; then
		loadkmap < /keymap
	fi
}

get_majorminor() {
	local device="$1"
	musthave device

	local major_hex="$(stat -L -c '%t' "${device}")"
	local minor_hex="$(stat -L -c '%T' "${device}")"

	musthave major_hex minor_hex

	if [ -n "${major_hex}" ] && [ -n "${minor_hex}" ]; then
		printf '%u:%u\n' "0x${major_hex}" "0x${minor_hex}"
	fi
}

InitializeLUKS() {
	if [ ! -f /bin/cryptsetup ]; then
		eerror "There is no cryptsetup binary into initramfs image."
		rescueshell
	fi

	musthave enc_root
	
	local enc_num='1'
	local dev_name="enc_root"
	# We will use : to separate devices but we need normal IFS inside the for loop anyway.
	local IFS=":"
	for enc_dev in ${enc_root}; do
		IFS="${default_ifs}"
		if ! [ "${enc_num}" = '1' ]; then
			dev_name="enc_root${enc_num}"
		fi

		resolve_device enc_dev

		einfo "Opening encrypted partition '${enc_dev##*/}' and mapping to '/dev/mapper/${dev_name}'."

		# Hack for cryptsetup which trying to run /sbin/udevadm.
		run echo -e "#!/bin/sh\nexit 0" > /sbin/udevadm
		run chmod 755 /sbin/udevadm

		local cryptsetup_args=""
		if ! use luks_no_discards; then
			cryptsetup_args="${cryptsetup_args} --allow-discards"
		fi

		if use sshd; then
			askpass "Enter passphrase for ${enc_dev}: " | run cryptsetup --tries 1 --key-file=- luksOpen ${cryptsetup_args} "${enc_dev}" "${dev_name}"
			# Remove the fifo, askpass will create new if needed (ex multiple devices).
			rm '/luks_passfifo'
		else
			run cryptsetup luksOpen --tries 25 ${cryptsetup_args} "${enc_dev}" "${dev_name}"
		fi
		enc_num="$((enc_num+1))"
	done
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
}

SwsuspResume() {
	musthave resume
	resolve_device resume
	if [ -f '/sys/power/resume' ]; then
		local resume_majorminor="$(get_majorminor "${resume}")"
		musthave resume_majorminor
		echo "${resume_majorminor}" > /sys/power/resume
	else
		ewarn "Apparently this kernel does not support suspend."
	fi
}

UswsuspResume() {
	musthave resume
	resolve_device resume
	if [ -f '/sys/power/resume' ]; then
		run resume --resume_device "${resume}"
	else
		ewarn "Apparently this kernel does not support suspend."
	fi
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

SetupNetwork() {
	# backward compatibility
	if [ "${sshd_interface}" ]; then
		ewarn "sshd_interface is deprecated, check README"
		ewarn "and switch to binit_net_if!"
		binit_net_if="${sshd_interface}"
		binit_net_addr="${sshd_ipv4}"
		binit_net_gw="${sshd_ipv4_gateway}"
	fi

	# setting _interface is the trigger.
	# after dropping backward compatibility there should be
	# a 'use FOO && SetupNetwork' in init script.
	use binit_net_if || return

	musthave binit_net_addr

	run ip link set up dev lo

	einfo "Setting ${binit_net_addr} on ${binit_net_if} ..."
	run ip link set up dev "${binit_net_if}"
	run ip addr add "${binit_net_addr}" dev "${binit_net_if}"

	if [ -n "${binit_net_gw}" ]; then
		einfo "Setting default routing via '${binit_net_gw}' ..."
		run ip route add default via "${binit_net_gw}" dev "${binit_net_if}"
	fi
}

setup_sshd() {
	# Prepare /dev/pts.
	einfo "Mounting /dev/pts ..."
	if ! [ -d /dev/pts ]; then run mkdir /dev/pts; fi
	run mount -t devpts none /dev/pts

	# Prepare dirs.
	dodir /etc/dropbear /var/log /var/run /root/.ssh

	# Generate host keys.
	einfo "Generating dropbear ssh host keys ..."
	test -f /etc/dropbear/dropbear_rsa_host_key || run dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key > /dev/null
	test -f /etc/dropbear/dropbear_dss_host_key || run dropbearkey -t dss -f /etc/dropbear/dropbear_dss_host_key > /dev/null

	# Prepare root account.
	run echo 'root:x:0:0:root:/root:/bin/sh' > /etc/passwd

	if [ -f /authorized_keys ]; then
		run cp /authorized_keys /root/.ssh/authorized_keys
	else
		eerror "Missing /authorized_keys file, you will be no able login via sshd."
		rescueshell
	fi

	einfo 'Starting dropbear sshd ...'
	run dropbear -s -p "${binit_net_addr%/*}:${sshd_port:-22}"
}

wait_sshd() {
	if use sshd_wait; then
		# sshd_wait exist, now we should sleep for X sec.
		if [ "${sshd_wait}" -gt 0 2>/dev/null ]; then
			einfo "Waiting ${sshd_wait}s (sshd_wait)"
			while [ ${sshd_wait} -gt 0 ]; do
				[ -f '/remote-rescueshell.lock' ] && break
				sshd_wait=$((sshd_wait - 1))
				sleep 1
			done
		else
			ewarn "\$sshd_wait variable must be numeric and greater than zero. Skipping sshd_wait."
		fi
	fi
}

cleanup() {
	if use binit_net_if; then
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

	fi

	was_shell && rm /rescueshell.pid

	if use sshd; then
		run pkill -9 dropbear > /dev/null 2>&1
	fi

	if use binit_net_if; then
		run ip addr flush dev "${binit_net_if}"
		run ip route flush dev "${binit_net_if}"
		run ip link set down dev "${binit_net_if}"
	fi
}

boot_newroot() {
	init="${init:-/sbin/init}"
	einfo "Switching root to /newroot and executing ${init}."
	if ! [ -x "/newroot/${init}" ]; then die "There is no executable '/newroot/${init}'."; fi
	exec env -i TERM="${TERM:-linux}" PATH="${PATH:-/bin:/sbin:/usr/bin:/usr/sbin}" switch_root /newroot "${init}"
}

emount() {
	# All mounts into one place is good idea.
	while [ "$#" -gt 0 ]; do
		case $1 in
			'/newroot')
				if mountpoint -q '/newroot'; then
					einfo "/newroot already mounted, skipping..."
				else	
					einfo "Mounting /newroot..."
					musthave root
					if [ -n "${rootfstype}" ]; then local mountparams="${rootfsmountparams} -t ${rootfstype}"; fi
					resolve_device root
					run mount -o ${root_rw_ro:-ro} ${mountparams} "${root}" '/newroot'
				fi
			;;

			'/newroot/usr')
				if [ -f '/newroot/etc/fstab' ]; then
						while read device mountpoint fstype fsflags _; do
						if [ "${mountpoint}" = '/usr' ]; then
							if [ -d '/newroot/usr' ]; then
								einfo "Mounting /newroot/usr..."
								run mount -o "${fsflags},${root_rw_ro:-ro}" -t "${fstype}" "${device}" '/newroot/usr'
							else
								die "/usr in fstab present but no mountpoint /newroot/usr found."
							fi
							break
						fi
					done < '/newroot/etc/fstab'
				else
					ewarn "No /newroot/etc/fstab present."
					ewarn "Early mouting of /usr will not be done."
				fi
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
	if use mdev; then run echo '' > /proc/sys/kernel/hotplug; fi
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

# vim: noexpandtab
