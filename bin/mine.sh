#!/usr/bin/env bash

# Find folder from which this script is run courtesy of https://stackoverflow.com/a/246128
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CONFIGS="${SCRIPT_DIR}/../config"

. "${CONFIGS}/algo.config"
echo "${ALGO}"

[ ! -f "${CONFIGS}/${ALGO}.config" ] && echo "Fatal error: algo config doesn't exist" && sleep 3600 && exit 1

. "${CONFIGS}/${ALGO}.config"

export OVERCLOCK_NVIDIA
export OVERCLOCK_AMD
"${SCRIPT_DIR}/oc.sh"

# Give the cards some time...
sleep 3

export ALGO
export MINER
export POOL
export PORT
export WALLET
export EXTRA_ARGS
"${SCRIPT_DIR}"/start_miner.sh

