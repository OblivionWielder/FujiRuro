#!/bin/bash

# Map monitor-sensor orientations to Sway transforms
# Fujitsu Q5010 is Portrait Native.
# normal -> 0
# bottom-up -> 180
# left-up -> 270 (Landscape Inverted)
# right-up -> 90 (Landscape)

# Ensure monitor-sensor is running
if ! pgrep -x "iio-sensor-prox" > /dev/null; then
    echo "iio-sensor-proxy is not running. Starting it..."
    sudo systemctl start iio-sensor-proxy
fi

monitor-sensor | while read -r line; do
    if [[ "$line" == *"Accelerometer orientation changed:"* ]]; then
        orientation=$(echo "$line" | awk -F': ' '{print $2}')
        case "$orientation" in
            "normal")
                swaymsg output "*" transform 0
                CONFIG="config.portrait"
                ;;
            "bottom-up")
                swaymsg output "*" transform 180
                CONFIG="config.portrait"
                ;;
            "left-up")
                swaymsg output "*" transform 270
                CONFIG="config.landscape"
                ;;
            "right-up")
                swaymsg output "*" transform 90
                CONFIG="config.landscape"
                ;;
        esac

        if [ -n "$CONFIG" ]; then
            # Swap waybar config if different
            ln -sf "$HOME/.config/waybar/$CONFIG" "$HOME/.config/waybar/config"
            # Restart waybar (kill and it should be restarted by systemd or we do it manually)
            # Actually, let's just use pkill and have it restarted or start it if not running.
            pkill -USR2 waybar || waybar &
            # Note: USR2 reloads config, but if we changed from single bar to array, 
            # some versions of waybar might need a full restart.
            # Let's use SIGUSR2 first, if it fails to handle array swap, we'll use a full restart.
            # pkill -SIGUSR2 waybar
            
            # Re-verify: Waybar 0.9.x+ handles config reload on SIGUSR2.
            # However, swapping from 1 bar to 2 bars might be tricky for some versions.
            # Let's just restart to be 100% sure and avoid ghost bars.
            pkill waybar
            waybar &
        fi
    fi
done
