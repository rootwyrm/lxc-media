**Important Note**: Python modules must be _built_ due to the Alpine package missing key functions (cryptography.hazmat.bindings.openssl.binding) used by python libs.

# Connection Information
https://ContainerHost:8181/ - only `https` will work as CouchPotato only listens on one port. You can disable `https` in the application after initial setup.

# Sample Setup
docker create -p 8181:8181 -v /media/config/headphones:/config -v /media/download:/downloads -v /media/headphones:/media/music --name=hptest docker.io/rootwyrm/lxc-media:headphones
