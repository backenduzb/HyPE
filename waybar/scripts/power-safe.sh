#!/usr/bin/env bash

# Hycon Power Safe mode
# - Verifies TLP status
# - Limits the CPU with cpupower (default: 1.5 GHz)
# - Disables boost / sets power-friendly EPP
# - Puts the NVIDIA dGPU into runtime power management
#
# Settings: waybar/power-safe.conf (or environment variables).
# Waybar: left click = toggle, right click = show details.

set -uo pipefail

CONFIG_HOME="${HYCON_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}}"
CONFIG_FILE="${HYCON_POWERSAFE_CONFIG:-$CONFIG_HOME/waybar/power-safe.conf}"

HYCON_POWERSAFE_MAX_FREQ="${HYCON_POWERSAFE_MAX_FREQ:-1.5GHz}"
HYCON_POWERSAFE_MIN_FREQ="${HYCON_POWERSAFE_MIN_FREQ:-400MHz}"
HYCON_POWERSAFE_GOVERNOR="${HYCON_POWERSAFE_GOVERNOR:-powersave}"
HYCON_POWERSAFE_EPP="${HYCON_POWERSAFE_EPP:-power}"
HYCON_POWERSAFE_BOOST="${HYCON_POWERSAFE_BOOST:-0}"
HYCON_POWERSAFE_PLATFORM_PROFILE="${HYCON_POWERSAFE_PLATFORM_PROFILE:-quiet}"
HYCON_POWERSAFE_TLP="${HYCON_POWERSAFE_TLP:-1}"
HYCON_POWERSAFE_START_TLP="${HYCON_POWERSAFE_START_TLP:-1}"
HYCON_POWERSAFE_GPU_PM="${HYCON_POWERSAFE_GPU_PM:-auto}"
HYCON_POWERSAFE_DISPLAY="${HYCON_POWERSAFE_DISPLAY:-1}"
HYCON_POWERSAFE_REFRESH_ON="${HYCON_POWERSAFE_REFRESH_ON:-60}"
HYCON_POWERSAFE_REFRESH_OFF="${HYCON_POWERSAFE_REFRESH_OFF:-max}"
HYCON_POWERSAFE_NOTIFY="${HYCON_POWERSAFE_NOTIFY:-1}"
HYCON_POWERSAFE_REFRESH_SIGNAL="${HYCON_POWERSAFE_REFRESH_SIGNAL:-9}"

if [[ -r "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
fi

STATE_FILE="${HYCON_POWERSAFE_STATE:-${XDG_RUNTIME_DIR:-/tmp}/hycon-power-safe}"
LOCK_FILE="${HYCON_POWERSAFE_LOCK:-${XDG_RUNTIME_DIR:-/tmp}/hycon-power-safe.lock}"

MAX_FREQ="$HYCON_POWERSAFE_MAX_FREQ"
MIN_FREQ="$HYCON_POWERSAFE_MIN_FREQ"
GOVERNOR="$HYCON_POWERSAFE_GOVERNOR"
EPP="$HYCON_POWERSAFE_EPP"
BOOST="$HYCON_POWERSAFE_BOOST"
PROFILE="$HYCON_POWERSAFE_PLATFORM_PROFILE"
USE_TLP="$HYCON_POWERSAFE_TLP"
START_TLP="$HYCON_POWERSAFE_START_TLP"
GPU_PM="$HYCON_POWERSAFE_GPU_PM"
DISPLAY_ENABLED="$HYCON_POWERSAFE_DISPLAY"
REFRESH_ON="$HYCON_POWERSAFE_REFRESH_ON"
REFRESH_OFF="$HYCON_POWERSAFE_REFRESH_OFF"
NOTIFY="$HYCON_POWERSAFE_NOTIFY"
REFRESH_SIGNAL="$HYCON_POWERSAFE_REFRESH_SIGNAL"

notify() {
    [[ "$NOTIFY" == "1" ]] || return 0
    command -v notify-send >/dev/null 2>&1 || return 0
    notify-send -a "Hycon Power Safe" "$1" "$2" 2>/dev/null || true
}

refresh_waybar() {
    [[ "$REFRESH_SIGNAL" =~ ^[0-9]+$ ]] || return 0
    pkill -RTMIN+"$REFRESH_SIGNAL" waybar 2>/dev/null || true
}

acquire_lock() {
    command -v flock >/dev/null 2>&1 || return 0
    exec 9>"$LOCK_FILE" || return 0
    if ! flock -n 9; then
        notify "Power Safe" "Another Power Safe operation is already running."
        return 1
    fi
    return 0
}

monitor_rows() {
    command -v hyprctl >/dev/null 2>&1 || return 1
    command -v jq >/dev/null 2>&1 || return 1
    hyprctl monitors -j 2>/dev/null | jq -r '
        .[] | [
            .name,
            (.width | tostring),
            (.height | tostring),
            (.refreshRate | tostring),
            (.x | tostring),
            (.y | tostring),
            (.scale | tostring),
            (.availableModes | join(","))
        ] | @tsv
    ' 2>/dev/null
}

pick_mode() {
    local width="$1" height="$2" target="$3" mode r diff best="" bestdiff=""
    local -a modes=()
    IFS=',' read -r -a modes <<< "$4"

    for mode in "${modes[@]}"; do
        [[ "$mode" =~ ^([0-9]+)x([0-9]+)@([0-9.]+)Hz$ ]] || continue
        [[ "${BASH_REMATCH[1]}" == "$width" ]] || continue
        [[ "${BASH_REMATCH[2]}" == "$height" ]] || continue
        r="${BASH_REMATCH[3]}"
        diff="$(awk -v a="$r" -v b="$target" 'BEGIN { d = a - b; if (d < 0) d = -d; printf "%.6f", d }')"
        if [[ -z "$best" ]] || awk -v a="$diff" -v b="$bestdiff" 'BEGIN { exit !(a < b) }'; then
            best="$mode"
            bestdiff="$diff"
        fi
    done

    printf '%s' "$best"
}

pick_max_mode() {
    local width="$1" height="$2" mode r best="" bestr=""
    local -a modes=()
    IFS=',' read -r -a modes <<< "$3"

    for mode in "${modes[@]}"; do
        [[ "$mode" =~ ^([0-9]+)x([0-9]+)@([0-9.]+)Hz$ ]] || continue
        [[ "${BASH_REMATCH[1]}" == "$width" ]] || continue
        [[ "${BASH_REMATCH[2]}" == "$height" ]] || continue
        r="${BASH_REMATCH[3]}"
        if [[ -z "$best" ]] || awk -v a="$r" -v b="$bestr" 'BEGIN { exit !(a > b) }'; then
            best="$mode"
            bestr="$r"
        fi
    done

    printf '%s' "$best"
}

apply_monitor_mode() {
    local name="$1" mode="$2" x="$3" y="$4" scale="$5"

    [[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] || return 1
    [[ "$mode" =~ ^[0-9]+x[0-9]+@[0-9.]+Hz$ ]] || return 1
    [[ "$x" =~ ^-?[0-9]+$ && "$y" =~ ^-?[0-9]+$ ]] || return 1
    [[ "$scale" =~ ^[0-9]+([.][0-9]+)?$ ]] || return 1

    hyprctl eval "hl.monitor({ output = \"$name\", mode = \"$mode\", position = \"${x}x${y}\", scale = $scale })" >/dev/null 2>&1
}

set_refresh_rate() {
    local target="$1" name width height refresh x y scale modes mode applied=0

    [[ "$DISPLAY_ENABLED" == "1" ]] || return 0
    command -v hyprctl >/dev/null 2>&1 || return 1
    command -v jq >/dev/null 2>&1 || return 1

    while IFS=$'\t' read -r name width height refresh x y scale modes; do
        [[ -n "$name" ]] || continue
        if [[ "$target" == "max" ]]; then
            mode="$(pick_max_mode "$width" "$height" "$modes")"
        else
            mode="$(pick_mode "$width" "$height" "$target" "$modes")"
        fi
        [[ -n "$mode" ]] || continue
        if apply_monitor_mode "$name" "$mode" "$x" "$y" "$scale"; then
            applied=$((applied + 1))
        fi
    done < <(monitor_rows)

    (( applied > 0 ))
}

display_summary() {
    local name width height refresh sep=""

    if ! command -v hyprctl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
        printf 'unavailable'
        return 0
    fi

    while IFS=$'\t' read -r name width height refresh _ _ _ _; do
        [[ -n "$name" ]] || continue
        printf '%s%s %sx%s@%sHz' "$sep" "$name" "$width" "$height" "$refresh"
        sep=", "
    done < <(monitor_rows)

    [[ -n "$sep" ]] || printf 'none'
}

display_is_power_safe() {
    command -v hyprctl >/dev/null 2>&1 || return 0
    command -v jq >/dev/null 2>&1 || return 0
    hyprctl monitors -j 2>/dev/null | jq -e 'length > 0 and all(.[]; .refreshRate <= 65)' >/dev/null 2>&1
}

run_root() {
    local askpass="${HYCON_POWERSAFE_ASKPASS:-$CONFIG_HOME/waybar/scripts/askpass.sh}"

    if (( EUID == 0 )); then
        "$@"
        return $?
    fi
    if sudo -n true 2>/dev/null; then
        sudo -n "$@"
        return $?
    fi
    if command -v sudo >/dev/null 2>&1 \
        && [[ -x "$askpass" ]] \
        && [[ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]]; then
        SUDO_ASKPASS="$askpass" sudo -A "$@"
        return $?
    fi
    if command -v pkexec >/dev/null 2>&1 && [[ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]]; then
        pkexec "$@"
        return $?
    fi
    return 1
}

read_sys() {
    [[ -r "$1" ]] && cat "$1" 2>/dev/null || printf ''
}

human_freq() {
    local khz="${1:-}"
    if [[ "$khz" =~ ^[0-9]+$ ]]; then
        if (( khz >= 1000000 )); then
            printf '%d.%02d GHz' "$((khz / 1000000))" "$(((khz % 1000000) / 10000))"
        else
            printf '%d MHz' "$((khz / 1000))"
        fi
    else
        printf '%s' "${khz:-N/A}"
    fi
}

power_source() {
    local f
    for f in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
        [[ -r "$f" ]] || continue
        if [[ "$(cat "$f" 2>/dev/null)" == "1" ]]; then
            printf 'AC'
        else
            printf 'battery'
        fi
        return 0
    done
    printf 'unknown'
}

tlp_active() {
    if command -v systemctl >/dev/null 2>&1; then
        systemctl is-active --quiet tlp 2>/dev/null && return 0
    fi
    if command -v tlp-stat >/dev/null 2>&1; then
        tlp-stat -s 2>/dev/null | grep -Eq '^tlp[[:space:]]*=[[:space:]]*enabled'
        return $?
    fi
    return 1
}

tlp_label() {
    if ! command -v tlp >/dev/null 2>&1 && ! command -v tlp-stat >/dev/null 2>&1; then
        printf 'not installed'
    elif tlp_active; then
        printf 'active'
    else
        printf 'inactive'
    fi
}

nvidia_devices() {
    local d
    for d in /sys/bus/pci/devices/*; do
        [[ -r "$d/vendor" ]] || continue
        [[ "$(cat "$d/vendor" 2>/dev/null)" == "0x10de" ]] && basename "$d"
    done
}

gpu_details() {
    local dev status found=0
    for dev in $(nvidia_devices); do
        found=1
        status="$(read_sys "/sys/bus/pci/devices/$dev/power/runtime_status")"
        printf '%s: %s\n' "$dev" "${status:-unknown}"
    done
    (( found == 1 )) || printf 'none\n'
}

apply_power_safe_settings() {
    local cpupower start_tlp=0
    cpupower="$(command -v cpupower 2>/dev/null)" || return 1

    if [[ "$USE_TLP" == "1" && "$START_TLP" == "1" ]] \
        && command -v systemctl >/dev/null 2>&1 \
        && ! tlp_active; then
        start_tlp=1
    fi

    local -a gpu_devs=()
    mapfile -t gpu_devs < <(nvidia_devices)

    run_root /bin/sh -c '
        set -e
        cpupower="$1"
        governor="$2"
        min="$3"
        max="$4"
        boost="$5"
        epp="$6"
        profile="$7"
        gpu_pm="$8"
        start_tlp="$9"
        shift 9

        if [ "$start_tlp" = "1" ]; then
            systemctl start tlp >/dev/null 2>&1 || true
            sleep 1
        fi
        "$cpupower" frequency-set -g "$governor" -d "$min" -u "$max" >/dev/null
        if [ -w /sys/devices/system/cpu/cpufreq/boost ]; then
            printf "%s\n" "$boost" > /sys/devices/system/cpu/cpufreq/boost
        fi
        for p in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
            [ -w "$p" ] && printf "%s\n" "$epp" > "$p" || true
        done
        if [ -w /sys/firmware/acpi/platform_profile ] && [ -n "$profile" ]; then
            printf "%s\n" "$profile" > /sys/firmware/acpi/platform_profile 2>/dev/null || true
        fi
        for dev in "$@"; do
            ctl="/sys/bus/pci/devices/$dev/power/control"
            [ -w "$ctl" ] && printf "%s\n" "$gpu_pm" > "$ctl" || true
        done
    ' hycon "$cpupower" "$GOVERNOR" "$MIN_FREQ" "$MAX_FREQ" "$BOOST" "$EPP" "$PROFILE" "$GPU_PM" "$start_tlp" "${gpu_devs[@]}"
}

restore_default_settings() {
    local cpupower hw_min hw_max source boost epp profile
    cpupower="$(command -v cpupower 2>/dev/null)" || return 1
    hw_min="$(read_sys /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq)"
    hw_max="$(read_sys /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq)"
    source="$(power_source)"

    boost=0
    epp=power
    profile=quiet
    if [[ "$source" == "AC" ]]; then
        boost=1
        epp=balance_performance
        profile=balanced
    fi

    local -a gpu_devs=()
    mapfile -t gpu_devs < <(nvidia_devices)

    run_root /bin/sh -c '
        set -e
        cpupower="$1"
        min="$2"
        max="$3"
        boost="$4"
        epp="$5"
        profile="$6"
        shift 6

        if [ -n "$min" ] && [ -n "$max" ]; then
            "$cpupower" frequency-set -g powersave -d "${min}kHz" -u "${max}kHz" >/dev/null
        else
            "$cpupower" frequency-set -g powersave >/dev/null
        fi
        if [ -w /sys/devices/system/cpu/cpufreq/boost ]; then
            printf "%s\n" "$boost" > /sys/devices/system/cpu/cpufreq/boost
        fi
        for p in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
            [ -w "$p" ] && printf "%s\n" "$epp" > "$p" || true
        done
        if [ -w /sys/firmware/acpi/platform_profile ]; then
            printf "%s\n" "$profile" > /sys/firmware/acpi/platform_profile 2>/dev/null || true
        fi
        for dev in "$@"; do
            ctl="/sys/bus/pci/devices/$dev/power/control"
            [ -w "$ctl" ] && printf "auto\n" > "$ctl" || true
        done
    ' hycon "$cpupower" "$hw_min" "$hw_max" "$boost" "$epp" "$profile" "${gpu_devs[@]}"
}

get_state() {
    if [[ -r "$STATE_FILE" ]] && [[ "$(cat "$STATE_FILE" 2>/dev/null)" == "on" ]]; then
        printf 'on'
    else
        printf 'off'
    fi
}

write_state() {
    mkdir -p "$(dirname "$STATE_FILE")" 2>/dev/null || true
    umask 077
    printf '%s\n' "$1" > "$STATE_FILE" 2>/dev/null || true
}

enable_power_safe() {
    local tlp display_ok=0

    acquire_lock || return 1

    if [[ "$(get_state)" == "on" ]]; then
        if [[ "$DISPLAY_ENABLED" == "1" ]]; then
            set_refresh_rate "$REFRESH_ON" || \
                notify "Power Safe" "Display refresh could not be set to ${REFRESH_ON}Hz."
        fi
        notify "Power Safe" "Already enabled. CPU max $MAX_FREQ."
        refresh_waybar
        return 0
    fi

    if ! apply_power_safe_settings; then
        notify "Power Safe" "Could not set CPU limit. Root privileges are required."
        printf 'error: could not apply CPU limit\n' >&2
        return 1
    fi

    if [[ "$DISPLAY_ENABLED" == "1" ]]; then
        if set_refresh_rate "$REFRESH_ON"; then
            display_ok=1
        fi
    else
        display_ok=1
    fi

    write_state on
    tlp="$(tlp_label)"

    if [[ "$display_ok" == "1" ]]; then
        if [[ "$tlp" == "active" ]]; then
            notify "Power Safe" "Enabled. CPU max $MAX_FREQ, display ${REFRESH_ON}Hz, TLP active."
        else
            notify "Power Safe" "Enabled. CPU max $MAX_FREQ, display ${REFRESH_ON}Hz. Warning: TLP is $tlp."
        fi
    else
        notify "Power Safe" "Enabled. CPU max $MAX_FREQ. Warning: display refresh could not be changed."
    fi
    refresh_waybar
    return 0
}

disable_power_safe() {
    local display_ok=0

    acquire_lock || return 1

    if [[ "$(get_state)" != "on" ]]; then
        notify "Power Safe" "Already disabled."
        refresh_waybar
        return 0
    fi

    if ! restore_default_settings; then
        notify "Power Safe" "Could not restore CPU settings. Root privileges are required."
        printf 'error: could not restore CPU settings\n' >&2
        return 1
    fi

    if [[ "$DISPLAY_ENABLED" == "1" ]]; then
        if set_refresh_rate "$REFRESH_OFF"; then
            display_ok=1
        fi
    else
        display_ok=1
    fi

    write_state off

    if [[ "$display_ok" == "1" ]]; then
        notify "Power Safe" "Disabled. CPU and display restored."
    else
        notify "Power Safe" "Disabled. CPU restored, but display refresh could not be restored."
    fi
    refresh_waybar
    return 0
}

reset_power_safe() {
    acquire_lock || return 1

    if ! restore_default_settings; then
        notify "Power Safe" "Reset failed. Root privileges are required."
        printf 'error: could not restore CPU settings\n' >&2
        return 1
    fi

    if [[ "$DISPLAY_ENABLED" == "1" ]]; then
        set_refresh_rate "$REFRESH_OFF" || \
            notify "Power Safe" "Display refresh could not be restored."
    fi

    write_state off
    notify "Power Safe" "Reset complete. Default CPU and display settings restored."
    refresh_waybar
    return 0
}

ensure_power_safe() {
    [[ "$(get_state)" == "on" ]] || return 0
    [[ "$DISPLAY_ENABLED" == "1" ]] || return 0
    display_is_power_safe && return 0
    set_refresh_rate "$REFRESH_ON" >/dev/null 2>&1 || true
    refresh_waybar
    return 0
}

toggle_power_safe() {
    if [[ "$(get_state)" == "on" ]]; then
        disable_power_safe
    else
        enable_power_safe
    fi
}

json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/}"
    s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

details_text() {
    local mode freq governor boost epp profile tlp source display
    mode="$(get_state)"
    freq="$(human_freq "$(read_sys /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq)")"
    governor="$(read_sys /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
    boost="$(read_sys /sys/devices/system/cpu/cpufreq/boost)"
    epp="$(read_sys /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference)"
    profile="$(read_sys /sys/firmware/acpi/platform_profile)"
    tlp="$(tlp_label)"
    source="$(power_source)"
    display="$(display_summary)"

    if [[ "$mode" == "on" ]]; then
        printf 'Power Safe: ON\n'
    else
        printf 'Power Safe: OFF\n'
    fi
    printf 'CPU max: %s (%s, boost %s)\n' "$freq" "${governor:-unknown}" "${boost:-unknown}"
    printf 'EPP: %s\n' "${epp:-unknown}"
    printf 'Platform profile: %s\n' "${profile:-unknown}"
    printf 'Display: %s\n' "$display"
    printf 'TLP: %s\n' "$tlp"
    printf 'Power source: %s\n' "$source"
    printf 'NVIDIA:\n'
    gpu_details
    printf 'Left click: toggle\n'
    printf 'Right click: this status\n'
}

status_json() {
    local mode text class tooltip tlp
    mode="$(get_state)"
    tlp="$(tlp_label)"

    if [[ "$mode" == "on" ]]; then
        text="󰌪"
        class="on"
    else
        text="󰓅"
        class="off"
    fi

    if [[ "$mode" == "on" && "$tlp" != "active" ]]; then
        class="warning"
    fi
    if [[ "$mode" == "on" && "$DISPLAY_ENABLED" == "1" ]] \
        && command -v hyprctl >/dev/null 2>&1 \
        && ! display_is_power_safe; then
        class="warning"
    fi

    tooltip="$(details_text)"

    printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' \
        "$(json_escape "$text")" \
        "$(json_escape "$tooltip")" \
        "$(json_escape "$class")"
}

case "${1:-status}" in
    status)
        status_json
        ;;
    details)
        details="$(details_text)"
        printf '%s\n' "$details"
        notify "Power Safe" "$details"
        ;;
    check)
        details_text
        ;;
    on|enable)
        enable_power_safe
        ;;
    off|disable)
        disable_power_safe
        ;;
    toggle)
        toggle_power_safe
        ;;
    ensure)
        ensure_power_safe
        ;;
    reset|recover)
        reset_power_safe
        ;;
    *)
        printf 'Usage: %s {status|details|check|on|off|toggle|ensure|reset}\n' "$0" >&2
        exit 1
        ;;
esac
