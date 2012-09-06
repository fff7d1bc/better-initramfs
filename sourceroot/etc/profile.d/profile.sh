#!/bin/sh

if [ -n "$SSH_TTY" ] || [ -n "$SSH_CONNECTiON" ]; then
	export PS1='remote rescueshell \w \# '
	touch /remote-rescueshell.lock
	. /functions.sh
	ewarn "The lockfile was created."
	ewarn "In order to resume boot proces, run 'resume-boot'."
	ewarn "Be aware that it will kill your connection which means"
	ewarn "you will no longer be able work in this shell."
	echo
	if [ -e '/luks_passfifo' ]; then
		einfo "To remote unlock LUKS-encrypted device run 'unlock-luks'."
		echo
	fi

else
	export PS1='rescueshell \w \# '
	# As the rescueshell 'pouse' boot proces we will write pid into file.
	# So we can easly kill -9 it via remote rescueshell to resume boot process.
	# fwiw from rescueshell we can just exit to make it resume.
	echo "$$" > /rescueshell.pid
fi
