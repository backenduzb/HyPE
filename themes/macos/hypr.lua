hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_STYLE_OVERRIDE", "Darkly")
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_SIZE", "24")

pcall(require, "themes.macos.colors")

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 6,
        border_size = 0,
    },
    decoration = {
        rounding = 8,
        active_opacity = 0.93,
        inactive_opacity = 0.90,
        shadow = {
            enabled = true,
            range = 24,
            render_power = 3,
            color = "rgba(00000055)",
        },
        blur = {
            enabled = false,
            size = 8,
            passes = 3,
            new_optimizations = true,
            xray = true,
            noise = 0.01,
            vibrancy = 0.2,
        },
    },
})
