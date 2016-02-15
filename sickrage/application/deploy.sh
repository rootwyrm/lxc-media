#!/bin/bash
# sickrage/application/deploy.sh
# vers = 6878a3960a2c24183c9160634d7995f3

# Copyright (C) 2015-* Phillip R. Jaenke <docker@rootwyrm.com>
#
# NO COMMERCIAL REDISTRIBUTION IN ANY FORM IS PERMISSIBLE WITHOUT EXPRESS
# WRITTEN CONSENT FROM PHILLIP R. JAENKE. IGNORANCE IS NOT A DEFENSE.
# SEE /LICENSE

export app_name="sickrage"
export app_url="https://sickrage.github.io/"
export app_git_url="https://github.com/SickRage/SickRage.git"
export app_destdir="/opt/sickrage"

#export app_cmd="/usr/bin/python /opt/sickrage/SickBeard.py"
export app_svname="sickrage"
export app_psname="SickBeard.py"

. /opt/rootwyrm/deploy.lib.sh

sickrage_deploy_config()
{
	if [ ! -f /config/config.ini ]; then
		cp /opt/rootwyrm/defaults/config.ini /config
		echo "[WARNING] You should manually regenerate the API KEY!"
	else
		echo "[NOTICE] Not overwriting existing /config/config.ini"
	fi
	chown $lxcuser:$lxcgroup /config/config.ini

	if [ ! -f /config/openssl.cnf ]; then
		cp /opt/rootwyrm/defaults/openssl.cnf /config
	else
		echo "[NOTICE] Not overwriting existing /config/openssl.cnf"
	fi
	chown $lxcuser:$lxcgroup /config/openssl.cnf
}

sickrage_config_checkdir()
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

sickrage_regenerate_api()
{
	export NEWAPI=$(/opt/rootwyrm/regenapi.py | cut -d : -f 2)
	sed -i -e "s,^api_key.*,api_key = $NEWAPI," application/defaults/config.ini
	echo "[NOTICE] New API Key: $NEWAPI"
}

######################################################################
## execution phase
######################################################################

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

sickrage_config_checkdir
sickrage_deploy_config
ssl_ssc_create
sickrage_regenerate_api

echo "[DEPLOY] Changing ownerships for lxc-media..."
deploy_lxcmedia_ownership

runit_linksv $appname

deploy_complete
