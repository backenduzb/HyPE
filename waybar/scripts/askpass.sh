#!/usr/bin/env bash

# GUI password prompt for sudo -A.
# Waybar scripts run without a terminal, so sudo cannot ask for a password
# on its own. This helper uses zenity or kdialog.

set -u

prompt="${1:-Password:}"

if command -v zenity >/dev/null 2>&1; then
    exec zenity --password --title="Hycon — root paroli" 2>/dev/null
fi

if command -v kdialog >/dev/null 2>&1; then
    exec kdialog --password "$prompt" --title "Hycon — root paroli" 2>/dev/null
fi

printf 'No GUI askpass helper found (install zenity or kdialog)\n' >&2
exit 1
