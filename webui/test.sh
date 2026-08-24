#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if [ -z "$1" ]; then
    echo "usage $0 yt-dlp-version"
    exit 1
fi

YTDLP_VERSION=$1
BIN=${DIR}/../build/snap/webui/bin

${BIN}/yt-dlp-webui --help
${BIN}/ffmpeg --help
${BIN}/ffprobe --help
${BIN}/python --version
${BIN}/node --version
${BIN}/yt-dlp --help

ACTUAL=$(${BIN}/yt-dlp --version)
if [ "$ACTUAL" != "$YTDLP_VERSION" ]; then
    echo "expected yt-dlp $YTDLP_VERSION, got $ACTUAL"
    exit 1
fi

${BIN}/python -c 'import yt_dlp_ejs'
