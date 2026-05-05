#!/bin/bash
# FujiRuro-OS Swaynag Wrapper
# Launches an interactive menu using swaynag.

TITLE=$1
BUTTONS=$2

# Close existing swaynag instance
pkill swaynag || true

# Launch new one
swaymsg exec "swaynag -t warning -m '$TITLE' $BUTTONS"
