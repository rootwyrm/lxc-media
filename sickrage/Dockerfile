FROM  docker.io/rootwyrm/lxc-media:base
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
        com.rootwyrm.changelog-url="https://www.github.com/rootwyrm/lxc-media/sickrage/CHANGELOG"

LABEL   com.rootwyrm.rootcore.base="gliderlabs/alpine" \
        com.rootwyrm.rootcore.base.tag="latest" \
        com.rootwyrm.rootcore.depends="" \
        com.rootwyrm.rootcore.provides="sickrage" \
        com.rootwyrm.rootcore.svctype="htpc" \
        com.rootwyrm.rootcore.ports_tcp="8081" \
        com.rootwyrm.rootcore.ports_udp="" \
        com.rootwyrm.rootcore.qnap_compatible="true" \
        com.rootwyrm.rootcore.synology_compatible="true"

## sudo docker create -p 8080:8080 -p 8081:8081 --name=testnzb alp-nzb

## PHASE ZERO
## Global container variables
EXPOSE	8081/tcp
#ENV 	lxcuser="lxcmedia" lxcuid="1024" lxcgroup="users" lxcgid="100"

## PHASE ONE
## Common components
#ENV pkg_common="apk-cron supervisor bash git"
#RUN apk update ; apk upgrade ; apk add --no-cache $pkg_common
RUN apk update && apk add --no-cache --virtual vp_python_base python && \
apk add --no-cache --virtual vp_sickrage curl git && mkdir -p /opt/sickrage

## PHASE TWO
## Application and support installation
COPY [ "sv/", "/etc/sv" ]
COPY [ "build/", "/root/build" ]
ADD	application/sitecustomize.py /usr/lib/python2.7/site-packages/sitecustomize.py
#### XXX: Must sleep 5 for docker autobuild to not lock-race
#RUN	chmod +x /root/lbuild.pyenv.sh && sleep 5; \
#/root/lbuild.pyenv.sh
#### XXX: Must define shell - gliderlabs/docker-alpine/issues/141
#RUN adduser -h /home/$lxcuser -g "lxc-media user" -u $lxcuid -G $lxcgroup -D -s /bin/sh $lxcuser && \
#RUN	mkdir -p /opt/rootwyrm/defaults && \
#mkdir /var/log/supervisor && \
#mkdir /opt/sickrage

COPY [ "application/", "/opt/rootwyrm/" ]

## PHASE THREE
## Configuration
#ADD config/supervisord.conf /etc/supervisord.conf
#ADD config/*.ini /etc/supervisor.d/ 
#ADD application/sickrage.ini /etc/supervisor.d/
VOLUME [ "/media/sickrage" ]
#VOLUME [ "/config", "/downloads", "/media/sickrage" ]
#RUN	chown $lxcuid:$lxcgid /config && chown $lxcuid:$lxcgid /downloads && \
#	mkdir /var/log/supervisor
#RUN	sed -i -e 's,LXCUSER,'$lxcuser',g' /etc/supervisord.conf ; \
#	sed -i -e 's,LXCUSER,'$lxcuser',g' /etc/supervisor.d/*.ini ; \
#	sed -i -e 's,LXCGROUP,'$lxcgroup',g' /etc/supervisord.conf ; \
#	sed -i -e 's,LXCGROUP,'$lxcgroup',g' /etc/supervisor.d/*.ini
#ADD application/config.ini /config/
#RUN chown -R $lxcuid:$lxcgid /config/*
# XXX: Missing default config

## PHASE TEN (from Navarone)
## Cleanup unsafe/unneeded users...
#RUN mkdir -p /opt/rootwyrm
ADD README.md /README.md

## XXX: TEMP SKIP
#RUN	mkdir -p /opt/sickrage
#RUN git clone https://github.com/SickRage/SickRage.git -b master --depth=1 /opt/sickrage && touch /deploy

## TERMINUS
#CMD [ "/usr/bin/supervisord", "-n", "-d", "/", "-u", "0", "-m", "027", "-c", "/etc/supervisord.conf" ]
CMD [ "/sbin/init" ]	# TEMP

