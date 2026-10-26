--[[
    THEME CONFIG
--]]

hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 9,
        border_size = 0,
        resize_on_border = true,
        allow_tearing = false,
    },

    decoration = {
        rounding = 8,
        active_opacity = 0.94,
        inactive_opacity = 0.90,

        shadow = {
            enabled = false,
            -- range = 10,
            -- render_power = 2,
            -- color = "rgba(00000035)",
        },

        blur = {
            enabled = true,
            size = 5,
            passes = 1,
            new_optimizations = true,
            popups = false,
            special = false,
            xray = true,
            noise = 0.01,
            vibrancy = 0.12,
        },
    },

    input = {
        follow_mouse = 1,
        sensitivity = 0,
    },

    misc = {
        vrr = 0,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
    },

    animations = {
        enabled = true,
    },
})
