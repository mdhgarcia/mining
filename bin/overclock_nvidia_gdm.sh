#!/usr/bin/env bash

usage() {
	echo "Usage: overclock_nvidia.sh
		-i  <gpu_index>        # Index of GPU (check output of nvidia-smi --list-gpus)
		[-c  <core_clock>]     # Optional - Core clock speed in MHz (absolute)
		[-m  <memory_offset>]  # Optional - Memory clock offset in MHz (double values from afterburner)
		[-p  <power_limit>]    # Optional - Power limit in Watts
		[-f  <fan_speed>]      # Optional - Fan speed (use 0 for default auto control)
	" 1>&2 && exit 1
}


# Process options
while getopts ":i:c:m:p:f:" opt; do
	case "${opt}" in
		i)	GPU_ID="${OPTARG}"
			;;
		c)	CORE_CLOCK="${OPTARG}"
			;;
		m)	MEMORY_OFFSET="${OPTARG}"
			;;
		p)	POWER_LIMIT="${OPTARG}"
			;;
		f)	FAN_SPEED="${OPTARG}"
			;;
		*)	usage
			;;
	esac
done

[ "${1:-}" = "--" ] && shift

# TODO: Sanity-check GPU_ID
[ -z "${GPU_ID}" ] && echo "Must provide GPU index" && usage
[ -z "${CORE_CLOCK}" ] \
	&& [ -z "${MEMORY_OFFSET}" ] \
	&& [ -z "${POWER_LIMIT}" ] \
	&& [ -z "${FAN_SPEED}" ] \
	&& echo "Nothing to do" && usage

# Function definitions

set_core_clock() {
	# Set absolute clock speed
	nvidia-smi -i "${1}" -lgc "${2}"
}

set_memory_offset() {
	nvidia-settings \
		-a "[gpu:${1}]/GPUMemoryTransferRateOffset[2]=${2}" \
		-a "[gpu:${1}]/GPUMemoryTransferRateOffset[3]=${2}" \
		-a "[gpu:${1}]/GPUMemoryTransferRateOffset[4]=${2}"
}

set_power_limit() {
	# In Watts
	nvidia-smi -i "${1}" -pl "${2}"
}

set_fan() {
	# If fan speed is set to 0, set control to auto
	if [ ${2} -eq 0 ]; then
		nvidia-settings -a "[gpu:${1}]/GPUFanControlState=0"
	else
		# Enable manual fan control and set speed in %
		nvidia-settings \
			-a "[gpu:${1}]/GPUFanControlState=1" \
			-a "[fan:${1}]/GPUTargetFanSpeed=${2}"
	fi
}

# Attempt to find a serviceable XAUTHORITY
find_x_config() {
	export XAUTHORITY="$(ps -ax | grep Xorg | head -n 1 | sed 's|.*-auth *\(.*/Xauthority\).*|\1|')"
	export DISPLAY="$(ps -axo pid= | xargs -I PID -r cat /proc/PID/environ 2> /dev/null | tr '\0' '\n' | grep ^DISPLAY=: | sort -u | sed 's|^DISPLAY=\(.*\)|\1|' | head -n1)"
}

# Start an Xorg server if there isn't one already
find_x_config
if [ -z "${XAUTHORITY}" ] || [ -z "${DISPLAY}" ]; then
	Xorg&
	find_x_config
fi

if [ -z "${XAUTHORITY}" ] || [ -z "${DISPLAY}" ]; then
	echo "Fatal error: Couldn't find or start an X server."
	echo "Ensure Xorg is installed and/or a display manager is running"
	usage
fi

# Enable persistence mode
nvidia-smi -i "${GPU_ID}" -pm 1

# Configure GPU
[ ! -z "${CORE_CLOCK}" ]    && set_core_clock    "${GPU_ID}" "${CORE_CLOCK}"
[ ! -z "${MEMORY_OFFSET}" ] && set_memory_offset "${GPU_ID}" "${CORE_CLOCK}"
[ ! -z "${POWER_LIMIT}" ]   && set_power_limit   "${GPU_ID}" "${POWER_LIMIT}"
[ ! -z "${FAN_SPEED}" ]     && set_fan           "${GPU_ID}" "${FAN_SPEED}"

# Find folder from which this script is run courtesy of https://stackoverflow.com/a/246128
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Query GPUs
"${SCRIPT_DIR}"/get_gpu_status.sh
