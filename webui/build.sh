#!/bin/bash -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

VERSION=$1
ARCH=$2

wget --progress dot:giga https://github.com/marcopeocchi/yt-dlp-web-ui/releases/download/v$VERSION/yt-dlp-webui_linux-$ARCH -O ${DIR}/../build/snap/webui