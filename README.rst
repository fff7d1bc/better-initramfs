================
better-initramfs
================

.. FIXME: Make website better, add style for <h2>.

.. contents:: Table of Contents

How can it be useful?
==========================
- Debug your brand-new kernel. For example, you got kernel panic unable to mount rootfs and you really don't know where the problem is, missing filesystems support in kernel or maybe missing support for your SCSI/SATA/whatever or your 2nd sata controller driver started before 1st and your 'sda' is 'sdb'. Really, initramfs sh is very useful. You can check dmesg, you can check /dev for devices and try to mount rootfs manually to get the error.
- Luks encrypted rootfs.
- LVM-based rootfs,
- System rescue tool.

Features
========
- Support for LVM.
- Support for dmcrypt Luks.
- Support for booting from rootfs over encrypted lvm (encrypted lv or encrypted pv).
- Support for TuxOnIce
- Support for **UUID** and **LABEL** based root and enc_root.
- RescueShell

Download
====================

.. important:: Be aware! Current code is under heavy development, make sure to read **ChangeLog** before starting with better-initramfs.

Clone git repository from github::

        git clone https://github.com/slashbeast/better-initramfs.git

If you want fully working version, after clone switch to **v0.3** tag.::

        git checkout v0.3

Usage
=====
This doc is based on Funtoo/Gentoo GNU/Linux so package names etc. can be different than in your distro.

Prepare static linked binary files (emerge with USE=static):
::

        sys-apps/busybox (must-have)
        sys-fs/cryptsetup (optional, if you don't use dmcrypt)
        sys-fs/lvm2 (optional, if you don't use LVM)

Build initramfs:
::

        make

If you don't have Funtoo/Gentoo-based system, you may need to install binary files manualy, go to initramfs_root/bin dir and:
::

        cp -v /bin/busybox busybox
        cp -v /sbin/cryptsetup cryptsetup
        cp -v /sbin/lvm.static lvm
        ln -s busybox sh

Then build image with:
::

        make image


Available kernel boot parameters:

rescueshell
  drop to busybox's sh just before mount rootfs to /newroot.
tuxonice
  try resuming with TuxOnIce. Remember to set resume= variable by **kernel** boot params.
resume=<device/path>
  Use only with *tuxonice* switch, set resume device/file. This have nothing to do with initramfs..
lvm
  Scan all disks for volume groups and activate them.
luks
  do ``cryptsetup luksOpen`` on enc_root variable.
enc_root=<device>
  for example ``/dev/sda2`` if sda2 is your encrypted rootfs. This variable is ignored if luks isn't enabled.
root=<device>
  for example ``/dev/mapper/enc_root`` if you have LUKS-encrypted rootfs, ``/dev/mapper/vg-rootfs`` or similar if lvm or just ``/dev/sdXX`` if you haven't rootfs over lvm or encrypted.
rootfstype=<filesystem type>
  Set type of filesystem on your rootfs if you do not want to use 'auto',
rootdelay=<integer>
  Set how many seconds initramfs should wait [for devices]. Useful for rootfs on USB device.


Example
=======
Few example on grub(1) config, all switches and variables are configured by kernel boot command line.


Dmcrypted rootfs::

        title Funtoo bzImage-2.6.32-gentoo-r5
        kernel /bzImage-2.6.32-gentoo-r5 root=/dev/mapper/enc_root enc_root=/dev/sda2 luks
        initrd /initramfs.cpio.gz

LVM based rootfs::

        title Funtoo bzImage-2.6.32-gentoo-r5
        kernel /bzImage-2.6.32-gentoo-r5 root=/dev/mapper/main-rootfs lvm
        initrd /initramfs.cpio.gz

LVM based rootfs, rescueshell::

        title Funtoo bzImage-2.6.32-gentoo-r5
        kernel /bzImage-2.6.32-gentoo-r5 root=/dev/mapper/main-rootfs lvm rescueshell
        initrd /initramfs.cpio.gz

Rootfs on LVM over dmcrypt (encrypted pv) with tuxonice and rootfstype env::

        title Funtoo bzImage-2.6.33
        kernel /bzImage-2.6.33 luks enc_root=/dev/sda2 lvm root=/dev/mapper/vg-rootfs rootfstype=ext4 resume=swap:/dev/mapper/vg-swap tuxonice
        initrd /initramfs.cpio.gz

License
=======
This code is released under Simplified BSD License, see LICENSE for more information.

Author
======
better-initramfs is written and maintained by:
        Piotr Karbowski <jabberuser@gmail.com>

Thanks to:
        Yamashita Takao for testing and code suggestions.
