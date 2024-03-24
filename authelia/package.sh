#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}
VERSION=$1
BUILD_DIR=${DIR}/../build/snap/authelia
while ! docker create --name=app authelia/authelia:$VERSION ; do
  sleep 1
  echo "retry docker"
done
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}
docker export app -o app.tar
tar xf app.tar
rm -rf app.tar
cp ${DIR}/authelia.sh ${BUILD_DIR}/bin/
