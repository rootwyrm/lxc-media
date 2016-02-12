FROM  gliderlabs/alpine:latest
## The magic begins...
MAINTAINER    Phillip "RootWyrm" Jaenke <docker@rootwyrm.com>

## Rebase to cut down on the layers, which are getting ridiculous.
## We always use labels.
## NOTE: Uses TSLE NVD with Substring ISO8601, hash=sha256
LABEL   com.rootwyrm.vendor="RootWyrm" \
        com.rootwyrm.project="lxc-media" \
        com.rootwyrm.status="stable" \
        com.rootwyrm.nvd.release="1" \
        com.rootwyrm.nvd.version="0" \
        com.rootwyrm.nvd.update="1" \
        com.rootwyrm.nvd.update_sub="2016-02-12" \
        com.rootwyrm.nvd.hash="d627a1e2df42e56d278d10f65856eec0b6bc047b356fe48465e02fd5b86400d6" \
        com.rootwyrm.vcs-type="git" \
        com.rootwyrm.changelog-url="https://www.github.com/rootwyrm/lxc-media/base/CHANGELOG"

LABEL   com.rootwyrm.rootcore.base="gliderlabs/alpine" \
        com.rootwyrm.rootcore.base.tag="latest" \
        com.rootwyrm.rootcore.depends="" \
        com.rootwyrm.rootcore.provides="" \
        com.rootwyrm.rootcore.svctype="" \
        com.rootwyrm.rootcore.ports_tcp="" \
        com.rootwyrm.rootcore.ports_udp="" \
        com.rootwyrm.rootcore.qnap_compatible="" \
        com.rootwyrm.rootcore.synology_compatible=""

ENV pkg_common="runit bash file"

## Create common elements
RUN mkdir -p /opt/rootwyrm/defaults; mkdir -p /opt/rootwyrm/build; \
mkdir -p /var/log/runit ; touch /deploy ; \
echo "http://alpine.gliderlabs.com/alpine/edge/testing" >> /etc/apk/repositories && \
apk add --no-cache $pkg_common
COPY [ "application/", "/opt/rootwyrm" ]
COPY [ "sv/", "/etc/sv" ]
RUN ln -s /etc/sv/firstboot /etc/service/ 

VOLUME [ "/config", "/downloads", "/shared", "/run" ]
