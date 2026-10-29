#!/usr/bin/env bash
set -euo pipefail

THEME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
NAME="${1:-}"
PRESET="$THEME_DIR/palettes/$NAME.sh"

if [[ -z "$NAME" || ! -f "$PRESET" ]]; then
    echo "Usage: $0 <dark|light>" >&2
    exit 1
fi

install -m644 "$PRESET" "$THEME_DIR/colors.sh"

TARGET="${XDG_CONFIG_HOME:-${HYCON_DIR:-$HOME/.config}}"
"$THEME_DIR/apply-colors.sh" "$THEME_DIR/colors.sh" "$TARGET"

source "$THEME_DIR/colors.sh"
: "${MAC_GTK_THEME:=adw-gtk3-dark}"
: "${MAC_ICON_THEME:=WhiteSur-dark}"
: "${MAC_COLOR_SCHEME:=prefer-dark}"

if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface gtk-theme "$MAC_GTK_THEME" >/dev/null 2>&1 || true
    gsettings set org.gnome.desktop.interface icon-theme "$MAC_ICON_THEME" >/dev/null 2>&1 || true
    gsettings set org.gnome.desktop.interface color-scheme "$MAC_COLOR_SCHEME" >/dev/null 2>&1 || true
fi

for conf in "$TARGET/qt6ct/qt6ct.conf" "$TARGET/qt5ct/qt5ct.conf"; do
    [[ -f "$conf" ]] || continue
    sed -i "s/^icon_theme=.*/icon_theme=$MAC_ICON_THEME/" "$conf"
done

if command -v pkill >/dev/null 2>&1; then
    pkill -SIGUSR2 waybar 2>/dev/null || true
    pkill -SIGUSR1 kitty 2>/dev/null || true
fi

if command -v hyprctl >/dev/null 2>&1 && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    hyprctl reload >/dev/null 2>&1 || true
fi

echo "Theme switched: $NAME"
