#!/bin/bash

set -e

# Create Alpine sysroot and pack it into tarball.

export chroot_dir=`pwd`/build_dir/
export arch=x86_64
export mirror=http://dl-cdn.alpinelinux.org/alpine/
export version='2.12.7-r0'

mkdir -p \
    "${chroot_dir}" \
    "${chroot_dir}/tmp" \
    "${chroot_dir}/tmp/apk"

wget "${mirror}/latest-stable/main/${arch}/apk-tools-static-${version}.apk" -O "${chroot_dir}/tmp/apk/apk-tools-static.apk" 
tar -xzf "${chroot_dir}/tmp/apk/apk-tools-static.apk" -C "${chroot_dir}/tmp/apk/"

"${chroot_dir}/tmp/apk//sbin/apk.static" -X "${mirror}/latest-stable/main" -U --allow-untrusted --root "${chroot_dir}" --initdb add \
    alpine-base \
    build-base \
    patch \
    automake \
    autoconf \
    cmake \
    meson \
    pkgconf \
    linux-headers \
    bash

rm -rf "${chroot_dir}/tmp/apk/"

alpine_version="$(< ${chroot_dir}/etc/alpine-release)"
alpine_version="${alpine_version//[^0-9.]/}"

export XZ_OPT="-T $(nproc)"
tar -cvJf "distfiles/alpine-${alpine_version}-x86_64-sysroot.tar.xz" --numeric-owner -C build_dir/ .
