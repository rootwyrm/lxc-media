#nzbget 

nzbget uses 6789/tcp for web interface. Default login.

#Automatic Update
Use the webui to automatically update nzbget

# Quick Creation (NOT FOR PRODUCTION)
docker create -p 6789:6789 -v /media/config/nzbget:/config -v /media/incoming:/downloads -v /nfs/shared:/shared --name=nzbget nzbget rootwyrm/lxc-media:nzbget
	
