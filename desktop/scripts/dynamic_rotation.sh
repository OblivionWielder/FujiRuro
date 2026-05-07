#!/bin/bash

# Map monitor-sensor orientations to Sway transforms
# Fujitsu Q5010 is Portrait Native.
# normal -> 0
# bottom-up -> 180
# left-up -> 270 (Landscape Inverted)
# right-up -> 90 (Landscape)

# Function to ensure we have the Wayland/Sway environment
import_env() {
    if [ -z "$SWAYSOCK" ] || [ -z "$WAYLAND_DISPLAY" ]; then
        eval $(systemctl --user show-environment | grep -E '^(WAYLAND_DISPLAY|SWAYSOCK|DISPLAY|XDG_CURRENT_DESKTOP)=')
    fi
}

# Ensure monitor-sensor is running
if ! pgrep -x "iio-sensor-prox" > /dev/null; then
    echo "iio-sensor-proxy is not running. Starting it..."
    sudo systemctl start iio-sensor-proxy
fi

monitor-sensor | while read -r line; do
    if [[ "$line" == *"Accelerometer orientation changed:"* ]]; then
        orientation=$(echo "$line" | awk -F': ' '{print $2}')
        import_env
        
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
            CURRENT_LINK=$(readlink "$HOME/.config/waybar/config")
            TARGET_CONFIG="$HOME/.config/waybar/$CONFIG"
            
            # Always ensure Waybar is running, even if config didn't change (crash recovery)
            if [ "$CURRENT_LINK" != "$TARGET_CONFIG" ] || ! pgrep -x waybar > /dev/null; then
                ln -sf "$TARGET_CONFIG" "$HOME/.config/waybar/config"
                
                # Robust Waybar restart
                pkill waybar
                # Wait up to 2 seconds for it to die
                for i in {1..20}; do
                    pgrep -x waybar > /dev/null || break
                    sleep 0.1
                done
                # Start fresh with environment
                WAYLAND_DISPLAY=$WAYLAND_DISPLAY SWAYSOCK=$SWAYSOCK waybar > /tmp/waybar.log 2>&1 &
                echo "Waybar restarted for $orientation with $CONFIG"
            fi
        fi
    fi
done
