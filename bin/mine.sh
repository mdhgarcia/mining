#!/usr/bin/env bash

# Find folder from which this script is run courtesy of https://stackoverflow.com/a/246128
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CONFIGS="${SCRIPT_DIR}/../config"

. "${CONFIGS}/algo.config"
echo "${ALGO}"

[ ! -f "${CONFIGS}/${ALGO}.config" ] && echo "Fatal error: algo config doesn't exist" && sleep 3600 && exit 1

. "${CONFIGS}/${ALGO}.config"

echo "Overclocking each GPU in OVERCLOCK lists:"
for gpu in "${OVERCLOCK_NVIDIA[@]}"; do
	echo "${gpu}"
	echo "${gpu}" | xargs "${SCRIPT_DIR}"/overclock_nvidia.sh
done

for gpu in "${OVERCLOCK_AMD[@]}"; do
	echo "${gpu}"
	echo "${gpu}" | xargs "${SCRIPT_DIR}"/overclock_amd.sh
done

export ALGO
export MINER
export POOL
export PORT
export WALLET
export EXTRA_ARGS
"${SCRIPT_DIR}"/start_miner.sh

