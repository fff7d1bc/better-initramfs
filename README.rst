================
better-initramfs
================

.. contents:: Table of Contents

Usecase
=======
- Boot from rootfs on encrypted storage, software raid, lvm or all of them together.
- Minimal rescue environment, also available remotely! SSH into initramfs before system boots, fix, for example, broken network scripts and boot it normaly.
- Choose rootfs over its LABEL or UUID, no more problems with wrong root variable because you added few hard disks.
- Debug, new kernel and kernel panic with unable to mount rootfs? Check in rescue shell if you have your disks in /dev, see dmesg if the kernel initialized hard disk controller.

Features
========
- Support for LVM.
- Support for dmcrypt LUKS
- Support for software RAID
- Rescue shell
- Remote rescue shell, available over ssh.
- UUID/LABEL support for root and enc_root
- Support for resume from TuxOnIce, in-kernel suspend (swsusp) and Userspace Software Suspend (uswsusp).



Use binary packages
===================

- Go to the https://github.com/slashbeast/better-initramfs/downloads and download tarball.
- Unpack and read README.binary and README.rst

Build from source
=================

Fetch
-----

Clone git repository from github::

        git clone https://github.com/slashbeast/better-initramfs.git


Build
-----
::

        bootstrap/bootstrap-all
        make prepare
        make image

The first one will fetch `Rob Landley's Aboriginal Linux <http://landley.net/aboriginal/>`_ root-filesystem image (about 25-27M), unpack it and prepare basic devices nodes (null, zero, random, urandom), next it will build in order busybox, lvm2, zlib, dropbear, libuuid, popt, libgpg-error, libgcrypt, cryptsetup, mdadm, libx86, pciutils, lzo and suspend. The build process takes about 2 minutes on first generation mobile Core i5. As the build process is done in chroot, you need to do it as root.
``make prepare`` will copy binaries from ``bootstrap/output`` into ``sourceroot/bin``.
``make image`` will pack sourceroot into cpio gzip archive. See about_ section for informations about why we build tools that way.

Parameters
==========

rescueshell
  drop to rescueshell just before mount rootfs to /newroot.
sshd
  Run sshd server. Let you ssh into initramfs on error, to input password for encrypted rootfs, or to fix something remotly.
sshd_wait=X
  Wait X seconds after setting up sshd, useful when you want to login (and thus pause boot process) before booting real system.
sshd_port=X
  Setup sshd to listen on X port. Default: 22.
sshd_interface=<if>
  Set an interface to what ssh deamon should bind to. Example: eth0
sshd_ipv4=<addr/cidr>
  Configure <addr> with <cidr> netmask on sshd_interface. Usualy you want something like '1.2.3.4/24'. If you will not add /CIDR, the IP will be configured with /32 thus you will be not able to connect to it unless you specify sshd_ipv4_gateway.
sshd_ipv4_gateway=<addr>
  Optional gateway config, if you want to connect via WAN.
rw
  Mount rootfs in read-write. Default: read-only.
mdev
  Don't check if kernel support devtmpfs, use mdev instead. (Useful for really old kernels).
softraid
  Get up raid arrays
init=X
  Run X after switching to newroot, Default: /sbin/init.
tuxonice
  try resuming with TuxOnIce. Depends on resume= variable which points to the device with image, usualy swap partition.
uswsusp
  try resuming with userspace software suspend. Depends on resume= variable which points to the device with the system snapshot, usually swap partition.
swsusp
  try resuming with swusps (in-kernel suspend). Depends on resume= variable which points to the device with system snapshot, usually swap partition.
resume=<device/path>
  Specify device from which you want to resume (with tuxonice or uswsusp).
lvm
  Scan all disks for volume groups and activate them.
luks
  do ``cryptsetup luksOpen`` on enc_root variable.
enc_root=<device>
  for example ``/dev/sda2`` if sda2 is your encrypted rootfs. This variable is ignored if luks isn't enabled. You can specify multiple devices with colon as spearator, like ``enc_root=/dev/sda2:/dev/sdb2:/dev/vda1``.
root=<device>
  for example ``/dev/mapper/enc_root`` if you have LUKS-encrypted rootfs, ``/dev/mapper/vg-rootfs`` or similar if lvm or just ``/dev/sdXX`` if you haven't rootfs over lvm or encrypted.
rootfstype=<filesystem type>
  Set type of filesystem on your rootfs if you do not want to use 'auto',
rootdelay=<integer>
  Set how many seconds initramfs should wait [for devices]. Useful for rootfs on USB device.
rootflags=X
  pass X flag(s) to mount while mounting rootfs, you can use it to specify which btrfs subvolume you want to mount.
luks_trim
  Enable TRIM support on LUKS-encrypted device, (SSD)

Remote rescue shell
===================

In order to use remote rescue shell you need to place your authorized_keys file into sourceroot/ dir before you run ``make image``. The in-initramfs sshd server support only keypair-based authorization.

Examples
========

Rootfs over encrypted lvm's pv (extlinux config)::

        LABEL kernel1_bzImage-3.2.2-frontier2
                MENU LABEL Gentoo Linux bzImage-3.2.2-frontier2
                LINUX /bzImage-3.2.2-frontier2
                INITRD /initramfs.cpio.gz
                APPEND rootfstype=ext4 luks enc_root=/dev/sda2 lvm root=/dev/mapper/vg-rootfs

Rootfs over software raid1 with remote rescueshell and rootfs over LABEL::

        LABEL kernel1_bzImage-3.2.2-frontier2
                MENU LABEL Gentoo Linux bzImage-3.2.2-frontier2
                LINUX /bzImage-3.2.2-frontier2
                INITRD /initramfs.cpio.gz
                APPEND softraid root=LABEL=rootfs sshd sshd_wait=10 sshd_port=2020 sshd_interface=eth0 sshd_ipv4=172.16.0.8/24

About
=====
The better-initramfs started from the need to boot from dmcrypted rootfs and the genkernel's initramfs looked like wrong idea in so many ways. Later I was in need to support  LVM, LVM over dmcrypt and dmcrypt over LVM, it ended with a several copies of code 'cryptlvm-initramfs' 'lvmcrypt-initramfs' and so on. So I decided to rename one of the 'best' copies into better-initramfs and make it flexible yet simple to read, understand and improve. The better-initramfs is host independent, thanks to the Aboriginal linux, we do build all the tools (and its deps) inside Aboriginal, with uClibc. The uClibc have many adventages over common used glibc, it is not so bloated, the static binaries are really static (static dropbear still need glibc's libc, libnss and friends to work!) and the size of uclibc-powered binaries is about 50% or even more smaller than the glibc one. For me, better-initramfs's (remote)rescueshell, among other features, is great replacement for livecd and other rescue systems for most of the incidents when I need to change/fix/adjust something what can't be done on booted system.

License
=======
This code is released under Simplified BSD License, see LICENSE for more information.

Author
======
better-initramfs maintained by:
        Piotr Karbowski <piotr.karbowski@gmail.com>
        Check contributors in ``git log``.

