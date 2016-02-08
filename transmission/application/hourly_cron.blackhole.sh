#!/bin/bash
# hourly_cron.blocklist.sh
# vers = 5bb70b257914b179a648ab820e522c3a

bldir=/config/blocklists

## Check if there are new files to ingest.
if [ ! -d $bldir ]; then
	## Directory missing is an error.
	exit 1
fi

check_enable()
{
	# Check settings.json
	if [ -f /config/settings.json ]; then
		export blcfg=$(grep "blocklist-enabled" /config/settings.json | awk '{print $2}' | sed -e 's/,//')
	fi
	if [ -z $blstate ]; then
		## May be set from command line.
		pgrep transmission-daemon | grep -e "-b " -e "--blocklist" > /dev/null
		if [ $? -ne 0 ]; then
			## Blocklist is not enabled
			exit 0
		fi
	fi
}

check_state()
{
	ls $bldir/*.dat > /dev/null
	if [ $? -ne 0 ]; then
		## No blocklist running set
		blstate=""
	else
		blstate="run"
	fi
}

## XXX: Not being used right now.
clean_active()
{
	# Ensure not running
	ps ax | grep transmission-daemon > /dev/null 
	if [ $? -eq 0 ]; then
		sv stop transmission
		if [ $? -ne 0 ]; then
			exit 1
		fi
	fi

	for datfile in `ls $bldir/$.dat`; do
		rm $datfile
	done
}

process_control()
{
	## Oh so much fun...
	/sbin/sv $1 transmission
	if [ $? -ne 0 ]; then
		echo "Error stopping transmission daemon."
		exit 1
	else
		while true; do
			sleep 1
			pgrep transmission-daemon > /dev/null 
			if [ $? -ne 0 ]; then
				break
			fi
		done
	fi
}

download_updates()
{
	blconf="/config/blocklist.conf" 
	tmpdir="/tmp/bl"
	if [ ! -d /tmp/bl ]; then
		mkdir /tmp/bl
	fi
	if [ -f $blconf ] && [ -s $blconf ]; then
		for entry in `cat $blconf | awk '{print $1}'`; do
			wget -q -O $tmpdir/$entry $(cat $blconf | grep $entry | awk '{print $2}')
			if [ $? -ne 0 ]; then
				echo "Error retrieving $entry"
			fi
		done
	fi
	## This part is slightly annoying.
	for entry in `cat $blconf`; do
		file $tmpdir/$entry | grep "gzip compressed" > /dev/null
		if [ $? -eq 0 ]; then
			mv $tmpdir/$entry $tmpdir/"$entry".gz
			gunzip $tmpdir/"$entry".gz
		fi
	done
}

place_updates()
{
	for entry in `cat $blconf`; do
		if [ -f $bldir/"$entry".dat ]; then
			rm $bldir/"$entry".dat
		fi
		if [ -f $bldir/$entry ]; then
			mv $bldir/$entry $bldir/"$entry".last
		fi
		mv $tmpdir/$entry $bldir/
	done
}

check_enable
download_updates
process_control stop
if [ $? -ne 0 ]; then
	RC=$?
	echo "[FATAL] process_control stop: $RC"
	exit $RC
fi
place_updates
process_control start
if [ $? -ne 0 ]; then
	RC=$?
	echo "[FATAL] process_control start: $RC"
	exit $RC
fi
