#!/usr/bin/env bash
set -euo pipefail

THEME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TARGET="${1:-${XDG_CONFIG_HOME:-${HYCON_DIR:-$HOME/.config}}}"
TARGET_ESC="${TARGET//&/\\&}"
KV_SRC="${KV_SRC:-/usr/share/Kvantum/KvMojave}"

KV_SRC="$KV_SRC" "$THEME_DIR/apply-colors.sh" "$THEME_DIR/colors.sh" "$TARGET"

source "$THEME_DIR/colors.sh"
: "${MAC_GTK_THEME:=adw-gtk3-dark}"
: "${MAC_ICON_THEME:=WhiteSur-dark}"
: "${MAC_COLOR_SCHEME:=prefer-dark}"

backup() {
    local file="$1"
    if [[ -e "$file" && ! -L "$file" && ! -e "$file.macos.bak" ]]; then
        cp -a "$file" "$file.macos.bak"
    fi
}

link_theme_file() {
    local src="$1"
    local dst="$2"
    mkdir -p "$(dirname "$dst")"
    backup "$dst"
    ln -sfn "$src" "$dst"
}

render_conf() {
    local src="$1"
    local dst="$2"
    mkdir -p "$(dirname "$dst")"
    backup "$dst"
    sed -e "s|@TARGET@|$TARGET_ESC|g" -e "s|@ICON_THEME@|$MAC_ICON_THEME|g" "$src" > "$dst.tmp"
    install -m644 "$dst.tmp" "$dst"
    rm -f "$dst.tmp"
}

link_theme_file "$THEME_DIR/gtk-3.0/settings.ini" "$TARGET/gtk-3.0/settings.ini"
link_theme_file "$THEME_DIR/gtk-3.0/gtk.css" "$TARGET/gtk-3.0/gtk.css"
link_theme_file "$THEME_DIR/gtk-3.0/colors.css" "$TARGET/gtk-3.0/colors.css"
link_theme_file "$THEME_DIR/gtk-4.0/settings.ini" "$TARGET/gtk-4.0/settings.ini"
link_theme_file "$THEME_DIR/gtk-4.0/gtk.css" "$TARGET/gtk-4.0/gtk.css"
link_theme_file "$THEME_DIR/gtk-4.0/colors.css" "$TARGET/gtk-4.0/colors.css"

render_conf "$THEME_DIR/qt6ct/qt6ct.conf" "$TARGET/qt6ct/qt6ct.conf"
link_theme_file "$THEME_DIR/qt6ct/colors.conf" "$TARGET/qt6ct/colors.conf"
render_conf "$THEME_DIR/qt5ct/qt5ct.conf" "$TARGET/qt5ct/qt5ct.conf"
link_theme_file "$THEME_DIR/qt5ct/colors.conf" "$TARGET/qt5ct/colors.conf"

link_theme_file "$THEME_DIR/rofi/macos.rasi" "$TARGET/rofi/macos.rasi"
link_theme_file "$THEME_DIR/rofi/colors.rasi" "$TARGET/rofi/colors.rasi"
link_theme_file "$THEME_DIR/rofi/icon-theme.rasi" "$TARGET/rofi/icon-theme.rasi"
link_theme_file "$THEME_DIR/rofi/banner.rasi" "$TARGET/rofi/banner.rasi"
link_theme_file "$THEME_DIR/rofi/dock.rasi" "$TARGET/rofi/dock.rasi"
link_theme_file "$THEME_DIR/rofi/menu.rasi" "$TARGET/rofi/menu.rasi"
link_theme_file "$THEME_DIR/rofi/picker.rasi" "$TARGET/rofi/picker.rasi"
link_theme_file "$THEME_DIR/rofi/emoji.rasi" "$TARGET/rofi/emoji.rasi"
link_theme_file "$THEME_DIR/rofi/wallpaper.rasi" "$TARGET/rofi/wallpaper.rasi"

if [[ -f "$THEME_DIR/kvantum/MacOS.kvconfig" ]]; then
    link_theme_file "$THEME_DIR/kvantum/MacOS.kvconfig" "$TARGET/Kvantum/MacOS/MacOS.kvconfig"
    link_theme_file "$THEME_DIR/kvantum/MacOS.svg" "$TARGET/Kvantum/MacOS/MacOS.svg"
fi

link_theme_file "$THEME_DIR/kvantum/kvantum.kvconfig" "$TARGET/Kvantum/kvantum.kvconfig"

if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface gtk-theme "$MAC_GTK_THEME" >/dev/null 2>&1 || true
    gsettings set org.gnome.desktop.interface icon-theme "$MAC_ICON_THEME" >/dev/null 2>&1 || true
    gsettings set org.gnome.desktop.interface color-scheme "$MAC_COLOR_SCHEME" >/dev/null 2>&1 || true
    gsettings set org.gnome.desktop.interface font-name "SF Pro Text 10" >/dev/null 2>&1 || true
    gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Classic" >/dev/null 2>&1 || true
    gsettings set org.gnome.desktop.interface cursor-size 24 >/dev/null 2>&1 || true
fi

echo "macOS theme applied to: $TARGET"
echo "GTK: $MAC_GTK_THEME + macos gtk.css"
echo "Icons: $MAC_ICON_THEME"
echo "Qt: qt6ct + Darkly"
echo "Use HYCON_THEME=macos to load the Hyprland and Waybar parts."
