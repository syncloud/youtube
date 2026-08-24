#!/bin/sh -e

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

if [ -z "$2" ]; then
    echo "usage $0 yt-dlp-version yt-dlp-ejs-version"
    exit 1
fi

YTDLP_VERSION=$1
YTDLP_EJS_VERSION=$2

BUILD_DIR=${DIR}/../build/snap/webui
mkdir -p $BUILD_DIR/bin

apk add --no-cache nodejs
pip install --no-cache-dir --upgrade --break-system-packages \
    yt-dlp==${YTDLP_VERSION} \
    yt-dlp-ejs==${YTDLP_EJS_VERSION}

cp /app/yt-dlp-webui ${BUILD_DIR}/bin
cp -r /opt ${BUILD_DIR}
cp -r /usr ${BUILD_DIR}
cp -r /bin ${BUILD_DIR}
cp -r /lib ${BUILD_DIR}
cp -r ${DIR}/bin/* ${BUILD_DIR}/bin
