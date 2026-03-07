#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

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
