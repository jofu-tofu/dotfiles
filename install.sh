#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# --- Dependencies ---

install_deps() {
    echo "=== Installing dependencies ==="
    echo

    # apt packages: git, zsh, flatpak
    echo "apt packages..."
    sudo apt update -y
    sudo apt install -y git zsh flatpak

    # Starship prompt
    if ! command -v starship &>/dev/null; then
        echo "Installing starship..."
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    else
        echo "starship already installed"
    fi

    # Claude Code
    if ! command -v claude &>/dev/null; then
        echo "Installing Claude Code..."
        curl -fsSL https://claude.ai/install.sh | sh
    else
        echo "claude already installed"
    fi

    # Codex (via npm — requires node/npm)
    if ! command -v codex &>/dev/null; then
        echo "Installing Codex..."
        npm install -g @openai/codex
    else
        echo "codex already installed"
    fi

    # Flatpak: add Flathub and install Gear Lever
    echo "Setting up Flatpak + Gear Lever..."
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    flatpak install -y flathub it.mijorus.gearlever || true

    echo
    echo "=== Dependencies done ==="
    echo
}

install_deps

# --- Symlinks ---

link_file() {
    local src="$1"
    local dest="$2"

    mkdir -p "$(dirname "$dest")"

    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        mkdir -p "$BACKUP_DIR"
        local backup_path="$BACKUP_DIR/${dest#$HOME/}"
        mkdir -p "$(dirname "$backup_path")"
        mv "$dest" "$backup_path"
        echo "  backed up $dest -> $backup_path"
    elif [ -L "$dest" ]; then
        rm "$dest"
    fi

    ln -s "$src" "$dest"
    echo "  linked $dest -> $src"
}

echo "Installing dotfiles from $DOTFILES_DIR"
echo

# ~/bin scripts
echo "bin/"
for f in "$DOTFILES_DIR"/bin/*; do
    [ -e "$f" ] || continue
    link_file "$f" "$HOME/bin/$(basename "$f")"
done
echo

# ~/ home dotfiles
echo "home/"
for f in "$DOTFILES_DIR"/home/.*; do
    [ -f "$f" ] || continue
    link_file "$f" "$HOME/$(basename "$f")"
done
echo

# ~/.config/ files
echo "config/"
link_file "$DOTFILES_DIR/config/ghostty/config" "$HOME/.config/ghostty/config"
echo

# ~/.claude/ files
echo "claude/"
link_file "$DOTFILES_DIR/config/claude/settings.json" "$HOME/.claude/settings.json"
echo

# ~/.codex/ files
echo "codex/"
link_file "$DOTFILES_DIR/config/codex/config.toml" "$HOME/.codex/config.toml"
echo

echo "Done."
