--[[
    SYSTEM AND APPS CONFIGS
--]]

local configHome = os.getenv("HYCON_DIR")
    or os.getenv("XDG_CONFIG_HOME")
    or ((os.getenv("HOME") or "") .. "/.config")

local themeName = os.getenv("HYCON_THEME")
if themeName == nil then
    themeName = "macos"
end
local themeDir = themeName ~= "" and (configHome .. "/themes/" .. themeName) or nil

if themeDir then
    local probe = io.open(themeDir .. "/waybar/style.css", "r")
    if probe then
        probe:close()
    else
        themeDir = nil
    end
end

local configs = {
    configDir = configHome,

    waybar = {
        dir = configHome .. "/waybar",
        config = configHome .. "/waybar/config.jsonc",
        styles = themeDir and (themeDir .. "/waybar/style.css") or (configHome .. "/waybar/style.css")
    },

    dunst = {
        config = configHome .. "/dunst/dunstrc"
    },

    rofi = {
        dir = configHome .. "/rofi",
        toggle = configHome .. "/rofi/scripts/toggle.sh",
        icon_picker = configHome .. "/rofi/scripts/picker.py",
        emoji_picker = configHome .. "/rofi/scripts/picker.py",
        theme = themeDir and (themeDir .. "/rofi/" .. themeName .. ".rasi") or (configHome .. "/rofi/full.rasi")
    },

    hypridle = {
        config = configHome .. "/hypridle/hypridle.conf"
    },

    wallpapres = {
        space = configHome .. "/assets/wallpapers/space.jpg"
    }
}

return configs