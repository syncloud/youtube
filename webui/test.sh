#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
${DIR}/../build/snap/webui/bin/yt-dlp-webui --help
${DIR}/../build/snap/webui/bin/ffmpeg --help
${DIR}/../build/snap/webui/bin/ffprobe --help
${DIR}/../build/snap/webui/bin/python --version
${DIR}/../build/snap/webui/bin/yt-dlp --help
