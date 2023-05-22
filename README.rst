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
- Support for BCACHE.
- Support for LVM.
- Support for dmcrypt LUKS
- Support for software RAID
- Rescue shell
- Remote rescue shell, available over ssh.
- UUID/LABEL support for resume, root and enc_root
- Support for resume from TuxOnIce and in-kernel suspend (swsusp)

Use binary packages
===================

- Go to the https://bitbucket.org/piotrkarbowski/better-initramfs/downloads and download tarball.
- Unpack and read README.binary and README.rst

Build from source
=================

Fetch
-----

Clone git repository from bitbucket::

        git clone https://bitbucket.org/piotrkarbowski/better-initramfs.git


Build
-----
::

        make bootstrap-all
        make prepare
        make image

The first one will fetch `Rob Landley's Aboriginal Linux <http://landley.net/aboriginal/>`_ root-filesystem image (about 25-27M), unpack it and prepare basic devices nodes (null, zero, random, urandom), next it will build in order busybox, lvm2, zlib, dropbear, libuuid, popt, libgpg-error, libgcrypt, cryptsetup, mdadm, libx86, pciutils, lzo and suspend. The build process takes about 2 minutes on first generation mobile Core i5. As the build process is done in chroot, you need to do it as root.
``make prepare`` will copy binaries from ``bootstrap/output`` into ``sourceroot/bin`` and do some basic device nodes. ``make image`` will pack sourceroot into cpio gzip archive. See about_ section for informations about why we build tools that way. Check ``make help`` for more options.

Testing, new features, bug fixes.
=================================

If you want to try new features or hit any bug, check branch ``devel`` if there is no already a fix for your issue, if not then please file bug report via bitbucket's issue tracker or mail.

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
binit_net_if=<if>
  Specify on which interface the network should be configured. Optionally a vlan can be specified separated by a dot. Example: eth0 or eth0.55
binit_net_addr=<addr/cidr> or binit_net_addr=dhcp
  Configure <addr> with <cidr> netmask on binit_net_if. Usualy you want something like '1.2.3.4/24'. If you will not add /CIDR, the IP will be configured with /32 thus you will be not able to connect to it unless you specify binit_net_gw. One may put ``dhcp`` there instead of address.
binit_net_route=<addr/cidr>
  Optional static on-link route(s) to add (can be given multiple times).
binit_net_gw=<addr>
  Optional gateway config, if you want to connect via WAN. If ``binit_net_addr`` is set to ``dhcp``, it will be configured automatically.
binit_net_ns=<addr>
  Optional dns servers. (can be given multiple times for multiple dns servers). If ``binit_net_addr`` is set to ``dhcp``, it will be configured automatically.
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
swsusp
  try resuming with swusps (in-kernel suspend). Depends on resume= variable which points to the device with system snapshot, usually swap partition.
resume=<device/path>
  Specify device from which you want to resume (with tuxonice or swsusp).
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
luks_no_discards
  Disable discards support on LUKS level, use if you don't want to allow lvm layer (if used) to send discards on reduce/resize or filesystem layer on file deletions to underlaying storage thru dmcrypt luks layer. Disabling discards on SSD-type storage may noticable degradate performance over time.
bcache
  Bring up bcache devices. This will get ready for use /dev/bcache* which means one can have rootfs on bcache as well as anything else.

.. important:: The ``enc_root``, ``root`` and ``resume`` can use LABEL= and UUID=, instead of device path, like ``root=LABEL=rootfs`` or ``resume=LABEL=swap``.

Custom storage layouts like LVM, Software RAID or BCACHE and 'real' system.
===========================================================================

When one gets storage initialized on better-initramfs level there's no need for 'real' system to provide anykind of userspace support for it later (unless some crazy usecases), meaning LVM will be up and running without lvm2 installed on system, same goes for software raid without mdadm, DM Crypt LUKS without cryptsetup and bcache without bcache-tools.

From the system point of view, there are already block devices when /sbin/init of 'real' system is executed so there's no need to bring up any userspace for given storage solutions, fully transparent and effective.

Hooks
=====

Hooks let users include own code in initramfs's init process, replacing functions, variables and including additional support (like ZFS in pre_newroot_mount for example).
In order to use hooks one have to create sourceroot/hooks/<LEVEL>/ dir and put there files with exec bit. Supported levels are init, early, pre_newroot_mount, pre_switch_root.

Remote rescue shell
===================

In order to use remote rescue shell you need to place your authorized_keys file into sourceroot/ dir before you run ``make image``. The in-initramfs sshd server support only keypair-based authentication.

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


Troubleshooting
===============

A few issues incorrectly reported as better-initramfs bugs commonly enough to write them here.

My USB keyboard does not work under better-initramfs
----------------------------------------------------

Initramfs does not 'support' any kind of hardware, if your USB keyboard does not work its propably because you did not compiled USB HID drivers into your kernel or have it as modules, which aren't loaded at initramfs boot time.

Unable to mount '/newroot'
--------------------------

If you use UUID/LABEL then no, it has nothing to do with your system's fstab, it means that your root variable, like root=LABEL=rootfs is not correct and there is no filesystem with such label or your kernel does not support your storage backend which makes the partitions not accessable to the kernel. Check whatever you can see /dev/sd* nodes, if no, then propably its about missing PATA/SATA/SCSI driver from your kernel.

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

