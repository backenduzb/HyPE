#!/usr/bin/env bash

BOLD='\033[1m'
DIM='\033[2m'
UNDERLINE='\033[4m'
RESET='\033[0m'

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

B_RED='\033[1;31m'
B_GREEN='\033[1;32m'
B_YELLOW='\033[1;33m'
B_BLUE='\033[1;34m'
B_MAGENTA='\033[1;35m'
B_CYAN='\033[1;36m'
B_WHITE='\033[1;37m'

log_info()    { echo -e "${B_BLUE}[INFO]${RESET} $1"; }
log_success() { echo -e "${B_GREEN}[SUCCESS]${RESET} $1"; }
log_warn()    { echo -e "${B_YELLOW}[WARNING]${RESET} $1"; }
log_error()   { echo -e "${B_RED}[ERROR]${RESET} $1"; }
log_step()    { echo -e "${B_CYAN}==>${RESET} ${BOLD}$1${RESET}"; }

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$PROJECT_DIR/hypr/hyprland.lua"
LOG_FILE="$PROJECT_DIR/hyprland_debug.log"
PARENT_HYPRLAND_SIG="${HYPRLAND_INSTANCE_SIGNATURE:-}"
NESTED_LAUNCHER_PID=""
TAIL_PID=""
DEBUG_HOME=""
SESSION_STARTED=0
PARENT_UNBOUND_BINDS=()
NESTED_HYPRLAND_SIG=""
INSTANCES_BEFORE=""

print_header() {
    clear
    echo -e "${B_MAGENTA}"
    echo "=================================================="
    echo "       HYPRLAND CONFIG RUNNER & DEBUGGER          "
    echo "=================================================="
    echo -e "${RESET}"
    echo -e "${DIM}Loyiha papkasi :${RESET} ${CYAN}$PROJECT_DIR${RESET}"
    echo -e "${DIM}Config fayli   :${RESET} ${CYAN}$CONFIG_FILE${RESET}"
    echo -e "${DIM}Config manbasi :${RESET} ${CYAN}$PROJECT_DIR${RESET} ${DIM}(waybar/dunst/kitty/... symlink)${RESET}"
    echo -e "${DIM}Izolyatsiya    :${RESET} ${CYAN}vaqtinchalik HOME + XDG${RESET}"
    echo -e "${DIM}Debug hajmi    :${RESET} ${CYAN}1920x1080${RESET}"
    echo ""
}

check_config_exists() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Config fayli topilmadi: ${UNDERLINE}$CONFIG_FILE${RESET}"
        log_info "Papka ichida ${YELLOW}hyprland.lua${RESET} fayli borligiga ishonch hosil qiling."
        exit 1
    fi
}

verify_config() {
    log_step "Hyprland konfiguratsiyasi tekshirilmoqda..."
    echo -e "${DIM}--------------------------------------------------${RESET}"
    
    if env -u HYPRLAND_INSTANCE_SIGNATURE \
        "HYPRLAND_CONFIG=$CONFIG_FILE" \
        "HYCON_DIR=$PROJECT_DIR" \
        "HYCON_NESTED=1" \
        "XDG_CONFIG_HOME=$PROJECT_DIR" \
        Hyprland --config "$CONFIG_FILE" --verify-config; then
        echo -e "${DIM}--------------------------------------------------${RESET}"
        log_success "Config sintaksisi to'g'ri! Hech qanday xatolik topilmadi."
    else
        echo -e "${DIM}--------------------------------------------------${RESET}"
        log_error "Config faylingizda sintaktik xatoliklar mavjud!"
        exit 1
    fi
}

check_waybar_dispatch_compat() {
    local waybar_bin
    waybar_bin="$(command -v waybar 2>/dev/null)" || return 0

    if ! grep -aq 'hl\.dsp\.focus' "$waybar_bin"; then
        log_warn "Waybar bu build'da Hyprland Lua dispatch qo'llab-quvvatlanmaydi."
        log_warn "Workspace tugmalari bosilganda workspace o'zgarmaydi (upstream waybar bug)."
        log_warn "Yechim: waybar-git yoki Lua dispatch patch'i qo'llangan build ishlating."
    fi
}

parent_modmask_to_mods() {
    local mask="$1"
    local -a mods=()
    (( mask & 1 )) && mods+=("SHIFT")
    (( mask & 4 )) && mods+=("CTRL")
    (( mask & 8 )) && mods+=("ALT")
    (( mask & 64 )) && mods+=("SUPER")
    (( mask & 128 )) && mods+=("MOD5")
    local IFS="+"
    printf '%s' "${mods[*]}"
}

find_nested_instance() {
    local before="$1" now sig
    [[ -n "$before" ]] || return 1
    command -v hyprctl >/dev/null 2>&1 || return 1
    command -v jq >/dev/null 2>&1 || return 1

    for _ in $(seq 1 20); do
        now=$(hyprctl instances -j 2>/dev/null | jq -r '.[].instance' 2>/dev/null) || now=""
        while IFS= read -r sig; do
            [[ -n "$sig" ]] || continue
            if ! grep -qxF "$sig" <<<"$before"; then
                NESTED_HYPRLAND_SIG="$sig"
                return 0
            fi
        done <<<"$now"
        sleep 0.25
    done
    return 1
}

wait_for_nested_binds() {
    local sig="$1" prev=-1 cur i
    [[ -n "$sig" ]] || return 1
    for i in $(seq 1 40); do
        cur=$(HYPRLAND_INSTANCE_SIGNATURE="$sig" hyprctl binds -j 2>/dev/null | jq 'length' 2>/dev/null) || cur=""
        if [[ -n "$cur" && "$cur" -gt 0 && "$cur" == "$prev" ]]; then
            return 0
        fi
        prev="$cur"
        sleep 0.25
    done
    return 0
}

disable_parent_conflicts() {
    [[ -n "$PARENT_HYPRLAND_SIG" ]] || return 0
    [[ -n "$NESTED_HYPRLAND_SIG" ]] || {
        log_warn "Nested Hyprland instance aniqlanmadi: parent bindlar o'chirilmadi."
        return 0
    }
    command -v hyprctl >/dev/null 2>&1 || return 0
    command -v jq >/dev/null 2>&1 || return 0

    local parent_binds nested_binds
    parent_binds=$(HYPRLAND_INSTANCE_SIGNATURE="$PARENT_HYPRLAND_SIG" hyprctl binds -j 2>/dev/null) || return 0
    nested_binds=$(HYPRLAND_INSTANCE_SIGNATURE="$NESTED_HYPRLAND_SIG" hyprctl binds -j 2>/dev/null) || return 0

    HYPRLAND_INSTANCE_SIGNATURE="$PARENT_HYPRLAND_SIG" hyprctl keyword submap reset >/dev/null 2>&1 || true

    local nested_mask nested_key nested_submap
    local parent_mask parent_key parent_desc parent_dispatcher parent_arg parent_submap
    local parent_locked parent_release parent_repeat parent_nonconsuming parent_mouse parent_longpress parent_hasdesc parent_universal
    local mods_str flags payload seen_key bind_key combo_key
    local -A seen=() seen_bind=() seen_combo=()

    while IFS=$'\x1f' read -r nested_mask nested_key nested_submap; do
        [[ "$nested_submap" == "" ]] || continue
        [[ -n "$nested_key" ]] || continue
        seen_key="${nested_mask}:${nested_key,,}"
        [[ -z "${seen[$seen_key]:-}" ]] || continue
        seen["$seen_key"]=1

        while IFS=$'\x1f' read -r parent_mask parent_key parent_desc parent_dispatcher parent_arg parent_submap parent_locked parent_release parent_repeat parent_nonconsuming parent_mouse parent_longpress parent_hasdesc parent_universal; do
            [[ "$parent_submap" == "" ]] || continue
            [[ -n "$parent_key" ]] || continue
            [[ "$parent_mask" == "$nested_mask" ]] || continue
            [[ "${parent_key,,}" == "${nested_key,,}" ]] || continue

            mods_str=$(parent_modmask_to_mods "$parent_mask")
            flags=""
            [[ "$parent_locked" == "true" ]] && flags+="l"
            [[ "$parent_release" == "true" ]] && flags+="r"
            [[ "$parent_repeat" == "true" ]] && flags+="e"
            [[ "$parent_nonconsuming" == "true" ]] && flags+="n"
            [[ "$parent_mouse" == "true" ]] && flags+="m"
            [[ "$parent_longpress" == "true" ]] && flags+="o"
            [[ "$parent_universal" == "true" ]] && flags+="u"

            payload="$mods_str"$'\x1f'"$parent_key"$'\x1f'"$parent_desc"$'\x1f'"$parent_dispatcher"$'\x1f'"$parent_arg"$'\x1f'"$flags"$'\x1f'"$parent_hasdesc"
            bind_key="$payload"
            combo_key="${mods_str,,}:${parent_key,,}"

            if [[ -z "${seen_bind[$bind_key]:-}" ]]; then
                seen_bind["$bind_key"]=1
                PARENT_UNBOUND_BINDS+=("$payload")
            fi

            if [[ -z "${seen_combo[$combo_key]:-}" ]]; then
                seen_combo["$combo_key"]=1
                HYPRLAND_INSTANCE_SIGNATURE="$PARENT_HYPRLAND_SIG" hyprctl keyword unbind "$mods_str, $parent_key" >/dev/null 2>&1 || true
                log_info "Parent bind vaqtincha o'chirildi: ${CYAN}${mods_str}+${parent_key}${RESET}"
            fi
        done < <(jq -r '.[] | [.modmask,.key,.description,.dispatcher,.arg,.submap,(.locked|tostring),(.release|tostring),(.repeat|tostring),(.non_consuming|tostring),(.mouse|tostring),(.longPress|tostring),(.has_description|tostring),(.submap_universal|tostring)] | join("\u001f")' <<<"$parent_binds")
    done < <(jq -r '.[] | select(.submap=="") | [.modmask,.key,.submap] | join("\u001f")' <<<"$nested_binds")

    if (( ${#PARENT_UNBOUND_BINDS[@]} > 0 )); then
        log_info "Debug session tugagach parent bindlar qayta tiklanadi."
    fi
}

restore_parent_binds() {
    (( ${#PARENT_UNBOUND_BINDS[@]} > 0 )) || return 0
    [[ -n "$PARENT_HYPRLAND_SIG" ]] || return 0

    HYPRLAND_INSTANCE_SIGNATURE="$PARENT_HYPRLAND_SIG" hyprctl keyword submap reset >/dev/null 2>&1 || true

    local payload mods key desc dispatcher arg flags hasdesc keyword line
    local -A restored=()
    for payload in "${PARENT_UNBOUND_BINDS[@]}"; do
        [[ -z "${restored[$payload]:-}" ]] || continue
        restored["$payload"]=1
        IFS=$'\x1f' read -r mods key desc dispatcher arg flags hasdesc <<<"$payload"
        if [[ "$hasdesc" == "true" ]]; then
            flags+="d"
            keyword="bind${flags}"
            line="$mods, $key, $desc, $dispatcher, $arg"
        else
            keyword="bind${flags}"
            line="$mods, $key, $dispatcher, $arg"
        fi
        HYPRLAND_INSTANCE_SIGNATURE="$PARENT_HYPRLAND_SIG" hyprctl keyword "$keyword" "$line" >/dev/null 2>&1 \
            || log_warn "Parent bind qayta tiklanmadi: ${mods}+${key} (hyprctl reload qiling)"
    done
    PARENT_UNBOUND_BINDS=()
}

reload_parent_hyprland() {
    [[ "$SESSION_STARTED" == "1" ]] || return 0
    SESSION_STARTED=0
    [[ -n "$PARENT_HYPRLAND_SIG" ]] || return 0

    if HYPRLAND_INSTANCE_SIGNATURE="$PARENT_HYPRLAND_SIG" hyprctl reload >/dev/null 2>&1; then
        log_info "System Hyprland reload qilindi: parent bindlar tozalandi."
    else
        log_warn "System Hyprland reload qilinmadi. Qo'lda: hyprctl reload"
    fi
}

cleanup() {
    restore_parent_binds
    if [[ -n "${TAIL_PID:-}" ]] && kill -0 "$TAIL_PID" 2>/dev/null; then
        kill "$TAIL_PID" 2>/dev/null
    fi
    if [[ -n "${NESTED_LAUNCHER_PID:-}" ]] && kill -0 "$NESTED_LAUNCHER_PID" 2>/dev/null; then
        pkill -TERM -P "$NESTED_LAUNCHER_PID" 2>/dev/null
        kill "$NESTED_LAUNCHER_PID" 2>/dev/null
    fi
    if [[ -n "${DEBUG_HOME:-}" && -d "$DEBUG_HOME" ]]; then
        rm -rf -- "$DEBUG_HOME"
    fi
    reload_parent_hyprland
}

prepare_debug_home() {
    DEBUG_HOME="$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/hycon-debug-home.XXXXXX")" || {
        log_error "Vaqtinchalik debug home yaratib bo'lmadi."
        exit 1
    }
    mkdir -p \
        "$DEBUG_HOME/.config" \
        "$DEBUG_HOME/.config-dirs" \
        "$DEBUG_HOME/.local/share" \
        "$DEBUG_HOME/.local/state" \
        "$DEBUG_HOME/.cache"

    local cfg
    for cfg in waybar dunst kitty wofi rofi hypr hypridle; do
        if [[ -e "$PROJECT_DIR/$cfg" ]]; then
            ln -s "$PROJECT_DIR/$cfg" "$DEBUG_HOME/.config/$cfg"
        fi
    done

    if [[ -d "$PROJECT_DIR/vim" ]]; then
        mkdir -p "$DEBUG_HOME/.vim"
        local vimfile
        for vimfile in settings.vim plugins.vim keymaps.vim nerdtree.vim airline.vim theme.vim coc-settings.json; do
            if [[ -e "$PROJECT_DIR/vim/$vimfile" ]]; then
                ln -s "$PROJECT_DIR/vim/$vimfile" "$DEBUG_HOME/.vim/$vimfile"
            fi
        done
        [[ -d "$PROJECT_DIR/vim/autoload" ]] && ln -s "$PROJECT_DIR/vim/autoload" "$DEBUG_HOME/.vim/autoload"
        [[ -d "$HOME/.vim/plugged" ]] && ln -s "$HOME/.vim/plugged" "$DEBUG_HOME/.vim/plugged"
        [[ -f "$PROJECT_DIR/vim/vimrc" ]] && ln -s "$PROJECT_DIR/vim/vimrc" "$DEBUG_HOME/.vimrc"
    fi
}

launch_hyprland() {
    local debug_mode="$1"
    prepare_debug_home
    local -a env_args=(
        -u HYPRLAND_INSTANCE_SIGNATURE
        -u HYPRLAND_CMD
        -u KITTY_PID
        -u KITTY_WINDOW_ID
        -u KITTY_PUBLIC_KEY
        -u KITTY_CONFIG_DIRECTORY
        -u ROFI_CONFIG
        -u WOFI_CONFIG
        -u WOFI_STYLE
        "HOME=$DEBUG_HOME"
        "HYPRLAND_CONFIG=$CONFIG_FILE"
        "HYCON_DIR=$PROJECT_DIR"
        "HYCON_NESTED=1"
        "XDG_CONFIG_HOME=$DEBUG_HOME/.config"
        "XDG_CONFIG_DIRS=$DEBUG_HOME/.config-dirs"
        "XDG_DATA_HOME=$DEBUG_HOME/.local/share"
        "XDG_CACHE_HOME=$DEBUG_HOME/.cache"
        "XDG_STATE_HOME=$DEBUG_HOME/.local/state"
    )
    local -a hypr_cmd=(Hyprland -c "$CONFIG_FILE")

    if [[ "$debug_mode" == "1" ]]; then
        env_args+=("HYCON_DEBUG=1" "HYPRLAND_LOG_WLR=1")
    fi

    if command -v dbus-run-session >/dev/null 2>&1; then
        hypr_cmd=(dbus-run-session -- env "${env_args[@]}" "${hypr_cmd[@]}")
    else
        hypr_cmd=(env "${env_args[@]}" "${hypr_cmd[@]}")
        log_warn "dbus-run-session topilmadi: dunst/mako system instance bilan to'qnashishi mumkin."
    fi

    if [[ "$debug_mode" == "1" ]]; then
        : > "$LOG_FILE"
        "${hypr_cmd[@]}" > "$LOG_FILE" 2>&1 &
        NESTED_LAUNCHER_PID=$!
        tail -n +1 -f "$LOG_FILE" &
        TAIL_PID=$!
    else
        "${hypr_cmd[@]}" &
        NESTED_LAUNCHER_PID=$!
    fi
    SESSION_STARTED=1
}

wait_for_nested_window() {
    local parent_sig="$1"
    [[ -n "$parent_sig" ]] || return 1

    if ! command -v hyprctl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
        log_warn "hyprctl yoki jq topilmadi: oyna hajmini avtomatik sozlab bo'lmadi."
        return 1
    fi

    local before now addr="" a i size=""
    before=$(HYPRLAND_INSTANCE_SIGNATURE="$parent_sig" hyprctl clients -j 2>/dev/null \
        | jq -r '.[] | select(.class == "aquamarine") | .address' | sort)

    for i in $(seq 1 80); do
        sleep 0.25
        now=$(HYPRLAND_INSTANCE_SIGNATURE="$parent_sig" hyprctl clients -j 2>/dev/null \
            | jq -r '.[] | select(.class == "aquamarine") | .address' 2>/dev/null)
        while IFS= read -r a; do
            [[ -z "$a" ]] && continue
            if ! grep -qxF "$a" <<<"$before"; then
                addr="$a"
                break 2
            fi
        done <<<"$now"
    done

    [[ -n "$addr" ]] || return 1

    HYPRLAND_INSTANCE_SIGNATURE="$parent_sig" hyprctl dispatch focuswindow "address:$addr" >/dev/null 2>&1
    sleep 0.2
    HYPRLAND_INSTANCE_SIGNATURE="$parent_sig" hyprctl dispatch fullscreen 0 >/dev/null 2>&1
    sleep 0.3
    HYPRLAND_INSTANCE_SIGNATURE="$parent_sig" hyprctl dispatch focuswindow "address:$addr" >/dev/null 2>&1
    sleep 0.2

    size=$(HYPRLAND_INSTANCE_SIGNATURE="$parent_sig" hyprctl clients -j 2>/dev/null \
        | jq -r --arg a "$addr" '.[] | select(.address == $a) | "\(.size[0])x\(.size[1])"')

    if [[ "$size" == "1920x1080" ]]; then
        log_success "Nested oyna 1920x1080 rejimiga moslandi."
    else
        log_warn "Nested oyna hajmi: ${size:-nomalum} (1920x1080 kutilgan edi)."
    fi

    return 0
}

cleanup_stale_instances() {
    command -v pgrep >/dev/null 2>&1 || return 0

    local parent_pid=""
    if [[ -n "$PARENT_HYPRLAND_SIG" ]] && command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
        parent_pid=$(hyprctl instances -j 2>/dev/null \
            | jq -r --arg sig "$PARENT_HYPRLAND_SIG" '.[] | select(.instance == $sig) | .pid' 2>/dev/null \
            | head -n1)
    fi

    local -A ancestors=()
    local p=$$
    while [[ -n "$p" && "$p" != "0" ]]; do
        ancestors["$p"]=1
        p=$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ')
    done

    local -a stale=()
    local pid cmdline
    while IFS= read -r pid; do
        [[ -n "$pid" ]] || continue
        [[ -n "${ancestors[$pid]:-}" ]] && continue
        [[ "$pid" == "$parent_pid" ]] && continue
        [[ "$pid" == "${NESTED_LAUNCHER_PID:-}" ]] && continue
        cmdline=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null) || continue
        [[ "$cmdline" == *"$CONFIG_FILE"* ]] || continue
        stale+=("$pid")
    done < <(pgrep -x Hyprland 2>/dev/null)

    (( ${#stale[@]} > 0 )) || return 0

    log_step "Eski Hyprland debug sessiyalari tozalanmoqda..."
    for pid in "${stale[@]}"; do
        log_info "To'xtatilmoqda: ${CYAN}PID $pid${RESET}"
        kill -TERM "$pid" 2>/dev/null || true
    done

    local i alive
    for i in $(seq 1 20); do
        alive=0
        for pid in "${stale[@]}"; do
            kill -0 "$pid" 2>/dev/null && alive=1
        done
        (( alive == 0 )) && break
        sleep 0.25
    done

    for pid in "${stale[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            log_warn "Majburiy to'xtatilmoqda: ${CYAN}PID $pid${RESET}"
            kill -KILL "$pid" 2>/dev/null || true
        fi
    done
}

run_session() {
    local debug_mode="$1"

    check_waybar_dispatch_compat
    cleanup_stale_instances
    if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
        INSTANCES_BEFORE=$(hyprctl instances -j 2>/dev/null | jq -r '.[].instance' 2>/dev/null) || INSTANCES_BEFORE=""
    fi
    launch_hyprland "$debug_mode"
    log_info "Nested Hyprland jarayoni: ${CYAN}$NESTED_LAUNCHER_PID${RESET}"
    log_info "Izolyatsiya qilingan HOME: ${CYAN}$DEBUG_HOME${RESET}"

    if [[ -n "$PARENT_HYPRLAND_SIG" ]]; then
        log_info "Nested oyna 1920x1080 ga moslanmoqda..."
        wait_for_nested_window "$PARENT_HYPRLAND_SIG" \
            || log_warn "Parent Hyprland oynasi topilmadi: hajmni qo'lda 1920x1080 qiling."

        if find_nested_instance "$INSTANCES_BEFORE"; then
            log_info "Nested Hyprland instance: ${CYAN}$NESTED_HYPRLAND_SIG${RESET}"
            wait_for_nested_binds "$NESTED_HYPRLAND_SIG"
        else
            log_warn "Nested Hyprland instance topilmadi: parent bindlar avtomatik o'chirilmaydi."
        fi
    else
        log_warn "Parent Hyprland aniqlanmadi: oynani 1920x1080 ga qo'lda moslang."
    fi

    disable_parent_conflicts

    wait "$NESTED_LAUNCHER_PID"
    local status=$?
    NESTED_LAUNCHER_PID=""

    if [[ -n "${TAIL_PID:-}" ]]; then
        kill "$TAIL_PID" 2>/dev/null
        wait "$TAIL_PID" 2>/dev/null
        TAIL_PID=""
    fi

    return "$status"
}

run_nested() {
    verify_config
    echo ""
    log_step "Hyprland Nested rejimda ishga tushirilmoqda..."
    log_info "Faqat loyiha configlari ishlatiladi: ${CYAN}$PROJECT_DIR${RESET}"
    log_info "Chiqish uchun ulanayotgan oynani yoping yoki terminalda ${B_YELLOW}Ctrl + C${RESET} bosing."
    echo -e "${DIM}--------------------------------------------------${RESET}"

    run_session 0
}

run_debug() {
    verify_config
    echo ""
    log_step "Hyprland Debug rejimida ishga tushirilmoqda..."
    log_warn "Loglar ushbu faylga yozilmoqda: ${CYAN}$LOG_FILE${RESET}"
    log_info "Faqat loyiha configlari ishlatiladi: ${CYAN}$PROJECT_DIR${RESET}"
    echo -e "${DIM}--------------------------------------------------${RESET}"

    run_session 1
}

trap cleanup EXIT INT TERM

show_menu() {
    print_header
    echo -e "${BOLD}Bajariladigan amalni tanlang:${RESET}"
    echo -e "  ${B_GREEN}1)${RESET} Config'ni tekshirish (${CYAN}--verify-config${RESET})"
    echo -e "  ${B_GREEN}2)${RESET} Nested rejimda ishga tushirish (${CYAN}Run Nested Window${RESET})"
    echo -e "  ${B_GREEN}3)${RESET} Debug rejimida loglar bilan ishga tushirish (${CYAN}Debug & Log to File${RESET})"
    echo -e "  ${B_RED}q)${RESET} Chiqish"
    echo ""
    read -p "Tanlovingiz [1-3 yoki q]: " choice

    case "$choice" in
        1)
            clear
            print_header
            verify_config
            ;;
        2)
            clear
            print_header
            run_nested
            ;;
        3)
            clear
            print_header
            run_debug
            ;;
        q|Q)
            log_info "Chiqilmoqda..."
            exit 0
            ;;
        *)
            log_error "Noto'g'ri tanlov!"
            exit 1
            ;;
    esac
}

check_config_exists

case "$1" in
    verify|--verify)
        verify_config
        ;;
    run|--run)
        run_nested
        ;;
    debug|--debug)
        run_debug
        ;;
    *)
        show_menu
        ;;
esac