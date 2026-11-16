local M = {}
local state = vim.env.XDG_STATE_HOME
local directory = (state and state ~= "" and state or (vim.env.HOME .. "/.local/state")) .. "/desktop-theme"

local function read_theme()
	local file = io.open(directory .. "/theme.json", "r")
	if not file then
		return
	end
	local text = file:read("*a")
	file:close()
	local ok, theme = pcall(vim.json.decode, text)
	if ok and theme.palette and theme.colors then
		return theme
	end
end

function M.statusline_theme(theme)
	theme = theme or read_theme()
	if not theme then
		return "auto"
	end
	local c = theme.colors
	local function mode()
		return {
			a = { fg = c.subtext, bg = c.background },
			b = { fg = c.subtext, bg = c.background },
			c = { fg = c.subtext, bg = c.background },
		}
	end
	return {
		normal = mode(),
		insert = mode(),
		visual = mode(),
		replace = mode(),
		command = mode(),
		inactive = {
			a = { fg = c.muted, bg = c.background },
			b = { fg = c.muted, bg = c.background },
			c = { fg = c.muted, bg = c.background },
		},
	}
end

function M.apply()
	local theme = read_theme()
	if not theme then
		return
	end
	vim.o.background = theme.variant == "light" and "light" or "dark"
	require("mini.base16").setup({ palette = theme.palette, use_cterm = true })
	vim.g.colors_name = "desktop"
	local c = theme.colors
	local highlights = {
		NormalFloat = { fg = c.text, bg = c.surface },
		FloatBorder = { fg = c.accent, bg = c.surface },
		FloatTitle = { fg = c.accent, bg = c.surface, bold = true },
		WinSeparator = { fg = c.overlay },
		CursorLine = { bg = c.surface },
		CursorLineNr = { fg = c.accent, bold = true },
		LineNr = { fg = c.muted, bg = c.background },
		SignColumn = { bg = c.background },
		FoldColumn = { fg = c.muted, bg = c.background },
		Visual = { bg = c.overlay },
		Pmenu = { fg = c.text, bg = c.surface },
		PmenuSel = { fg = c.background, bg = c.accent, bold = true },
		DiagnosticWarn = { fg = c.yellow },
		DiagnosticFloatingWarn = { fg = c.yellow, bg = c.surface },
		DiagnosticUnderlineWarn = { undercurl = true, sp = c.yellow },
		BufferLineFill = { bg = c.background },
		BufferLineBackground = { fg = c.muted, bg = c.background },
		BufferLineBufferSelected = { fg = c.accent, bg = c.surface, bold = true },
		BufferLineIndicatorSelected = { fg = c.accent, bg = c.surface },
		BufferLineTabSelected = { fg = c.accent, bg = c.surface, bold = true },
		SnacksPickerBorder = { link = "FloatBorder" },
		SnacksPickerTitle = { link = "FloatTitle" },
		SnacksPickerMatch = { fg = c.accent, bold = true },
		SnacksPickerSelected = { fg = c.accent, bold = true },
		SnacksDashboardHeader = { fg = c.accent },
		SnacksDashboardIcon = { fg = c.accent },
		SnacksDashboardKey = { fg = c.secondary },
		SnacksDashboardTitle = { fg = c.accent, bold = true },
	}
	for group, value in pairs(require("config.desktop-syntax").highlights(theme)) do
		highlights[group] = value
	end
	for group, value in pairs(highlights) do
		vim.api.nvim_set_hl(0, group, value)
	end
	-- Keep the plain status line in sync with desktop palette changes.
	if package.loaded["lualine"] then
		local lualine = require("lualine")
		local options = lualine.get_config()
		options.options.theme = M.statusline_theme(theme)
		lualine.setup(options)
	end
end

function M.setup()
	M.apply()
	if M.watcher then
		return
	end
	M.watcher = vim.uv.new_fs_event()
	M.watcher:start(
		directory,
		{},
		vim.schedule_wrap(function(error, filename)
			if not error and filename == "theme.json" then
				-- Use the colorscheme command so plugins also receive ColorScheme events.
				vim.cmd.colorscheme("desktop")
			end
		end)
	)
	vim.api.nvim_create_autocmd("VimLeavePre", {
		once = true,
		callback = function()
			M.watcher:stop()
			M.watcher:close()
		end,
	})
end

return M
