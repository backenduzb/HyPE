--[[
    SYSTEM AND APPS CONFIGS
--]]

local configHome = os.getenv("HYCON_DIR")
    or os.getenv("XDG_CONFIG_HOME")
    or ((os.getenv("HOME") or "") .. "/.config")

local configs = {
    configDir = configHome,

    waybar = {
        dir = configHome .. "/waybar",
        config = configHome .. "/waybar/config.jsonc",
        styles = configHome .. "/waybar/style.css"
    },

    dunst = {
        config = configHome .. "/dunst/dustrc"
    },

    rofi = {
        dir = configHome .. "/rofi",
        toggle = configHome .. "/rofi/scripts/toggle.sh"
    },

    wallpapres = {
        space = configHome .. "/assets/wallpapers/space.jpg"
    }
}

return configs