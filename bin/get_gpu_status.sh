#!/usr/bin/env bash

# Query GPUs
ID_ARGS="index,gpu_bus_id,name"
STAT_ARGS="clocks.gr,clocks.mem,power.draw,fan.speed,temperature.gpu"
UTILIZATION="utilization.gpu,utilization.memory"
EXTRA_ARGS="clocks_throttle_reasons.active"

nvidia-smi --query-gpu="timestamp,${ID_ARGS},${STAT_ARGS},${UTILIZATION}" --format=csv

