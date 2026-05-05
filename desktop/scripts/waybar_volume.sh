#!/bin/bash
# Unified Volume Script for Waybar
# Optimized for FujiRuro-OS

HW_SINK=$(pactl list sinks short | grep -E "alsa_output.pci|bluez_output|usb" | awk '{print $2}' | head -n 1)
VOL=$(pactl get-sink-volume "$HW_SINK" 2>/dev/null | grep -Po "[0-9]+(?=%)" | head -n 1 || echo 0)
MUTE=$(pactl get-sink-mute "$HW_SINK" 2>/dev/null | grep "yes")

ICON=""
[ -n "$MUTE" ] && ICON="" && VOL="Muted"

echo "{\"text\": \"$ICON [$VOL%]\", \"percentage\": ${VOL:-0}}"
