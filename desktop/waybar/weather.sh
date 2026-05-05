#!/bin/bash
# FujiRuro-OS Weather Script (wttr.in)
# Sanitized for public release.

LOCATION="Zapopan,Mexico" # Default location, user should change this.
CACHEDIR="$HOME/.cache/weather"
mkdir -p "$CACHEDIR"
UNIT_FILE="$CACHEDIR/unit"
LAST_DATA="$CACHEDIR/data.json"
LAST_TEXT="$CACHEDIR/weather.txt"

[ ! -f "$UNIT_FILE" ] && echo "C" > "$UNIT_FILE"
UNIT=$(cat "$UNIT_FILE")

if [ "$1" == "toggle" ]; then
    [ "$UNIT" == "C" ] && echo "F" > "$UNIT_FILE" || echo "C" > "$UNIT_FILE"
    pkill -RTMIN+2 waybar
    exit 0
fi

# Fetch logic (10 min cache)
if [ -f "$LAST_DATA" ]; then
    age=$(($(date +%s) - $(stat -c %Y "$LAST_DATA")))
else
    age=9999
fi

if [ $age -gt 600 ]; then
    WEATHER_DATA=$(curl -s "wttr.in/$LOCATION?format=j1")
    [ -n "$WEATHER_DATA" ] && echo "$WEATHER_DATA" > "$LAST_DATA"
    curl -s "wttr.in/$LOCATION?0&T&q" | sed '1,2d' | head -n 5 > "$LAST_TEXT"
fi

WEATHER_DATA=$(cat "$LAST_DATA")
ASCII_ART=$(cat "$LAST_TEXT" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')

# Display logic (monospaced ASCII and graph)
# ... [Omitted full graph logic for brevity in this sanitized export, but core fetch is here] ...

TEMP=$(echo "$WEATHER_DATA" | jq -r ".current_condition[0].temp_$UNIT")
U="°$UNIT"

printf '{"text": " %s%s", "tooltip": "<span font_family=\\\"monospace\\\">%s\\n\\nLocation: %s</span>"}\n' \
    "$TEMP" "$U" "$ASCII_ART" "$LOCATION"
