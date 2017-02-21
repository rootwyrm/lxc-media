#!/bin/bash
# transmission/application/deploy.sh
# vers = 6b6708075076f10c133cd47b9e9e57d8


# Copyright (C) 2015-* Phillip R. Jaenke <docker@rootwyrm.com>
#
# NO COMMERCIAL REDISTRIBUTION IN ANY FORM IS PERMISSIBLE WITHOUT EXPRESS 
# WRITTEN CONSENT FROM PHILLIP R. JAENKE. IGNORANCE IS NOT A DEFENSE.
# SEE /LICENSE

export app_name="nzbget"
export app_url="http://www.nzbget.net/"
export app_git_url=""
#export app_destdir=""

export app_cmd="/usr/bin/nzbget"
export app_svname="nzbget"
export app_psname="nzbget"

## Ingest library
. /opt/rootwyrm/deploy.lib.sh

## application install
########################################
application_install()
{
	test -d /opt/nzbget
	if [ $? -eq 0 ]; then
		echo "[FATAL] Found existing nzbget installation!"
		exit 1
	fi

	## Download from github is a little funky.
	echo "Retrieving nzbget 18.0"
	curl -L https://github.com/nzbget/nzbget/releases/download/v18.0/nzbget-18.0-bin-linux.run > /root/nzbget-18.0-bin-linux.run
	chmod +x /root/nzbget-18.0-bin-linux.run
	/root/nzbget-18.0-bin-linux.run --destdir /opt/nzbget
	if [ $? -ne 0 ]; then
		echo "[FATAL] Error occurred during nzbget installation!"
		exit 1
	fi
}

## configuration install
########################################
config_checkdir()
{
	test -d /config
	if [ $? -ne 0 ]; then
		echo "[FATAL] /config is missing!!"
		exit 1
	fi
	test -d /shared/nzbget
	if [ $? -ne 0 ]; then
		mkdir /shared/nzbget
		chown -R $lxcuser:$lxcgroup /shared/nzbget
	fi

}

config_copybase()
{
	## Only one config file
	export basecfg="/config/nzbget.conf"
	if [ -f $basecfg ]; then
		## Don't overwrite.
		echo "[WARNING] Not overwriting existing configuration."
		return 0
	fi

	cp /opt/rootwyrm/defaults/nzbget.conf $basecfg
	if [ $? -ne 0 ]; then
		RC=$?
		return $rc
	else
		return 0
	fi
	## Copy base template 
	cp /usr/share/nzbget.conf /config/nzbget.conf.template
	chown $lxcuser:$lxcgroup /config/nzbget.conf.template
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

config_checkdir
config_copybase

application_install

echo "[DEPLOY] Changing ownerships for lxc-media..."
deploy_lxcmedia_ownership
## XXX: Fixup
chown -R $lxcuser:$lxcgroup /shared/nzbget

runit_linksv

deploy_complete

echo "[DEPLOY] Disabling firstboot."
rm /etc/service/firstboot
