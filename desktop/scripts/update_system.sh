#!/bin/bash
# FujiRuro-OS System Update Wrapper

# Dynamic socket detection
export SWAYSOCK="${SWAYSOCK:-$(ls /run/user/$(id -u)/sway-ipc.*.sock 2>/dev/null | head -n 1)}"

foot bash -c 'echo "--- FUJIRURO SYSTEM UPDATE ---"; sudo apt update && sudo apt upgrade -y; echo; echo "Complete. Press Enter to close."; read'
