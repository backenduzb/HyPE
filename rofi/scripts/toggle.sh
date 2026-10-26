#!/usr/bin/env bash

DOCK_THEME="$HOME/.config/rofi/dock.rasi"
FULL_THEME="$HOME/.config/rofi/full.rasi"

MODE="${1:-toggle}"

if [ "$MODE" = "full" ]; then
    pkill rofi 2>/dev/null
    rofi -show drun -config "$FULL_THEME"
elif [ "$MODE" = "dock" ]; then
    pkill rofi 2>/dev/null
    rofi -show drun -config "$DOCK_THEME"
else
    if pgrep -x "rofi" > /dev/null; then
        pkill rofi
    else
        rofi -show drun -config "$DOCK_THEME"
    fi
fi
