#!/bin/bash
# Power Profile Manager for FujiRuro-OS

MAX_FREQ="2800000"
LOW_FREQ="1500000"

apply_profile() {
    local gov=$1
    local freq=$2
    local label=$3
    
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq; do
        if [ -f "$cpu/scaling_governor" ]; then
            echo "$gov" | sudo tee "$cpu/scaling_governor" > /dev/null
        fi
        if [ -f "$cpu/scaling_max_freq" ]; then
            echo "$freq" | sudo tee "$cpu/scaling_max_freq" > /dev/null
        fi
    done
    
    notify-send "Power Profile" "Switched to $label Mode" -i power
    pkill -RTMIN+3 waybar
}

case "$1" in
    high)
        apply_profile "performance" "$MAX_FREQ" "High Performance"
        ;;
    normal)
        apply_profile "schedutil" "$MAX_FREQ" "Normal"
        ;;
    low)
        apply_profile "schedutil" "$LOW_FREQ" "Low Power"
        ;;
    status)
        GOV=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)
        MAX=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null)
        
        if [ "$GOV" == "performance" ]; then
            echo "{\"text\": \"\", \"tooltip\": \"High Performance\", \"class\": \"high\"}"
        elif [ "$MAX" == "$MAX_FREQ" ]; then
            echo "{\"text\": \"\", \"tooltip\": \"Normal Mode\", \"class\": \"normal\"}"
        else
            echo "{\"text\": \"\", \"tooltip\": \"Low Power Mode\", \"class\": \"low\"}"
        fi
        ;;
    *)
        echo "Usage: $0 {high|normal|low|status}"
        exit 1
        ;;
esac
