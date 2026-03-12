# Linux-only environment (Windows env is set in .bashrc before exec zsh)
if [[ -z "$MSYSTEM" ]]; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    export SUDO_ASKPASS="$HOME/.local/bin/sudo-askpass.sh"
    export PATH="$HOME/.local/bin:$PATH"
    # bun
    [ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
else
    # Strip PATH entries with spaces (e.g. "Program Files") from inherited Windows PATH
    PATH=$(echo "$PATH" | tr ':' '\n' | grep -v ' ' | tr '\n' ':' | sed 's/:$//')
fi

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS

# Completion
autoload -Uz compinit
compinit -C

# Autosuggestions
[[ -f "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
    source "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"

# Starship prompt (fall back to basic prompt if unavailable)
if [[ -n "$MSYSTEM" ]] && [[ -x "$HOME/bin/starship.exe" ]]; then
    eval "$("$HOME/bin/starship.exe" init zsh)"
elif command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
else
    autoload -Uz vcs_info
    precmd() { vcs_info }
    zstyle ':vcs_info:git:*' formats ' %F{cyan}(%b)%f'
    setopt PROMPT_SUBST
    PROMPT='%F{green}%~%f${vcs_info_msg_0_} %F{red}$%f '
fi

# Zoxide
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# fzf (Ctrl+R history, Ctrl+T file finder)
if command -v fzf >/dev/null 2>&1; then
    eval "$(fzf --zsh)"
fi

# Aliases
alias cdx='aiw launch --codex'
alias dvn='aiw launch --devin'
if command -v eza >/dev/null 2>&1; then
    alias ls='eza'
    alias ll='eza -la --git'
    alias tree='eza --tree'
fi

# Custom cd function to support ~p shortcut
cd() {
  if [ "$1" = "~p" ]; then
    builtin cd "$PAI_DIR"
  else
    builtin cd "$@"
  fi
}
