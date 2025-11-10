#!/bin/bash -e
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
/bin/rm -rf $SNAP_DATA/webui.socket
export PATH=$PATH:${DIR}/webui/bin
exec ${DIR}/webui/bin/yt-dlp-webui \
  -conf $SNAP_DATA/config/webui.yaml \
  -db $SNAP_DATA/local.db
