#!/bin/bash 
# base/application/deploy.lib
# vers = 35e0c179d4c7c037539bc5bee6ce2de6

# Copyright (C) 2015-* Phillip R. Jaenke <docker@rootwyrm.com>
#
# NO COMMERCIAL REDISTRIBUTION IN ANY FORM IS PERMISSIBLE WITHOUT EXPRESS 
# WRITTEN CONSENT FROM PHILLIP R. JAENKE. IGNORANCE IS NOT A DEFENSE.
# SEE /LICENSE

## NOTE: Must export due to bash limitation
export chkfile="/deploy"
export basedir="/opt/rootwyrm/defaults"

## Trap early
test_deploy()
{
	if [ ! -f $chkfile ]; then
		exit 0
	else
		# Ingest configuration
		if [ -f $chkfile ]; then
			. $chkfile
		elif [ -f "$chkfile".conf ]; then
			. "$chkfile".conf
		fi
	fi
}

ingest_environment()
{
	if [ -s /.dockerenv ]; then
		. /.dockerenv
	fi
	if [ -s /.dockerinit ]; then
		. /.dockerinit
	fi
}

deploy_complete()
{
	if [ -f $chkfile ]; then
		rm $chkfile
	fi
	if [ -f /deploy.new ]; then
		rm /deploy.new
	fi
}

## user management
########################################
deploy_lxcmedia_user()
{
	## If we're on a Synology, we run as DSM admin uid, user gid.
	if [[ -f /proc/syno_cpu_arch ]]; then
		export lxcuser="lxcmedia"
		export lxcuid="1024"
		export lxcgroup="users"
		export lxcgid="100"
	else
		# Defaults are lxcmedia:users @ 1024:100
		if [[ -z $lxcuser ]]; then export lxcuser="lxcmedia"; fi
		if [[ -z $lxcuid ]]; then export lxcuid="1024"; fi
		if [[ -z $lxcgroup ]]; then export lxcgroup="users"; fi
		if [[ -z $lxcgid ]]; then 
			grep $lxcgroup /etc/group > /dev/null
			if [ $? -ne 0 ]; then
				set lxcgid="100"
				addgroup -g $lxcgid $lxcgroup
				check_error $? addgroup
			else
				grep $lxcgroup /etc/group | cut -d : -f 3 > /tmp/gid
				export lxcgid=$(cat /tmp/gid)
			fi
		fi
	fi
	echo "[DEPLOY] user: $lxcuser uid: $lxcuid group: $lxcgroup gid: $lxcgid"
	if [ -z $lxcshell ]; then
		## XXX: gliderlabs/docker-alpine/issues/141
		export lxcshell=/bin/sh
	fi

	if [[ $(id -u $lxcuser) -eq $lxcuid ]]; then
		echo "[DEPLOY] User $lxcuser already at $lxcuid, leaving as is."
		return 0
	elif [[ $(id -u $lxcuser) != 0 ]]; then
		## NOP - user doesn't exist
		echo -n "" > /dev/null
	else
		deluser $lxcuser
	fi
	
	# NOTE: NEVER use \ to make readable, base chokes on it.	
	adduser -h /home/$lxcuser -g "lxc-media user" -u $lxcuid -G $lxcgroup -D -s $lxcshell $lxcuser
	check_error $? adduser

	rm /tmp/gid
}

deploy_lxcmedia_ownership()
{
	## XXX: numeric to work around Synology issues. May be fixed in
	## DSM6 but not holding my breath.
	if [[ -z $lxcuid ]] || [[ -z $lxcgid ]]; then
		printf '[FATAL] $lxcuid or $lxcgid unset!\n'
		return 1
	fi
	
	chown -R $lxcuid:$lxcgid /home/$lxcuser
	check_error $? chown_home
	chmod 0700 /home/$lxcuser
	chown -R $lxcuid:$lxcgid /config
	check_error $? chown_config

	chown -R $lxcuid:$lxcgid $app_destdir
	check_error $? chown_app_destdir
	# Don't forget the git files...
	chown -R $lxcuid:$lxcgid $app_destdir/.[a-z]*
	check_error $? chown_app_destdir
}

## motd
########################################
generate_motd()
{
	releasefile="/opt/rootwyrm/release.id"
	if [ -s $releasefile ]; then
		releaseid="!!! DEBUG *** DEBUG *** DEBUG !!!"
	else
		releaseid=$(cat $releasefile)
	fi

	cp /opt/rootwyrm/defaults/motd /etc/motd
	sed -e -i 's/RELEASEID/'$releaseid'' /etc/motd
	sed -e -i 's/APPNAME/'$app_name'' /etc/motd
	sed -i -i 's/APPURL/'$app_url'' /etc/motd

	if [ -f /opt/rootwyrm/app.message ]; then
		sed -e -i 's/APPMESSAGE/'$(cat /opt/rootwyrm/app.message)'' /etc/motd
	fi
}

# generic application functions
########################################
deploy_application_git()
{
	case $1 in
		[rR][eE][iI][nN][sS][tT]*)
		## This function generally shouldn't come up, but might.
			if [[ -z $app_destdir ]] && [[ -d $app_destdir ]]; then
				rm -rf $app_destdir
				mkdir $app_destdir
			fi
			git clone $app_git_url -b master --depth=1 $app_destdir
			check_error $? git_clone
			chown -R $lxcuid:$lxcgid $app_destdir
			return $?
			;;
		[uU][pP][dD][aA][tT][eE])
			if [ ! -d $app_destdir ]; then
				## Presume user error.
				deploy_application_git REINST
			else
				export return=$PWD; cd $app_destdir
				su $lxcuser -c 'git pull'
				check_error $? git_pull_update
			   	cd $return
				unset return
			fi
			return $?
			;;
		*)
			return 1
			;;
	esac
}

