#!/usr/bin/env bash
set -euo pipefail

BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
B_RED='\033[1;31m'
B_GREEN='\033[1;32m'
B_YELLOW='\033[1;33m'
B_BLUE='\033[1;34m'
B_CYAN='\033[1;36m'

log_info()    { echo -e "${B_BLUE}[INFO]${RESET} $*"; }
log_success() { echo -e "${B_GREEN}[OK]${RESET} $*"; }
log_warn()    { echo -e "${B_YELLOW}[WARN]${RESET} $*"; }
log_error()   { echo -e "${B_RED}[ERROR]${RESET} $*" >&2; }
log_step()    { echo -e "\n${B_CYAN}==>${RESET} ${BOLD}$*${RESET}"; }

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Hycon (macOS themed Hyprland) konfiguratsiyasini o'rnatadi.
Eski configlar avtomatik backup qilinadi va o'chiriladi.

Options:
  -y, --yes     Tasdiqlash so'ramasdan davom etish
      --force   Majburiy komandalar/fontlar topilmasa ham davom etish
      --with-sddm          SDDM victhem mavzusini o'rnatish (sudo)
      --with-grub          Hycon GRUB mavzusini o'rnatish (sudo, grub-mkconfig)
      --with-system-themes SDDM va GRUB mavzularini o'rnatish (sudo)
  -h, --help    Ushbu yordamni ko'rsatish

Backup:
  \${XDG_STATE_HOME:-\$HOME/.local/state}/hycon/backups/<timestamp>
  Tizim mavzulari backupi: <timestamp>/system/...
EOF
}

die() { log_error "$*"; exit 1; }

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TARGET="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
BACKUP_ROOT="$STATE_HOME/hycon/backups"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)-$$"
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"
SDDM_THEME_DIR="${HYCON_SDDM_THEME_DIR:-/usr/share/sddm/themes/victhem}"
SDDM_CONF="${HYCON_SDDM_CONF:-/etc/sddm.conf.d/99-hycon-theme.conf}"
GRUB_THEME_DIR="${HYCON_GRUB_THEME_DIR:-/usr/share/grub/themes/hycon}"
GRUB_THEME_PATH="${HYCON_GRUB_THEME_PATH:-/usr/share/grub/themes/hycon/theme.txt}"
GRUB_DEFAULT="${HYCON_GRUB_DEFAULT:-/etc/default/grub}"
GRUB_CFG="${HYCON_GRUB_CFG:-/boot/grub/grub.cfg}"
GRUB_DEFAULT_BACKUP=""

ASSUME_YES=0
FORCE=0
WITH_SDDM=0
WITH_GRUB=0
SDDM_INSTALLED=0
GRUB_INSTALLED=0
TMP_LOG=""
declare -A BACKED_UP_PATHS=()

while (( $# > 0 )); do
    case "$1" in
        -y|--yes) ASSUME_YES=1 ;;
        --force) FORCE=1 ;;
        --with-sddm) WITH_SDDM=1 ;;
        --with-grub) WITH_GRUB=1 ;;
        --with-system-themes) WITH_SDDM=1; WITH_GRUB=1 ;;
        -h|--help) usage; exit 0 ;;
        *) log_error "Noma'lum argument: $1"; usage; exit 2 ;;
    esac
    shift
done

on_error() {
    local status=$?
    echo
    log_error "O'rnatish to'xtatildi (exit $status)."
    if [[ -d "$BACKUP_DIR" ]]; then
        log_info "Eski configlar backupda: $BACKUP_DIR"
    fi
    exit "$status"
}
trap on_error ERR
trap '[[ -n "${TMP_LOG:-}" && -f "$TMP_LOG" ]] && rm -f "$TMP_LOG"' EXIT

[[ -n "$TARGET" && "$TARGET" != "/" ]] || die "XDG_CONFIG_HOME noto'g'ri: $TARGET"
TARGET="${TARGET%/}"
[[ -n "$TARGET" ]] || die "XDG_CONFIG_HOME bo'sh"
[[ "$PROJECT_DIR" != "$TARGET" ]] || die "Loyiha papkasi bilan target bir xil: $TARGET"
(( EUID != 0 )) || die "install.sh ni root sifatida ishga tushirmang"

MANAGED_DIRS=(hypr waybar kitty rofi dunst hypridle wlogout themes assets)
THEME_TARGET_FILES=(
    gtk-3.0/settings.ini
    gtk-3.0/gtk.css
    gtk-3.0/colors.css
    gtk-4.0/settings.ini
    gtk-4.0/gtk.css
    gtk-4.0/colors.css
    qt5ct/qt5ct.conf
    qt5ct/colors.conf
    qt6ct/qt6ct.conf
    qt6ct/colors.conf
    Kvantum/kvantum.kvconfig
    Kvantum/MacOS/MacOS.kvconfig
    Kvantum/MacOS/MacOS.svg
)
COPY_BACKUP_FILES=(
    kdeglobals
    darklyrc
)
EXTRA_CLEAN_PATHS=(
    "$TARGET/hyprlock"
    "$TARGET/mako"
)
LEGACY_PATHS=(
    "$TARGET/uwsm/env-hyprland.d/00-hyde.sh"
    "$TARGET/hyde"
    "$HOME/.local/share/hyde"
    "$HOME/.local/share/hypr"
    "$TARGET/hyprland"
    "$TARGET/hyprland.conf"
)

PROJECT_REQUIRED_FILES=(
    hypr/hyprland.lua
    hypr/configs.lua
    hypr/modules/animations.lua
    hypr/modules/autostart.lua
    hypr/modules/input.lua
    hypr/modules/keybinds.lua
    hypr/modules/settings.lua
    hypr/modules/windowrules.lua
    hypr/theme/theme.lua
    hypr/monitors.conf
    hypr/workspaces.conf
    hypr/hyprlock.conf
    hypr/hyprlock/main.conf
    hypr/hyprlock/theme.conf
    hypr/hyprlock/colors.conf
    hypr/hyprlock/modules/battery.sh
    hypr/hyprlock/modules/spoticover.sh
    waybar/config.jsonc
    waybar/style.css
    waybar/menu/settings.xml
    waybar/scripts/gpu.sh
    waybar/scripts/settings-menu.py
    kitty/kitty.conf
    rofi/scripts/toggle.sh
    rofi/scripts/dock-window.sh
    rofi/scripts/picker.py
    rofi/scripts/nerd-icons.tsv
    dunst/dunstrc
    hypridle/hypridle.conf
    wlogout/layout
    wlogout/style.css
    assets/wallpapers/space.jpg
    assets/wallpapers/aotlevi.png
    themes/macos/apply.sh
    themes/macos/apply-colors.sh
    themes/macos/switch.sh
    themes/macos/colors.sh
    themes/macos/colors.lua
    themes/macos/hypr.lua
    themes/macos/palettes/dark.sh
    themes/macos/palettes/light.sh
    themes/macos/waybar/style.css
    themes/macos/rofi/macos.rasi
    themes/macos/rofi/menu.rasi
    themes/macos/rofi/picker.rasi
    themes/macos/rofi/emoji.rasi
    themes/macos/rofi/dock.rasi
    themes/macos/rofi/icon-theme.rasi
    themes/macos/rofi/wallpaper.rasi
    themes/macos/gtk-3.0/gtk.css
    themes/macos/gtk-3.0/settings.ini
    themes/macos/gtk-4.0/gtk.css
    themes/macos/gtk-4.0/settings.ini
    themes/macos/qt5ct/qt5ct.conf
    themes/macos/qt6ct/qt6ct.conf
    themes/macos/kvantum/kvantum.kvconfig
    themes/macos/kvantum/MacOS.kvconfig
    themes/macos/kvantum/MacOS.svg
    assets/sddm/victhem/Main.qml
    assets/sddm/victhem/metadata.desktop
    assets/sddm/victhem/levi.jpeg
    assets/sddm/victhem/aotlevi.png
    assets/grub/hycon/theme.txt
    assets/grub/hycon/background.png
    assets/grub/hycon/title.pf2
    assets/grub/hycon/menu.pf2
    assets/grub/hycon/small.pf2
    assets/grub/hycon/terminal.pf2
    assets/grub/hycon/hud_top.png
    assets/grub/hycon/hud_bottom.png
    assets/grub/hycon/menu_c.png
    assets/grub/hycon/select_w.png
    assets/grub/hycon/select_c.png
    assets/grub/hycon/select_e.png
    assets/grub/hycon/terminal_c.png
    assets/grub/hycon/slider_c.png
    assets/grub/hycon/icons/arch.png
)

REQUIRED_COMMANDS=(
    Hyprland
    hyprctl
    waybar
    kitty
    rofi
    dunst
    python3
    fc-list
    jq
    bc
    hyprshot
    grim
    slurp
    wl-copy
    brightnessctl
    wpctl
    playerctl
    hyprlock
    wlogout
)

OPTIONAL_COMMANDS=(
    hypridle
    awww
    swww
    pamixer
    notify-send
    gsettings
    kwriteconfig6
    wtype
    ydotool
    xclip
    xsel
    grimblast
    sudo
    grub-mkconfig
    sddm
)

REQUIRED_FONTS=(
    "JetBrainsMono Nerd Font"
    "SF Pro Text"
    "Noto Color Emoji"
)

required_gtk_themes=("adw-gtk3-dark")
required_icon_themes=("WhiteSur-dark" "WhiteSur-light" "Bibata-Modern-Classic")

check_project_files() {
    log_step "Loyiha fayllari tekshirilmoqda"
    local missing=()
    local file
    for file in "${PROJECT_REQUIRED_FILES[@]}"; do
        if [[ ! -e "$PROJECT_DIR/$file" && ! -L "$PROJECT_DIR/$file" ]]; then
            missing+=("$file")
        fi
    done
    if (( ${#missing[@]} > 0 )); then
        log_error "Loyihada kerakli fayllar topilmadi:"
        printf '  - %s\n' "${missing[@]}" >&2
        exit 1
    fi
    log_success "Loyiha fayllari to'liq"
}

check_commands() {
    log_step "Kerakli komandalar tekshirilmoqda"
    local missing_required=()
    local missing_optional=()
    local cmd

    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        command -v "$cmd" >/dev/null 2>&1 || missing_required+=("$cmd")
    done

    if (( ${#missing_required[@]} > 0 )); then
        log_error "Majburiy komandalar topilmadi: ${missing_required[*]}"
        log_info "Arch: sudo pacman -S hyprland waybar kitty rofi dunst python jq bc brightnessctl wireplumber playerctl hyprshot grim slurp wl-clipboard hyprlock wlogout"
        if (( FORCE == 0 )); then
            log_info "Baribir davom etish uchun: $0 --force"
            exit 1
        fi
        log_warn "--force berilgan, yetishmayotgan komandalar bilan davom etilmoqda"
    else
        log_success "Majburiy komandalar mavjud"
    fi

    for cmd in "${OPTIONAL_COMMANDS[@]}"; do
        command -v "$cmd" >/dev/null 2>&1 || missing_optional+=("$cmd")
    done

    if (( ${#missing_optional[@]} > 0 )); then
        log_warn "Ixtiyoriy komandalar topilmadi: ${missing_optional[*]}"
        log_warn "Ularga bog'liq funksiyalar ishlamasligi mumkin."
    else
        log_success "Ixtiyoriy komandalar ham mavjud"
    fi
}

font_family_present() {
    local family="$1"
    local families
    command -v fc-list >/dev/null 2>&1 || return 1
    families="$(fc-list : family 2>/dev/null | tr ',' '\n' | sed 's/^ *//;s/ *$//')"
    grep -Fqix "$family" <<<"$families"
}

check_fonts() {
    log_step "Kerakli fontlar tekshirilmoqda"
    local missing=()
    local font

    for font in "${REQUIRED_FONTS[@]}"; do
        font_family_present "$font" || missing+=("$font")
    done

    if (( ${#missing[@]} > 0 )); then
        log_error "Kerakli fontlar topilmadi: ${missing[*]}"
        log_info "Arch: sudo pacman -S ttf-jetbrains-mono-nerd noto-fonts-emoji"
        log_info "SF Pro Text: Apple fonts paketini o'rnating (AUR: apple-fonts)"
        if (( FORCE == 0 )); then
            log_info "Baribir davom etish uchun: $0 --force"
            exit 1
        fi
        log_warn "--force berilgan, yetishmayotgan fontlar bilan davom etilmoqda"
    else
        log_success "Kerakli fontlar mavjud"
    fi
}

gtk_theme_present() {
    local name="$1"
    local dir
    for dir in /usr/share/themes "$HOME/.themes" "$HOME/.local/share/themes"; do
        [[ -d "$dir/$name" ]] && return 0
    done
    return 1
}

icon_theme_present() {
    local name="$1"
    local dir
    for dir in /usr/share/icons "$HOME/.icons" "$HOME/.local/share/icons"; do
        [[ -d "$dir/$name" ]] && return 0
    done
    return 1
}

check_themes() {
    log_step "Kerakli GTK/icon/cursor/Qt mavzulari tekshirilmoqda"
    local missing=()
    local item

    for item in "${required_gtk_themes[@]}"; do
        gtk_theme_present "$item" || missing+=("GTK: $item")
    done
    for item in "${required_icon_themes[@]}"; do
        icon_theme_present "$item" || missing+=("Icon/cursor: $item")
    done
    if ! command -v darkly-settings6 >/dev/null 2>&1; then
        missing+=("Qt style: Darkly (darkly-bin)")
    fi

    if (( ${#missing[@]} > 0 )); then
        log_warn "Quyidagi mavzular topilmadi:"
        printf '  - %s\n' "${missing[@]}"
        log_info "Arch: sudo pacman -S adw-gtk3 bibata-cursor-theme"
        log_info "WhiteSur icon/GTK mavzularini o'rnating (AUR: whitesur-icon-theme, whitesur-gtk-theme)"
        log_info "Darkly Qt style: yay -S darkly-bin"
        log_warn "Mavzular topilmasa ham config o'rnatiladi, lekin ko'rinish to'liq bo'lmasligi mumkin."
    else
        log_success "Kerakli mavzular mavjud"
    fi
}

confirm_install() {
    if (( ASSUME_YES == 1 )); then
        return 0
    fi
    if [[ ! -t 0 ]]; then
        die "Interaktiv terminal yo'q. Avtomatik o'rnatish uchun --yes ishlatilsin."
    fi

    echo
    log_warn "Quyidagi eski configlar backup qilinadi va o'chiriladi:"
    printf '  - %s\n' "${MANAGED_DIRS[@]/#/$TARGET/}"
    printf '  - %s\n' "${THEME_TARGET_FILES[@]/#/$TARGET/}"
    printf '  - %s\n' "${COPY_BACKUP_FILES[@]/#/$TARGET/} (copy)"
    printf '  - %s\n' "${EXTRA_CLEAN_PATHS[@]}"
    printf '  - %s\n' "${LEGACY_PATHS[@]}"
    if (( WITH_SDDM == 1 )); then
        printf '  - %s (system)\n' "$SDDM_THEME_DIR"
        printf '  - %s (system)\n' "$SDDM_CONF"
    fi
    if (( WITH_GRUB == 1 )); then
        printf '  - %s (system)\n' "$GRUB_THEME_DIR"
        printf '  - %s (system)\n' "$GRUB_DEFAULT"
        printf '  - %s (system)\n' "$GRUB_CFG"
    fi
    echo
    log_info "Backup: $BACKUP_DIR"
    echo
    local reply=""
    read -r -p "Davom etasizmi? [y/N]: " reply || reply=""
    if [[ ! "$reply" =~ ^[yY]$ ]]; then
        log_info "Bekor qilindi."
        exit 0
    fi
}

backup_path() {
    local path="$1"
    local rel dest

    if [[ ! -e "$path" && ! -L "$path" ]]; then
        return 0
    fi

    if [[ -n "${BACKED_UP_PATHS[$path]:-}" ]]; then
        return 0
    fi
    BACKED_UP_PATHS["$path"]=1

    if [[ "$path" == "$HOME"/* ]]; then
        rel="${path#"$HOME"/}"
    else
        rel="external/${path#/}"
    fi
    dest="$BACKUP_DIR/$rel"

    mkdir -p "$(dirname "$dest")"
    if mv -- "$path" "$dest" 2>/dev/null; then
        log_info "Backup: $path"
    else
        cp -a -- "$path" "$dest"
        rm -rf -- "$path"
        log_info "Backup (copy): $path"
    fi
}

backup_copy_path() {
    local path="$1"
    local rel dest

    if [[ ! -e "$path" && ! -L "$path" ]]; then
        return 0
    fi

    if [[ -n "${BACKED_UP_PATHS[$path]:-}" ]]; then
        return 0
    fi
    BACKED_UP_PATHS["$path"]=1

    if [[ "$path" == "$HOME"/* ]]; then
        rel="${path#"$HOME"/}"
    else
        rel="external/${path#/}"
    fi
    dest="$BACKUP_DIR/$rel"

    mkdir -p "$(dirname "$dest")"
    cp -a -- "$path" "$dest"
    log_info "Backup (copy): $path"
}

backup_system_copy() {
    local path="$1"
    local rel dest

    if [[ ! -e "$path" && ! -L "$path" ]]; then
        return 0
    fi

    if [[ -n "${BACKED_UP_PATHS[$path]:-}" ]]; then
        return 0
    fi
    BACKED_UP_PATHS["$path"]=1

    rel="system/${path#/}"
    dest="$BACKUP_DIR/$rel"

    mkdir -p "$(dirname "$dest")"
    if ! sudo cp -a -- "$path" "$dest"; then
        log_warn "Tizim fayli backup qilinmadi: $path"
        return 1
    fi
    sudo chown -R "$(id -u):$(id -g)" "$dest" 2>/dev/null || true
    log_info "Backup (system): $path"
}

backup_old_config() {
    log_step "Eski configlar backup qilinmoqda"
    mkdir -p "$BACKUP_DIR"

    local item
    for item in "${MANAGED_DIRS[@]}"; do
        backup_path "$TARGET/$item"
    done
    for item in "${THEME_TARGET_FILES[@]}"; do
        backup_path "$TARGET/$item"
    done
    for item in "${COPY_BACKUP_FILES[@]}"; do
        backup_copy_path "$TARGET/$item"
    done
    for item in "${EXTRA_CLEAN_PATHS[@]}"; do
        backup_path "$item"
    done
    for item in "${LEGACY_PATHS[@]}"; do
        backup_path "$item"
    done
    log_success "Eski configlar backup qilindi: $BACKUP_DIR"
}

install_configs() {
    log_step "Yangi configlar o'rnatilmoqda"
    mkdir -p "$TARGET"

    local item src dst
    for item in "${MANAGED_DIRS[@]}"; do
        src="$PROJECT_DIR/$item"
        dst="$TARGET/$item"
        if [[ ! -d "$src" ]]; then
            log_warn "Manba papka topilmadi, o'tkazib yuborildi: $src"
            continue
        fi
        if [[ -e "$dst" || -L "$dst" ]]; then
            rm -rf -- "$dst"
        fi
        cp -a -- "$src" "$dst"
        log_info "O'rnatildi: $dst"
    done

    find "$TARGET/hypr" "$TARGET/rofi" "$TARGET/waybar" "$TARGET/themes" \
        -type d -name __pycache__ -prune -exec rm -rf {} + 2>/dev/null || true

    find "$TARGET/hypr" "$TARGET/rofi/scripts" "$TARGET/waybar/scripts" "$TARGET/themes/macos" \
        -type f \( -name '*.sh' -o -name '*.py' \) -exec chmod +x {} + 2>/dev/null || true

    log_success "Config fayllari o'rnatildi"
}

apply_theme() {
    log_step "macOS mavzusi qo'llanilmoqda"
    local apply_script="$TARGET/themes/macos/apply.sh"
    [[ -x "$apply_script" ]] || die "Theme apply skripti topilmadi: $apply_script"
    HYCON_DIR="$TARGET" "$apply_script" "$TARGET"
    log_success "Mavzu qo'llanildi"
}

configure_uwsm_env() {
    log_step "UWSM muhiti sozlanmoqda"
    local uwsm_dir="$TARGET/uwsm"
    local env_dir="$uwsm_dir/env-hyprland.d"
    local env_file="$env_dir/10-hycon.sh"

    if [[ ! -d "$uwsm_dir" ]] && ! command -v uwsm >/dev/null 2>&1; then
        log_warn "UWSM topilmadi. Hyprland hyprland.lua ni avtomatik topishi kerak."
        return 0
    fi

    mkdir -p "$env_dir"
    cat > "$env_file" <<'EOF'
#!/usr/bin/env sh
HYPRLAND_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprland.lua"
HYCON_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
HYCON_THEME="${HYCON_THEME:-macos}"
QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-wayland;xcb}"
QT_AUTO_SCREEN_SCALE_FACTOR="${QT_AUTO_SCREEN_SCALE_FACTOR:-1}"
QT_WAYLAND_DISABLE_WINDOWDECORATION="${QT_WAYLAND_DISABLE_WINDOWDECORATION:-1}"
QT_QPA_PLATFORMTHEME="${QT_QPA_PLATFORMTHEME:-qt6ct}"
QT_STYLE_OVERRIDE="${QT_STYLE_OVERRIDE:-Darkly}"
XCURSOR_THEME="${XCURSOR_THEME:-Bibata-Modern-Classic}"
XCURSOR_SIZE="${XCURSOR_SIZE:-24}"
HYPRCURSOR_THEME="${HYPRCURSOR_THEME:-Bibata-Modern-Classic}"
HYPRCURSOR_SIZE="${HYPRCURSOR_SIZE:-24}"
MOZ_ENABLE_WAYLAND="${MOZ_ENABLE_WAYLAND:-1}"
GDK_SCALE="${GDK_SCALE:-1}"
ELECTRON_OZONE_PLATFORM_HINT="${ELECTRON_OZONE_PLATFORM_HINT:-auto}"
export HYPRLAND_CONFIG HYCON_DIR HYCON_THEME
export QT_QPA_PLATFORM QT_AUTO_SCREEN_SCALE_FACTOR QT_WAYLAND_DISABLE_WINDOWDECORATION
export QT_QPA_PLATFORMTHEME QT_STYLE_OVERRIDE
export XCURSOR_THEME XCURSOR_SIZE HYPRCURSOR_THEME HYPRCURSOR_SIZE
export MOZ_ENABLE_WAYLAND GDK_SCALE ELECTRON_OZONE_PLATFORM_HINT
EOF
    chmod +x "$env_file"
    log_success "UWSM env yozildi: $env_file"
}

install_sddm_theme() {
    log_step "SDDM mavzusi o'rnatilmoqda (victhem)"
    local src="$PROJECT_DIR/assets/sddm/victhem"
    local dest="$SDDM_THEME_DIR"
    local conf="$SDDM_CONF"

    if ! command -v sddm >/dev/null 2>&1; then
        log_warn "SDDM topilmadi; SDDM mavzusi o'tkazib yuborildi."
        return 0
    fi
    if ! command -v sudo >/dev/null 2>&1; then
        log_warn "sudo topilmadi; SDDM mavzusi o'tkazib yuborildi."
        return 0
    fi
    [[ -f "$src/Main.qml" ]] || die "SDDM mavzusi topilmadi: $src/Main.qml"
    [[ -f "$src/metadata.desktop" ]] || die "SDDM metadata topilmadi: $src/metadata.desktop"

    backup_system_copy "$dest" || die "SDDM mavzusi backup qilinmadi; to'xtatildi."
    backup_system_copy "$conf" || die "SDDM config backup qilinmadi; to'xtatildi."

    sudo mkdir -p "$(dirname "$dest")" "$(dirname "$conf")"
    sudo rm -rf -- "$dest"
    sudo cp -aL -- "$src" "$dest"
    sudo chown -R root:root "$dest"
    sudo chmod -R a+rX "$dest"
    printf '[Theme]\nCurrent=victhem\n' | sudo tee "$conf" >/dev/null
    sudo chmod 644 "$conf"

    SDDM_INSTALLED=1
    log_success "SDDM mavzusi o'rnatildi: $dest"
    log_info "Qo'llash: sudo systemctl restart sddm (joriy sessiyani yopadi)"
}

install_grub_theme() {
    log_step "GRUB mavzusi o'rnatilmoqda (hycon)"
    local src="$PROJECT_DIR/assets/grub/hycon"
    local dest="$GRUB_THEME_DIR"
    local grub_default="$GRUB_DEFAULT"
    local grub_cfg="$GRUB_CFG"
    local tmp_default tmp_cfg grub_log part default_backup tmp_cfg_boot

    default_backup="$BACKUP_DIR/system/${grub_default#/}"
    tmp_cfg_boot="$(dirname "$grub_cfg")/grub.cfg.hycon"

    if ! command -v grub-mkconfig >/dev/null 2>&1; then
        log_warn "grub-mkconfig topilmadi; GRUB mavzusi o'tkazib yuborildi."
        return 0
    fi
    if ! command -v sudo >/dev/null 2>&1; then
        log_warn "sudo topilmadi; GRUB mavzusi o'tkazib yuborildi."
        return 0
    fi
    if [[ ! -f "$grub_default" ]]; then
        log_warn "$grub_default topilmadi; GRUB mavzusi o'tkazib yuborildi."
        return 0
    fi
    [[ -f "$src/theme.txt" ]] || die "GRUB theme.txt topilmadi: $src/theme.txt"
    [[ -f "$src/background.png" ]] || die "GRUB background.png topilmadi"
    [[ -d "$src/icons" ]] || die "GRUB icons papkasi topilmadi"
    for part in nw n ne w c e sw s se; do
        [[ -f "$src/menu_${part}.png" ]] || die "GRUB menu_${part}.png topilmadi"
        [[ -f "$src/terminal_${part}.png" ]] || die "GRUB terminal_${part}.png topilmadi"
    done
    for part in w c e; do
        [[ -f "$src/select_${part}.png" ]] || die "GRUB select_${part}.png topilmadi"
    done

    log_warn "GRUB mavzusi /etc/default/grub va /boot/grub/grub.cfg ni o'zgartiradi."
    log_info "Faqat GRUB_THEME yangilanadi; kernel cmdline va boot tartibi tegmaydi."

    backup_system_copy "$grub_default" || die "GRUB default backup qilinmadi; xavfsizlik uchun to'xtatildi."
    backup_system_copy "$grub_cfg" || die "grub.cfg backup qilinmadi; xavfsizlik uchun to'xtatildi."
    backup_system_copy "$dest" || true
    GRUB_DEFAULT_BACKUP="$default_backup"

    sudo mkdir -p "$(dirname "$dest")" "$(dirname "$grub_cfg")"
    sudo rm -rf -- "$dest"
    sudo cp -a -- "$src" "$dest"
    sudo chown -R root:root "$dest"
    sudo chmod -R a+rX "$dest"

    tmp_default="$(mktemp "${TMPDIR:-/tmp}/hycon-grub-default.XXXXXX")"
    tmp_cfg="$(mktemp "${TMPDIR:-/tmp}/hycon-grub.cfg.XXXXXX")"
    grub_log="$(mktemp "${TMPDIR:-/tmp}/hycon-grub-log.XXXXXX")"

    cp -- "$grub_default" "$tmp_default"
    if grep -q '^GRUB_THEME=' "$tmp_default"; then
        sed -i "s|^GRUB_THEME=.*|GRUB_THEME=\"$GRUB_THEME_PATH\"|" "$tmp_default"
    else
        printf '\nGRUB_THEME="%s"\n' "$GRUB_THEME_PATH" >> "$tmp_default"
    fi
    sudo install -m 644 -o root -g root -- "$tmp_default" "$grub_default"

    if ! sudo grub-mkconfig -o "$tmp_cfg" >"$grub_log" 2>&1; then
        log_error "grub-mkconfig xatosi:"
        cat "$grub_log" >&2
        sudo install -m 644 -o root -g root -- "$default_backup" "$grub_default" 2>/dev/null || true
        rm -f "$tmp_default" "$tmp_cfg" "$grub_log"
        return 1
    fi

    if ! grep -q 'menuentry' "$tmp_cfg" || ! grep -q 'hycon/theme.txt' "$tmp_cfg"; then
        log_error "Yangi grub.cfg tekshiruvdan o'tmadi; /etc/default/grub tiklanmoqda."
        sudo install -m 644 -o root -g root -- "$default_backup" "$grub_default" 2>/dev/null || true
        rm -f "$tmp_default" "$tmp_cfg" "$grub_log"
        return 1
    fi

    if ! sudo cp -- "$tmp_cfg" "$tmp_cfg_boot" || ! sudo mv -- "$tmp_cfg_boot" "$grub_cfg"; then
        log_error "Yangi grub.cfg o'rnatilmadi; /etc/default/grub tiklanmoqda."
        sudo rm -f -- "$tmp_cfg_boot"
        sudo install -m 644 -o root -g root -- "$default_backup" "$grub_default" 2>/dev/null || true
        rm -f "$tmp_default" "$tmp_cfg" "$grub_log"
        return 1
    fi

    rm -f "$tmp_default" "$tmp_cfg" "$grub_log"
    GRUB_INSTALLED=1
    log_success "GRUB mavzusi o'rnatildi: $dest/theme.txt"
    log_info "Qaytarish: sudo cp $default_backup $grub_default && sudo grub-mkconfig -o $grub_cfg"
}

install_system_themes() {
    if (( WITH_SDDM == 0 && WITH_GRUB == 0 )); then
        log_info "Tizim mavzulari o'tkazib yuborildi. Qo'shish: $0 --with-sddm --with-grub"
        return 0
    fi

    log_step "Tizim mavzulari o'rnatilmoqda"
    log_info "Tizim backup: $BACKUP_DIR/system"
    if (( WITH_SDDM == 1 )); then
        install_sddm_theme
    fi
    if (( WITH_GRUB == 1 )); then
        install_grub_theme || die "GRUB mavzusi o'rnatilmadi; /boot/grub/grub.cfg o'zgartirilmadi."
    fi
}

validate_install() {
    log_step "O'rnatilgan config tekshirilmoqda"
    local hypr_config="$TARGET/hypr/hyprland.lua"
    local log_file

    [[ -f "$hypr_config" ]] || die "Hyprland config topilmadi: $hypr_config"

    log_file="$(mktemp "${TMPDIR:-/tmp}/hycon-install-verify.XXXXXX")"
    TMP_LOG="$log_file"

    if env -u HYPRLAND_INSTANCE_SIGNATURE \
        "HYPRLAND_CONFIG=$hypr_config" \
        "HYCON_DIR=$TARGET" \
        "HYCON_THEME=macos" \
        "XDG_CONFIG_HOME=$TARGET" \
        Hyprland --config "$hypr_config" --verify-config >"$log_file" 2>&1; then
        log_success "Hyprland config sintaksisi to'g'ri"
    else
        log_error "Hyprland config xatosi:"
        cat "$log_file" >&2
        exit 1
    fi

    if command -v rofi >/dev/null 2>&1; then
        local theme
        for theme in picker emoji menu; do
            if rofi -config "$TARGET/themes/macos/rofi/$theme.rasi" -dump-config >/dev/null 2>&1; then
                log_success "Rofi theme OK: $theme.rasi"
            else
                log_error "Rofi theme xatosi: $theme.rasi"
                exit 1
            fi
        done
    fi
}

print_summary() {
    echo
    log_success "O'rnatish muvaffaqiyatli tugadi"
    echo -e "${DIM}Config:${RESET}   $TARGET"
    echo -e "${DIM}Backup:${RESET}   $BACKUP_DIR"
    echo -e "${DIM}Hyprland:${RESET} $TARGET/hypr/hyprland.lua"
    echo -e "${DIM}Theme:${RESET}    $TARGET/themes/macos (dark)"
    if (( SDDM_INSTALLED == 1 )); then
        echo -e "${DIM}SDDM:${RESET}     victhem ($SDDM_THEME_DIR)"
    fi
    if (( GRUB_INSTALLED == 1 )); then
        echo -e "${DIM}GRUB:${RESET}     hycon ($GRUB_THEME_DIR)"
    fi
    echo
    log_warn "Yangi config faollashishi uchun sessiyadan chiqib, qayta kiring."
    log_info "Dark/light almashtirish: $TARGET/themes/macos/switch.sh light"
    log_info "Nested test: $PROJECT_DIR/runner.sh verify"
    if (( GRUB_INSTALLED == 1 )); then
        log_info "GRUB rollback: sudo cp ${GRUB_DEFAULT_BACKUP:-$BACKUP_DIR/system/etc/default/grub} $GRUB_DEFAULT && sudo grub-mkconfig -o $GRUB_CFG"
    fi
    if (( SDDM_INSTALLED == 1 )); then
        log_info "SDDM restart: sudo systemctl restart sddm (joriy sessiyani yopadi)"
    fi

    if [[ -n "${HYPRLAND_CONFIG:-}" && "$HYPRLAND_CONFIG" != "$TARGET/hypr/hyprland.lua" ]]; then
        log_warn "Joriy sessiyada HYPRLAND_CONFIG=$HYPRLAND_CONFIG"
        log_warn "Qayta login qilmaguncha eski config ishlaydi."
    fi
}

check_project_files
check_commands
check_fonts
check_themes
confirm_install
backup_old_config
install_configs
apply_theme
configure_uwsm_env
validate_install
install_system_themes
print_summary
