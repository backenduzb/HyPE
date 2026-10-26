--[[
    ANIMATIONS CONFIG
--]]

hl.curve("smooth", {
    type = "bezier",
    points = {
        { 0.16, 1.0 },
        { 0.3, 1.0 },
    },
})

hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 5,
    bezier = "smooth",
    style = "popin 95%",
})

hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 4,
    bezier = "smooth",
    style = "popin 90%",
})

hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 5,
    bezier = "smooth",
    style = "slide",
})
