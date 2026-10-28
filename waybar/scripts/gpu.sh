#!/usr/bin/env bash

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/waybar_gpu_state"

get_state() {
    if [[ -f "$STATE_FILE" ]]; then
        cat "$STATE_FILE"
    else
        echo "nvidia"
    fi
}

toggle_state() {
    local current
    current="$(get_state)"
    if [[ "$current" == "radeon" ]]; then
        echo "nvidia" > "$STATE_FILE"
    else
        echo "radeon" > "$STATE_FILE"
    fi
    pkill -RTMIN+8 waybar 2>/dev/null || true
}

get_amd_temp() {
    for f in /sys/class/drm/card*/device/hwmon/hwmon*/temp1_input /sys/class/hwmon/hwmon*/temp1_input; do
        if [[ -r "$f" ]]; then
            local dir
            dir="$(dirname "$f")"
            if [[ -f "$dir/name" ]] && grep -qi "amdgpu" "$dir/name" 2>/dev/null; then
                local temp
                temp="$(cat "$f" 2>/dev/null)"
                if [[ -n "$temp" && "$temp" -gt 0 ]]; then
                    echo "$(( temp / 1000 ))"
                    return 0
                fi
            fi
        fi
    done
    echo "N/A"
}

get_nvidia_temp() {
    local temp
    temp="$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1 | tr -d '[:space:]')"
    if [[ -n "$temp" ]]; then
        echo "$temp"
    else
        echo "N/A"
    fi
}

action="${1:-temp}"

case "$action" in
    toggle)
        toggle_state
        ;;
    icon)
        state="$(get_state)"
        if [[ "$state" == "radeon" ]]; then
            echo '{"text":"󰊗","tooltip":"AMD Radeon Graphics (iGPU)\nClick to switch to NVIDIA RTX 3050 Ti","class":"radeon"}'
        else
            echo '{"text":"󰊗","tooltip":"NVIDIA GeForce RTX 3050 Ti Laptop GPU\nClick to switch to AMD Radeon","class":"nvidia"}'
        fi
        ;;
    temp)
        state="$(get_state)"
        if [[ "$state" == "radeon" ]]; then
            temp="$(get_amd_temp)"
            echo "{\"text\":\"${temp}°C\",\"tooltip\":\"AMD Radeon Graphics: ${temp}°C\\nClick to switch to NVIDIA RTX 3050 Ti\",\"class\":\"radeon\"}"
        else
            temp="$(get_nvidia_temp)"
            echo "{\"text\":\"${temp}°C\",\"tooltip\":\"NVIDIA GeForce RTX 3050 Ti: ${temp}°C\\nClick to switch to AMD Radeon\",\"class\":\"nvidia\"}"
        fi
        ;;
    *)
        echo "Usage: $0 {icon|temp|toggle}"
        exit 1
        ;;
esac
