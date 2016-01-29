#!/bin/bash
## Build par2 using virtual package so we can slim it back down.

buildname="pyenv_sabnzbd"

vbpkg="vp_python_sabnzbd_build"
## NOTE: Must include ALL contents...
vbpkg_content="musl-dev python-dev libffi-dev openssl-dev gcc"
## And one for only running
vrpkg="vp_python_sabnzbd"
vrpkg_content=""

url_pip="https://bootstrap.pypa.io/get-pip.py"
url_yenc="https://bitbucket.org/dual75/yenc/get/default.tar.gz"

curl_cmd="/usr/bin/curl --tlsv1.2 --cert-status --progress-bar"
pycmd="/usr/bin/python"

pip_pre="--prefix /usr/local"
pip_args="--prefix /usr/local --quiet --no-cache-dir --exists-action i"

check_error()
{
	if [ $? -ne 0 ]; then
		RC=$?
		if [ -z $2 ]; then
			echo '[FATAL] Error occurred in $1\n'
			exit $RC
		else 
			echo '[FATAL] Error occurred in $1 : $2\n'
			exit $RC
		fi
	fi
}

## Check to make sure Docker added the sitecustomize
if [ ! -f /usr/lib/python2.7/site-packages/sitecustomize.py ]; then
	echo "$buildname: [FATAL] Missing python2.7/site-packages/sitecustomize.py!"
	exit 2
fi

## Bootstrap pip
$curl_cmd $url_pip > /root/pip.py
$pycmd /root/pip.py $pip_pre
if [ $? -ne 0 ]; then
	RC=$?
	echo "$buildname: [FATAL] pip bootstrap failure! RC $RC"
	exit $RC
fi

## Confirm functionality
/usr/local/bin/pip list > /dev/null
if [ $? -ne 0 ]; then
	RC=$?
	echo "$buildname: [FATAL] pip functional fail: pip list return $RC"
	exit $RC
fi

printf 'Installing Cheetah\n'
/usr/local/bin/pip install $pip_args cheetah
check_error cheetah

printf 'Installing configobj\n'
/usr/local/bin/pip install $pip_args configobj 
check_error configobj

printf 'Installing feedparser\n'
/usr/local/bin/pip install $pip_args feedparser
check_error feedparser

echo "Installing $vbpkg"
/sbin/apk --no-cache add --virtual $vbpkg $vbpkg_content
check_error $vbpkg

printf 'Building and installing pyOpenSSL\n'
/usr/local/bin/pip install $pip_args pyOpenSSL
check_error pyOpenSSL

printf 'Building and installing yenc from BitBucket\n'
/usr/local/bin/pip install $pip_args $url_yenc

echo "Cleaning up $vbpkg and preparing run test..."
/sbin/apk --no-cache del $vbpkg

echo "Verifying all modules installed..."
pip list | awk '{print $1}' > /tmp/pip.list
for pydep in cffi cheetah configobj cryptography enum34 feedparser \
	idna ipaddress markdown pip pyasn1 pycparser pyOpenSSL setuptools \
	six wheel yenc; do
	grep -i $pydep /tmp/pip.list
	if [ $? -eq 0 ]; then
		printf '%s ' "$pydep"
	else
		printf '%s: [FATAL] %s did not install!\n' "$buildname" "$pydep"
		rm /tmp/pip.list
		exit 2
	fi
done

echo "$buildname: Completed with no errors."
