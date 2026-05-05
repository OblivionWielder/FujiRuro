#!/bin/bash
# Waybar Battery Script for FujiRuro-OS
# Optimized: Uses native sysfs calculation for remaining time.

# 1. Dynamic Path Detection
BAT_PATH=$(ls -d /sys/class/power_supply/BAT* /sys/class/power_supply/CMB* 2>/dev/null | head -n 1)
[ -z "$BAT_PATH" ] && echo "{\"text\": \"No Battery\"}" && exit 0

# 2. Capacity and Status
CAP=$(cat "$BAT_PATH/capacity")
STATUS=$(cat "$BAT_PATH/status")

# 3. Raw Ah Info (uAh)
NOW_UAH=$(cat "$BAT_PATH/charge_now" 2>/dev/null || cat "$BAT_PATH/energy_now" 2>/dev/null || echo 0)
FULL_UAH=$(cat "$BAT_PATH/charge_full" 2>/dev/null || cat "$BAT_PATH/energy_full" 2>/dev/null || echo 0)
CURRENT_UA=$(cat "$BAT_PATH/current_now" 2>/dev/null || cat "$BAT_PATH/power_now" 2>/dev/null || echo 0)

calc_time() {
    [ "$CURRENT_UA" -le 0 ] && echo "Calculating..." && return
    
    if [ "$STATUS" = "Discharging" ]; then
        awk "BEGIN { h=$NOW_UAH/$CURRENT_UA; m=(h-int(h))*60; printf \"%dh %dm\", int(h), int(m) }"
    elif [ "$STATUS" = "Charging" ]; then
        awk "BEGIN { h=($FULL_UAH-$NOW_UAH)/$CURRENT_UA; m=(h-int(h))*60; printf \"%dh %dm\", int(h), int(m) }"
    else
        echo "Full"
    fi
}

TIME=$(calc_time)

# 4. Icon Logic
ICON=""
if [ "$STATUS" = "Charging" ]; then
    ICON=""
elif [ "$STATUS" = "Full" ] || [ "$STATUS" = "Not charging" ]; then
    ICON=""
    TIME="Full"
fi

# 5. Waybar JSON Output
echo "{\"text\": \"$ICON [$CAP%] ($TIME)\", \"percentage\": $CAP, \"class\": \"${STATUS,,}\"}"
