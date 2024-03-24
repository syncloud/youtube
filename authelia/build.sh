#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}
VERSION=$1
BUILD_DIR=${DIR}/../build/snap/authelia
apk --no-cache add gcc musl-dev wget

wget https://codeload.github.com/authelia/authelia/tar.gz/refs/heads/v4.38.0-beta3 -O authelia.tar.gz
tar xf authelia.tar.gz
cd authelia-4.38.0-beta3
sed -i 's#config.Server.Address.SetPath("/")#config.Server.Address.SetPath("/authelia")#g' internal/configuration/validator/server.go
CGO_ENABLED=1 CGO_CPPFLAGS="-D_FORTIFY_SOURCE=2 -fstack-protector-strong" CGO_LDFLAGS="-Wl,-z,relro,-z,now" go build \
	-ldflags "-linkmode=external -s -w ${LDFLAGS_EXTRA}" -trimpath -buildmode=pie -o authelia ./cmd/authelia
cp authelia ${BUILD_DIR}/app/authelia
