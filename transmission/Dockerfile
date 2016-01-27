FROM  centos:7
## The magic begins...
MAINTAINER    Phillip "RootWyrm" Jaenke <docker@rootwyrm.com>

## We always use labels.
## NOTE: Uses TSLE NVD with Substring ISO8601
LABEL	com.rootwyrm.vendor="RootWyrm" \
		com.rootwyrm.project="lxc-media" \
		com.rootwyrm.status="release" \
		com.rootwyrm.nvd.release="0" \
		com.rootwyrm.nvd.version="0" \
		com.rootwyrm.nvd.update="0" \
		com.rootwyrm.nvd.update_sub="2016-01-26" \
		com.rootwyrm.vcs-type="git" \
		com.rootwyrm.changelog-url="https://www.github.com/rootwyrm/lxc-media/transmission/CHANGELOG"

LABEL	com.rootwyrm.rootcore.base="centos" \
		com.rootwyrm.rootcore.base.tag="7" \
		com.rootwyrm.rootcore.depends="" \
		com.rootwyrm.rootcore.provides="transmission" \
		com.rootwyrm.rootcore.svctype="torrent" \
		com.rootwyrm.rootcore.ports="9091 51413" \
		com.rootwyrm.rootcore.qnap_compatible="true" \
		com.rootwyrm.rootcore.synology_compatible="true"


#ENV yuminst="/usr/bin/yum -q -y"
ENV yuminst="/usr/bin/yum -y" \
	yum_common="deltarpm epel-release yum-plugin-post-transaction-actions yum-cron"
## PHASE ONE
## Common components
## XXX: 2016-01-26: Work around an issue with nss-tools update
## XXX: 2016-01-26: Preload the key to reduce noise.
RUN echo "Bootstrapping CentOS GPG Keys..." ; \
	/usr/bin/rpm --import http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-7 ; \ 
	/usr/bin/rpm --import https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7 
	#echo "[WORKAROUND] 2016-01-26: issue with nss vs deltarpm" ; \ 
	#$yuminst update nss nss-tools nss-sysinit openssl-libs

RUN $yuminst update && \
	$yuminst install $yum_common

## XXX: systemd hackery...
#RUN yum -y install systemd; yum clean all; \
#(cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
#rm -f /lib/systemd/system/multi-user.target.wants/*;\
#rm -f /etc/systemd/system/*.wants/*;\
#rm -f /lib/systemd/system/local-fs.target.wants/*; \
#rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
#rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
#rm -f /lib/systemd/system/basic.target.wants/*;\
#rm -f /lib/systemd/system/anaconda.target.wants/*;
RUN yum -y swap -- remove systemd-container systemd-container-libs -- install systemd systemd-libs dbus
RUN systemctl mask dev-mqueue.mount dev-hugepages.mount \
    systemd-remount-fs.service sys-kernel-config.mount \
    sys-kernel-debug.mount sys-fs-fuse-connections.mount \
    display-manager.service graphical.target systemd-logind.service 
ADD dbus.service /etc/systemd/system/dbus.service
RUN systemctl enable dbus.service
VOLUME [ "/sys/fs/cgroup" ]
VOLUME [ "/run" ]

## PHASE 2
## Application and supporting components
ENV yum_application="supervisor logrotate transmission-daemon"
RUN $yuminst install $yum_application && \
	systemctl enable supervisord.service 
	#mkdir /config ; mkdir /downloads
	#rm /etc/supervisord.conf
ADD supervisord.conf /etc/supervisord.d/transmission.ini

## PHASE 3
## Application setup
ENV lxcuname="lxcmedia" lxcuid="1024" lxcgroup="users" lxcgid="100"
RUN /usr/sbin/useradd $lxcuname -d /home/$lxcuname -c "LXC MediaHub" -u $lxcuid -g $lxcgroup 
ADD config/settings.json /config/settings.json
RUN mkdir -p /downloads; chown -R $lxcuid:$lxcgroup /downloads ; \
	mkdir -p /config ; chown -R $lxcuid:$lxcgroup /config ;
VOLUME	/config
VOLUME	/downloads

#RUN locale-gen en_US.utf8

## Port Configuration
EXPOSE	9091 51413

#CMD [ "/usr/lib/systemd/systemd" ]
CMD [ "/usr/sbin/init" ]
