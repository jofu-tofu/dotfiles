# .dotfiles

Personal Linux configuration repository for tracking and deploying user configuration files across machines.

## Purpose

This repo is a centralized store for all Linux user configuration. Files are organized to mirror their destination paths relative to `$HOME`. The `install.sh` script symlinks everything into place.

Long-term this may evolve into a NixOS-style declarative setup, but for now it tracks per-app config files and utility scripts.

## Repository Structure

```
.dotfiles/
├── install.sh              # Symlink installer script
├── bin/                    # Scripts for ~/bin (on $PATH via .profile)
│   └── raise-terminals.py  # Super+T keybind: cycle/raise terminal windows
├── home/                   # Dotfiles that go directly into ~/
│   ├── .bashrc
│   ├── .zshrc
│   ├── .profile
│   ├── .gitconfig
│   └── .npmrc
└── config/                 # Files for ~/.config/ and other ~/. directories
    ├── ghostty/config      # -> ~/.config/ghostty/config
    ├── claude/settings.json # -> ~/.claude/settings.json
    └── codex/config.toml   # -> ~/.codex/config.toml
```

## Install

```sh
./install.sh
```

The script does two things:

1. **Installs dependencies** — git, zsh, starship, flatpak, Claude Code, Codex, and Gear Lever (via Flatpak).
2. **Symlinks config files** — backs up any existing files to `~/.dotfiles-backup/` before creating symlinks.

## Conventions

- `bin/` entries are symlinked to `~/bin/` and are expected to be on `$PATH` (added by `.profile`).
- `home/` entries are symlinked directly into `~/`.
- `config/` entries map to their respective `~/.config/` or `~/.{name}/` directories.
- When adding a new config file, place it in the appropriate directory and add a mapping in `install.sh`.
- Do not commit secrets or credentials (`.credentials.json`, SSH keys, auth tokens).
