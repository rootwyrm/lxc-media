FROM  base
#FROM  rootwyrm/lxc-media:base
## The magic begins...
MAINTAINER    Phillip "RootWyrm" Jaenke <docker@rootwyrm.com>

## We always use labels.
## NOTE: Uses TSLE NVD with Substring ISO8601
LABEL   com.rootwyrm.vendor="RootWyrm" \
        com.rootwyrm.project="lxc-media" \
        com.rootwyrm.status="release" \
        com.rootwyrm.nvd.release="0" \
        com.rootwyrm.nvd.version="0" \
        com.rootwyrm.nvd.update="0" \
        com.rootwyrm.nvd.update_sub="2016-01-27" \
        com.rootwyrm.vcs-type="git" \
        com.rootwyrm.changelog-url="https://www.github.com/rootwyrm/lxc-media/transmission/CHANGELOG"

LABEL   com.rootwyrm.rootcore.base="gliderlabs/alpine" \
        com.rootwyrm.rootcore.base.tag="latest" \
        com.rootwyrm.rootcore.depends="" \
        com.rootwyrm.rootcore.provides="transmission" \
        com.rootwyrm.rootcore.svctype="torrent" \
        com.rootwyrm.rootcore.ports_tcp="9091" \
        com.rootwyrm.rootcore.ports_udp="9091 51413" \
        com.rootwyrm.rootcore.qnap_compatible="true" \
        com.rootwyrm.rootcore.synology_compatible="true"

## PHASE ZERO
## Global container variables
EXPOSE	9091/udp 9091/tcp 43454/udp

## PHASE ONE
## Common components

## PHASE TWO
## Application and support installation
ENV pkg_application="openssl transmission-daemon"
RUN apk add --no-cache $pkg_application

## PHASE THREE
## Configuration
#ADD application/supervisord.conf /etc/supervisord.conf
#ADD application/*.ini /etc/supervisor.d/
ENV lxcuser="lxcmedia" lxcuid="1024" lxcgroup="users" lxcgid="100"
#### XXX: Must define shell 
#### -- gliderlabs/docker-alpine/issues/141
#### -- http://bugs.alpinelinux.org/issues/5083
RUN adduser -h /home/$lxcuser -g "lxc-media user" -u $lxcuid -G $lxcgroup -D -s /bin/sh $lxcuser && \
	mkdir -p /etc/runit ; mkdir -p /service
#VOLUME [ "/config", "/downloads" ]
COPY [ "application/", "/opt/rootwyrm/" ]
COPY [ "sv/", "/etc/sv/" ]
#ADD application/settings.json /opt/rootwyrm/defaults/ 
ADD config/rc.conf /etc/rc.conf
#RUN chmod +x /etc/runit/* && \
RUN sed -i -e '/^tty*/d' /etc/inittab && \
sed -i -e '/^# Set up*/d' /etc/inittab && \
sed -i -e '/^::ctrlalt*/d' /etc/inittab  && \
sed -i -e '/.*salute$/d' /etc/inittab

## PHASE TEN (from Navarone)
## Cleanup unsafe/unneeded users...
ADD README.md /README.md

## TERMINUS
CMD [ "/sbin/init" ]
