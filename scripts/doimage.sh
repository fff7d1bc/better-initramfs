#!/bin/bash

workdir="$(readlink -f $(dirname $0))"
. $workdir/core.sh || exit 1


( cd $initramfs_root && find . | $sudo cpio --quiet -H newc -o | gzip -9 > ../initramfs.cpio.gz)

if [[ -f $initramfs_root/../initramfs.cpio.gz ]]; then
	einfo "initramfs.cpio.gz is ready."
else
	die "There is no initramfs.cpio.gz, something goes wrong."
fi
