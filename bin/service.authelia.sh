#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
rm -rf /var/snap/youtube/current/authelia.socket
exec ${DIR}/authelia/authelia.sh --config /var/snap/youtube/current/config/authelia/config.yml
