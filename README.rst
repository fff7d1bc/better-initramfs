================
better-initramfs
================

What can it be useful for?
--------------------------
- Debug your brand-new kernel. For example, you got kernel panic unable to mount rootfs and you really don't know where is problem, missing filesystems support in kernel or maybe missing support for your SCSI/SATA/whatever or your 2nd sata controller driver started before 1st and your 'sda' is 'sdb'. Really, initramfs sh is very useful. You can check dmesg, you can check /dev for devices and try manual mount rootfs to get error.
- You have encrypted with dmcrypt luks rootfs and you dont want use genkernel-based initramfs or write your own initramfs.
- You have LVM-based rootfs, same as above.

Goal
----
The goal is to make an easy to use initramfs with support for dmcrypted rootfs, rootfs over LVM array and the remote rescue shell (sshd).

Status
------
- **dmcrypt support** -- works.
- **lvm support** -- works.
- **dmcrypted rootfs over lvm (encrypted lv)** -- should work, not tested.
- **lvm rootfs over dmcrypt (encrypted pv)** -- works.

Usage
-----
This docs is based on Funtoo/Gentoo GNU/Linux so package names etc. can be different than in your distro.

build with static use flag:
::

        sys-apps/busybox (must-have)
        sys-fs/cryptsetup (optional, if you don't use dmcrypt)
        sys-fs/lvm2 (optional, if you don't use LVM)

go to initramfs_root/bin dir and:
::

        cp -v /bin/busybox busybox
        cp -v /sbin/cryptsetup cryptsetup
        cp -v /sbin/lvm.static lvm
        ln -s busybox sh
        ln -s busybox bb

Now, go up one level outside, to the initramfs_root dir (``cd ..``) and copy one of config.example to 'config' and edit it (config file is optional). Each env like root, enc_root, lvm etc can be set with a kernel boot parameter. Available kernel boot parameters:

rescueshell=<boolean>
  drop to busybox sh just before mount rootfs to /newroot.
tuxonice_resume=<boolean>
  try resume using TuxOnIce. Remember to set resume= env by *kernel* boot params.
resume=<device/path>
  This is tuxonice env, set resume device/file. This have nothing to do with initramfs, set it normally, like for normal tuxonice. You **cannot** set it in config file.
lvm=<boolean>
  enable getting up LVM volumes if any, set true if you have rootfs on LVM.
dmcrypt_root=<boolean>
  enable cryptsetup luksOpen on selected enc_root, set true if you have encrypted rootfs.
enc_root=<device>
  for example =/dev/sda2 if sda2 is your encrypted rootfs. This env is ignored if dmcrypt_root isn't enabled.
root=<device>
  for example =/dev/mapper/dmcrypt_root if you have dmcrypted rootfs, =/dev/mapper/vg-rootfs or similar if lvm or just =/dev/sdXX if you don't have lvm based or dmcrypted rootfs.
rootfstype=<filesystem type>
  Set type of filesystem on your rootfs if you do not want to use 'auto', for example ext4.
rootdelay=<integer>
  Set how many secunds initramfs should wait before init /dev dir. Useful for rootfs on USB device. Default 0 (no wait).

All boolean are 'false' by default, enable if needed.

Now execute '``sh testbindir.sh``', you should get something like:

::

        [ OK ] busybox found.
        [ OK ] lvm found.
        [ OK ] cryptsetup found.
        [ OK ] bb is symlink to busybox.
        [ OK ] sh is symlink to busybox.

Now just pack your initramfs image by '``sh make_initramfs.sh``' and you should have a shiny brand-new initramfs.cpio.gz ready for use.

Example
-------
Few example on grub(1) config, all env set by kernel boot parametr


Dmcrypted rootfs::

        title Funtoo bzImage-2.6.32-gentoo-r5
        kernel /bzImage-2.6.32-gentoo-r5 root=/dev/mapper/dmcrypt_root enc_root=/dev/sda2 dmcrypt_root=true
        initrd /initramfs.cpio.gz

LVM based rootfs::

        title Funtoo bzImage-2.6.32-gentoo-r5
        kernel /bzImage-2.6.32-gentoo-r5 root=/dev/mapper/main-rootfs lvm=true
        initrd /initramfs.cpio.gz

LVM based rootfs, rescueshell::

        title Funtoo bzImage-2.6.32-gentoo-r5
        kernel /bzImage-2.6.32-gentoo-r5 root=/dev/mapper/main-rootfs lvm=true rescueshell=true
        initrd /initramfs.cpio.gz

Rootfs on LVM over dmcrypt (encrypted pv) with tuxonice and rootfstype env::

        title Funtoo bzImage-2.6.33
        kernel /bzImage-2.6.33 dmcrypt_root=true enc_root=/dev/sda2 lvm=true root=/dev/mapper/vg-rootfs rootfstype=ext4 resume=swap:/dev/mapper/vg-swap tuxonice_resume=true
        initrd /initramfs.cpio.gz

Known Issues
------------
switch_root: no rootfs
  If you dropped to busybox sh and manual mounted rootfs to /newroot, you did switch_root /newroot /sbin/init but you got "switch_root: no rootfs" first, umount /sys and /proc, this have nothing to do with this error but just do it. ;-) Your problem is missing ``exec`` before switch_root. Do ``exec switch_root /newroot /sbin/init``. Why? Boot your distro and check man exec.

License
-------
This project *may* contain some code from initramfs projects that can be found by googling around, gentoo-wiki.com and jootamam.net.
This code is under Simplified BSD License, see LICENSE for more info

Author
------
Piotr Karbowski <jabberuser@gmail.com>

slashbeast at irc freenode.

PS.
---
Feel free to report any issue or feature request direct to me, also, feel free to send patch for my buggy english or other buggy code in this project. ;-)
