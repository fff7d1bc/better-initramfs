#!/bin/sh

find initramfs_root | cpio -H newc -o |  gzip > initramfs.igz

if [[ $? == 0 ]] ; then
    echo "Done, copy initramfs.igz to /boot"
else
    echo "Buu. :("
fi
