#!/bin/sh
cd initramfs_root && \
find . | cpio -H newc -o > ../initramfs.cpio && \
cd .. && \
cat initramfs.cpio | gzip > initramfs.igz && \
rm initramfs.cpio && \
echo "Done, copy initramfs.igz to /boot" || \
echo "Buu. :("
