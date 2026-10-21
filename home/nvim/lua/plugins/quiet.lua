return {
  {
    "folke/snacks.nvim",
    opts = { notifier = { enabled = false } },
  },
  {
    "folke/noice.nvim",
    opts = function(_, opts)
      -- Leave errors in the normal command line and :messages instead of popups.
      opts.messages = { enabled = false }
      opts.lsp = vim.tbl_deep_extend("force", opts.lsp or {}, {
        progress = { enabled = false },
        message = { enabled = false },
      })
      opts.routes = opts.routes or {}
      table.insert(opts.routes, 1, { filter = { event = "notify" }, opts = { skip = true } })
    end,
  },
}
