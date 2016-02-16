**Important Note**: Python modules must be _built_ due to the Alpine package missing key functions (cryptography.hazmat.bindings.openssl.binding) used by CouchPotato.

# Connection Information
https://ContainerHost:5050/ - only `https` will work as CouchPotato only listens on one port. You can disable `https` in the application after initial setup.

# Sample Setup
docker create -p 5050:5050 -v /media/config/couchpotato:/config -v /media/download:/downloads -v /media/couchpotato:/media/movies --name=testcp docker.io/rootwyrm/lxc-media:couchpotato
