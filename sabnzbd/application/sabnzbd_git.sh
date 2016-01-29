#!/bin/bash
## Set branch
if [ $DEVEL -ne "false" ]; then
	branch="0.7.x"
else
	branch=$DEVEL
fi

installdir=/opt/sabnzbd
git=/usr/bin/git

install()
{
	## Install to destination
	$git clone https://github.com/sabnzbd/sabnzbd.git -b $branch --depth=1 $installdir >> /dev/null 2&>1
	if [ $? -ne 0 ]; then
		echo "[ERROR] Initial git cloning failed."
		exit 1
	fi
}

update()
{
	if [ ! -f $installdir/.gitignore ]; then
		echo "[ERROR] Installation missing $installdir/.gitignore - broken"
		exit 1
	fi
	
