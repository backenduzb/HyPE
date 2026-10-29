#!/usr/bin/env bash
set -euo pipefail

THEME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
COLORS_FILE="${1:-$THEME_DIR/colors.sh}"
TARGET="${2:-${XDG_CONFIG_HOME:-${HYCON_DIR:-$HOME/.config}}}"
TARGET="${TARGET%/}"
KV_SRC="${KV_SRC:-/usr/share/Kvantum/KvMojave}"

source "$COLORS_FILE"

KWRITE_CONFIG="$(command -v kwriteconfig6 2>/dev/null || command -v kwriteconfig5 2>/dev/null || true)"

: "${MAC_GTK_THEME:=adw-gtk3-dark}"
: "${MAC_ICON_THEME:=WhiteSur-dark}"
: "${MAC_COLOR_SCHEME:=prefer-dark}"
: "${MAC_GTK_PREFER_DARK:=1}"
: "${MAC_BLUE:=#0a84ff}"
: "${MAC_CYAN:=#64d2ff}"

CSS_VARS=(
    bg bg_translucent menu_bg tooltip_bg surface surface_alt surface_hover
    text text_dim text_muted accent accent_hover accent_inactive on_accent
    red yellow green blue cyan purple border separator shadow bar_border icon_muted
    icon_hover entry_bg button_shadow focus_ring control_bg control_disabled
    switch_bg progress_bg scrollbar scrollbar_hover sidebar
)

value_of() {
    local name="MAC_${1^^}"
    printf '%s' "${!name}"
}

write_css() {
    local out="$1"
    local var
    : > "$out"
    for var in "${CSS_VARS[@]}"; do
        printf '@define-color mac_%s %s;\n' "$var" "$(value_of "$var")" >> "$out"
    done
}

write_css "$THEME_DIR/gtk-3.0/colors.css"
write_css "$THEME_DIR/gtk-4.0/colors.css"
write_css "$THEME_DIR/waybar/colors.css"

{
    printf '* {\n'
    for var in "${CSS_VARS[@]}"; do
        printf '    mac-%s: %s;\n' "${var//_/-}" "$(value_of "$var")"
    done
    printf '}\n'
} > "$THEME_DIR/rofi/colors.rasi"

cat > "$THEME_DIR/rofi/icon-theme.rasi" <<EOF
configuration {
    icon-theme: "$MAC_ICON_THEME";
}
EOF

REAL_HOME="$(getent passwd "$(id -u)" 2>/dev/null | cut -d: -f6 || true)"
PROJECT_DIR="$(dirname "$(dirname "$THEME_DIR")")"
WALLPAPER_LINK="$THEME_DIR/rofi/wallpaper.jpg"
if [[ ! -e "$WALLPAPER_LINK" ]]; then
    if [[ -n "$REAL_HOME" && -f "$REAL_HOME/Wallpapers/space.jpg" ]]; then
        ln -sfn "$REAL_HOME/Wallpapers/space.jpg" "$WALLPAPER_LINK"
    elif [[ -f "$PROJECT_DIR/assets/wallpapers/space.jpg" ]]; then
        ln -sfn "$PROJECT_DIR/assets/wallpapers/space.jpg" "$WALLPAPER_LINK"
    fi
fi

: > "$THEME_DIR/rofi/banner.rasi"
if [[ -e "$WALLPAPER_LINK" ]]; then
    printf 'banner {\n    background-image: url("%s", height);\n}\n' \
        "$WALLPAPER_LINK" > "$THEME_DIR/rofi/banner.rasi"
fi

for gtk_dir in gtk-3.0 gtk-4.0; do
    settings="$THEME_DIR/$gtk_dir/settings.ini"
    [[ -f "$settings" ]] || continue
    sed -i \
        -e "s/^gtk-theme-name=.*/gtk-theme-name=$MAC_GTK_THEME/" \
        -e "s/^gtk-icon-theme-name=.*/gtk-icon-theme-name=$MAC_ICON_THEME/" \
        -e "s/^gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=$MAC_GTK_PREFER_DARK/" \
        "$settings"
done

qt_hex() {
    local hex="${1#\#}"
    printf '#ff%s' "${hex^^}"
}

qt_alpha() {
    local hex="${1#\#}" alpha="$2"
    printf '#%s%s' "$alpha" "${hex^^}"
}

qt_palette() {
    local mode="$1"
    local wt btn light midlight dark mid text bright btntext base window shadow
    local highlight htext link linkvisited alt norole tooltipbase tooltiptext placeholder

    case "$mode" in
        active)
            wt="$MAC_TEXT"
            btn="$MAC_SURFACE_ALT"
            light="$MAC_SURFACE_HOVER"
            midlight="$MAC_SURFACE_HOVER"
            dark="$MAC_QT_DARK"
            mid="$MAC_SURFACE"
            text="$MAC_TEXT"
            bright="$MAC_TEXT"
            btntext="$MAC_TEXT"
            base="$MAC_BG"
            window="$MAC_BG"
            shadow="$MAC_QT_SHADOW"
            highlight="$MAC_ACCENT"
            htext="$MAC_ON_ACCENT"
            link="$MAC_ACCENT"
            linkvisited="$MAC_PURPLE"
            alt="$MAC_SURFACE"
            norole="$MAC_QT_SHADOW"
            tooltipbase="$MAC_SURFACE_ALT"
            tooltiptext="$MAC_TEXT"
            placeholder="$(qt_alpha "$MAC_TEXT_MUTED" 80)"
            ;;
        disabled)
            wt="$MAC_TEXT_MUTED"
            btn="$MAC_SURFACE"
            light="$MAC_SURFACE_ALT"
            midlight="$MAC_SURFACE_ALT"
            dark="$MAC_QT_DARK"
            mid="$MAC_SURFACE"
            text="$MAC_TEXT_MUTED"
            bright="$MAC_TEXT_DIM"
            btntext="$MAC_TEXT_MUTED"
            base="$MAC_BG"
            window="$MAC_BG"
            shadow="$MAC_QT_SHADOW"
            highlight="$MAC_ACCENT_INACTIVE"
            htext="$MAC_TEXT_DIM"
            link="$MAC_TEXT_MUTED"
            linkvisited="$MAC_TEXT_MUTED"
            alt="$MAC_SURFACE"
            norole="$MAC_QT_SHADOW"
            tooltipbase="$MAC_SURFACE_ALT"
            tooltiptext="$MAC_TEXT_MUTED"
            placeholder="$(qt_alpha "$MAC_TEXT_MUTED" 40)"
            ;;
        inactive)
            wt="$MAC_TEXT_DIM"
            btn="$MAC_SURFACE_ALT"
            light="$MAC_SURFACE_HOVER"
            midlight="$MAC_SURFACE_HOVER"
            dark="$MAC_QT_DARK"
            mid="$MAC_SURFACE"
            text="$MAC_TEXT_DIM"
            bright="$MAC_TEXT"
            btntext="$MAC_TEXT_DIM"
            base="$MAC_BG"
            window="$MAC_BG"
            shadow="$MAC_QT_SHADOW"
            highlight="$MAC_ACCENT_INACTIVE"
            htext="$MAC_TEXT"
            link="$MAC_ACCENT_INACTIVE"
            linkvisited="$MAC_PURPLE"
            alt="$MAC_SURFACE"
            norole="$MAC_QT_SHADOW"
            tooltipbase="$MAC_SURFACE_ALT"
            tooltiptext="$MAC_TEXT_DIM"
            placeholder="$(qt_alpha "$MAC_TEXT_MUTED" 60)"
            ;;
    esac

    printf '%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s\n' \
        "$(qt_hex "$wt")" "$(qt_hex "$btn")" "$(qt_hex "$light")" \
        "$(qt_hex "$midlight")" "$(qt_hex "$dark")" "$(qt_hex "$mid")" \
        "$(qt_hex "$text")" "$(qt_hex "$bright")" "$(qt_hex "$btntext")" \
        "$(qt_hex "$base")" "$(qt_hex "$window")" "$(qt_hex "$shadow")" \
        "$(qt_hex "$highlight")" "$(qt_hex "$htext")" "$(qt_hex "$link")" \
        "$(qt_hex "$linkvisited")" "$(qt_hex "$alt")" "$(qt_hex "$norole")" \
        "$(qt_hex "$tooltipbase")" "$(qt_hex "$tooltiptext")" "$placeholder"
}

write_qt_colors() {
    local out="$1"
    {
        printf '[ColorScheme]\n'
        printf 'active_colors=%s\n' "$(qt_palette active)"
        printf 'disabled_colors=%s\n' "$(qt_palette disabled)"
        printf 'inactive_colors=%s\n' "$(qt_palette inactive)"
    } > "$out"
}

write_qt_colors "$THEME_DIR/qt6ct/colors.conf"
write_qt_colors "$THEME_DIR/qt5ct/colors.conf"

kde_backup() {
    local file="$1"
    if [[ -f "$file" && ! -e "$file.macos.bak" ]]; then
        cp -a "$file" "$file.macos.bak"
    fi
}

kde_set() {
    local group="$1" key="$2" value="$3" type="${4:-string}"
    local args=(--file "$TARGET/kdeglobals" --group "$group" --key "$key")
    [[ "$type" == "bool" ]] && args+=(--type bool)
    "$KWRITE_CONFIG" "${args[@]}" "$value" >/dev/null 2>&1 || true
}

kde_color_group() {
    local group="$1" bg="$2" alt="$3" fg="$4" fg_active="${5:-$4}"
    kde_set "$group" BackgroundNormal "$bg"
    kde_set "$group" BackgroundAlternate "$alt"
    kde_set "$group" ForegroundNormal "$fg"
    kde_set "$group" ForegroundInactive "$MAC_TEXT_DIM"
    kde_set "$group" ForegroundActive "$fg_active"
    kde_set "$group" ForegroundLink "$MAC_BLUE"
    kde_set "$group" ForegroundVisited "$MAC_PURPLE"
    kde_set "$group" ForegroundNegative "$MAC_RED"
    kde_set "$group" ForegroundNeutral "$MAC_YELLOW"
    kde_set "$group" ForegroundPositive "$MAC_GREEN"
    kde_set "$group" DecorationFocus "$MAC_BLUE"
    kde_set "$group" DecorationHover "$MAC_BLUE"
}

apply_kde_colors() {
    [[ -n "$KWRITE_CONFIG" ]] || return 0
    mkdir -p "$TARGET"
    kde_backup "$TARGET/kdeglobals"

    kde_color_group "Colors:Window" "$MAC_BG" "$MAC_SURFACE" "$MAC_TEXT"
    kde_color_group "Colors:View" "$MAC_BG" "$MAC_SURFACE" "$MAC_TEXT"
    kde_color_group "Colors:Button" "$MAC_SURFACE_ALT" "$MAC_SURFACE_HOVER" "$MAC_TEXT"
    kde_color_group "Colors:Selection" "$MAC_ACCENT" "$MAC_ACCENT_HOVER" "$MAC_ON_ACCENT" "$MAC_ON_ACCENT"
    kde_color_group "Colors:Tooltip" "$MAC_SURFACE_ALT" "$MAC_SURFACE" "$MAC_TEXT"
    kde_color_group "Colors:Complementary" "$MAC_SURFACE_ALT" "$MAC_SURFACE" "$MAC_TEXT"
    kde_color_group "Colors:Header" "$MAC_SURFACE" "$MAC_BG" "$MAC_TEXT"

    kde_set "WM" activeBackground "$MAC_SURFACE"
    kde_set "WM" inactiveBackground "$MAC_BG"
    kde_set "WM" activeForeground "$MAC_TEXT"
    kde_set "WM" inactiveForeground "$MAC_TEXT_DIM"
    kde_set "WM" activeBlend "$MAC_TEXT"
    kde_set "WM" inactiveBlend "$MAC_TEXT_DIM"
}

apply_darkly_config() {
    [[ -n "$KWRITE_CONFIG" ]] || return 0
    mkdir -p "$TARGET"
    kde_backup "$TARGET/darklyrc"

    "$KWRITE_CONFIG" --file "$TARGET/darklyrc" --group Common --key CornerRadius 10 >/dev/null 2>&1 || true
    "$KWRITE_CONFIG" --file "$TARGET/darklyrc" --group Common --key FloatingTitlebar --type bool false >/dev/null 2>&1 || true
    "$KWRITE_CONFIG" --file "$TARGET/darklyrc" --group Common --key FancyMargins --type bool true >/dev/null 2>&1 || true
    "$KWRITE_CONFIG" --file "$TARGET/darklyrc" --group Common --key SunkenEffect --type bool false >/dev/null 2>&1 || true
    "$KWRITE_CONFIG" --file "$TARGET/darklyrc" --group Style --key WidgetDrawShadow --type bool false >/dev/null 2>&1 || true
    "$KWRITE_CONFIG" --file "$TARGET/darklyrc" --group Style --key WidgetToolBarShadow --type bool false >/dev/null 2>&1 || true
    "$KWRITE_CONFIG" --file "$TARGET/darklyrc" --group Style --key DisableDolphinUrlNavigatorBackground --type bool true >/dev/null 2>&1 || true
    "$KWRITE_CONFIG" --file "$TARGET/darklyrc" --group Style --key DockWidgetDrawFrame --type bool false >/dev/null 2>&1 || true
    "$KWRITE_CONFIG" --file "$TARGET/darklyrc" --group Style --key NewDolphinSelectionStyle --type bool true >/dev/null 2>&1 || true
    "$KWRITE_CONFIG" --file "$TARGET/darklyrc" --group Style --key DolphinSidebarOpacity 100 >/dev/null 2>&1 || true
    "$KWRITE_CONFIG" --file "$TARGET/darklyrc" --group Style --key DolphinViewOpacity 100 >/dev/null 2>&1 || true
    "$KWRITE_CONFIG" --file "$TARGET/darklyrc" --group Style --key MenuOpacity 90 >/dev/null 2>&1 || true
    "$KWRITE_CONFIG" --file "$TARGET/darklyrc" --group Style --key MenuBarOpacity 100 >/dev/null 2>&1 || true
    "$KWRITE_CONFIG" --file "$TARGET/darklyrc" --group Style --key ToolBarOpacity 100 >/dev/null 2>&1 || true
    "$KWRITE_CONFIG" --file "$TARGET/darklyrc" --group Style --key TabBarOpacity 100 >/dev/null 2>&1 || true
}

apply_kde_colors
apply_darkly_config

mkdir -p "$THEME_DIR/kitty"
cat > "$THEME_DIR/kitty/colors.conf" <<EOF
background $MAC_BG
foreground $MAC_TEXT
cursor $MAC_ACCENT
cursor_text_color $MAC_BG
selection_background $MAC_SURFACE_HOVER
selection_foreground $MAC_TEXT
url_color $MAC_BLUE
active_border_color $MAC_ACCENT
inactive_border_color $MAC_TEXT_DIM
active_tab_background $MAC_SURFACE_ALT
active_tab_foreground $MAC_TEXT
inactive_tab_background $MAC_BG
inactive_tab_foreground $MAC_TEXT_DIM
tab_bar_background $MAC_BG
color0 $MAC_SURFACE
color8 $MAC_SURFACE_HOVER
color1 $MAC_RED
color9 $MAC_RED
color2 $MAC_GREEN
color10 $MAC_GREEN
color3 $MAC_YELLOW
color11 $MAC_YELLOW
color4 $MAC_BLUE
color12 $MAC_BLUE
color5 $MAC_PURPLE
color13 $MAC_PURPLE
color6 $MAC_CYAN
color14 $MAC_CYAN
color7 $MAC_TEXT_DIM
color15 $MAC_TEXT
EOF

cat > "$THEME_DIR/kvantum/general-colors.conf" <<EOF
window.color=$MAC_BG
inactive.window.color=$MAC_BG
base.color=$MAC_BG
inactive.base.color=$MAC_BG
alt.base.color=$MAC_SURFACE_ALT
inactive.alt.base.color=$MAC_SURFACE_ALT
button.color=$MAC_SURFACE_ALT
light.color=$MAC_SURFACE_HOVER
mid.light.color=$MAC_SURFACE_HOVER
dark.color=$MAC_QT_DARK
mid.color=$MAC_SURFACE
highlight.color=$MAC_ACCENT
inactive.highlight.color=$MAC_ACCENT_INACTIVE
tooltip.base.color=$MAC_SURFACE_ALT
text.color=$MAC_TEXT
inactive.text.color=$MAC_TEXT_DIM
window.text.color=$MAC_TEXT
inactive.window.text.color=$MAC_TEXT_DIM
button.text.color=$MAC_TEXT
disabled.text.color=$MAC_TEXT_MUTED
tooltip.text.color=$MAC_TEXT
highlight.text.color=$MAC_ON_ACCENT
inactive.highlight.text.color=$MAC_ON_ACCENT
link.color=$MAC_ACCENT
link.visited.color=$MAC_PURPLE
EOF

if [[ -f "$KV_SRC/KvMojave.kvconfig" ]]; then
    awk -v colors="$THEME_DIR/kvantum/general-colors.conf" '
        BEGIN {
            while ((getline line < colors) > 0) {
                palette = palette line "\n"
            }
            close(colors)
        }
        /^\[GeneralColors\]/ {
            print
            printf "%s", palette
            while ((getline line) > 0 && line != "") { }
            print ""
            next
        }
        { print }
    ' "$KV_SRC/KvMojave.kvconfig" > "$THEME_DIR/kvantum/MacOS.kvconfig"

    if [[ -f "$KV_SRC/KvMojave.svg" ]]; then
        ln -sfn "$KV_SRC/KvMojave.svg" "$THEME_DIR/kvantum/MacOS.svg"
    fi
fi

hypr_rgba() {
    local hex="${1#\#}" alpha="$2"
    printf 'rgba(%s%s)' "${hex,,}" "$alpha"
}

cat > "$THEME_DIR/colors.lua" <<EOF
hl.env("GTK_THEME", "$MAC_GTK_THEME")

hl.config({
    general = {
        col = {
            active_border = { colors = { "$(hypr_rgba "$MAC_ACCENT" ee)" } },
            inactive_border = "$(hypr_rgba "$MAC_TEXT_DIM" 55)",
        },
    },
})
EOF
