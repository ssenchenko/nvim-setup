# tools-setup

My terminal toolchain as a set of dotfiles: **WezTerm**, **Neovim**, **zsh +
starship**, and **git + delta** — all themed [Catppuccin](https://catppuccin.com)
and following the macOS light/dark appearance.

A `make install` copies each config to where the tool expects it and installs
the handful of Homebrew packages they depend on.

```bash
git clone git@gitlab.com:s.senchenko/tools-setup.git
cd tools-setup
make install
```

## What's in here

| Path                  | Installs to                        | What it is                                        |
| --------------------- | ---------------------------------- | ------------------------------------------------- |
| `wezterm/.wezterm.lua`| `~/.wezterm.lua`                   | Terminal: theme, keys, tab titles, notifications   |
| `nvim/`               | `~/.config/nvim/`                  | Neovim config (see [nvim/README.md](nvim/README.md)) |
| `zsh/custom.zsh`      | `~/.config/zsh/custom.zsh`         | Shell aliases, keybindings, WezTerm integration    |
| `zsh/starship.toml`   | `~/.config/starship.toml`          | Prompt                                             |
| `git/delta.gitconfig` | `~/.config/git/delta.gitconfig` \* | Side-by-side syntax-highlighted `git diff`         |

\* Not installed by `make` — see [git diff](#git-diff) below.

## Make targets

| Target           | Does                                                      |
| ---------------- | --------------------------------------------------------- |
| `make install`   | Everything below                                          |
| `make font`      | `brew install --cask font-cascadia-code-nf`                |
| `make starship`  | `brew install starship`                                    |
| `make nvim`      | Copies the Neovim config                                   |
| `make wezterm`   | Copies `.wezterm.lua`                                      |
| `make zsh`       | Copies the zsh snippet + starship config, sources it from `~/.zshrc` |

Every target is safe to re-run.

## How your existing files are treated

This repo tries hard not to clobber anything you already have:

- **Copied files** (`.wezterm.lua`, the nvim config, the zsh/starship/delta
  configs) are backed up to `<file>.bak` first, but only when the contents
  actually differ.
- **`~/.zshrc` is never overwritten.** `make zsh` appends a single `source` line,
  and only if it isn't already there. Machine-specific setup (brew shellenv,
  nvm, cargo, work variables) stays in your own `~/.zshrc` / `~/.zprofile` and is
  deliberately not tracked here.
- **`~/.gitconfig` is never touched** by any target. The delta config is wired in
  by hand with a single `include.path` entry (below), so your `[user]` block and
  anything else you've set is left alone.

## Requirements

- **macOS** with [Homebrew](https://brew.sh) — the theme switching and the
  `brew install` steps are macOS-specific.
- **Neovim ≥ 0.11**, **tree-sitter CLI**, and **LLVM/clangd** for the editor;
  see [nvim/README.md](nvim/README.md) for the details.
- `font-cascadia-code-nf` and `starship` are installed by `make install`.
- `git-delta` is **not** — install it yourself if you want the diff setup.

If Homebrew is missing, the `font` and `starship` targets print a warning
and continue rather than failing the build — the configs still get installed, and
the tools degrade gracefully until you install the binaries.

## Theme switching

Everything follows the system appearance, but not by the same mechanism, and the
difference matters:

- **WezTerm** uses `wezterm.gui.get_appearance()` and re-evaluates its config on
  every light/dark flip, so the terminal repaints live.
- **git/delta** gets its theme from WezTerm, which exports `DELTA_FEATURES` via
  `set_environment_variables`. That is applied to *newly spawned* panes, so open
  a new tab after the system theme changes.

Note that `defaults read -g AppleInterfaceStyle` — the usual shell one-liner for
this — **does not work if you have macOS appearance set to "Auto"**. In Auto mode
the key is simply absent regardless of the appearance actually in effect, so the
check silently reports "light" forever. That's why the appearance is read from
WezTerm rather than from the shell.

## WezTerm keys

These are the bindings this config adds; WezTerm's own defaults still apply for
everything else.

| Key                | Action              |
| ------------------ | ------------------- |
| `Cmd+T` / `Cmd+W`  | New / close tab     |
| `Cmd+1`…`Cmd+9`    | Jump to tab N       |
| `Cmd+D`            | Split left/right    |
| `Cmd+Shift+D`      | Split top/bottom    |
| `Cmd+←` / `Cmd+→`  | Start / end of line |

## Shell niceties

`zsh/custom.zsh` adds a few things beyond aliases:

- **Tab titles show the current directory** — the shell reports its cwd to
  WezTerm over OSC 7, and the terminal renders the folder name.
- **Background-task notifications** — any command running longer than 10 seconds
  (`_NOTIFY_CMD_THRESHOLD`) rings the bell on completion. WezTerm turns that into
  a desktop toast, and flashes the tab, but only when you aren't already looking
  at that pane. The command's exit status rides along in the toast.

## git diff

`git/delta.gitconfig` configures [delta](https://github.com/dandavison/delta) as
the pager, so `git diff` renders side-by-side with syntax highlighting, per-side line numbers,
and clickable file paths. `n` / `N` jump between hunks while paging.

It also turns on a few things that matter as much as the renderer:
`diff.algorithm = histogram` (much better hunk alignment than the default Myers),
`diff.colorMoved` (moved blocks colored distinctly from real additions), and
`merge.conflictstyle = zdiff3` (conflict markers keep the common ancestor).

There is no `make` target for this yet — wire it up by hand:

```bash
brew install git-delta
cp git/delta.gitconfig ~/.config/git/delta.gitconfig
git config --global --add include.path ~/.config/git/delta.gitconfig
```

The theme comes from `DELTA_FEATURES`, which the WezTerm config exports; without
it delta falls back to the Catppuccin Macchiato (dark) theme.
