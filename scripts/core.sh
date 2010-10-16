#!/bin/bash

initramfs_root="$(readlink -f $(dirname $0)/../initramfs_root)"

die() {
	echo -e "\033[1;30m>\033[0;31m>\033[1;31m> ERROR:\033[0m ${@}" && exit 1
}

einfo() {
	echo -ne "\033[1;30m>\033[0;36m>\033[1;36m> \033[0m${@}\n"
}
ewarn() {
	echo -ne "\033[1;30m>\033[0;33m>\033[1;33m> \033[0m${@}\n"
}

