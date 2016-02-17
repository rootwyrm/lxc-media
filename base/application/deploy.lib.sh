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
export svcdir="/etc/service"

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

	rm /etc/service/firstboot
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

	grep $lxcuser /etc/passwd > /dev/null
	if [ $? -eq 0 ]; then
		if [[ $(id -u $lxcuser) -eq $lxcuid ]]; then
			echo "[DEPLOY] User $lxcuser already at $lxcuid, leaving as is."
			return 0
		elif [[ $(id -u $lxcuser) != 0 ]]; then
			## NOP - user doesn't exist
			echo -n "" > /dev/null
		else
			deluser $lxcuser
		fi
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
	
	if [ ! -d $app_destdir ] ; then
		chown -R $lxcuid:$lxcgid $app_destdir
		if [ $? -ne 0 ]; then
			echo "[FATAL] Could not adjust ownership."
			exit 1
		fi
		# Don't forget the git files...
		chown -R $lxcuid:$lxcgid $app_destdir/.[a-z]*
		if [ $? -ne 0 ]; then
			echo "[FATAL] Could not chown_app_destdir."
			exit 1
		fi
	fi
}

## motd
########################################
generate_motd()
{
	baserel="R0V0U0.2016-02-05"
	releasefile="/opt/rootwyrm/release.id"
	if [ -s $releasefile ]; then
		releaseid="DEBUG_DEBUG_DEBUG_DEBUG"
	else
		releaseid=$(cat $releasefile)
	fi

	cp /opt/rootwyrm/defaults/motd /etc/motd
	sed -i -e 's,BASERELID,'$baserel',' /etc/motd
	sed -i -e 's,RELEASEID,'$releaseid',' /etc/motd
	sed -i -e 's,APPNAME,'$app_name',' /etc/motd
	sed -i -e 's,APPURL,'$app_url',' /etc/motd

	if [ -f /opt/rootwyrm/app.message ]; then
		sed -i -e '/APPMESSAGE$/d' /etc/motd
		cat /opt/rootwyrm/app.message >> /etc/motd
	else
		sed -i -e '/APPMESSAGE$/d' /etc/motd
	fi
}

# generic application functions
########################################
deploy_application_git()
{
	case $1 in
		[rR][eE][iI][nN][sS][tT]*)
		## This function generally shouldn't come up, but might.
			if [[ ! -z $app_destdir ]] && [[ -d $app_destdir ]]; then
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
                if [ $? -ne 0 ]; then
                    echo "[FATAL] Error in git_pull_update"
                    exit 1
                fi
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

## openssl functions
########################################
ssl_ssc_create()
{
	export ssldir="/config/ssl"
	if [[ -f $ssldir/media.crt ]] || [[ -f $ssldir/media.key ]]; then
		## Don't obliterate user provided key.
		echo "[SSL] Found existing $ssldir/media.crt"
		ssl_certificate_print
		return 0
	fi

	export sslpass=$(head -c 500 /dev/urandom | tr -dc a-z0-9A-Z | head -c 64)
	export mydomain=$(cat /etc/resolv.conf | grep search | awk '{print $2}')
	if [ -z $shorthost ]; then
		export shorthost=$(cat /etc/hostname)
	fi
	## Self-signed certs use the docker container ID and domain.
	export OPENSSLCONFIG=/opt/rootwyrm/defaults/openssl.cnf
	## Fix-up openssl.cnf
	sed -i -e 's,_REPLACE_HOSTNAME_,'$shorthost'.'$mydomain',' $OPENSSLCONFIG
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
	echo $sslpass > $ssldir/media.key.lock.string
	chmod 0400 $ssldir/media.key.lock.string

	## unlock key
	openssl rsa -in $ssldir/media.key.lock -out $ssldir/media.key -passin env:sslpass
	check_error $? ssl_unlock_key

	for sslfile in `ls $ssldir/*`; do
		chown $lxcuid:$lxcgid $sslfile
		chmod 0600 $sslfile
	done
}

ssl_certificate_print()
{
	## Print the certificate info
	if [ -f $ssldir/media.crt ]; then
		crtfp=`openssl x509 -subject -dates -fingerprint -in $ssldir/media.crt | grep Finger`
		echo "[SSL] $crtfp"
		check_error $? ssl_get_fingerprint
		crtdns=`openssl x509 -text -noout -subject -in $ssldir/media.crt | grep DNS | awk '{print $1,$2,$3,$4,$5,$6}'`
		echo "[SSL] $crtdns"
		## Don't check for DNS error.	
		crtissuer=`openssl x509 -text -noout -subject -in $ssldir/media.crt | grep Issuer:`
		echo "[SSL] $crtissuer"
		check_error $? ssl_get_issuer
		if [[ $(stat -c %U $ssldir/media.crt) != $lxcuser ]]; then
			chown $lxcuser $ssldir/media.crt
		fi
		if [[ $(stat -c %G $ssldir/media.crt) != $lxcgroup ]]; then
			chgrp $lxcgroup $ssldir/media.crt
		fi
		if [[ $(stat -c %a $ssldir/media.crt) != '700' ]]; then
			chmod 0700 $ssldir/media.crt
		fi
	else
		echo "[FATAL] ssl_certificate_print couldn't find certificate."
		exit 1
	fi
}

## runit configuration and management
########################################
runit_linksv()
{
	if [ -d /etc/sv/$app_svname ]; then
		ln -s /etc/sv/$app_svname /etc/service
		if [ $? -ne 0 ]; then
			echo "[FATAL] Failed to install $app_svname in runit."
			exit 1
		fi
	fi
	## Link crond if it's present
	if [ -d /etc/sv/cron ]; then
		ln -s /etc/sv/cron /etc/service
		if [ $? -ne 0 ]; then
			echo "[FATAL] Failed to install crond in runit."
		fi
	fi
}

