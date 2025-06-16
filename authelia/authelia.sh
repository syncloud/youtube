#!/bin/bash -e
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
LIBS=$(echo ${DIR}/lib/*-linux-gnu*)
${DIR}/lib/*-linux*/ld-*.so* --library-path ${LIB} ${DIR}/app/authelia "$@"
