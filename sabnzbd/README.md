# Known Issues
* https port interferes with cockpit
* first run script displays three times after setup (cosmetic)

# Sample Setup
docker create -p 9080:9080 -p 9090:9090 -v /media/config/sabnzbd:/config -v /media/download:/downloads --name=testsab docker.io/rootwyrm/lxc-media:sabnzbd

