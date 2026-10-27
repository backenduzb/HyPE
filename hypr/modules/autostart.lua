--[[
    AUTO START CONFIG
--]]

local cfg = require("configs")

hl.on("hyprland.start", function()
    hl.exec_cmd(string.format('waybar -c "%s" -s "%s"', cfg.waybar.config, cfg.waybar.styles))
    hl.exec_cmd(string.format('dunst -conf "%s"', cfg.dunst.config))
    hl.exec_cmd("command -v awww-daemon >/dev/null 2>&1 && awww-daemon")
    hl.exec_cmd(string.format('awww img "%s"', cfg.wallpapres.space))
    hl.exec_cmd("command -v hyprpolkitagent >/dev/null 2>&1 && hyprpolkitagent")
    hl.exec_cmd("command -v nm-applet >/dev/null 2>&1 && nm-applet --indicator")
end)
