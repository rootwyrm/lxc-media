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


#ENV yumcmd="/usr/bin/yum -q -y"
ENV yumcmd="/usr/bin/yum -q -y" \
	yum_common="deltarpm epel-release yum-plugin-post-transaction-actions yum-cron"
## PHASE ONE
## Common components
## XXX: 2016-01-26: Work around an issue with nss-tools update
## XXX: 2016-01-26: Preload the key to reduce noise.
RUN echo "Bootstrapping CentOS GPG Keys..." ; \
	/usr/bin/rpm --import http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-7 ; \ 
	/usr/bin/rpm --import https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7 
	#echo "[WORKAROUND] 2016-01-26: issue with nss vs deltarpm" ; \ 
	#$yumcmd update nss nss-tools nss-sysinit openssl-libs

RUN $yumcmd update && \
	$yumcmd install $yum_common

## XXX: systemd hackery...
RUN $yumcmd swap -- remove systemd-container systemd-container-libs -- install systemd systemd-libs dbus
RUN systemctl mask dev-mqueue.mount dev-hugepages.mount \
    systemd-remount-fs.service sys-kernel-config.mount \
    sys-kernel-debug.mount sys-fs-fuse-connections.mount \
    display-manager.service graphical.target systemd-logind.service 
RUN systemctl enable dbus.service 
ADD dbus.service /etc/systemd/system/dbus.service
VOLUME [ "/sys/fs/cgroup", "/run", "/tmp" ]

## PHASE 2
## Application and supporting components
ENV yum_application="supervisor logrotate transmission-daemon"
RUN $yumcmd install $yum_application && \
	systemctl enable supervisord.service 
ADD supervisord.conf /etc/supervisord.d/transmission.ini

## PHASE 3
## Application setup
ENV lxcuname="lxcmedia" lxcuid="1024" lxcgroup="users" lxcgid="100"
RUN /usr/sbin/useradd $lxcuname -d /home/$lxcuname -c "LXC MediaHub" -u $lxcuid -g $lxcgroup 
RUN mkdir -p /downloads; chown -R $lxcuid:$lxcgroup /downloads ; \
	mkdir -p /config ; chown -R $lxcuid:$lxcgroup /config ;
ADD config/settings.json /config/settings.json
## Volumes
VOLUME	[ "/config", "/downloads" ]

## PHASE 4
## Cleanup
RUN $yumcmd clean all 
## Nuke extraneous users...
RUN userdel adm ; userdel lp ; userdel mail ; userdel games ; userdel ftp;\
	groupdel games
## supervisord fixup
RUN sed -i -e '/\[unix_http/,/^$/d' /etc/supervisord.conf && \
	sed -i -e '/^$/ d' /etc/supervisord.conf && \
	sed -i -e 's/^.prompt.*/prompt=(media)supervisor/' /etc/supervisord.conf && \
	sed -i -e 's/^logfile_maxbytes.*/logfile_maxbytes=1MB/' /etc/supervisord.conf && \
	sed -i -e 's/^logfile_backups.*/logfile_backups=7/' /etc/supervisord.conf && \
	sed -i -e 's/^loglevel.*/loglevel=warn/' /etc/supervisord.conf && \
	sed -i -e '/^;/ d' /etc/supervisord.conf

## Port Configuration
EXPOSE	9091 51413

ENV container docker
CMD [ "/usr/sbin/init", "--system", "--log-target=console", "--log-level=notice" ]
