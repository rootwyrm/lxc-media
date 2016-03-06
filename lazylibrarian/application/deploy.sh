#!/bin/bash
# headphones/application/deploy.sh
# vers = 5499adbbc3203f5c91ce9eb6436df585

# Copyright (C) 2015-* Phillip R. Jaenke <docker@rootwyrm.com>
#
# NO COMMERCIAL REDISTRIBUTION IN ANY FORM IS PERMISSIBLE WITHOUT EXPRESS
# WRITTEN CONSENT FROM PHILLIP R. JAENKE. IGNORANCE IS NOT A DEFENSE.
# SEE /LICENSE

export app_name="lazylibrarian"
export app_url="https://github.com/DobyTang/LazyLibrarian"
export app_git_url="https://github.com/DobyTang/LazyLibrarian.git"
export app_destdir="/opt/lazylibrarian"

#export app_cmd="/usr/bin/python /opt/lazylibrarian/LazyLibrarian.py"
export app_svname="lazylibrarian"
export app_psname="LazyLibrarian.py"

. /opt/rootwyrm/deploy.lib.sh

lazylibrarian_deploy_config()
{
	if [ ! -f /config/config.ini ]; then
		cp /opt/rootwyrm/defaults/config.ini /config
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

lazylibrarian_config_checkdir()
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

lazylibrarian_install_settings()
{
	conffile="/config/config.ini"
	## We modify the configuration here.
	export NEWAPI=$(/opt/rootwyrm/regenapi.py | cut -d : -f 2)
	sed -i -e "s,^api_key.*,api_key = $NEWAPI," $conffile
	echo "[NOTICE] New API Key: $NEWAPI"

	sed -i -e "s,^http_host.*,http_host = 0.0.0.0," $conffile
	sed -i -e "s,^https_cert.*,https_cert = /config/ssl/media.crt," $conffile
	sed -i -e "s,^https_key.*,https_key = /config/ssl/media.key," $conffile

	sed -i -e "s,^enable_https.*,enable_https = 1," $conffile

	sed -i -e "s,launch_browser.*,launch_browser = 0," $conffile
	# Be explicit about git path
	sed -i -e "s,git_path.*,git_path = /usr/bin/git," $conffile
}

lazylibrarian_install_bookstrap()
{
	bookstrapurl="https://github.com/warlord0/lazylibrarian.bookstrap.git"
	git clone $bookstrapurl -b master --depth=1 -c $app_destdir/
	if [ $? -ne 0 ]; then
		echo "[WARNING] Error installing bookstrap."
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

deploy_application_git reinst
chown -R $lxcuser:$lxcgroup $app_destdir

lazylibrarian_config_checkdir
lazylibrarian_deploy_config
ssl_ssc_create
lazylibrarian_install_settings
lazylibrarian_install_bookstrap

echo "[DEPLOY] Changing ownerships for lxc-media..."
deploy_lxcmedia_ownership

runit_linksv $appname

deploy_complete
