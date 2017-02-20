# rootwyrm/lxc-media
Media Hub (Docker Composer and Containers)

Designed to quickly deploy an entire media hub using Docker Composer and Docker Containers. Mostly built for me. Available to the world at large (with some restrictions) because I'm a nice guy. Also because I can't be the only one with this brilliant idea - but so far I am the only one to actually *implement* it.

# Components (those in bold are complete!)
* **Base** [![](https://images.microbadger.com/badges/image/rootwyrm/lxc-media:base.svg)](https://microbadger.com/images/rootwyrm/lxc-media:base "Get your own image badge on microbadger.com")
* **Transmission** - rootwyrm/lxc-media:transmission [![](https://images.microbadger.com/badges/image/rootwyrm/lxc-media:transmission.svg)](https://microbadger.com/images/rootwyrm/lxc-media:transmission "Get your own image badge on microbadger.com")
* **[sabnzbd]** - rootwyrm/lxc-media:sabnzbd [![](https://images.microbadger.com/badges/image/rootwyrm/lxc-media:sabnzbd.svg)](https://microbadger.com/images/rootwyrm/lxc-media:sabnzbd "Get your own image badge on microbadger.com")
* **[SickRage]** - rootwyrm/lxc-media:sickrage [![](https://images.microbadger.com/badges/image/rootwyrm/lxc-media:sickrage.svg)](https://microbadger.com/images/rootwyrm/lxc-media:sickrage "Get your own image badge on microbadger.com")
* **[CouchPotato]** - rootwyrm/lxc-media:couchpotato [![](https://images.microbadger.com/badges/image/rootwyrm/lxc-media:couchpotato.svg)](https://microbadger.com/images/rootwyrm/lxc-media:couchpotato "Get your own image badge on microbadger.com")
* **[Headphones]** - rootwyrm/lxc-media:headphones [![](https://images.microbadger.com/badges/image/rootwyrm/lxc-media:headphones.svg)](https://microbadger.com/images/rootwyrm/lxc-media:headphones "Get your own image badge on microbadger.com")
* **[Mylar]** - rootwyrm/lxc-media:mylar [![](https://images.microbadger.com/badges/image/rootwyrm/lxc-media:mylar.svg)](https://microbadger.com/images/rootwyrm/lxc-media:mylar "Get your own image badge on microbadger.com")
* **LazyLibrarian** (currently tracking [DobyTang]) - rootwyrm/lxc-media:lazylib [![](https://images.microbadger.com/badges/image/rootwyrm/lxc-media:lazylibrarian.svg)](https://microbadger.com/images/rootwyrm/lxc-media:lazylibrarian "Get your own image badge on microbadger.com")
  * [BookStrap] included at no extra charge!

**CAUTION**: There is some magic involved to ensure containers can cross-talk. Each container is configured separately. READ THE README IN EACH CONTAINER.

# Host Portmap
Because people can't agree (or agree too much) on which ports they want to use, there is a fixed map in the composer.

| Container Name 	| Port Type 	| Host Port 	| Internal Port 	|
|----------------	|-----------	|-----------	|---------------	|
| transmission   	| http      	| 9091      	| 9091          	|
| sabnzbd        	| http      	| 9080      	| 9080          	|
| sabnzbd        	| https     	| 9090      	| 9090          	|
| sickrage       	| https     	| 8081      	| 8081          	|
| couchpotato    	| https     	| 5050      	| 5050          	|
| headphones     	| https      	| 8181      	| 8181          	|
| mylar          	| https      	| 8071      	| 8071          	|
| lazylibrarian  	| http	     	| 5299			| 5299				|

# Volume Layout
These containers use a common volume layout to make life easier.
* `/config` - holds application configuration data
* `/downloads` - where downloads land by default
* `/shared` - general purpose shared volume area

# TODO: Document host requirements
Due to the nature of the containers, the host may require additional packages installed to support tools or containers themselves.

# TODO: SSL Self-Signed Certificate auto-generation and replacing
All supporting containers will create a self-signed certificate on first boot at a fixed location, or on restart if the file is missing. These files can be replaced with your own certificate file set.

`/config/ssl/media.crt` and `/config/ssl/media.key`
* All containers complete

# TODO: nginx/Apache vhost proxy Alternate Composer File
Alternate composer file for proxied vhosts (i.e. transmission.example.com mapping to container port) which uses an entirely different portmap to stay better out of the way.

# TODO: Basically all the docs and then some.

# Read The License!!
**READ THE LICENSE CAREFULLY. IGNORANCE IS NOT A DEFENSE. COMMERCIAL DISTRIBUTION, REDISTRIBUTION, OR REPACKAGING WITHOUT WRITTEN CONSENT IS PROHIBITED.** While this builds on various open source licensed software, the specific contents of this repository (that means the build files, scripts, etcetera) are external tools and do not directly contribute to or modify the software they work with. I have my eye on you abusers - and you know exactly who you are. 

[sabnzbd]:https://github.com/sabnzbd/sabnzbd
[SickRage]:https://github.com/SickRage/SickRage
[CouchPotato]:https://github.com/RuudBurger/CouchPotatoServer
[Headphones]:https://github.com/rembo10/headphones
[Mylar]:https://github.com/evilhero/mylar
[DobyTang]:https://github.com/DobyTang/LazyLibrarian
[BookStrap]:https://github.com/warlord0/lazylibrarian.bookstrap
