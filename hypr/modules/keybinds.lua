--[[
    KEYBINDS CONFIG
--]]

local cfg = require("configs")
local mainMod = "SUPER"

hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(cfg.rofi.toggle .. " toggle"))

hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("firefox"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("spotify"))
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())

for i = 1, 9 do
    local key = tostring(i)

    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "r+1" }))
hl.bind("CTRL + SUPER + right", hl.dsp.focus({ workspace = "r+1" }))

hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "r-1" }))
hl.bind("CTRL + SUPER + left", hl.dsp.focus({ workspace = "r-1" }))

hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("wlogout"))
