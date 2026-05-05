#!/bin/bash
# FujiRuro-OS Screenshot Tool (snip.sh)

# Dynamic Environment
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export SWAYSOCK="${SWAYSOCK:-$(ls /run/user/$(id -u)/sway-ipc.*.sock 2>/dev/null | head -n 1)}"

DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"
FILE="$DIR/$(date +%Y-%m-%d_%H-%M-%S).png"
TEMP_FILE="/tmp/snip_capture.png"

GEOM=$(slurp)
if [ -z "$GEOM" ]; then
    notify-send "Snip" "Canceled"
    exit 1
fi

if grim -g "$GEOM" "$TEMP_FILE"; then
    swaymsg exec "swappy -f $TEMP_FILE -o $FILE"
    notify-send "Snip" "Opening Editor..."
else
    notify-send "Snip" "Capture failed"
fi
