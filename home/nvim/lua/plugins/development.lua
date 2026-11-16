return {
  {
    "folke/snacks.nvim",
    -- Quickfile starts highlighting before LazyVim's Tree-sitter settings apply.
    opts = { quickfile = { exclude = { "latex", "fortran" } } },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Explicit Nix paths avoid Mason downloads and incompatible ELF binaries.
        fortls = {
          mason = false,
          cmd = { "@fortls@", "--hover_signature", "--hover_language=fortran", "--use_signature_help" },
        },
        clangd = {
          mason = false,
          cmd = {
            "@clangd@",
            "--background-index",
            "--clang-tidy",
            "--completion-style=detailed",
            "--header-insertion=iwyu",
          },
        },
        lua_ls = { mason = false, cmd = { "@luaLanguageServer@" } },
        neocmake = { mason = false, cmd = { "@neocmake@", "stdio" } },
        taplo = { mason = false, cmd = { "@taplo@", "lsp", "stdio" } },
        jsonls = { mason = false, cmd = { "@jsonLanguageServer@", "--stdio" } },
        yamlls = { mason = false, cmd = { "@yamlLanguageServer@", "--stdio" } },
        bashls = { mason = false, cmd = { "@bashLanguageServer@", "start" } },
        nil_ls = { mason = false, cmd = { "@nil@" } },
        pyright = { mason = false, cmd = { "@pyright@", "--stdio" } },
        ruff = { mason = false, cmd = { "@ruff@", "server" } },
        texlab = { mason = false, cmd = { "@texlab@" } },
        marksman = { mason = false, cmd = { "@marksman@", "server" } },
      },
    },
  },
  {
    "mrcjkb/rustaceanvim",
    version = "^9",
    opts = {
      server = {
        cmd = { "@rustAnalyzer@" },
        default_settings = {
          ["rust-analyzer"] = {
            cargo = { allFeatures = false, sysrootSrc = "@rustSrc@" },
            check = { command = "clippy" },
          },
        },
      },
    },
    -- The Rust extra's optional Mason debugger bootstrap assumes a downloaded
    -- LLDB layout. Language support here uses Nix and needs no debugger download.
    config = function(_, opts)
      vim.g.rustaceanvim = vim.tbl_deep_extend("force", vim.g.rustaceanvim or {}, opts)
    end,
  },
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = vim.tbl_filter(function(tool)
        return tool ~= "codelldb"
      end, opts.ensure_installed or {})
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      -- Error recovery can color the IN in MIN_Y as a separate keyword.
      -- The Fortran ftplugin uses Neovim's built-in syntax highlighting instead.
      highlight = { disable = { "fortran" } },
      -- Incomplete program units can also lose their body indentation.
      indent = { disable = { "fortran" } },
      ensure_installed = { "fortran", "c", "cpp", "rust", "lua", "cmake", "make", "toml", "json", "yaml", "bash" },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        fortran = { "fprettify" },
        c = { "clang_format" },
        cpp = { "clang_format" },
        rust = { "rustfmt" },
        cmake = { "cmake_format" },
      },
      formatters = {
        fprettify = { command = "@fprettify@" },
        clang_format = { command = "@clangFormat@" },
        rustfmt = { command = "@rustfmt@" },
        cmake_format = { command = "@cmakeFormat@" },
      },
    },
  },
  {
    "Civitasv/cmake-tools.nvim",
    cmd = { "CMakeGenerate", "CMakeBuild", "CMakeRun", "CMakeSelectBuildType", "CMakeSelectBuildTarget" },
    keys = {
      { "<leader>m", desc = "+build" },
      { "<leader>mg", "<cmd>CMakeGenerate<cr>", desc = "CMake Configure" },
      { "<leader>mb", "<cmd>CMakeBuild<cr>", desc = "CMake Build" },
      { "<leader>mr", "<cmd>CMakeRun<cr>", desc = "CMake Run" },
      { "<leader>mt", "<cmd>CMakeSelectBuildTarget<cr>", desc = "CMake Target" },
    },
    opts = {
      cmake_generate_options = { "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" },
      cmake_notifications = { runner = { enabled = false }, executor = { enabled = false } },
    },
  },
}
