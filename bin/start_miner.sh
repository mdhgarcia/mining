#!/usr/bin/env bash

usage() {
	echo "Usage: start-miner.sh
		-m  <miner>            # Miner to use e.g. gminer, t-rex, nbminer
		-a  <algorithm>        # Algo parameter e.g. ethash
		-s  <pool_server>      # Pool URL e.g. ssl://eth-us-west.flexpool.io
		-p  <server_port>      # Pool server port e.g. 5555
		-u  <user_wallet>      # Username/wallet e.g. <MY_WALLET_ADDRESS>.workerName
		-x  <extra_args>       # Any extra args to pass the miner e.g. \"--coin Ethash\"" 1>&2 && exit 1
}

while getopts ":m:a:s:p:u:x:" opt; do
	case "${opt}" in
		m)	MINER="${OPTARG}"
			;;
		a)	ALGO="${OPTARG}"
			;;
		s)	POOL="${OPTARG}"
			;;
		p)	PORT="${OPTARG}"
			;;
		u)	WALLET="${OPTARG}"
			;;
		x)	EXTRA_ARGS="${OPTARG}"
			;;
		*)	usage
			;;
	esac
done

[ "${1:-}" = "--" ] && shift

[ -z "${MINER}" ]   && echo "Must provide miner" && usage
[ -z "${ALGO}" ]    && echo "Must provide algorithm" && usage
[ -z "${POOL}" ]    && echo "Must provide pool server URL" && usage
[ -z "${PORT}" ]    && echo "Must provide pool server PORT" && usage
[ -z "${WALLET}" ]  && echo "Must provide user/wallet" && usage

echo "Miner=${MINER} Algo=${ALGO} Pool=${POOL} Port=${PORT} User=${WALLET}"

# Find folder from which this script is run courtesy of https://stackoverflow.com/a/246128
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="${SCRIPT_DIR}/.."
MINERS="${ROOT_DIR}/miners"

# Find the miner and set up args
MINER_DIR="$(find ${MINERS} -maxdepth 1 -name ${MINER}* | head -n 1)"
[ ! -d "${MINER_DIR}" ] && echo "Couldn't find miner directory" && usage

if [ "${MINER}"x = "t-rex"x ]; then
	MINER_EXE="${MINER_DIR}/t-rex"
	ARGS="-a ${ALGO} -o ${POOL}:${PORT} -u ${WALLET}"
fi

"${MINER_EXE}" ${ARGS} ${EXTRA_ARGS}
