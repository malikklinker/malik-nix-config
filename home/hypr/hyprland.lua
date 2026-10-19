hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

hl.config({
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
            active_border = "rgba(cba6f7ff)",
            inactive_border = "rgba(45475aff)",
        },
    },
    decoration = {
        rounding = 6,
        blur = { enabled = true, size = 6, passes = 2, new_optimizations = true },
    },
})

hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + Return", hl.dsp.exec_cmd("session-app kitty"))
hl.bind("SUPER + Space", hl.dsp.exec_cmd("session-app walker"))
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind("SUPER + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + L", hl.dsp.exec_cmd("session-app swaylock"))
hl.bind("SUPER + M", hl.dsp.exit())

for workspace = 1, 5 do
    hl.bind("SUPER + " .. workspace, hl.dsp.focus({ workspace = workspace }))
    hl.bind("SUPER + SHIFT + " .. workspace, hl.dsp.window.move({ workspace = workspace }))
end

hl.bind("Print", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))
