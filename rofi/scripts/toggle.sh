#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROFI_DIR="$(dirname "$SCRIPT_DIR")"
REPO_DIR="$(dirname "$ROFI_DIR")"

DOCK_THEME="$HOME/.config/rofi/dock.rasi"
[ ! -f "$DOCK_THEME" ] && DOCK_THEME="$ROFI_DIR/dock.rasi"

FULL_THEME="$HOME/.config/rofi/full.rasi"
[ ! -f "$FULL_THEME" ] && FULL_THEME="$ROFI_DIR/full.rasi"

THEME_NAME="${HYCON_THEME-macos}"
THEME_DIR="${HYCON_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}}/themes/$THEME_NAME"
if [[ -n "$THEME_NAME" && ! -d "$THEME_DIR" && -d "$REPO_DIR/themes/$THEME_NAME" ]]; then
    THEME_DIR="$REPO_DIR/themes/$THEME_NAME"
fi
if [[ -n "$THEME_NAME" && -f "$THEME_DIR/rofi/dock.rasi" ]]; then
    DOCK_THEME="$THEME_DIR/rofi/dock.rasi"
fi
if [[ -n "$THEME_NAME" && -f "$THEME_DIR/rofi/$THEME_NAME.rasi" ]]; then
    FULL_THEME="$THEME_DIR/rofi/$THEME_NAME.rasi"
fi

DOCK_WINDOW="$SCRIPT_DIR/dock-window.sh"

DOCK_ICON_SIZE=52
DOCK_ELEMENT_PADDING=4
DOCK_LIST_SPACING=4
DOCK_WINDOW_PADDING=16
DOCK_WINDOW_BORDER=2
DOCK_WIDTH_BUFFER=12

MODE="${1:-toggle}"

launch_dock() {
    local list_file total width selected_idx
    list_file="$(mktemp "${XDG_RUNTIME_DIR:-/tmp}/hycon-dock.XXXXXX")" || return 1
    "$DOCK_WINDOW" --list > "$list_file" 2>/dev/null

    total="$(awk 'END { print NR }' "$list_file" 2>/dev/null || true)"
    if [[ -z "$total" || "$total" -lt 1 ]]; then
        total=1
    fi

    width=$(( \
        total * (DOCK_ICON_SIZE + DOCK_ELEMENT_PADDING) \
        + (total - 1) * DOCK_LIST_SPACING \
        + DOCK_WINDOW_PADDING \
        + DOCK_WINDOW_BORDER \
        + DOCK_WIDTH_BUFFER \
    ))

    selected_idx=$(rofi -dmenu \
        -format i \
        -config "$DOCK_THEME" \
        -theme-str "window { width: ${width}px; } listview { lines: ${total}; }" \
        < "$list_file")
    rm -f "$list_file"

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
