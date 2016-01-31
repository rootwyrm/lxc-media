#!/bin/bash
# application/deploy.sh
# vers = 4c5e8caddcb7eca6115862d2fd4f29c2

chkfile="/deploy"
basedir="/opt/rootwyrm/defaults"

app_name="sabnzbd"
app_git_url="https://github.com/sabnzbd/sabnzbd.git"
app_destdir="/opt/sabnzbd"

## First things first, stop application
# Trap early
test_run()
{
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
}

## Generic error check
check_error()
{
	if [ $1 -ne 0 ]; then
		RC=$1
		if [ -z $2 ]; then
			echo "[FATAL] Error occurred in $2"
			exit $RC
		else
			echo "[FATAL] Error occurred in $2 : $1"
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


deploy_app_config()
{
	if [ -f /config/sabnzbd.ini ]; then
		echo "[WARNING] Overwriting existing configuration."
		mv /config/sabnzbd.ini /config/sabnzbd.ini.$(date "+%d%m%Y")
		cp $basedir/sabnzbd.ini /config/sabnzbd.ini
		check_error $? config_ini
		chown $lxcuid:$lxcgid /config/sabnzbd.ini
	else
		cp $basedir/sabnzbd.ini /config/sabnzbd.ini
		check_error $? config_ini
		chown $lxcuid:$lxcgid /config/sabnzbd.ini
	fi

	## Check for required directories.
	if [ ! -d /config/nzb ]; then
		mkdir /config/nzb ; chown $lxcuid:$lxcgid /config/nzb
	fi
	if [ ! -d /config/email ]; then
		mkdir /config/email ; chown $lxcuid:$lxcgid /config/email
	fi
	if [ ! -d /config/admin ]; then
		mkdir /config/admin ; chown $lxcuid:$lxcgid /config/admin
	fi
	if [ ! -d /config/logs ]; then
		mkdir /config/logs ; chown $lxcuid:$lxcgid /config/logs
	fi
	if [ ! -d /config/ssl ]; then
		mkdir /config/ssl ; chown $lxcuid:$lxcgid /config/ssl
	fi

	if [[ $(stat -c %u /config) != $lxcuid ]]; then
		chown $lxcuid /config
	fi
	if [[ $(stat -c %g /config) != $lxcgid ]]; then
		chgrp $lxcgid /config
	fi

	## Download directories
	for dest in complete incomplete television movies music comics books; do
		if [ ! -d /downloads/$dest ]; then
			mkdir /downloads/$dest ; chown $lxcuid:$lxcgid /downloads/$dest
		fi
	done
	if [[ $(stat -c %a /downloads) -lt 777 ]]; then
		chmod 0777 /downloads
	fi

	## Move the supervisor configuration to active.
	mv /etc/supervisor.d/sabnzbd.holdini /etc/supervisor.d/sabnzbd.ini
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
				check_error $? addgroup
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

	if [[ $(id -u $lxcuser) -eq $lxcuid ]]; then
		return 0
	elif [[ $(id -u $lxcuser) != 0 ]]; then
		## NOP
		echo -n "" > /dev/null
	else
		deluser $lxcuser
	fi
	
	# NOTE: NEVER use \ to make readable, base chokes on it.	
	adduser -h /home/$lxcuser -g "RootWyrm Media Compose User" -u $lxcuid -G $lxcgroup -D -s $lxcshell $lxcuser
	check_error $? adduser

	rm /tmp/gid
}

supervisor_setowner()
{
	sed -i -e 's,_LXCUSER,'$lxcuser',g' /etc/supervisord.conf ; \
	sed -i -e 's,_LXCUSER,'$lxcuser',g' /etc/supervisor.d/*.ini ; \
	sed -i -e 's,_LXCGROUP,'$lxcgroup',g' /etc/supervisord.conf ; \
	sed -i -e 's,_LXCGROUP,'$lxcgroup',g' /etc/supervisor.d/*.ini
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
	esac
}

ssl_ssc_create()
{
	export ssldir="/config/ssl"
	if [[ -f $ssldir/media.crt ]] || [[ -f $ssldir/media.key ]]; then
		## Don't obliterate user provided key.
		return 0
	fi

	export sslpass=$(head -c 500 /dev/urandom | tr -dc a-z0-9A-Z | head -c 64)
	export mydomain=$(cat /etc/resolv.conf | grep search | awk '{print $2}')
	export myhost=$(cat /etc/hostname)
	## Self-signed certs use the docker container ID and domain.
	export OPENSSLCONFIG=/opt/rootwyrm/defaults/openssl.cnf
	## Fix-up openssl.cnf
	sed -i -e 's,_REPLACE_HOSTNAME_,'$myhost'.'$mydomain',' $OPENSSLCONFIG
	sed -i -e 's,_DOMAIN_,'$mydomain',' $OPENSSLCONFIG

	## genkey
	openssl genrsa -des3 -out $ssldir/media.key -passout env:sslpass 2048
	check_error $? ssl_gen_key

	## gencsr
	openssl req -new -x509 -days 3650 -batch -nodes \
		-config $OPENSSLCONFIG -key $ssldir/media.key \
		-out $ssldir/media.crt -passin env:sslpass
	check_error $? ssl_gen_csr

	mv $ssldir/media.key $ssldir/media.key.lock

	## unlock key
	openssl rsa -in $ssldir/media.key.lock -out $ssldir/media.key -passin env:sslpass 
	check_error $? ssl_unlock_key

	## gencert
	#openssl x509 -req -days 3650 -in $ssldir/media.csr -signkey $ssldir/media.key -out $ssldir/media.crt -config $OPENSSLCONFIG
	#check_error $? ssl_gen_cert

	for sslfile in `ls $ssldir/*`; do
		chown $lxcuid:$lxcgid $sslfile
		chmod 0600 $sslfile
	done
}

sabnzbd_regen_api()
{
	call="api?mode=config&name=set_apikey&apikey=357e729fed6617e4cabd237a36179f00"
	## sabnzbd doesn't listen on localhost.
	ipaddr=$(ifconfig eth0 | grep "inet addr" | cut -d : -f 2 | awk '{print $1}')
	curl "http://$ipaddr:9080/$call" > /config/sabnzbd.api
	if [ $? -ne 0 ]; then
		echo "[FATAL] Error regenerating API key."
		exit 1
	fi
	chown $lxcuid:$lxcgid /config/sabnzbd.api
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

test_run

. /.dockerenv 

## Extra clean-up bit.
if [ -f /root/pip.py ]; then
	rm /root/pip.py
fi

if [ -z $1 ]; then
	## We're at zero
	deploy_lxcmedia_user
	deploy_app_config
	deploy_lxcmedia_ownership
	supervisor_setowner
	ssl_ssc_create
	## Prevent supervisord from reaping deploy..	
	supervisord_clean	
	/usr/bin/supervisorctl reload
	sleep 5
	/usr/bin/supervisorctl start sabnzbd
	## sabnzbd takes a while to start
	sleep 30
	sabnzbd_regen_api
	deploy_complete		## Because we don't want it doing stupid.
else
	/usr/bin/supervisorctl stop sabnzbd
	deploy_application_git $1
	deploy_lxcmedia_ownership
	/usr/bin/supervisorctl restart sabnzbd
fi

exit 0
