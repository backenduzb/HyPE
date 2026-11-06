#!/usr/bin/env bash
# Apply the Hycon TLP power profile.
# Usage: sudo bash tlp/apply.sh

set -euo pipefail

if (( EUID != 0 )); then
    echo "Run as root: sudo bash $0" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/99-hycon-power.conf"
DEST="/etc/tlp.d/99-hycon-power.conf"
CONF="/etc/tlp.conf"
BACKUP="/var/backups/hycon"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

[[ -f "$SRC" ]] || { echo "Missing: $SRC" >&2; exit 1; }
command -v tlp >/dev/null 2>&1 || { echo "TLP is not installed." >&2; exit 1; }

mkdir -p "$BACKUP"
cp -a "$CONF" "$BACKUP/tlp.conf.$TIMESTAMP" 2>/dev/null || true
if [[ -f "$DEST" ]]; then
    cp -a "$DEST" "$BACKUP/99-hycon-power.conf.$TIMESTAMP" 2>/dev/null || true
fi

install -Dm644 -o root -g root "$SRC" "$DEST"

# /etc/tlp.conf is read after /etc/tlp.d, so comment out the old manual
# overrides that would otherwise keep the NVIDIA GPU powered on battery.
TMP="$(mktemp "${TMPDIR:-/tmp}/hycon-tlp.XXXXXX")"
cp "$CONF" "$TMP"
sed -E -i \
    's/^(TLP_ENABLE|CPU_SCALING_GOVERNOR_ON_AC|CPU_SCALING_GOVERNOR_ON_BAT|CPU_ENERGY_PERF_POLICY_ON_AC|CPU_ENERGY_PERF_POLICY_ON_BAT|CPU_BOOST_ON_AC|CPU_BOOST_ON_BAT|CPU_HWP_DYN_BOOST_ON_AC|CPU_HWP_DYN_BOOST_ON_BAT|PLATFORM_PROFILE_ON_AC|PLATFORM_PROFILE_ON_BAT|RUNTIME_PM_ON_AC|RUNTIME_PM_ON_BAT|RUNTIME_PM_DENYLIST|RUNTIME_PM_DRIVER_DENYLIST|RUNTIME_PM_BLACKLIST|RUNTIME_PM_DRIVER_BLACKLIST|PCI_DEVICES|USB_AUTOSUSPEND|DISK_APM_LEVEL_ON_AC|DISK_APM_LEVEL_ON_BAT)=/# &/' \
    "$TMP"
install -m 644 -o root -g root "$TMP" "$CONF"
rm -f "$TMP"

systemctl restart tlp
sleep 1

echo "TLP profile installed: $DEST"
echo "Backup: $BACKUP"
echo
tlp-stat -s | sed -n '/+++ TLP Status/,/^$/p'
echo "NVIDIA runtime PM:"
for d in /sys/bus/pci/devices/*; do
    [[ -r "$d/vendor" ]] || continue
    [[ "$(cat "$d/vendor")" == "0x10de" ]] || continue
    printf '  %s control=%s status=%s\n' \
        "$(basename "$d")" \
        "$(cat "$d/power/control")" \
        "$(cat "$d/power/runtime_status")"
done
