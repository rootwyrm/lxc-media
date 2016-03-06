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
        com.rootwyrm.nvd.update_sub="2016-03-06" \
        com.rootwyrm.nvd.hash="asdf" \
        com.rootwyrm.vcs-type="git" \
        com.rootwyrm.changelog-url="https://www.github.com/rootwyrm/lxc-media/lazylibrarian/CHANGELOG"

LABEL   com.rootwyrm.rootcore.base="docker.io/rootwyrm/lxc-media:base" \
        com.rootwyrm.rootcore.base.tag="latest" \
        com.rootwyrm.rootcore.depends="" \
        com.rootwyrm.rootcore.provides="lazylibrarian" \
        com.rootwyrm.rootcore.svctype="htpc" \
        com.rootwyrm.rootcore.ports_tcp="8171" \
        com.rootwyrm.rootcore.ports_udp="" \
        com.rootwyrm.rootcore.qnap_compatible="true" \
        com.rootwyrm.rootcore.synology_compatible="true"

## PHASE ZERO
## Global container variables
#ENV    lxcuser="lxcmedia" lxcuid="1024" lxcgroup="users" lxcgid="100"
EXPOSE  8171/tcp

## PHASE ONE
## Common components
RUN apk update && \
apk add --no-cache --virtual vp_python_base python && \
apk add --no-cache --virtual vp_lazylibrarian curl git 

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
VOLUME [ "/media/books" ]

## PHASE TEN (from Navarone)
ADD README.md /README.md

## TERMINUS
CMD [ "/sbin/runsvdir", "-P", "/etc/service" ]
