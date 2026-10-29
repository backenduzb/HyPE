#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd -P)"
SRC_IMAGE="${1:-$PROJECT_DIR/assets/wallpapers/aotlevi.png}"
FONT_REGULAR="${FONT_REGULAR:-$HOME/.local/share/fonts/JetBrains/JetBrainsMonoNerdFont-Regular.ttf}"

command -v convert >/dev/null 2>&1 || { echo "ImageMagick (convert) kerak" >&2; exit 1; }
command -v grub-mkfont >/dev/null 2>&1 || { echo "grub-mkfont kerak" >&2; exit 1; }
[[ -f "$SRC_IMAGE" ]] || { echo "Rasm topilmadi: $SRC_IMAGE" >&2; exit 1; }
[[ -f "$FONT_REGULAR" ]] || { echo "Font topilmadi: $FONT_REGULAR" >&2; exit 1; }

cd "$SCRIPT_DIR"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/hycon-grub.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

convert "$SRC_IMAGE" \
    -resize 1920x1080^ -gravity center -extent 1920x1080 \
    -colorspace Gray -fill black -colorize 32% \
    \( -size 1920x1080 radial-gradient:'rgba(0,0,0,0)'-'rgba(0,0,0,0.45)' \) \
    -compose over -composite \
    -strip -define png:compression-level=9 -define png:color-type=2 background.png

convert -size 1920x2 xc:'rgba(255,255,255,0.55)' -define png:color-type=6 hud_top.png
convert -size 1920x2 xc:'rgba(255,255,255,0.30)' -define png:color-type=6 hud_bottom.png

slice9() {
    local full="$1" prefix="$2"
    convert "$full" -crop 16x16+0+0   +repage -define png:color-type=6 "${prefix}_nw.png"
    convert "$full" -crop 32x16+16+0  +repage -define png:color-type=6 "${prefix}_n.png"
    convert "$full" -crop 16x16+48+0  +repage -define png:color-type=6 "${prefix}_ne.png"
    convert "$full" -crop 16x32+0+16  +repage -define png:color-type=6 "${prefix}_w.png"
    convert "$full" -crop 32x32+16+16 +repage -define png:color-type=6 "${prefix}_c.png"
    convert "$full" -crop 16x32+48+16 +repage -define png:color-type=6 "${prefix}_e.png"
    convert "$full" -crop 16x16+0+48  +repage -define png:color-type=6 "${prefix}_sw.png"
    convert "$full" -crop 32x16+16+48 +repage -define png:color-type=6 "${prefix}_s.png"
    convert "$full" -crop 16x16+48+48 +repage -define png:color-type=6 "${prefix}_se.png"
}

convert "$SRC_IMAGE" -crop 1024x1024+3200+900 +repage \
    -resize 64x64^ -gravity center -extent 64x64 \
    -colorspace Gray -blur 0x2 -fill black -colorize 58% \
    \( -size 64x64 xc:black -fill white -draw 'roundrectangle 0,0 63,63 6,6' \) \
    -alpha off -compose CopyOpacity -composite \
    -stroke 'rgba(255,255,255,0.55)' -strokewidth 1 -fill none \
    -draw 'roundrectangle 0.5,0.5 63.5,63.5 6,6' \
    "$TMP/menu_full.png"
slice9 "$TMP/menu_full.png" menu

rm -f select_*.png
convert "$SRC_IMAGE" -crop 768x768+700+800 +repage \
    -resize 64x52^ -gravity center -extent 64x52 \
    -colorspace Gray -fill black -colorize 45% \
    \( -size 64x52 xc:black -fill white -draw 'roundrectangle 0,0 63,51 6,6' \) \
    -alpha off -compose CopyOpacity -composite \
    -stroke 'rgba(255,255,255,0.90)' -strokewidth 1 -fill none \
    -draw 'roundrectangle 0.5,0.5 63.5,51.5 6,6' \
    -fill 'rgba(255,255,255,0.85)' -stroke none \
    -draw 'rectangle 2,8 3,43' \
    "$TMP/select_full.png"
convert "$TMP/select_full.png" -crop 16x52+0+0   +repage -define png:color-type=6 select_w.png
convert "$TMP/select_full.png" -crop 32x52+16+0  +repage -define png:color-type=6 select_c.png
convert "$TMP/select_full.png" -crop 16x52+48+0  +repage -define png:color-type=6 select_e.png

convert "$SRC_IMAGE" -crop 1024x1024+3400+1100 +repage \
    -resize 64x64^ -gravity center -extent 64x64 \
    -colorspace Gray -blur 0x3 -fill black -colorize 72% \
    \( -size 64x64 xc:black -fill white -draw 'roundrectangle 0,0 63,63 6,6' \) \
    -alpha off -compose CopyOpacity -composite \
    -stroke 'rgba(255,255,255,0.45)' -strokewidth 1 -fill none \
    -draw 'roundrectangle 0.5,0.5 63.5,63.5 6,6' \
    "$TMP/terminal_full.png"
slice9 "$TMP/terminal_full.png" terminal

convert -size 6x24 xc:'rgba(255,255,255,0.55)' \
    -stroke 'rgba(255,255,255,0.85)' -strokewidth 1 -fill none \
    -draw 'rectangle 0.5,0.5 5.5,23.5' -define png:color-type=6 slider_c.png
convert -size 6x4 xc:'rgba(255,255,255,0.0)' -define png:color-type=6 slider_n.png
convert -size 6x4 xc:'rgba(255,255,255,0.0)' -define png:color-type=6 slider_s.png

grub-mkfont -s 48 -n HyconTitle -r 0x20-0x7E -o title.pf2 "$FONT_REGULAR" 2>/dev/null
grub-mkfont -s 22 -n HyconMenu  -r 0x20-0x7E -o menu.pf2 "$FONT_REGULAR" 2>/dev/null
grub-mkfont -s 16 -n HyconSmall -r 0x20-0x7E -o small.pf2 "$FONT_REGULAR" 2>/dev/null
grub-mkfont -s 18 -n HyconTerm  -r 0x20-0x7E -o terminal.pf2 "$FONT_REGULAR" 2>/dev/null

if [[ -f icons/arch.png ]]; then
    convert icons/arch.png -fill white -colorize 100 \
        -type TrueColorAlpha -define png:color-type=6 icons/arch.png
fi

echo "GRUB assetlar tayyor: $SCRIPT_DIR"
