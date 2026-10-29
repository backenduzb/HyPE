#!/bin/bash
set -euo pipefail

BAT_PATH="/sys/class/power_supply/BAT0"
if [ ! -d "$BAT_PATH" ]; then
  BAT_PATH="$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n1 || true)"
fi

if [ -z "${BAT_PATH:-}" ] || [ ! -r "$BAT_PATH/capacity" ]; then
  echo "󰁺 N/A"
  exit 0
fi

capacity="$(cat "$BAT_PATH/capacity")"
status="$(cat "$BAT_PATH/status" 2>/dev/null || echo "")"

if [ "$capacity" -ge 90 ]; then icon="󰁹"
elif [ "$capacity" -ge 70 ]; then icon="󰂂"
elif [ "$capacity" -ge 50 ]; then icon="󰂀"
elif [ "$capacity" -ge 30 ]; then icon="󰁾"
elif [ "$capacity" -ge 15 ]; then icon="󰁼"
else icon="󰁺"
fi

if [ "$status" = "Charging" ]; then
  icon="󰂄"
fi

case "${1:-}" in
  icon) echo "$icon" ;;
  percent) echo "${capacity}%" ;;
  *) echo "$icon ${capacity}%" ;;
esac
