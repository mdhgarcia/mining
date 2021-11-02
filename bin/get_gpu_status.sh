#!/usr/bin/env bash

# TODO: Something useful with this info
get_settings() {
	SETTINGS=$(nvidia-settings -q GPUPerfModes -q GPUMemoryTransferRateOffset -q GPUGraphicsClockOffset -q GPUPowerMizerMode -q GPULogoBrightness -q GPUTargetFanSpeed | grep -vE "values|target")
	echo "Settings: ${SETTINGS}"
}

get_settings

# Query GPUs via nvidia-smi
ID_ARGS="index,gpu_bus_id,name"
STAT_ARGS="clocks.gr,clocks.mem,power.draw,fan.speed,temperature.gpu"
UTILIZATION="utilization.gpu,utilization.memory"
EXTRA_ARGS="clocks_throttle_reasons.active"

nvidia-smi --query-gpu="timestamp,${ID_ARGS},${STAT_ARGS},${UTILIZATION}" --format=csv

