#!/bin/bash -e
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
exec ${DIR}/webui \
  -driver ${DIR}/ytd-lp/ytd-lp \
  -out /data/youtube \
  -host /var/snap/youtube/current/webui.socket \
  -session /var/snap/youtube/current \
  -db /var/snap/youtube/current/local.db

