#!/bin/bash

HYPRLOCK_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ART_FILE="$HYPRLOCK_DIR/album_art.png"
FALLBACK="$HYPRLOCK_DIR/fallback_album_art.jpg"
PLAYERCTL="/usr/bin/playerctl"
CURL="/usr/bin/curl"

url_decode() {
    local url_encoded="${1//+/ }"
    printf '%b' "${url_encoded//%/\\x}"
}

PLAYER=""
while IFS= read -r p; do
    STATUS=$($PLAYERCTL -p "$p" status 2>/dev/null | tr '[:upper:]' '[:lower:]')
    if [[ "$STATUS" == "playing" || "$STATUS" == "paused" ]]; then
        PLAYER="$p"
        break
    fi
done < <($PLAYERCTL -l 2>/dev/null)

# Player topilmasa -> fallback
if [[ -z "$PLAYER" ]]; then
    cp "$FALLBACK" "$ART_FILE"
    exit 0
fi

# Album art URL
URL=$($PLAYERCTL -p "$PLAYER" metadata mpris:artUrl 2>/dev/null)

if [[ -z "$URL" ]]; then
    cp "$FALLBACK" "$ART_FILE"
elif [[ "$URL" =~ ^data:image ]]; then
    echo "${URL#*,}" | base64 -d > "$ART_FILE"
elif [[ "$URL" =~ ^file:// ]]; then
    PATH_DECODED=$(url_decode "${URL#file://}")
    cp "$PATH_DECODED" "$ART_FILE"
elif [[ "$URL" =~ ^https:// ]]; then
    $CURL -s "$URL" -o "$ART_FILE"
fi