#!/bin/bash
# transmission/application/deploy.sh
# vers = 6b6708075076f10c133cd47b9e9e57d8


# Copyright (C) 2015-* Phillip R. Jaenke <docker@rootwyrm.com>
#
# NO COMMERCIAL REDISTRIBUTION IN ANY FORM IS PERMISSIBLE WITHOUT EXPRESS 
# WRITTEN CONSENT FROM PHILLIP R. JAENKE. IGNORANCE IS NOT A DEFENSE.
# SEE /LICENSE

export app_name="transmission"
export app_url="http://www.transmissionbt.com/"
export app_git_url=""
#export app_destdir=""

export app_cmd="/usr/bin/transmission-daemon"
export app_svname="transmission"
export app_psname="transmission-daemon"

## Ingest library
. /opt/rootwyrm/deploy.lib.sh

## configuration install
########################################
config_checkdir()
{
	test -d /config
	if [ $? -ne 0 ]; then
		echo "[FATAL] /config is missing!!"
		exit 1
	fi

	for cdir in blocklists resume torrents; do
		test -d /config/$cdir
		if [ $? -ne 0 ]; then
			mkdir /config/$cdir
		fi
	done

	for cfile in stats.json; do
		test -f /config/$cfile
		if [ $? -ne 0 ]; then
			touch /config/$cfile
		fi
	done
}

config_copybase()
{
	## Only one config file
	export basecfg="/config/settings.json"
	if [ -f $basecfg ]; then
		## Don't overwrite.
		echo "[WARNING] Not overwriting existing configuration."
		return 0
	fi

	cp /opt/rootwyrm/defaults/settings.json $basecfg
	if [ $? -ne 0 ]; then
		RC=$?
		return $rc
	else
		return 0
	fi
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

echo "[DEPLOY] Changing ownerships for lxc-media..."
deploy_lxcmedia_ownership

runit_linksv

deploy_complete
