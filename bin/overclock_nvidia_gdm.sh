#!/usr/bin/env bash

# Default input parameters
GPU_ID=0
CORE_CLOCK=1450
MEMORY_OFFSET=2000
POWER_LIMIT=130
FAN_SPEED=60

# Grab current GDM user ID and set up XAUTHORITY
GDMUSER=`id -u gdm`
export XAUTHORITY="/run/user/${GDMUSER}/gdm/Xauthority"
export DISPLAY=:0


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

config_gpu() {
	# Enable persistence mode
	nvidia-smi -i "${1}" -pm 1
	
	set_core_clock "${1}" "${2}"
	set_memory_offset "${1}" "${3}"
	set_power_limit "${1}" "${4}"
	set_fan "${1}" "${5}"
}

# Display all GPUs
# TODO: Use output to sanity-check arguments
nvidia-smi --list-gpus

# Configure GPU
config_gpu "${GPU_ID}" "${CORE_CLOCK}" "${MEMORY_OFFSET}" "${POWER_LIMIT}" "${FAN_SPEED}"

# Query GPUs
#nvidia-smi --query-gpu=timestamp,gpu_bus_id,utilization.gpu,utilization.memory,temperature.gpu,fan.speed,power.draw --format=csv
nvidia-smi -i "${GPU_ID}" -q
