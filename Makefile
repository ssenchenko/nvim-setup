# Dotfiles installer — copies configs from this repo to their live locations.
#
#   make install    # install everything (font + nvim + wezterm + zsh)
#   make nvim       # just Neovim config
#   make wezterm    # just WezTerm config
#   make zsh        # just zsh + starship config
#   make font       # just the terminal font
#   make starship   # just the starship binary
#
# Existing files are backed up to <file>.bak before being overwritten.

SHELL := /bin/bash

REPO    := $(CURDIR)
HOME    ?= $(shell echo $$HOME)
CONFIG  := $(HOME)/.config

# Copy $1 -> $2, creating the parent dir and backing up any existing target.
define install_file
	@mkdir -p "$(dir $(2))"
	@if [ -e "$(2)" ] && ! cmp -s "$(1)" "$(2)"; then cp "$(2)" "$(2).bak"; echo "  backed up $(2) -> $(2).bak"; fi
	@cp "$(1)" "$(2)"
	@echo "  installed $(2)"
endef

.PHONY: install nvim wezterm zsh font starship

install: font starship nvim wezterm zsh
	@echo "All configs installed."

# Terminal font. The config references the family name "Cascadia Code NF";
# without it WezTerm falls back to another font and warns on every launch.
FONT_CASK   := font-cascadia-code-nf
FONT_FAMILY := Cascadia Code NF

font:
	@echo "==> font -> $(FONT_FAMILY)"
	@if system_profiler SPFontsDataType 2>/dev/null | grep -qF "Family: $(FONT_FAMILY)"; then \
		echo "  $(FONT_FAMILY) already installed"; \
	elif command -v brew >/dev/null 2>&1; then \
		brew install --cask $(FONT_CASK) && echo "  installed $(FONT_CASK)"; \
	else \
		echo "  WARNING: $(FONT_FAMILY) is missing and Homebrew was not found."; \
		echo "           Install it manually, or WezTerm will warn about the font on startup."; \
	fi

# Starship prompt binary. ~/.config/zsh/custom.zsh calls `starship init zsh`,
# so without it every new shell prints "command not found: starship".
starship:
	@echo "==> starship"
	@if command -v starship >/dev/null 2>&1; then \
		echo "  starship already installed ($$(command -v starship))"; \
	elif command -v brew >/dev/null 2>&1; then \
		brew install starship && echo "  installed starship"; \
	else \
		echo "  WARNING: starship is missing and Homebrew was not found."; \
		echo "           Install it from https://starship.rs, and make sure"; \
		echo "           'eval \"$$(/opt/homebrew/bin/brew shellenv)\"' is in ~/.zprofile."; \
	fi

nvim:
	@echo "==> nvim -> $(CONFIG)/nvim"
	$(call install_file,$(REPO)/nvim/init.lua,$(CONFIG)/nvim/init.lua)
	$(call install_file,$(REPO)/nvim/lazy-lock.json,$(CONFIG)/nvim/lazy-lock.json)
	$(call install_file,$(REPO)/nvim/README.md,$(CONFIG)/nvim/README.md)

wezterm:
	@echo "==> wezterm -> $(HOME)/.wezterm.lua"
	$(call install_file,$(REPO)/wezterm/.wezterm.lua,$(HOME)/.wezterm.lua)

# Installed location of the sourced snippet, and the exact line we add to ~/.zshrc.
ZSH_SNIPPET := $(CONFIG)/zsh/custom.zsh
ZSH_SOURCE_LINE := [ -f "$$HOME/.config/zsh/custom.zsh" ] && source "$$HOME/.config/zsh/custom.zsh"

zsh:
	@echo "==> zsh -> $(CONFIG)"
	$(call install_file,$(REPO)/zsh/starship.toml,$(CONFIG)/starship.toml)
	$(call install_file,$(REPO)/zsh/custom.zsh,$(ZSH_SNIPPET))
	@# Append the source line to ~/.zshrc only once — never overwrites the file.
	@touch "$(HOME)/.zshrc"
	@if grep -qF '.config/zsh/custom.zsh' "$(HOME)/.zshrc"; then \
		echo "  ~/.zshrc already sources the snippet — left untouched"; \
	else \
		printf '\n# nvim-setup: load portable zsh customizations\n%s\n' '$(ZSH_SOURCE_LINE)' >> "$(HOME)/.zshrc"; \
		echo "  appended source line to ~/.zshrc"; \
	fi
	@echo "  note: the starship binary itself is installed by the 'starship' target"
