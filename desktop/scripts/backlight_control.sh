#!/bin/bash
# Handle manual brightness changes and disable auto-brightness if needed

CMD="$1"
ARG="$2"

# If we are changing brightness, stop auto-mode
if [ "$CMD" != "status" ]; then
    {{USER_HOME}}/oblivion/OSFunctionScripts/auto_brightness.py stop > /dev/null 2>&1
fi

case "$CMD" in
    "set")
        brightnessctl set "$ARG"
        ;;
    "up")
        brightnessctl set 1%+
        ;;
    "down")
        brightnessctl set 1%-
        ;;
esac

# Signal waybar to update
pkill -RTMIN+4 waybar
