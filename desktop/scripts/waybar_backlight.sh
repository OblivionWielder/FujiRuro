#!/bin/bash

# Get current brightness percentage
CUR=$(brightnessctl g)
MAX=$(brightnessctl m)
PCT=$(( 100 * CUR / MAX ))

PID_FILE="/tmp/auto_brightness.pid"

if [ -f "$PID_FILE" ]; then
    # Check if process actually exists
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null; then
        MODE="Auto"
    else
        rm "$PID_FILE"
        MODE="Manual"
    fi
else
    MODE="Manual"
fi

echo "{\"text\": \" ${MODE}[${PCT}%]\", \"class\": \"${MODE,,}\", \"percentage\": ${PCT}}"
