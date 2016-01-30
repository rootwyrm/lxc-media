FROM  gliderlabs/alpine:latest
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
EXPOSE	9091/udp 9091/tcp 51413/udp

## PHASE ONE
## Common components
ENV pkg_common="apk-cron supervisor bash"
RUN apk update ; apk upgrade ; apk add --no-cache $pkg_common

## PHASE TWO
## Application and support installation
ENV pkg_application="openssl transmission-daemon"
RUN apk add --no-cache $pkg_application

## PHASE THREE
## Configuration
ADD application/supervisord.conf /etc/supervisord.conf
ADD application/*.ini /etc/supervisor.d/
ENV lxcuser="lxcmedia" lxcuid="1024" lxcgroup="users" lxcgid="100"
#### XXX: Must define shell - gliderlabs/docker-alpine/issues/141
RUN adduser -h /home/$lxcuser -g "lxc-media user" -u $lxcuid -G $lxcgroup -D -s /bin/sh $lxcuser && \
	mkdir /config && mkdir /downloads && \
	chown $lxcuid:$lxcgid /config && chown $lxcuid:$lxcgid /downloads && \
	mkdir /var/log/supervisor 
RUN	sed -i -e 's,LXCUSER,'$lxcuser',g' /etc/supervisord.conf ; \
	sed -i -e 's,LXCUSER,'$lxcuser',g' /etc/supervisor.d/*.ini ; \
	sed -i -e 's,LXCGROUP,'$lxcgroup',g' /etc/supervisord.conf ; \
	sed -i -e 's,LXCGROUP,'$lxcgroup',g' /etc/supervisor.d/*.ini
VOLUME [ "/config", "/downloads" ]
ADD application/settings.json /config/

## PHASE TEN (from Navarone)
## Cleanup unsafe/unneeded users...
RUN mkdir -p /opt/rootwyrm
ADD README.md /README.md
ADD application/user.cleanup /opt/rootwyrm/user.cleanup
RUN /opt/rootwyrm/user.cleanup ; rm /opt/rootwyrm/user.cleanup

## TERMINUS
CMD [ "/usr/bin/supervisord", "-n", "-d", "/", "-u", "0", "-m", "027", "-c", "/etc/supervisord.conf" ]
