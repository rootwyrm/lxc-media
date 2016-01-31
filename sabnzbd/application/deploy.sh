#!/bin/bash
# application/deploy.sh
# vers = 4c5e8caddcb7eca6115862d2fd4f29c2

chkfile="/deploy"
basedir="/opt/rootwyrm/defaults"

app_name="sabnzbd"
app_git_url="https://github.com/sabnzbd/sabnzbd.git"
app_destdir="/opt/sabnzbd"

## First things first, stop application
/usr/bin/supervisorctl stop $app_name > /dev/null
#if [ $? -ne 0 ]; then echo "[FATAL] supervisord not running!"; exit 1; fi

# Trap early
if [ ! -f $chkfile ]; then
	exit 0
else
	# Try to ingest deploy configuration
	if [ -f $chkfile ]; then
		. $chkfile
	elif [ -f "$chkfile".conf ]; then
		. "$chkfile".conf
	fi
fi

## Generic error check
check_error()
{
	if [ $? -ne 0 ]; then
		RC=$?
		if [ -z $2 ]; then
			echo "[FATAL] Error occurred in $1"
			exit $RC
		else
			echo "[FATAL] Error occurred in $1 : $2"
			exit $RC
		fi
	fi
}

## Clean up supervisord so it doesn't re-run deploy
supervisord_clean()
{
	if [ -f /etc/supervisor.d/deploy.ini ]; then
		mv /etc/supervisor.d/deploy.ini /etc/supervisor.d/deploy.done
	fi
}

## Mark as complete
deploy_complete()
{
	if [ -f $chkfile ]; then
		rm $chkfile
	fi
	if [ -f /deploy.new ]; then
		rm /deploy.new
	fi
}

deploy_app_config()
{
	if [ -f /config/config.ini ]; then
		if [ -z $DEPLOY_OVERWRITE ]; then
			printf '[WARNING] Declining to overwrite existing config.\n'
			return 1
		else
			printf '[WARNING] Overwriting existing configuration.\n'
			mv /config/config.ini /config/config.ini.$(date "+%d%m%Y")
		fi
	fi
	cp $basedir/config.ini /config/
	check_error config.ini
}

## Create the user here, cuts down on layers.
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
				check_error addgroup
			else
				grep $lxcgroup /etc/group | cut -d : -f 3 > /tmp/gid
				export lxcgid=$(cat /tmp/gid)
			fi
		fi
	fi
	if [ -z $lxcshell ]; then
		## XXX: gliderlabs/docker-alpine/issues/141
		export lxcshell=/bin/sh
	fi
	
	# NOTE: NEVER use \ to make readable, base chokes on it.	
	adduser -h /home/$lxcuser -g "RootWyrm Media Compose User" -u $lxcuid -G $lxcgroup -D -s $lxcshell $lxcuser
	check_error adduser

	rm /tmp/gid
}

supervisor_setowner()
{
	sed -i -e 's,LXCUSER,'$lxcuser',g' /etc/supervisord.conf ; \
	sed -i -e 's,LXCUSER,'$lxcuser',g' /etc/supervisor.d/*.ini ; \
	sed -i -e 's,LXCGROUP,'$lxcgroup',g' /etc/supervisord.conf ; \
	sed -i -e 's,LXCGROUP,'$lxcgroup',g' /etc/supervisor.d/*.ini
}

## Set ownerships
deploy_lxcmedia_ownership()
{
	## XXX: numeric to work around Synology issues. May be fixed in
	## DSM6 but not holding my breath.
	if [[ -z $lxcuid ]] || [[ -z $lxcgid ]]; then
		printf '[FATAL] $lxcuid or $lxcgid unset!\n'
		return 1
	fi
	
	chown -R $lxcuid:$lxcgid /home/$lxcuser
	check_error chown_home
	chmod 0700 /home/$lxcuser
	chown -R $lxcuid:$lxcgid /config
	check_error chown_config

	chown -R $lxcuid:$lxcgid $app_destdir
	check_error chown_app_destdir
	# Don't forget the git files...
	chown -R $lxcuid:$lxcgid $app_destdir/.[a-z]*
	check_error chown_app_destdir
}

deploy_application_git()
{
	## This function generally shouldn't come up, but might.
	case $1 in
		[rR][eE][iI][nN][sS][tT]*)
			if [[ -z $app_destdir ]] && [[ -d $app_destdir ]]; then
				rm -rf $app_destdir
				mkdir $app_destdir
			fi
			git clone $app_git_url -b master --depth=1 $app_destdir
			check_error git_clone
			return $?
			;;
		[uU][pP][dD][aA][tT][eE])
			if [ ! -d $app_destdir ]; then
				## Presume user error.
				deploy_application_git REINST
			else
				export return=$PWD; cd $app_destdir
				git pull
				check_error git_pull_update
			   	cd $return
				unset return
			fi
			return $?
			;;
	esac
}


if [ -z $1 ]; then
	## We're at zero
	deploy_lxcmedia_user
	#deploy_app_config
	deploy_lxcmedia_ownership
	mv /etc/supervisor.d/sabnzbd.holdini /etc/supervisor.d/sabnzbd.ini
	supervisor_setowner
	supervisord_clean
	deploy_complete		## Because we don't want it doing stupid.
else
	deploy_application_git $1
	deploy_lxcmedia_ownership
fi

sleep 5
/usr/bin/supervisorctl remove deploy
/usr/bin/supervisorctl reload
/usr/bin/supervisorctl start $app_name
