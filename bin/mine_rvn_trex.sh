#!/usr/bin/env bash

VERSION="0.24.2"
MINER="t-rex-${VERSION}-linux"
MINEREXE="t-rex"
POOL="ssl://stratum-ravencoin.flypool.org:3443"
WALLET="RK2KCUseKt2Hir23fy7QjshmHKY3Z6EKwL.ubuntu1"
ALGO="kawpow"

ARGS=""

cd "/home/mgarcia/crypto/${MINER}/"

./"${MINEREXE}" -a "${ALGO}" -o "${POOL}" -u "${WALLET}" ${ARGS} $@
