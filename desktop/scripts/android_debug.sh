#!/bin/bash
# FujiRuro-OS Android Debug Script
# Sanitized for public release.

log() { echo "[Android] $1"; }

log "Checking for connected devices..."
adb devices

log "Configuring TCP/IP for wireless debugging..."
adb tcpip 5555

log "Waiting for device to connect over WiFi..."
sleep 2
DEVICE_IP=$(adb shell ip route | awk '{print $NF}' | grep -E '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)

if [ -n "$DEVICE_IP" ]; then
    log "Connecting to $DEVICE_IP..."
    adb connect "$DEVICE_IP:5555"
    log "Launching screen mirror (scrcpy)..."
    scrcpy -d
else
    log "Could not detect device IP. Please ensure USB debugging is enabled."
fi
