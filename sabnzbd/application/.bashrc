if [ $UID = '0' ]; then
	export PS1="DOCKER (lxc-media/sabnzbd)\n[\u@\h] ${PWD/#$HOME/~} # "
	export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
else
	export PS1="DOCKER (lxc-media/sabnzbd)\n[\u@\h] ${PWD/#$HOME/~} \$ "
	export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME/bin:$HOME/sbin
fi
