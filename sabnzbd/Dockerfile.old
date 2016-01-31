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
        com.rootwyrm.rootcore.ports_tcp="8080 8081" \
        com.rootwyrm.rootcore.ports_udp="" \
        com.rootwyrm.rootcore.qnap_compatible="true" \
        com.rootwyrm.rootcore.synology_compatible="true"

## sudo docker create -p 8080:8080 -p 8081:8081 --name=testnzb alp-nzb

## PHASE ZERO
## Global container variables
EXPOSE  8080/tcp
EXPOSE	8081/tcp
ENV 	lxcuser="lxcmedia" lxcuid="1024" lxcgroup="users" lxcgid="100"

## PHASE ONE
## Common components
ENV pkg_common="apk-cron supervisor bash git"
RUN apk update ; apk upgrade ; apk add --no-cache $pkg_common

## PHASE TWO
## Application and support installation
#ENV pkg_application="openssl unrar p7zip git py-virtualenv py-cffi py-openssl gcc aclocal automake autoconf"
#### par2cmdline, unrar, unzip
#### XXX: Must sleep 5 for docker autobuild to not lock-race
ADD	application/lbuild.par2.sh /root/
RUN chmod +x /root/lbuild.par2.sh && sleep 5; \
	/root/lbuild.par2.sh
RUN apk add --no-cache p7zip unrar
#### python base and pip
RUN apk add --no-cache --virtual vp_python_base python 
ADD	application/sitecustomize.py /usr/lib/python2.7/site-packages/sitecustomize.py
ADD application/lbuild.pyenv.sh /root/
#### XXX: Must sleep 5 for docker autobuild to not lock-race
RUN	chmod +x /root/lbuild.pyenv.sh && sleep 5; \
	/root/lbuild.pyenv.sh
#### XXX: Must define shell - gliderlabs/docker-alpine/issues/141
RUN adduser -h /home/$lxcuser -g "lxc-media user" -u $lxcuid -G $lxcgroup -D -s /bin/sh $lxcuser 

## PHASE THREE
## Configuration
ADD application/supervisord.conf /etc/supervisord.conf
ADD application/*.ini /etc/supervisor.d/
RUN	mkdir /config && mkdir /downloads && \
	chown $lxcuid:$lxcgid /config && chown $lxcuid:$lxcgid /downloads && \
	mkdir /var/log/supervisor
RUN	sed -i -e 's,LXCUSER,'$lxcuser',g' /etc/supervisord.conf ; \
	sed -i -e 's,LXCUSER,'$lxcuser',g' /etc/supervisor.d/*.ini ; \
	sed -i -e 's,LXCGROUP,'$lxcgroup',g' /etc/supervisord.conf ; \
	sed -i -e 's,LXCGROUP,'$lxcgroup',g' /etc/supervisor.d/*.ini
VOLUME [ "/config", "/downloads" ]
# XXX: Missing default config

## PHASE TEN (from Navarone)
## Cleanup unsafe/unneeded users...
#RUN mkdir -p /opt/rootwyrm
ADD README.md /README.md

## XXX: TEMP SKIP
RUN	mkdir -p /opt/sabnzbd
RUN git clone https://github.com/sabnzbd/sabnzbd.git -b 0.7.x --depth=1 /opt/sabnzbd

## TERMINUS
CMD [ "/usr/bin/supervisord", "-n", "-d", "/", "-u", "0", "-m", "027", "-c", "/etc/supervisord.conf" ]

