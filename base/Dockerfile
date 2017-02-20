FROM  gliderlabs/alpine:latest
## The magic begins...
MAINTAINER    Phillip "RootWyrm" Jaenke <docker@rootwyrm.com>

## Rebase to cut down on the layers, which are getting ridiculous.
## We always use labels.
## NOTE: Uses TSLE NVD with Substring ISO8601, hash=sha256
ARG VCS_REF
ARG BUILD_DATE
LABEL   com.rootwyrm.vendor="RootWyrm" \
        com.rootwyrm.project="lxc-media" \
        com.rootwyrm.status="stable" \
        com.rootwyrm.nvd.release="1" \
        com.rootwyrm.nvd.version="0" \
        com.rootwyrm.nvd.update="3" \
        com.rootwyrm.nvd.update_sub="2017-02-20" \
		com.rootwyrm.nvd.build_time="$BUILD_DATE" \
        com.rootwyrm.vcs-type="git" \
        com.rootwyrm.changelog-url="https://www.github.com/rootwyrm/lxc-media/base/CHANGELOG" \
		com.rootwyrm.rootcore.base="gliderlabs/alpine" \
        com.rootwyrm.rootcore.base.tag="latest" \
        com.rootwyrm.rootcore.depends="" \
        com.rootwyrm.rootcore.provides="" \
        com.rootwyrm.rootcore.svctype="" \
        com.rootwyrm.rootcore.ports_tcp="" \
        com.rootwyrm.rootcore.ports_udp="" \
        com.rootwyrm.rootcore.qnap_compatible="true" \
        com.rootwyrm.rootcore.synology_compatible="true" \
		## label-schema.org 
		org.label-schema.vcs-ref=$VCS_REF \
		org.label-schema.vcs-url="https://github.com/rootwyrm/lxc-media/base" \
		org.label-schema.build-date=$BUILD_DATE

ENV pkg_common="runit bash file dcron apk-cron openssl"

## Create common elements
COPY [ "application/", "/opt/rootwyrm" ]
COPY [ "sv/", "/etc/sv" ]
RUN mkdir -p /opt/rootwyrm/defaults; mkdir -p /opt/rootwyrm/build; \
mkdir -p /var/log/runit ; touch /deploy ; \
echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
apk add --no-cache $pkg_common ; \ 
ln -s /etc/sv/firstboot /etc/service/ ; \
ln -s /etc/service /service ; \
sed -i -e '/^tty*/d' /etc/inittab && \
sed -i -e '/^# Set up*/d' /etc/inittab && \
sed -i -e '/^::ctrlalt*/d' /etc/inittab  && \
sed -i -e '/.*salute$/d' /etc/inittab

VOLUME [ "/config", "/downloads", "/shared", "/run" ]
