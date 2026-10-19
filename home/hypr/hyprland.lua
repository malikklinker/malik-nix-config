hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
hl.monitor({ output = "eDP-1", mode = "2560x1600@240", position = "auto", scale = 1.5 })

local theme_path = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state"))
    .. "/desktop-theme/hyprland.lua"
local theme_ok, theme = pcall(dofile, theme_path)
if not theme_ok then
    theme = { active_border = "rgba(cba6f7ff)", inactive_border = "rgba(45475aff)" }
end

hl.config({
    cursor = { enable_hyprcursor = false },
    input = {
        kb_layout = "us",
        touchpad = { natural_scroll = true },
    },
    general = {
        border_size = 2,
        gaps_in = 4,
        gaps_out = 8,
        layout = "dwindle",
        col = {
            active_border = theme.active_border,
            inactive_border = theme.inactive_border,
        },
    },
    decoration = {
        rounding = 6,
        blur = { enabled = true, size = 6, passes = 2, new_optimizations = true },
    },
})

-- Keep the default 800 ms timing and styles, with a quicker ease-out curve.
hl.curve("snappy", { type = "bezier", points = { {0.16, 1}, {0.3, 1} } })
hl.animation({ leaf = "global", enabled = true, speed = 8, bezier = "snappy" })

hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + Return", hl.dsp.exec_cmd("session-app kitty"))
hl.bind("SUPER + Space", hl.dsp.exec_cmd("session-app walker"))
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind("SUPER + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + L", hl.dsp.exec_cmd("session-app swaylock"))
hl.bind("SUPER + M", hl.dsp.exit())

-- Use the same default output and 5% steps as the panel, including while locked.
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("desktop-volume up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("desktop-volume down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("desktop-volume mute"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("desktop-volume mic-mute"), { locked = true })

for workspace = 1, 5 do
    hl.bind("SUPER + " .. workspace, hl.dsp.focus({ workspace = workspace }))
    hl.bind("SUPER + SHIFT + " .. workspace, hl.dsp.window.move({ workspace = workspace }))
end

hl.bind("Print", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))
