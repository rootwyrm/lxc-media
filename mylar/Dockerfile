FROM  docker.io/rootwyrm/lxc-media:base
## The magic begins...
MAINTAINER    Phillip "RootWyrm" Jaenke <docker@rootwyrm.com>

## We always use labels.
## NOTE: Uses TSLE NVD with Substring ISO8601
LABEL   com.rootwyrm.vendor="RootWyrm" \
        com.rootwyrm.project="lxc-media" \
        com.rootwyrm.status="stable" \
        com.rootwyrm.nvd.release="1" \
        com.rootwyrm.nvd.version="0" \
        com.rootwyrm.nvd.update="0" \
        com.rootwyrm.nvd.update_sub="2016-03-05" \
        com.rootwyrm.nvd.hash="0900940fe726500f202f409d6182fd945f917e93fb34115fb3f0aab0c50d2c35" \
        com.rootwyrm.vcs-type="git" \
        com.rootwyrm.changelog-url="https://www.github.com/rootwyrm/lxc-media/couchpotato/CHANGELOG"

LABEL   com.rootwyrm.rootcore.base="docker.io/rootwyrm/lxc-media:base" \
        com.rootwyrm.rootcore.base.tag="latest" \
        com.rootwyrm.rootcore.depends="" \
        com.rootwyrm.rootcore.provides="mylar" \
        com.rootwyrm.rootcore.svctype="htpc" \
        com.rootwyrm.rootcore.ports_tcp="8071" \
        com.rootwyrm.rootcore.ports_udp="" \
        com.rootwyrm.rootcore.qnap_compatible="true" \
        com.rootwyrm.rootcore.synology_compatible="true"

## PHASE ZERO
## Global container variables
#ENV    lxcuser="lxcmedia" lxcuid="1024" lxcgroup="users" lxcgid="100"
EXPOSE  8071/tcp

## PHASE ONE
## Common components
RUN apk update && \
apk add --no-cache --virtual vp_python_base python && \
apk add --no-cache --virtual vp_mylar curl git 

## PHASE TWO
## Application and support installation
COPY [ "sv/", "/etc/sv" ]
COPY [ "build/", "/root/build" ]
ADD	application/sitecustomize.py /usr/lib/python2.7/site-packages/sitecustomize.py
RUN	for bld in `ls /root/build/ | sort`; do \
		/root/build/$bld ; \
	done

COPY [ "application/", "/opt/rootwyrm/" ]

## PHASE THREE
## Configuration
## Volume for output
VOLUME [ "/media/comics" ]

## PHASE TEN (from Navarone)
ADD README.md /README.md

## TERMINUS
CMD [ "/sbin/runsvdir", "-P", "/etc/service" ]
