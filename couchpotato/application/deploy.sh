#!/bin/bash
# couchpotato/application/deploy.sh
# vers = ff2ea3b3bf8127a4fe4574ce0849a607

# Copyright (C) 2015-* Phillip R. Jaenke <docker@rootwyrm.com>
#
# NO COMMERCIAL REDISTRIBUTION IN ANY FORM IS PERMISSIBLE WITHOUT EXPRESS
# WRITTEN CONSENT FROM PHILLIP R. JAENKE. IGNORANCE IS NOT A DEFENSE.
# SEE /LICENSE

export app_name="couchpotato"
export app_url="https://couchpota.to/"
export app_git_url="https://github.com/CouchPotato/CouchPotatoServer.git"
export app_destdir="/opt/couchpotato"

#export app_cmd="/usr/bin/python /opt/sickrage/SickBeard.py"
export app_svname="couchpotato"
export app_psname="CouchPotato.py"

. /opt/rootwyrm/deploy.lib.sh

couchpotato_deploy_config()
{
	if [ ! -f /config/settings.conf ]; then
		cp /opt/rootwyrm/defaults/settings.conf /config
	else
		echo "[NOTICE] Not overwriting existing /config/settings.conf"
	fi
	chown $lxcuser:$lxcgroup /config/settings.conf

	if [ ! -f /config/openssl.cnf ]; then
		cp /opt/rootwyrm/defaults/openssl.cnf /config
	else
		echo "[NOTICE] Not overwriting existing /config/openssl.cnf"
	fi
	chown $lxcuser:$lxcgroup /config/openssl.cnf
}

couchpotato_config_checkdir()
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

couchpotato_install_settings()
{
	## We modify the configuration here.
	export NEWAPI=$(/opt/rootwyrm/regenapi.py | cut -d : -f 2)
	sed -i -e "s,^api_key.*,api_key = $NEWAPI," /config/settings.conf
	echo "[NOTICE] New API Key: $NEWAPI"

	sed -i -e "s,^ssl_key.*,ssl_key = /config/ssl/media.key," /config/settings.conf
	sed -i -e "s,^ssl_cert.*,ssl_cert = /config/ssl/media.crt," /config/settings.conf

	sed -i -e "s,launch_browser.*,launch_browser = False," /config/settings.conf
	# Be explicit about git path
	sed -i -e "s,git_command.*,git_command = /usr/bin/git," /config/settings.conf
}

######################################################################
## execution phase
######################################################################

ingest_environment
test_deploy

generate_motd
cat /etc/motd

echo "[DEPLOY] Deploying lxc-media user:"
deploy_lxcmedia_user

deploy_application_git reinst
chown -R $lxcuser:$lxcgroup $app_destdir

couchpotato_config_checkdir
couchpotato_deploy_config
ssl_ssc_create
couchpotato_install_settings

echo "[DEPLOY] Changing ownerships for lxc-media..."
deploy_lxcmedia_ownership

runit_linksv $appname

deploy_complete
