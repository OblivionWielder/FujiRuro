#!/bin/bash
# FujiRuro-OS Nomadic Launcher
# A categorized and descriptive application launcher.

declare -A apps
apps["[Comm] Aerc - Terminal Email"]="foot -e aerc"
apps["[Comm] Newsboat - RSS Reader"]="foot -e newsboat"
apps["[File] Yazi - Terminal FM"]="foot -e ~/scripts/nomadic_yazi.sh"
apps["[Edit] Helix - Modal Editor"]="foot -e hx"
apps["[Plan] Khal - TUI Calendar"]="foot -e khal interactive"
apps["[Sys] Htop - System Monitor"]="foot -e htop"
apps["[Tool] Snip - Screenshot Tool"]="~/scripts/snip.sh"
apps["[Z-Other] Standard Fuzzel Launcher"]="fuzzel"

choice=$(printf "%s\n" "${!apps[@]}" | sort | fuzzel --dmenu --prompt=" FujiRuro: " --width=60)

if [ -n "$choice" ]; then
    eval "${apps[$choice]}"
fi
