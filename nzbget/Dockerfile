FROM  docker.io/rootwyrm/lxc-media:base
## The magic begins...
MAINTAINER    Phillip "RootWyrm" Jaenke <docker@rootwyrm.com>

## We always use labels.
## NOTE: Uses TSLE NVD with Substring ISO8601
ARG	VCS_REF BUILD_DATE \
	NVD_UPDATE_SUB
LABEL   com.rootwyrm.vendor="RootWyrm" \
        com.rootwyrm.project="lxc-media" \
        com.rootwyrm.status="master" \
        com.rootwyrm.nvd.release="1" \
        com.rootwyrm.nvd.version="0" \
        com.rootwyrm.nvd.update="0" \
        com.rootwyrm.nvd.update_sub="$NVD_UPDATE_SUB" \
        com.rootwyrm.nvd.build_time="$BUILD_DATE" \
        com.rootwyrm.vcs-type="git" \
        com.rootwyrm.changelog-url="https://www.github.com/rootwyrm/lxc-media/transmission/CHANGELOG" \
		com.rootwyrm.rootcore.base="gliderlabs/alpine" \
        com.rootwyrm.rootcore.base.tag="latest" \
        com.rootwyrm.rootcore.depends="" \
        com.rootwyrm.rootcore.provides="nzbget" \
        com.rootwyrm.rootcore.svctype="nntp" \
        com.rootwyrm.rootcore.ports_tcp="6789" \
        com.rootwyrm.rootcore.ports_udp="" \
        com.rootwyrm.rootcore.qnap_compatible="true" \
        com.rootwyrm.rootcore.synology_compatible="true" \
		## label-schema.org
		org.label-schema.vcs-ref=$VCS_REF \
		org.label-schema.vcs-url="https://github.com/rootwyrm/lxc-media/nzbget" \
		org.label-schema.build-date=$BUILD_DATE

## PHASE ZERO
## Global container variables
EXPOSE	6789/tcp

## PHASE ONE
## Common components

## PHASE TWO
## Application and support installation
ENV pkg_application="curl dcron apk-cron"
RUN apk update && \
	apk upgrade && \
	apk add --no-cache $pkg_application 
COPY [ "application/", "/opt/rootwyrm/" ]
COPY [ "sv/", "/etc/sv/" ]

## PHASE THREE
## Configuration

## PHASE TEN (from Navarone)
## Cleanup unsafe/unneeded users...
ADD README.md /README.md

## TERMINUS
CMD [ "/sbin/runsvdir", "-P", "/etc/service" ]
