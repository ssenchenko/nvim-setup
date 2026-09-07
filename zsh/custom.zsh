# Portable zsh customizations from nvim-setup.
# Sourced from ~/.zshrc via a single line added by `make zsh`.
# Machine-specific setup (brew, nvm, cargo, work env vars) stays in the
# target machine's own ~/.zshrc / ~/.zprofile and is intentionally NOT here.

# ls colors
export CLICOLOR=1
export LSCOLORS=ExGxFxDxCxDxDxhbhdacad
alias ls='ls -G'
alias ll='ls -alG'

# Use Neovim as vim
alias vim='nvim'

# --- WezTerm integration ---------------------------------------------------

# Home/End -> start/end of line (Cmd+Left/Right in WezTerm send these).
# Bind terminfo values plus common fallbacks so it works regardless of TERM.
bindkey "${terminfo[khome]}" beginning-of-line 2>/dev/null
bindkey "${terminfo[kend]}"  end-of-line       2>/dev/null
bindkey '\e[H'  beginning-of-line
bindkey '\e[F'  end-of-line
bindkey '\eOH'  beginning-of-line
bindkey '\eOF'  end-of-line
bindkey '\e[1~' beginning-of-line
bindkey '\e[4~' end-of-line

# Report cwd to the terminal via OSC 7 (lets WezTerm show the dir in tab titles)
_osc7_cwd() { printf '\033]7;file://%s%s\033\\' "${HOST}" "${PWD}"; }
autoload -Uz add-zsh-hook
add-zsh-hook chpwd _osc7_cwd
_osc7_cwd  # emit once for the starting directory

# Ring the terminal bell when a command runs longer than N seconds. WezTerm's
# `bell` handler turns this into a desktop toast only if the tab/window isn't
# focused, so you get pinged when a long task finishes in the background.
_NOTIFY_CMD_THRESHOLD=10   # seconds; bump/lower to taste
typeset -g _notify_cmd_start=0
_notify_preexec() { _notify_cmd_start=$SECONDS }
_notify_precmd() {
  local ret=$?   # exit status of the command that just finished (capture first!)
  if (( _notify_cmd_start > 0 )); then
    if (( SECONDS - _notify_cmd_start >= _NOTIFY_CMD_THRESHOLD )); then
      # Report exit status to WezTerm as a user var, then ring the bell.
      printf '\033]1337;SetUserVar=cmd_status=%s\033\\' "$(printf '%s' "$ret" | base64)"
      printf '\a'
    fi
    _notify_cmd_start=0
  fi
}
add-zsh-hook preexec _notify_preexec
add-zsh-hook precmd _notify_precmd

# --- Starship prompt (keep last so it initializes after everything else) ---
# Guarded: without this the whole file errors out on a machine where the
# `make starship` step hasn't run (or brew isn't on PATH yet).
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
else
  echo "custom.zsh: starship not found — run 'make starship' in tools-setup (or 'brew install starship')" >&2
fi
