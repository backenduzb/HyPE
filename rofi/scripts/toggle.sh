#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROFI_DIR="$(dirname "$SCRIPT_DIR")"

DOCK_THEME="$HOME/.config/rofi/dock.rasi"
[ ! -f "$DOCK_THEME" ] && DOCK_THEME="$ROFI_DIR/dock.rasi"

FULL_THEME="$HOME/.config/rofi/full.rasi"
[ ! -f "$FULL_THEME" ] && FULL_THEME="$ROFI_DIR/full.rasi"

DOCK_WINDOW="$SCRIPT_DIR/dock-window.sh"

MODE="${1:-toggle}"

launch_dock() {
    local total
    total="$("$DOCK_WINDOW" --count 2>/dev/null)"
    if [[ -z "$total" || "$total" -lt 1 ]]; then
        total=1
    fi
    local width=$(( total * 60 + 14 ))

    local selected_idx
    selected_idx=$("$DOCK_WINDOW" --list | rofi -dmenu \
        -format i \
        -config "$DOCK_THEME" \
        -theme-str "window { width: ${width}px; } listview { lines: ${total}; }")

    if [[ -n "$selected_idx" ]]; then
        "$DOCK_WINDOW" --select "$selected_idx"
    fi
}

if [ "$MODE" = "full" ]; then
    pkill rofi 2>/dev/null
    rofi -show drun -config "$FULL_THEME"
elif [ "$MODE" = "dock" ]; then
    pkill rofi 2>/dev/null
    launch_dock
else
    if pgrep -x "rofi" > /dev/null; then
        pkill rofi
    else
        launch_dock
    fi
fi
