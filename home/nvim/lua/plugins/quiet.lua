return {
	{
		"folke/snacks.nvim",
		opts = {
			notifier = { enabled = false },
			indent = { enabled = false },
		},
	},
	{ "akinsho/bufferline.nvim", enabled = false },
	{
		"LazyVim/LazyVim",
		keys = {
			{ "<S-h>", "<cmd>bprevious<cr>", desc = "Prev Buffer" },
			{ "<S-l>", "<cmd>bnext<cr>", desc = "Next Buffer" },
			{ "[b", "<cmd>bprevious<cr>", desc = "Prev Buffer" },
			{ "]b", "<cmd>bnext<cr>", desc = "Next Buffer" },
		},
	},
	{
		"neovim/nvim-lspconfig",
		opts = {
			diagnostics = { virtual_text = false, virtual_lines = false },
			inlay_hints = { enabled = false },
		},
	},
	{
		"nvim-lualine/lualine.nvim",
		opts = function(_, opts)
			opts.options.icons_enabled = false
			opts.options.component_separators = ""
			opts.options.section_separators = ""
			opts.sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = {
					{ "filename", path = 1, symbols = { modified = "[+]", readonly = "[RO]", unnamed = "[New]" } },
				},
				lualine_x = { { "filetype", colored = false }, "location" },
				lualine_y = {},
				lualine_z = {},
			}
			opts.inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = { { "filename", path = 1 } },
				lualine_x = { "location" },
				lualine_y = {},
				lualine_z = {},
			}
		end,
	},
	{
		"folke/noice.nvim",
		opts = function(_, opts)
			-- Leave errors in the normal command line and :messages instead of popups.
			opts.messages = { enabled = false }
			opts.cmdline = { enabled = false }
			opts.lsp = vim.tbl_deep_extend("force", opts.lsp or {}, {
				progress = { enabled = false },
				message = { enabled = false },
			})
			opts.routes = opts.routes or {}
			table.insert(opts.routes, 1, { filter = { event = "notify" }, opts = { skip = true } })
		end,
	},
}
