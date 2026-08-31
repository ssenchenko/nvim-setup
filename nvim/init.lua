-- Leader keys (must be set before lazy.nvim and any mappings)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Editor settings
vim.opt.number = true         -- absolute line numbers
vim.opt.relativenumber = true -- relative numbers on other lines (hybrid)
vim.opt.signcolumn = "yes"    -- always show sign column (stable gutter for LSP)
vim.opt.scrolloff = 8         -- keep 8 lines of context around the cursor
vim.opt.colorcolumn = "100"   -- width guide at column 100
vim.opt.termguicolors = true  -- 24-bit color (needed for Catppuccin fidelity)
vim.opt.ignorecase = true     -- case-insensitive search...
vim.opt.smartcase = true      -- ...unless the query contains an uppercase letter

-- Persistent undo (survives closing a file)
local undodir = vim.fn.stdpath("state") .. "/undo"
vim.fn.mkdir(undodir, "p")
vim.opt.undodir = undodir
vim.opt.undofile = true

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

  -- Render mermaid code blocks inline as ASCII/Unicode art (no terminal graphics needed).
  -- Shells out to `node` (managed by nvm here), so only load when node is on PATH;
  -- otherwise warn clearly instead of failing with a cryptic ENOENT.
  {
    "kais-radwan/ascii-mermaid",
    ft = "markdown",
    cond = function()
      if vim.fn.executable("node") == 1 then
        return true
      end
      vim.schedule(function()
        vim.notify(
          "ascii-mermaid: `node` not found on PATH (it's managed by nvm). "
            .. "Launch nvim from a shell where nvm has loaded node.",
          vim.log.levels.WARN
        )
      end)
      return false
    end,
    opts = {},
  },

  -- Syntax highlighting
  -- Uses the new nvim-treesitter rewrite (Neovim 0.12+); highlight/indent are Neovim built-ins.
  -- The rewrite compiles parsers with the tree-sitter CLI. Homebrew's `tree-sitter`
  -- formula ships only the library, so install the CLI separately:
  --   brew install tree-sitter-cli
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    -- Only (re)build parsers when the tree-sitter CLI is available.
    build = function()
      if vim.fn.executable("tree-sitter") == 1 then
        vim.cmd("TSUpdate")
      end
    end,
    config = function()
      -- Without the CLI, install fails with a cryptic ENOENT, so check first
      -- and surface an actionable message instead.
      if vim.fn.executable("tree-sitter") == 0 then
        vim.notify(
          "nvim-treesitter: `tree-sitter` CLI not found on PATH. "
            .. "Install it with `brew install tree-sitter-cli`, then run `:TSUpdate`.",
          vim.log.levels.WARN
        )
        return
      end

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
