#Transmission Port Layout

Transmission uses ports 9091 (TCP/UDP) for web interface and peer communications. The randomized port range has been moved to 43210-48210 and random port is on by default. This can be changed in `/config/settings.json`.

#Blacklist Automatic Update
**Work in progress.**

#Important Host Configuration Requirements
Required in `/etc/sysctl.conf`:
    net.core.rmem_max=8388608
	net.core.wmem_max=2097152

# Quick Creation (NOT FOR PRODUCTION)
docker create -p 9091:9091 -p 43210-48210:43210-48210 -v /media/config/transmission:/config -v /media/incoming:/downloads -v /nfs/shared:/shared --name=testtrans rootwyrm/lxc-media:transmission 
