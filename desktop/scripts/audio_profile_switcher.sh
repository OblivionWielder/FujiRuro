#!/bin/bash
# Audio Profile & Output Switcher for FujiRuro-OS
# Hardened: Includes sink validation and automatic fallback.

SCRIPT_PATH="$HOME/scripts/audio_profile_switcher.sh"
VOL_BACKUP="/tmp/audio_vol_backup"
ALSA_SINK="alsa_output.pci-0000_00_0e.0.analog-stereo"

# 1. Dynamic Detection
DEFAULT_SINK=$(pactl info | grep "Default Sink" | cut -d" " -f3)
HW_SINK=$(pactl list sinks short | grep "bluez_output" | awk '{print $2}' | head -n 1)
[ -z "$HW_SINK" ] && HW_SINK=$(pactl list sinks short | grep "alsa_output.usb" | awk '{print $2}' | head -n 1)

# 2. Validation & Fallback
if [ -z "$HW_SINK" ] || ! pactl list sinks short | grep -q "$HW_SINK"; then
    [ -n "$HW_SINK" ] && notify-send "Audio" "Target sink missing, falling back to Internal"
    HW_SINK="$ALSA_SINK"
fi

case "$1" in
    "mute")
        IS_MUTED=$(pactl get-sink-mute "$HW_SINK" 2>/dev/null | grep "yes")
        if [ -n "$IS_MUTED" ]; then
            pactl set-sink-mute "$HW_SINK" no
            notify-send "Audio" "Unmuted" -i audio-volume-high
        else
            pactl set-sink-mute "$HW_SINK" yes
            notify-send "Audio" "Muted" -i audio-volume-muted
        fi
        ;;
    "menu")
        ~/scripts/toggle_swaynag.sh "Audio Control" \
            "-B 'Internal Spk' '$SCRIPT_PATH out-internal' \
             -B 'Mute Toggle' '$SCRIPT_PATH mute'"
        ;;
esac

pkill -RTMIN+1 waybar
