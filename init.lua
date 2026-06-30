-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Detect macOS dark mode
local function is_dark_mode()
  local handle = io.popen("defaults read -g AppleInterfaceStyle 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    return result:match("Dark") ~= nil
  end
  return false
end

-- Set background and Catppuccin flavour based on system appearance
local flavour = is_dark_mode() and "macchiato" or "latte"
vim.o.background = is_dark_mode() and "dark" or "light"

-- Indentation
vim.opt.tabstop     = 4   -- visual width of a tab character
vim.opt.shiftwidth  = 4   -- >> / << and auto-indent step
vim.opt.softtabstop = 4   -- <Tab> in insert mode inserts this many spaces
vim.opt.expandtab   = true -- use spaces, not tabs

-- Plugins
require("lazy").setup({
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = flavour,
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin")
    end,
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    opts = {},
  },

  -- Syntax highlighting
  -- Uses the new nvim-treesitter rewrite (Neovim 0.12+); highlight/indent are Neovim built-ins.
  -- Requires: tree-sitter-cli (brew install tree-sitter-cli)
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      -- Install parsers (async, no-op if already installed)
      require("nvim-treesitter").install({
        "c", "cpp", "lua", "vim", "vimdoc", "markdown", "markdown_inline",
      })
    end,
  },

  -- Multi-cursor (like Ctrl+D in VSCode)
  { "mg979/vim-visual-multi" },

  -- File explorer
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {},
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
    },
  },

  -- Auto-close brackets/parens/quotes
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },

  -- LSP
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- Override clangd defaults from nvim-lspconfig using the native 0.11+ API
      vim.lsp.config("clangd", {
        cmd = {
          "/opt/homebrew/opt/llvm/bin/clangd",
          "--background-index",
          "--clang-tidy",
          "--header-insertion=iwyu",
          "--completion-style=detailed",
        },
        -- Fallback flags when no compile_commands.json is present
        init_options = {
          fallbackFlags = { "--std=c++23", "-stdlib=libc++" },
        },
      })
      vim.lsp.enable("clangd")

      -- Keymaps applied whenever any LSP attaches
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local map = function(keys, fn, desc)
            vim.keymap.set("n", keys, fn, { buffer = args.buf, desc = desc })
          end
          map("gd",         vim.lsp.buf.definition,     "Go to definition")
          map("gD",         vim.lsp.buf.declaration,    "Go to declaration")
          map("gi",         vim.lsp.buf.implementation, "Go to implementation")
          map("gr",         vim.lsp.buf.references,     "References")
          map("K",          vim.lsp.buf.hover,          "Hover docs")
          map("<leader>rn", vim.lsp.buf.rename,         "Rename symbol")
          map("<leader>ca", vim.lsp.buf.code_action,    "Code action")
          map("[d",         vim.diagnostic.goto_prev,   "Prev diagnostic")
          map("]d",         vim.diagnostic.goto_next,   "Next diagnostic")
        end,
      })
    end,
  },
})
