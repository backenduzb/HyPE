app=$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // "Desktop"')

echo "$app" | sed -E 's/(^|-)([a-z])/\U\2/g' | sed 's/-/ /g'
