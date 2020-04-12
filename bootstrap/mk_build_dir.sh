#!/bin/bash

# This is really a placeholder than a real script.
# Create Alpine sysroot.

export chroot_dir=`pwd`/build_dir/
export arch=x86_64
export mirror=http://dl-cdn.alpinelinux.org/alpine/
export version='2.10.5-r0'

mkdir -p \
    "${chroot_dir}" \
    "${chroot_dir}/tmp" \
    "${chroot_dir}/tmp/apk"

wget "${mirror}/latest-stable/main/${arch}/apk-tools-static-${version}.apk" -O "${chroot_dir}/tmp/apk/apk-tools-static.apk" 
tar -xzf "${chroot_dir}/tmp/apk/apk-tools-static.apk" -C "${chroot_dir}/tmp/apk/"

"${chroot_dir}/tmp/apk//sbin/apk.static" -X "${mirror}/latest-stable/main" -U --allow-untrusted --root ${chroot_dir} --initdb add \
    alpine-base \
    build-base \
    patch \
    automake \
    autoconf \
    pkgconf \
    linux-headers

rm -rf "${chroot_dir}/tmp/apk/"

mknod -m 666 "${chroot_dir}/"dev/null c 1 3
mknod -m 666 "${chroot_dir}/"dev/urandom c 1 9
mknod -m 666 "${chroot_dir}/"dev/random c 1 8
mknod -m 666 "${chroot_dir}/"dev/zero c 1 5
