#!/usr/bin/env bash

# Find folder from which this script is run courtesy of https://stackoverflow.com/a/246128
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CONFIGS="${SCRIPT_DIR}/../config"

. "${CONFIGS}/algo.config"
echo "${ALGO}"

[ ! -f "${CONFIGS}/${ALGO}.config" ] && echo "Fatal error: algo config doesn't exist" && sleep 3600 && exit 1

. "${CONFIGS}/${ALGO}.config"

# Attempt to find a serviceable XAUTHORITY
find_x_config() {
	export XAUTHORITY="$(ps -ax | grep Xorg | head -n 1 | sed 's|.*-auth *\(.*/Xauthority\).*|\1|')"
	export DISPLAY="$(ps -axo pid= | xargs -I PID -r cat /proc/PID/environ 2> /dev/null | tr '\0' '\n' | grep ^DISPLAY=: | sort -u | sed 's|^DISPLAY=\(.*\)|\1|' | head -n1)"
}

# Check for Nvidia cards
if [ ${#OVERCLOCK_NVIDIA[@]} -gt 0 ]; then
	# TODO: Don't overwrite existing configs and check whether number of extra X screens match number of nvidia GPUs
#	nvidia-xconfig -a --cool-bits=28 --allow-empty-initial-configuration

	# Start an Xorg server if there isn't one already
	find_x_config
	if [ -z "${XAUTHORITY}" ] || [ -z "${DISPLAY}" ]; then
		echo "Couldn't find existing Xorg server. Starting a new one."
		STARTEDX=1
		Xorg :9&
		export DISPLAY=:9
	fi

	if [ -z "${XAUTHORITY}" ] || [ -z "${DISPLAY}" ]; then
		echo "Fatal error: Couldn't find or start an X server for Nvidia overclock."
		echo "Ensure Xorg is installed and/or a display manager is running"
		return 1
	fi

	echo "Overclocking NVIDIA GPUs"
	for gpu in "${OVERCLOCK_NVIDIA[@]}"; do
		echo "${gpu}"
		echo "${gpu}" | xargs "${SCRIPT_DIR}"/overclock_nvidia.sh
	done

	if [ ! -z "${STARTEDX}" ] && [ ${STARTEDX} -gt 0 ]; then
		echo "Should stop X here"
	fi
fi

echo "Overclocking AMD GPUs"
for gpu in "${OVERCLOCK_AMD[@]}"; do
	echo "${gpu}"
	echo "${gpu}" | xargs "${SCRIPT_DIR}"/overclock_amd.sh
done

echo "Querying GPUs"
"${SCRIPT_DIR}"/get_gpu_status.sh
