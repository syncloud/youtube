#!/bin/bash -xe
DIR=$( cd "$( dirname "$0" )" && pwd )
LIBS=$(echo ${DIR}/lib/*-linux-gnu*)
${DIR}/lib/*-linux*/ld-*.so* --library-path ${LIBS} ${DIR}/authelia "$@"
