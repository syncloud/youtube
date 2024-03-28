#!/bin/bash -e
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
export PATH=$PATH:${DIR}/webui/bin
exec ${DIR}/webui/bin/python ${DIR}/webui/usr/bin/yt-dlp \
  -conf /var/snap/youtube/current/config/webui.yaml  \
  -db /var/snap/youtube/current/local.db

