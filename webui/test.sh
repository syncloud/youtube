#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
${DIR}/../build/snap/webui/bin/yt-dlp-webui --help
${DIR}/../build/snap/webui/bin/ffmpeg --help
${DIR}/../build/snap/webui/bin/ffprob --help
${DIR}/../build/snap/webui/usr/bin/yt-dlp --help
