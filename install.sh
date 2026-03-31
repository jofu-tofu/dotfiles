#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
APT_PACKAGES=(ca-certificates curl flatpak git nodejs npm python3 tmux zsh)

# --- Dependencies ---

install_apt_packages() {
    echo "System packages..."
    sudo apt update -y
    sudo apt install -y "${APT_PACKAGES[@]}"
}

install_starship() {
    if command -v starship &>/dev/null; then
        echo "starship already installed"
        return
    fi

    echo "Installing starship..."
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y
}

install_claude() {
    if command -v claude &>/dev/null; then
        echo "claude already installed"
        return
    fi

    echo "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | sh
}

install_codex() {
    local npm_prefix

    if command -v codex &>/dev/null; then
        echo "codex already installed"
        return
    fi

    echo "Installing Codex..."
    npm_prefix="$(npm config get prefix 2>/dev/null || true)"

    if [[ "$npm_prefix" == "$HOME"* ]]; then
        npm install -g @openai/codex
    else
        sudo npm install -g @openai/codex
    fi
}

install_bun() {
    if command -v bun &>/dev/null; then
        echo "bun already installed"
        return
    fi

    echo "Installing Bun..."
    curl -fsSL https://bun.sh/install | bash
}

install_uv() {
    if command -v uv &>/dev/null; then
        echo "uv already installed"
        return
    fi

    echo "Installing uv..."
    env UV_NO_MODIFY_PATH=1 sh -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'
}

install_flatpak_apps() {
    echo "Setting up Flatpak + Gear Lever..."
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    flatpak install -y flathub it.mijorus.gearlever || true
    flatpak install -y flathub md.obsidian.Obsidian || true
}

install_deps() {
    echo "=== Installing dependencies ==="
    echo

    install_apt_packages
    echo

    install_starship
    install_bun
    install_uv
    install_claude
    install_codex
    echo

    install_flatpak_apps

    echo
    echo "=== Dependencies done ==="
    echo
}

install_deps

# --- Templating ---

# Files containing {{HOME}} need sed substitution instead of symlinks.
# Generates the file in-place at the destination.
TEMPLATE_FILES=(
    "config/claude/settings.json"
    "config/codex/config.toml"
    "config/obsidian/obsidian.json"
)

template_file() {
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

    sed "s|{{HOME}}|$HOME|g" "$src" > "$dest"
    local local_file="${src}.local"
    if [ -f "$local_file" ]; then
        cat "$local_file" >> "$dest"
        echo "  generated $dest (from template + .local)"
    else
        echo "  generated $dest (from template)"
    fi
}

is_template() {
    local rel="$1"
    for t in "${TEMPLATE_FILES[@]}"; do
        if [ "$rel" = "$t" ]; then
            return 0
        fi
    done
    return 1
}

# --- Git identity ---

setup_git_identity() {
    if [ -f "$HOME/.gitconfig-user" ]; then
        echo "~/.gitconfig-user already exists, skipping"
        return
    fi

    echo "No ~/.gitconfig-user found. Setting up git identity..."
    read -rp "  Git name: " git_name
    read -rp "  Git email: " git_email

    cat > "$HOME/.gitconfig-user" <<EOF
[user]
	name = $git_name
	email = $git_email
EOF
    echo "  created ~/.gitconfig-user"
}

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

link_tree() {
    local src_root="$1"
    local dest_root="$2"
    local src
    local rel

    while IFS= read -r -d '' src; do
        [[ "$src" == *.local ]] && continue
        rel="${src#$DOTFILES_DIR/}"
        local file_rel="${src#$src_root/}"
        if is_template "$rel"; then
            template_file "$src" "$dest_root/$file_rel"
        else
            link_file "$src" "$dest_root/$file_rel"
        fi
    done < <(find "$src_root" -type f -print0)
}

link_config_entries() {
    local entry
    local name
    local dest_root

    for entry in "$DOTFILES_DIR"/config/*; do
        [ -e "$entry" ] || continue

        name="$(basename "$entry")"

        case "$name" in
            claude)
                dest_root="$HOME/.claude"
                ;;
            codex)
                dest_root="$HOME/.codex"
                ;;
            obsidian)
                dest_root="$HOME/.var/app/md.obsidian.Obsidian/config/obsidian"
                ;;
            *)
                dest_root="$HOME/.config/$name"
                ;;
        esac

        echo "$name/"

        if [ -d "$entry" ]; then
            link_tree "$entry" "$dest_root"
        else
            local rel="config/$name"
            if is_template "$rel"; then
                template_file "$entry" "$dest_root"
            else
                link_file "$entry" "$dest_root"
            fi
        fi

        echo
    done
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
    [[ "$f" == *.local ]] && continue
    local_file="${f}.local"
    if [ -f "$local_file" ]; then
        dest="$HOME/$(basename "$f")"
        mkdir -p "$BACKUP_DIR" 2>/dev/null || true
        if [ -e "$dest" ] && [ ! -L "$dest" ]; then
            backup_path="$BACKUP_DIR/${dest#$HOME/}"
            mkdir -p "$(dirname "$backup_path")"
            mv "$dest" "$backup_path"
            echo "  backed up $dest -> $backup_path"
        elif [ -L "$dest" ]; then
            rm "$dest"
        fi
        cat "$f" "$local_file" > "$dest"
        echo "  merged $dest (repo + .local)"
    else
        link_file "$f" "$HOME/$(basename "$f")"
    fi
done
echo

# ~/.config/ files
echo "config/"
link_config_entries

# Git identity
echo "git identity/"
setup_git_identity
echo

echo "Done."
