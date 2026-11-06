#!/bin/bash

slurp | grim -g - - | tesseract stdin stdout --oem 1 -l eng+uzb 2>/dev/null | wl-copy

notify-send "Image to text" "Text sucessfully copied!"
