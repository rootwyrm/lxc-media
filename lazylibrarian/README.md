**Important Note**: Python modules must be _built_ due to the Alpine package missing key functions (cryptography.hazmat.bindings.openssl.binding) used by python libs.

# Connection Information
https://ContainerHost:8171/ - only `https` will work as LazyLibrarian only listens on one port. You can disable `https` in the application after initial setup.

# Sample Setup
docker create -p 8171:8171 -v /media/config/lazylibrarian:/config -v /media/download:/downloads -v /media/books:/media/books --name=lazylibtest docker.io/rootwyrm/lxc-media:lazylibrarian
