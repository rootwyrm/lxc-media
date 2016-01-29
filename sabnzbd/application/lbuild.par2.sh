#!/bin/bash
## Build par2 using virtual package so we can slim it back down.

vpkg="vp_par2cmdline_build"
## NOTE: Must include ALL contents...
vpkg_build="musl musl-utils binutils binutils-libs gmp isl libgomp libatomic libgcc pkgconf pkgconfig mpfr3 mpc1 libstdc++ gcc musl-dev libc-dev g++ m4 perl automake autoconf make"
## And one for only running
vpkg_run="libstdc++ libgcc"

par2cmdline_git="https://github.com/Parchive/par2cmdline.git"

buildname="par2cmdline"
builddir="/root/src/par2cmdline"

/sbin/apk --no-cache --update add --virtual $vpkg $vpkg_build

mkdir -p $builddir
cd $builddir

git clone $par2cmdline_git $builddir

## Enter main routine
echo "$buildname: Executing aclocal"
aclocal
if [ $? -ne 0 ]; then
	RC=$?
	echo "[FATAL] aclocal failed"
	exit $RC
fi

echo "$buildname: Executing automake"
automake --add-missing > /dev/null
if [ $? -ne 0 ]; then
	RC=$?
	echo "[FATAL] automake failed"
	exit $RC
fi

echo "$buildname: Executing autoconf"
autoconf
if [ $? -ne 0 ]; then
	RC=$?
	echo "[FATAL] autoconf failed"
	exit $RC
fi

echo "$buildname: Executing ./configure"
./configure --bindir=/usr/local/bin --sbindir=/usr/local/sbin --sysconfdir=/usr/local/etc --quiet
if [ $? -ne 0 ]; then
	RC=$?
	echo "$buildname: [FATAL] Error in ./configure"
	exit $RC
fi

echo "$buildname: Building with make - output /root/par2cmdline.buildlog"
make > ~/par2cmdline.buildlog
if [ $? -ne 0 ]; then
	RC=$?
	echo "$buildname: [FATAL] Error during build!"
	cat /root/par2cmdline.buildlog
	exit $RC
else
	## Clean up the build log.
	echo "$buildname: Build succeeded, removing buildlog."
	rm /root/par2cmdline.buildlog
fi

echo "$buildname: Executing built-in tests"
make check | tee /root/par2cmdline.test > /dev/null 2&>1
## Now actually check if they succeeded.
txfail=$(grep '# XFAIL:' /root/par2cmdline.test | awk '{print $3}')
if [ $txfail != '0' ]; then
	echo "$buildname: Unit tests show XFAIL $txfail"
	exit 1
fi
tfail=$(grep '# FAIL:' ~/par2cmdline.test | awk '{print $3}')
if [ $tfail != '0' ]; then
	echo "$buildname: Unit tests show FAIL $tfail"
	exit 1
fi
rm /root/par2cmdline.test

make install

## Fail test complete
apk del --virtual $vpkg 
apk add --no-cache --virtual vp_par2cmdline $vpkg_run
if [ $? -ne 0 ]; then
	RC=$?
	echo "$buildname: Error cleaning up virtual package! apk return: $RC"
	exit $RC
fi

echo "$buildname: Testing executable operation."
for bin in `ls /usr/local/bin/par*`; do
	$bin -h > /dev/null 
	if [ $? -ne 0 ]; then
		RC=$?
		echo "$buildname: execution failure $bin - $RC"
		exit $RC
	fi
done

echo "$buildname: Cleaning up source..."
rm -rf /root/src/par2cmdline

echo "$buildname: Completed with no errors."
