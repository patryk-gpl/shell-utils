#!/usr/bin/env bash

function parse_mem() {
  name=$1
  vm_stat | awk "/$name:/"'{print $NF}' | tr -d '.'
}

FREE_BLOCKS=$(parse_mem free)
ACTIVE_BLOCKS=$(parse_mem "Pages active")
INACTIVE_BLOCKS=$(parse_mem inactive)
SPECULATIVE_BLOCKS=$(parse_mem speculative)

FREE=$(((FREE_BLOCKS + SPECULATIVE_BLOCKS) * 4096 / 1048576))
INACTIVE=$((INACTIVE_BLOCKS * 4096 / 1048576))
ACTIVE=$((ACTIVE_BLOCKS * 4096 / 1048576))
TOTAL=$((FREE + INACTIVE))

echo Free: $FREE MB
echo Active: $ACTIVE MB
echo Inactive: $INACTIVE MB
echo Total free: $TOTAL MB
