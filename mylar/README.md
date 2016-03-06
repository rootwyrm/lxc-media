**Important Note**: Python modules must be _built_ due to the Alpine package missing key functions (cryptography.hazmat.bindings.openssl.binding) used by python libs.

# Connection Information
https://ContainerHost:8071/ - only `https` will work as Mylar only listens on one port. You can disable `https` in the application after initial setup.

# Sample Setup
docker create -p 8071:8071 -v /media/config/mylar:/config -v /media/download:/downloads -v /media/comics:/media/comics --name=mylartest docker.io/rootwyrm/lxc-media:mylar
