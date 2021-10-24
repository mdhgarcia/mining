#!/usr/bin/env bash

usage() {
	echo "Usage: overclock_amd.sh
		-i  <gpu_index>        # Index of GPU (check output of nvidia-smi --list-gpus)
		[-c  <core_clock>]     # Optional - Core clock speed in MHz (absolute)
		[-v  <core_voltage>]   # Optional - Core voltage in mV (absolute)
		[-m  <memory_clock>]  # Optional - Memory clock in MHz (absolute)
		[-t  <memory_voltage>]  # Optional - Memory voltage in mV (absolute)
		[-p  <power_limit>]    # Optional - Power limit in Watts
		[-f  <fan_speed>]      # Optional - Fan speed (use 0 for default auto control)
	" 1>&2 && exit 1
}


# Process options
while getopts ":i:c:v:m:t:p:f:" opt; do
	case "${opt}" in
		i)	GPU_ID="${OPTARG}"
			;;
		c)	CORE_CLOCK="${OPTARG}"
			;;
		v)	CORE_VOLTAGE="${OPTARG}"
			;;
		m)	MEMORY_CLOCK="${OPTARG}"
			;;
		t)	MEMORY_VOLTAGE="${OPTARG}"
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
	&& [ -z "${MEMORY_CLOCK}" ] \
	&& [ -z "${POWER_LIMIT}" ] \
	&& [ -z "${FAN_SPEED}" ] \
	&& echo "Nothing to do" && usage

# Function definitions

set_core_clock() {
	# Set absolute clock speed
	echo "s 7 ${2} ${3}" > "/sys/class/drm/card${1}/device/pp_od_clk_voltage"
}

set_memory_offset() {
	echo "m 2 ${2} ${3}" > "/sys/class/drm/card${1}/device/pp_od_clk_voltage"
}

set_power_limit() {
	# In Watts
	echo "Nothing here"
}

set_fan() {
	# If fan speed is set to 0, set control to auto
	if [ ${2} -eq 0 ]; then
		echo "2" > "/sys/class/drm/card${1}/device/hwmon/hwmon1/pwm1_enable"
	else
		# Enable manual fan control and set speed in %
		echo "1" > "/sys/class/drm/card${1}/device/hwmon/hwmon1/pwm1_enable"
		echo "${2}" > "/sys/class/drm/card${1}/device/hwmon/hwmon1/pwm1"
	fi
}

apply_oc() {
	echo "c" > "/sys/class/drm/card${1}/device/pp_od_clk_voltage"
}

# Attempt to find a serviceable XAUTHORITY
find_x_config() {
	export XAUTHORITY="$(ps -ax | grep Xorg | head -n 1 | sed 's|.*-auth *\(.*/Xauthority\).*|\1|')"
	export DISPLAY="$(ps -axo pid= | xargs -I PID -r cat /proc/PID/environ 2> /dev/null | tr '\0' '\n' | grep ^DISPLAY=: | sort -u | sed 's|^DISPLAY=\(.*\)|\1|' | head -n1)"
}

# Start an Xorg server if there isn't one already
#find_x_config
#if [ -z "${XAUTHORITY}" ] || [ -z "${DISPLAY}" ]; then
#	echo "Couldn't find existing Xorg server. Starting a new one."
#	Xorg :0&
#	export DISPLAY=:0
#fi

#if [ -z "${XAUTHORITY}" ] || [ -z "${DISPLAY}" ]; then
#	echo "Fatal error: Couldn't find or start an X server."
#	echo "Ensure Xorg is installed and/or a display manager is running"
#	usage
#fi

echo "Setting GPU ${GPU_ID} clock=${CORE_CLOCK} cv=${CORE_VOLTAGE} mem=${MEMORY_CLOCK} mv=${MEMORY_VOLTAGE} pwr=${POWER_LIMIT} fan=${FAN_SPEED}"

# Configure GPU
[ ! -z "${CORE_CLOCK}" ]    && set_core_clock    "${GPU_ID}" "${CORE_CLOCK}" "${CORE_VOLTAGE}"
[ ! -z "${MEMORY_CLOCK}" ]  && set_memory_offset "${GPU_ID}" "${MEMORY_CLOCK}" "${MEMORY_VOLTAGE}"
[ ! -z "${POWER_LIMIT}" ]   && set_power_limit   "${GPU_ID}" "${POWER_LIMIT}"
[ ! -z "${FAN_SPEED}" ]     && set_fan           "${GPU_ID}" "${FAN_SPEED}"

apply_oc "${GPU_ID}"

