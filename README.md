# nvim-setup

My personal [Neovim](https://neovim.io) configuration — a single self-contained
`init.lua` that uses [lazy.nvim](https://github.com/folke/lazy.nvim) for plugin
management.

## Features

- **lazy.nvim** — self-bootstrapping plugin manager (installs itself on first run)
- **Catppuccin** theme that auto-switches light/dark with the macOS system appearance
- **Treesitter** syntax highlighting (nvim-treesitter rewrite)
- **oil.nvim** file explorer — press `-` to open the parent directory
- **nvim-autopairs** and **vim-visual-multi** (VSCode-style multi-cursor)
- **render-markdown.nvim** for nicer Markdown rendering
- **clangd** LSP for C/C++ with common keymaps (`gd`, `gD`, `gi`, `gr`, `K`, `<leader>rn`, `<leader>ca`, `[d`, `]d`)

## Requirements

- **Neovim ≥ 0.11** (0.12+ recommended — uses the Treesitter rewrite and the native `vim.lsp` config API)
- **git** — used to bootstrap lazy.nvim and to clone this repo
- **tree-sitter CLI** — `brew install tree-sitter-cli`
- A **Nerd Font** — for file-explorer icons
- For C/C++: **LLVM / clangd** — `brew install llvm` (config expects `/opt/homebrew/opt/llvm/bin/clangd`)

## Use on another machine

1. Back up any existing config:

   ```bash
   mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null || true
   ```

2. Clone this repo into place and launch Neovim:

   ```bash
   git clone https://github.com/ssenchenko/nvim-setup.git ~/.config/nvim
   nvim
   ```

On first launch, lazy.nvim installs itself and all plugins, and Treesitter
parsers install automatically. Restart Neovim once it finishes.

## Update later

```bash
cd ~/.config/nvim && git pull
```

## Notes

- Light/dark detection uses `defaults read -g AppleInterfaceStyle` (macOS). On
  other operating systems it falls back to the light Catppuccin flavour.
- The clangd path targets Homebrew LLVM on Apple Silicon. On Intel macOS use
  `/usr/local/opt/llvm/bin/clangd`; adjust the path in `init.lua` as needed.
