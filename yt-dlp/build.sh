#!/bin/sh -e

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}
BUILD_DIR=${DIR}/../build/snap/webui
mkdir -p $BUILD_DIR/bin

cp /app/yt-dlp-webui ${BUILD_DIR}/bin
cp -r /opt ${BUILD_DIR}
cp -r /usr ${BUILD_DIR}
cp -r /bin ${BUILD_DIR}
cp -r /lib ${BUILD_DIR}
cp -r ${DIR}/bin/* ${BUILD_DIR}/bin