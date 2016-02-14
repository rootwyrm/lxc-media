FROM  docker.io/rootwyrm/lxc-media:base
## The magic begins...
MAINTAINER    Phillip "RootWyrm" Jaenke <docker@rootwyrm.com>

## We always use labels.
## NOTE: Uses TSLE NVD with Substring ISO8601
LABEL   com.rootwyrm.vendor="RootWyrm" \
        com.rootwyrm.project="lxc-media" \
        com.rootwyrm.status="release" \
        com.rootwyrm.nvd.release="1" \
        com.rootwyrm.nvd.version="0" \
        com.rootwyrm.nvd.update="0" \
        com.rootwyrm.nvd.update_sub="2016-02-14" \
        com.rootwyrm.nvd.hash="234f8a9256889f6944719f0505eca52ee7b59f0df4b3b12dcf2a4fd8beb1bc5b" \
        com.rootwyrm.vcs-type="git" \
        com.rootwyrm.changelog-url="https://www.github.com/rootwyrm/lxc-media/sabnzbd/CHANGELOG"

LABEL   com.rootwyrm.rootcore.base="gliderlabs/alpine" \
        com.rootwyrm.rootcore.base.tag="latest" \
        com.rootwyrm.rootcore.depends="" \
        com.rootwyrm.rootcore.provides="sabnzbd" \
        com.rootwyrm.rootcore.svctype="htpc" \
        com.rootwyrm.rootcore.ports_tcp="8081" \
        com.rootwyrm.rootcore.ports_udp="" \
        com.rootwyrm.rootcore.qnap_compatible="true" \
        com.rootwyrm.rootcore.synology_compatible="true"

## PHASE ZERO
## Global container variables
EXPOSE	9080/tcp 9090/tcp

## PHASE ONE
## Base system components
#ENV pkg_common="apk-cron openrc supervisor bash git"
#RUN apk update ; apk upgrade ; apk add --no-cache $pkg_common
RUN apk update && apk add --no-cache --virtual vp_python_base python && \
apk add --no-cache --virtual vp_sabnzbd curl git 

## PHASE TWO
## Application and support installation
#### python base and pip
COPY [ "sv/", "/etc/sv/" ]
COPY [ "build/", "/root/build" ]
ADD	application/sitecustomize.py /usr/lib/python2.7/site-packages/sitecustomize.py
#### XXX: moved to deploy.sh
#### XXX: Must sleep 5 for docker autobuild to not lock-race
#RUN	chmod +x /root/lbuild.par2.sh && sleep 5; \
#/root/lbuild.par2.sh
#RUN	chmod +x /root/lbuild.pyenv.sh && sleep 5; \
#/root/lbuild.pyenv.sh
#RUN	mkdir -p /opt/rootwyrm/defaults && \
#mkdir /var/log/supervisor && \
RUN mkdir /opt/sabnzbd 
#&& \
#git clone https://github.com/sabnzbd/sabnzbd.git -b 0.7.x --depth=1 /opt/sabnzbd && touch /deploy
#
COPY [ "application/", "/opt/rootwyrm/" ]
#ADD application/defaults/* /opt/rootwyrm/defaults/

## PHASE THREE
## Configuration
#ADD application/sickrage.ini /etc/supervisor.d/
#VOLUME [ "/config", "/downloads", "/run" ]

## PHASE TEN (from Navarone)
## Cleanup unsafe/unneeded users...
ADD README.md /README.md

## TERMINUS
CMD [ "/sbin/runsvdir", "-P", "/etc/service" ]
