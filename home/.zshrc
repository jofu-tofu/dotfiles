export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

autoload -Uz compinit
compinit

if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

export SUDO_ASKPASS="$HOME/.local/bin/sudo-askpass.sh"

# Aliases
alias cdx='aiw launch --codex'
alias dvn='aiw launch --devin'

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
