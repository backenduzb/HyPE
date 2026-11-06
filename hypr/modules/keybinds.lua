--[[
    KEYBINDS CONFIG
--]]

local cfg = require("configs")
local mainMod = "SUPER"

hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(cfg.rofi.toggle .. " toggle"))
hl.bind(mainMod .. " + period", hl.dsp.exec_cmd(cfg.rofi.icon_picker .. " icons"))
hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd(cfg.rofi.emoji_picker .. " emoji"))

hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("firefox"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("spotify"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())


hl.bind(
    "SUPER + mouse:272",
    hl.dsp.window.drag(),
    { mouse = true }
)
hl.bind(
    "SUPER + mouse:273",
    hl.dsp.window.resize(),
    { mouse = true }
)

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

hl.gesture({
    fingers = 3,
    direction = "vertical",
    action = {
        start = function(e)
            if e.delta.y ~= 0 then
                local change = -0.25 * e.delta.y
                local sign = change < 0 and "-" or "+"
                hl.exec_cmd(
                    "wpctl set-volume @DEFAULT_AUDIO_SINK@ " ..
                    math.abs(change) .. "%" .. sign
                )
            end
        end,
        update = function(e)
            if e.delta.y ~= 0 then
                local change = -0.25 * e.delta.y
                local sign = change < 0 and "-" or "+"
                hl.exec_cmd(
                    "wpctl set-volume @DEFAULT_AUDIO_SINK@ " ..
                    math.abs(change) .. "%" .. sign
                )
            end
        end,
    },
})

hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("$HOME/.config/scripts/tessaract.sh"))

hl.bind(mainMod .. " + W", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen(0))

hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("hyprshot -m region -z"))
hl.bind("ALT + Q", hl.dsp.window.close())

hl.bind("CTRL + SUPER + ALT + Right", hl.dsp.window.move({ workspace = "+1" }))

hl.bind("CTRL + SUPER + ALT + Left", hl.dsp.window.move({ workspace = "-1" }))

for i = 1, 9 do
    local key = tostring(i)
    
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "r+1" }))
hl.bind("CTRL + SUPER + right", hl.dsp.focus({ workspace = "r+1" }))

hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "r-1" }))
hl.bind("CTRL + SUPER + left", hl.dsp.focus({ workspace = "r-1" }))

hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd("wlogout"))


hl.bind("F1", hl.dsp.exec_cmd("hyprshot -m region -z"))
hl.bind("F2", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })
hl.bind("F3", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set +5%"), { locked = true, repeating = true })
hl.bind("F5", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("F6", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("F7", hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("F8", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("F9", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("F10", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("F11", hl.dsp.exec_cmd("playerctl stop"), { locked = true })

hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set +5%"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"), { locked = true })
