#!/usr/bin/env bash

VERSION="0.24.2"
MINER="t-rex-${VERSION}-linux"
MINEREXE="t-rex"
POOL="ssl://eth-us-west.flexpool.io:5555"
POOL2="ssl://eth-us-east.flexpool.io:5555"
WALLET="0x7DDFe0f47e09160099f28Da3C21362daB0Bc887E.ubuntu1"
ALGO="ethash"

# Doesn't work right now with 8GB VRAM (try replacing gdm?)
LHRARGS="--lhr-algo kawpow --url2 stratum+ssl://stratum-ravencoin.flypool.org:3443 --user2 RK2KCUseKt2Hir23fy7QjshmHKY3Z6EKwL.ubuntu1"

ARGS="--coin Ethash"

cd "/home/mgarcia/crypto/${MINER}/"

./"${MINEREXE}" -a "${ALGO}" -o "${POOL}" -u "${WALLET}" ${ARGS} $@
