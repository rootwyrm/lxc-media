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

## sudo docker create -p 8080:8080 -p 8081:8081 --name=testnzb alp-nzb

## PHASE ZERO
## Global container variables
#ENV 	lxcuser="lxcmedia" lxcuid="1024" lxcgroup="users" lxcgid="100"
EXPOSE	9080/tcp
EXPOSE	9081/tcp 

## PHASE ONE
## Common components
ENV pkg_common="apk-cron supervisor bash git"
RUN apk update ; apk upgrade ; apk add --no-cache $pkg_common

## PHASE TWO
## Application and support installation
#### python base and pip
RUN apk add --no-cache --virtual vp_python_base python 
ADD	application/sitecustomize.py /usr/lib/python2.7/site-packages/sitecustomize.py
ADD build/lbuild.par2.sh /root/
ADD build/lbuild.pyenv.sh /root/
#### XXX: Must sleep 5 for docker autobuild to not lock-race
RUN	chmod +x /root/lbuild.par2.sh && sleep 5; \
/root/lbuild.par2.sh
RUN	chmod +x /root/lbuild.pyenv.sh && sleep 5; \
/root/lbuild.pyenv.sh
RUN	mkdir -p /opt/rootwyrm/defaults && \
mkdir /var/log/supervisor && \
mkdir /opt/sabnzbd && \
git clone https://github.com/sabnzbd/sabnzbd.git -b 0.7.x --depth=1 /opt/sabnzbd && touch /deploy

ADD application/* /opt/rootwyrm/
ADD application/defaults/* /opt/rootwyrm/defaults/

## PHASE THREE
## Configuration
ADD config/supervisord.conf /etc/supervisord.conf
ADD config/*ini /etc/supervisor.d/ 
#ADD application/sickrage.ini /etc/supervisor.d/
VOLUME [ "/config", "/downloads" ]

## PHASE TEN (from Navarone)
## Cleanup unsafe/unneeded users...
ADD README.md /README.md

## TERMINUS
CMD [ "/usr/bin/supervisord", "-n", "-d", "/", "-u", "0", "-m", "027", "-c", "/etc/supervisord.conf" ]
