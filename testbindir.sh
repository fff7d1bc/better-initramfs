#!/bin/sh

work_dir_name="$(readlink -f $(dirname $0))"
bindir="${work_dir_name}/sourceroot/bin"

test_files() { 
	test -f ${bindir}/$1 && echo "[ OK ] $1 found." || echo "[ !! } Missing $1 binary in sourceroot/bin dir."
}

test_symlinks() {
	if [ -L "${bindir}/$1" ] 
	then
		if [ "$(readlink ${bindir}/$1)" = "$2" ]
		then
			echo "[ OK ] $1 is symlink to $2."
		else
			echo "{ !! } $1 is symlink but NOT to $2."
		fi
	else
		echo "[ !! ] $1 not exist or isn't symlink!"
	fi
}

test_files busybox
test_files lvm
test_files cryptsetup
test_symlinks bb busybox
test_symlinks sh busybox
