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
	echo "Setting absolute clock speed to ${2} for GPU ${1}"
	nvidia-smi -i "${1}" -lgc "${2}"
}

set_memory_offset() {
	echo "Setting memory offset ${2} for GPU ${1}"
	nvidia-settings \
		-a "[gpu:${1}]/GPUMemoryTransferRateOffset[2]=${2}" \
		-a "[gpu:${1}]/GPUMemoryTransferRateOffset[3]=${2}" \
		-a "[gpu:${1}]/GPUMemoryTransferRateOffset[4]=${2}"
}

set_power_limit() {
	echo "Setting power limit to ${2} Watts for GPU ${1}"
	nvidia-smi -i "${1}" -pl "${2}"
}

set_fan() {
	echo "Setting fan to ${2} percent for GPU ${1}"
	# If fan speed is set to 0, set control to auto
	if [ ${2} -eq 0 ]; then
		nvidia-settings -a "[gpu:${1}]/GPUFanControlState=0"
	else
		# Enable manual fan control and set speed in %
		# Assume each GPU has 2 fans for now
		# TODO: Check nvidia-settings for number of fans
		FANS_PER_GPU=2
		FAN_1=$(( ${FANS_PER_GPU}*${1} ))
		FAN_2=$(( ${FAN_1} + 1 ))
		echo "Setting fans ${FAN_1} and ${FAN_2}"
		nvidia-settings \
			-a "[gpu:${1}]/GPUFanControlState=1" \
			-a "[fan:${FAN_1}]/GPUTargetFanSpeed=${2}" \
			-a "[fan:${FAN_2}]/GPUTargetFanSpeed=${2}"
	fi
}

if [ -z "${XAUTHORITY}" ] || [ -z "${DISPLAY}" ]; then
	echo "Fatal error: Couldn't find or start an X server."
	echo "Ensure Xorg is installed and/or a display manager is running"
	usage
fi

echo "Setting GPU ${GPU_ID} clock=${CORE_CLOCK} mem=${MEMORY_OFFSET} pwr=${POWER_LIMIT} fan=${FAN_SPEED}"

# Enable persistence mode
nvidia-smi -i "${GPU_ID}" -pm 1

# Configure GPU
[ ! -z "${CORE_CLOCK}" ]    && set_core_clock    "${GPU_ID}" "${CORE_CLOCK}"
[ ! -z "${MEMORY_OFFSET}" ] && set_memory_offset "${GPU_ID}" "${MEMORY_OFFSET}"
[ ! -z "${POWER_LIMIT}" ]   && set_power_limit   "${GPU_ID}" "${POWER_LIMIT}"
[ ! -z "${FAN_SPEED}" ]     && set_fan           "${GPU_ID}" "${FAN_SPEED}"

# Find folder from which this script is run courtesy of https://stackoverflow.com/a/246128
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Query GPUs
"${SCRIPT_DIR}"/get_gpu_status.sh
