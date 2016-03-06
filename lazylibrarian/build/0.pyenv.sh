#!/bin/bash
# couchpotato/build/0.pyenv.sh
# vers = 11fece527863e4cb3378f63ea251e35f

# Copyright (C) 2015-* Phillip R. Jaenke <docker@rootwyrm.com>
#
# NO COMMERCIAL REDISTRIBUTION IN ANY FORM IS PERMISSIBLE WITHOUT EXPRESS
# WRITTEN CONSENT FROM PHILLIP R. JAENKE. IGNORANCE IS NOT A DEFENSE.
# SEE /LICENSE

########################################
# Build Python OpenSSL
########################################

# Import functions
. /opt/rootwyrm/deploy.lib.sh

buildname="pyenv_mylar"

## NOTE: Must include all contents.
vbpkg="vp_python_mylar_build"
vbpkg_content="musl-dev python-dev libffi-dev openssl-dev gcc"
## NOTE: For running.
vrpkg="vp_python_mylar"
vrpkg_content="libffi py-lxml"

url_pip="https://bootstrap.pypa.io/get-pip.py"

curl_cmd="/usr/bin/curl --tlsv1.2 --cert-status --progress-bar"
pycmd="/usr/bin/python"

pip_pre="--prefix /usr/local"
pip_args="--prefix /usr/local --quiet --no-cache-dir --exists-action i"

## Check to make sure Docker added the sitecustomize
if [ ! -f /usr/lib/python2.7/site-packages/sitecustomize.py ]; then
	echo "$buildname: [FATAL] Missing python2.7/site-packages/sitecustomize.py!"
	exit 2
fi

## Install runtime
echo "[BUILD] Installing $vrpkg"
/sbin/apk --no-cache add --virtual $vrpkg $vrpkg_content
check_error $? $vrpkg

## Install pip
$curl_cmd $url_pip > /root/pip.py
check_error $? "pip bootstrap"
$pycmd /root/pip.py $pip_pre
if [ $? -ne 0 ]; then
	RC=$?
	echo "$buildname: [FATAL] pip bootstrap failure! RC $RC"
	exit $RC
fi

## Confirm functionality
/usr/local/bin/pip list > /dev/null
check_error $? "pip list functional test"

echo "[BUILD] Installing $vbpkg"
/sbin/apk --no-cache add --virtual $vbpkg $vbpkg_content
check_error $? $vbpkg

## pyOpenSSL
printf '[BUILD] Building and installing pyOpenSSL\n'
/usr/local/bin/pip install $pip_args pyOpenSSL
check_error $? pyOpenSSL

echo "[BUILD] Cleaning up $vbpkg"
/sbin/apk --no-cache del $vbpkg

echo "[BUILD] Verifying modules installed..."
pip list | awk '{print $1}' > /tmp/pip.list
for pydep in \
	cffi cryptography enum34 idna ipaddress lxml pip pyasn1 pycparser \
	pyOpenSSL setuptools six wheel; do
	grep -i $pydep /tmp/pip.list > /dev/null
	if [ $? -eq 0 ]; then
		printf '[OK] %s ' "$pydep"
	else
		printf '[FATAL] %s did not install!' "$pydep"
		exit 2
	fi
done
rm /tmp/pip.list

echo ""
echo "[BUILD] $0 completed successfully!"
