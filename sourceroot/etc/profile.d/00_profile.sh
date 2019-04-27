#!/bin/sh
# better-initramfs project
# https://bitbucket.org/piotrkarbowski/better-initramfs
# Copyright (c) 2010-2018, Piotr Karbowski <piotr.karbowski@gmail.com>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
#    * Redistributions of source code must retain the above copyright notice,
#      this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright notice,
#      this list of conditions and the following disclaimer in the documentation
#      and/or other materials provided with the distribution.
#    * Neither the name of the Piotr Karbowski nor the names of its contributors
#      may be used to endorse or promote products derived from this software
#      without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE

if [ -n "$SSH_TTY" ] || [ -n "$SSH_CONNECTION" ]; then
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
	# As the rescueshell 'pause' boot proces we will write pid into file.
	# So we can easly kill -9 it via remote rescueshell to resume boot process.
	# fwiw from rescueshell we can just exit to make it resume.
	echo "$$" > /rescueshell.pid
fi
