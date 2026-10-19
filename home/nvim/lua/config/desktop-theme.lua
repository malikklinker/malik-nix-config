local M = {}
local state = vim.env.XDG_STATE_HOME
local directory = (state and state ~= "" and state or (vim.env.HOME .. "/.local/state")) .. "/desktop-theme"

function M.apply()
  local file = io.open(directory .. "/theme.json", "r")
  if not file then
    return
  end
  local text = file:read("*a")
  file:close()
  local ok, theme = pcall(vim.json.decode, text)
  if not ok or not theme.palette then
    return
  end
  vim.o.background = theme.variant == "light" and "light" or "dark"
  require("mini.base16").setup({ palette = theme.palette, use_cterm = true })
  vim.g.colors_name = "desktop"
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
        M.apply()
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
