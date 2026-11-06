--[[
    AUTO START CONFIG
--]]

local cfg = require("configs")

local function ensure_power_safe()
    hl.exec_cmd(string.format(
        'sleep 1; [ -x "%s/waybar/scripts/power-safe.sh" ] && "%s/waybar/scripts/power-safe.sh" ensure >/dev/null 2>&1 || true',
        cfg.configDir, cfg.configDir
    ))
end

local function start_services()
    hl.exec_cmd(string.format(
        'command -v waybar >/dev/null 2>&1 && [ -f "%s" ] && [ -f "%s" ] && { pgrep -x waybar >/dev/null 2>&1 || waybar -c "%s" -s "%s"; }',
        cfg.waybar.config, cfg.waybar.styles, cfg.waybar.config, cfg.waybar.styles
    ))
    hl.exec_cmd(string.format(
        'command -v dunst >/dev/null 2>&1 && [ -f "%s" ] && { pgrep -x dunst >/dev/null 2>&1 || dunst -conf "%s"; }',
        cfg.dunst.config, cfg.dunst.config
    ))
    hl.exec_cmd('command -v awww-daemon >/dev/null 2>&1 && { pgrep -x awww-daemon >/dev/null 2>&1 || awww-daemon; }')
    -- hl.exec_cmd(string.format('command -v awww >/dev/null 2>&1 && awww img "%s"', cfg.wallpapres.space))
    hl.exec_cmd([[
        if command -v hyprpolkitagent >/dev/null 2>&1; then
            pgrep -x hyprpolkitagent >/dev/null 2>&1 || hyprpolkitagent
        elif [ -x /usr/lib/polkit-kde-authentication-agent-1 ]; then
            pgrep -f '^/usr/lib/polkit-kde-authentication-agent-1$' >/dev/null 2>&1 || /usr/lib/polkit-kde-authentication-agent-1
        fi
    ]])
    hl.exec_cmd('command -v nm-applet >/dev/null 2>&1 && { pgrep -x nm-applet >/dev/null 2>&1 || nm-applet --indicator; }')
    hl.exec_cmd(string.format(
        'command -v hypridle >/dev/null 2>&1 && [ -f "%s" ] && { pgrep -x hypridle >/dev/null 2>&1 || hypridle -c "%s"; }',
        cfg.hypridle.config, cfg.hypridle.config
    ))
    ensure_power_safe()
end

hl.on("hyprland.start", start_services)
hl.on("config.reloaded", start_services)
hl.on("monitor.added", ensure_power_safe)
hl.on("monitor.removed", ensure_power_safe)
