# rootwyrm/lxc-media
Media Hub (Docker Composer and Containers)

Designed to quickly deploy an entire media hub using Docker Composer and Docker Containers. Mostly built for me. Available to the world at large (with some restrictions) because I'm a nice guy. Also because I can't be the only one with this brilliant idea - but so far I am the only one to actually *implement* it.

# Components
* Transmission
* [sabnzbd]
* [SickRage] (spare me the politics, people)
* [CouchPotato]
* [Headphones]
* Mylar
* LazyLibrarian (currently tracking [DobyTang])
  * [BookStrap] included at no extra charge!

**CAUTION**: There is some magic involved to ensure containers can cross-talk. Each container is configured separately. READ THE README IN EACH CONTAINER.

# Host Portmap
Because people can't agree (or agree too much) on which ports they want to use, there is a fixed map in the composer.

| Container Name 	| Port Type 	| Host Port 	| Internal Port 	|
|----------------	|-----------	|-----------	|---------------	|
| transmission   	| http      	| 9091      	| 9091          	|
| sabnzbd        	| http      	| 9080      	| 8080          	|
| sabnzbd        	| https     	| 9081      	| 8081          	|
| sickrage       	| http      	| 8080      	| 8080          	|
| couchpotato    	| http      	| TBD       	| 5050          	|
| headphones     	| http      	| TBD       	| TBD           	|
| mylar          	| http      	| TBD       	| TBD           	|
| lazylibrarian  	| http      	| TBD       	| TBD           	|

# TODO: Document host requirements
Due to the nature of the containers, the host may require additional packages installed to support tools or containers themselves.

# TODO: SSL Self-Signed Certificate auto-generation and replacing
All containers will create a self-signed certificate on first boot at a fixed location, or on restart if the file is missing. These files can be replaced with your own certificate file set.

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
