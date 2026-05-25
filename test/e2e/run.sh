#!/bin/bash -e
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd "${DIR}"

DISTRO=${1:-bookworm}
NAME=${NAME:-youtube}

export PLAYWRIGHT_FULL_DOMAIN="${DISTRO}.com"
export PLAYWRIGHT_APP_DOMAIN="${NAME}.${DISTRO}.com"
export PLAYWRIGHT_DEVICE_HOST="${NAME}.${DISTRO}.com"
export PLAYWRIGHT_DEVICE_USER="user"
export PLAYWRIGHT_DEVICE_PASSWORD="Password1"
export PLAYWRIGHT_ARTIFACT_DIR="${PLAYWRIGHT_ARTIFACT_DIR:-/drone/src/artifact/e2e-${DISTRO}}"

apt-get update && apt-get install -y sshpass
npm ci
npx playwright test --project=desktop
