#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

/bin/rm -f /var/snap/youtube/common/web.socket
exec ${DIR}/nginx/bin/nginx.sh -c /var/snap/youtube/current/config/nginx.conf -p ${DIR}/nginx -e stderr
