#!/bin/bash
# Unified CPU Speed Script for Waybar
# Optimized for FujiRuro-OS

FREQ=$(grep "cpu MHz" /proc/cpuinfo | awk '{sum+=$4} END {printf "%.0f", sum/NR}')
[ "$FREQ" -ge 1000 ] && RAW="$(awk "BEGIN {printf \"%.1f\", $FREQ/1000}")GHz" || RAW="${FREQ}MHz"

USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
USAGE_INT=$(printf "%.0f" "$USAGE")

echo "{\"text\": \" $RAW [$USAGE_INT%]\", \"percentage\": $USAGE_INT}"
