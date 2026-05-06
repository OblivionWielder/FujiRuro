#!/bin/bash

PID_FILE="/tmp/auto_brightness.pid"

if [ -f "$PID_FILE" ]; then
    python3 {{USER_HOME}}/oblivion/OSFunctionScripts/auto_brightness.py stop
    notify-send "Auto-Brightness" "Disabled" -i display-brightness
else
    python3 {{USER_HOME}}/oblivion/OSFunctionScripts/auto_brightness.py &
    notify-send "Auto-Brightness" "Enabled" -i display-brightness
fi

pkill -RTMIN+4 waybar
