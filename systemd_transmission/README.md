# WARNING: THIS IS A PROOF OF CONCEPT AREA. IT IS NOT SAFE FOR NORMAL USE.

docker create -p 9091:9091 -p 51413:51413 -v /sys/fs/cgroup:/sys/fs/cgroup:ro --name=testtrans  mcc-transmission
