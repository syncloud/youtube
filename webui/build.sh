#!/bin/sh -e

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

VERSION=$1
ARCH=$2

apk add wget

wget --progress dot:giga https://github.com/marcopeocchi/yt-dlp-web-ui/releases/download/v$VERSION/yt-dlp-webui_linux-$ARCH -O ${DIR}/../build/snap/webui
chmod +x ${DIR}/../build/snap/webui
