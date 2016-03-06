#!/bin/bash

# Copyright (C) 2015-* Phillip R. Jaenke <docker@rootwyrm.com>
#
# NO COMMERCIAL REDISTRIBUTION IN ANY FORM IS PERMISSIBLE WITHOUT EXPRESS
# WRITTEN CONSENT FROM PHILLIP R. JAENKE. IGNORANCE IS NOT A DEFENSE.
# SEE /LICENSE

export app_name="sabnzbd"
export app_url="http://www.sabnzbd.org/"
export app_git_url="https://github.com/sabnzbd/sabnzbd.git"
export app_destdir="/opt/sabnzbd"

#export app_cmd="/usr/bin/python /opt/sabnzbd/SABnzbd.py"
export app_svname="sabnzbd"
export app_psname="SABnzbd.py"

## Ingest library
. /opt/rootwyrm/deploy.lib.sh

sabnzbd_deploy_config()
{
	if [ ! -f /config/sabnzbd.ini ]; then
		cp /opt/rootwyrm/defaults/sabnzbd.ini /config
		export sabnzbd_regen_api="true"
	else
		echo "[NOTICE] Not overwriting existing sabnzbd.ini"
	fi
	chown $lxcuser:$lxcgroup /config/sabnzbd.ini

	if [ ! -f /config/openssl.cnf ]; then
		cp /opt/rootwyrm/defaults/openssl.cnf /config
	else
		echo "[NOTICE] Not overwriting existing openssl.cnf"
	fi
	chown $lxcuser:$lxcgroup /config/openssl.cnf
}

sabnzbd_config_checkdir()
{
	test -d /downloads
	if [ $? -ne 0 ]; then
		echo "[FATAL] /downloads is missing!!"
		exit 1
	fi
	chown $lxcuser:$lxcgroup /downloads

	test -d /config
	if [ $? -ne 0 ]; then
		echo "[FATAL] /config is missing!!"
		exit 1
	fi
	if [[ $(stat -c %U /config) != $lxcuser ]]; then
		chown $lxcuser /config
	fi
	if [[ $(stat -c %G /config) != $lxcgroup ]]; then
		chgrp $lxcgroup /config
	fi

	if [ ! -f /config/sabnzbd.ini ]; then
		## Try to reinstall from defaults
		cp /opt/rootwyrm/defaults/sabnzbd.ini /config/sabnzbd.ini
		if [ $? -ne 0 ]; then
			echo "[FATAL] Missing /config/sabnzbd.ini and could not replace!"
			exit 1
		fi
		chown $lxcuser:$lxcgroup /config/sabnzbd.ini
	fi

	if [ -f /config/sabnzbd.ini ]; then
		for cfgdir in `cat /config/sabnzbd.ini | grep "^dir =" | awk '{print $2}'`; do
			if [ -d $cfgdir ]; then
				if [[ `stat -c %U $cfgdir` != $lxcuser ]]; then
					chown $lxcuser $cfgdir
				fi
				if [[ `stat -c %G $cfgdir` != $lxcgroup ]]; then
					chgrp $lxcgroup $cfgdir
				fi
			fi
		done
	fi
	## Check blackhole
	blackhole_dir=$(grep dirscan_dir /config/sabnzbd.ini | awk '{print $2}')
	if [ ! -d $blackhole_dir ] && [ -z $blackhole_dir ]; then
		mkdir $blackhole_dir
		chown $lxcuser:$lxcgroup $blackhole_dir
	fi
	## Incomplete Directory
	incomp_dir=$(grep incomplete_dir /config/sabnzbd.ini | awk '{print $2}')
	if [ ! -d $incomp_dir ] && [ -z $incomp_dir ]; then
		mkdir $incomp_dir
		chown $lxcuser:$lxcgroup $incomp_dir
	fi

	## SSL Directory 
	if [ ! -d /config/ssl ]; then
		mkdir /config/ssl
		chown $lxcuser:$lxcgroup /config/ssl
		chmod 0700 /config/ssl
	else
		if [[ `stat -c %U /config/ssl` != $lxcuser ]]; then
			chown -R $lxcuser /config/ssl
		fi
		if [[ `stat -c %G /config/ssl` != $lxcgroup ]]; then
			chgrp -R $lxcgroup /config/ssl
		fi
		if [[ `stat -c %a /config/ssl` != '700' ]]; then
			chmod -R 0700 /config/ssl
		fi
	fi

}

sabnzbd_regen_apikey()
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


######################################################################
## execution phase
######################################################################

## XXX: Bugfix
#ln -s /etc/service /service

ingest_environment
test_deploy

generate_motd
cat /etc/motd

## Do build phase.
for bp in `ls /root/build/*.sh | sort`; do
	chmod +x $bp
	$bp
	check_error $? $bp
done

echo "[DEPLOY] Deploying lxc-media user:"
deploy_lxcmedia_user

deploy_application_git reinst
chown -R $lxcuser:$lxcgroup $app_destdir
sabnzbd_deploy_config

sabnzbd_config_checkdir
sabnzbd_deploy_config
ssl_ssc_create

echo "[DEPLOY] Changing ownerships for lxc-media..."
deploy_lxcmedia_ownership

runit_linksv $appname
if [ ! -z $sabnzbd_regen_api ]; then
	echo "[SABnzbd] Regenerating API Key."
	sv start sabnzbd; sleep 5; sabnzbd_regen_apikey
	#while true; do
	#	sleep 1
	#	ps ax |grep -i sabnzbd > /dev/null
	#	if [ $? -ne 0 ]; then
	#		break
	#	fi
	#done
	sv restart sabnzbd
	#sleep 10
	#sabnzbd_regen_apikey
	#sv stop sabnzbd
fi

deploy_complete
