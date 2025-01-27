#!/bin/bash

POOL="${1}"
LOGFILE="/var/log/zpool-pushover-$POOL.log"
ZFS="$(whereis zfs | awk '{print $2}')"

if [ "$(zpool status $POOL -x)" != "pool '$POOL' is healthy" ]; then
  echo "$(date) - Alarm - zpool $POOL is not healthy" >> $LOGFILE
  curl -s -F "token=$PO_TOKEN" \
    -F "user=$PO_UK" \
    -F "title=zpool status unhealthy!" \
    -F "message=status of pool $POOL is unhealthy" https://api.pushover.net/1/messages.json
else
  echo "$(date) - zpool $POOL status is healthy" >> $LOGFILE
fi
