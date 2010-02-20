#!/bin/sh

einfo() { echo -ne "\033[1;30m>\033[0;36m>\033[1;36m> \033[0m${@}\n" ;}
ewarn() { echo -ne "\033[1;30m>\033[0;33m>\033[1;33m> \033[0m${@}\n" ;}
eerror() { echo -ne "\033[1;30m>\033[0;31m>\033[1;31m> ${@}\033[0m\n" ;}

droptoshell() {
	ewarn "Dropping to shell."
	ewarn "\tIn order to reboot press control-alt-delete."
	exec sh
	}

run() { "$@" || ( eerror $@ 'failed.' ; droptoshell ) ;}

get_opt() {
	echo "$@" | cut -d "=" -f 2
}


