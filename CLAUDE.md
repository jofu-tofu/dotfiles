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
│   ├── .tmux.conf
│   ├── .profile
│   ├── .gitconfig
│   └── .npmrc
└── config/                 # Files for ~/.config/ and other ~/. directories
    ├── starship.toml       # -> ~/.config/starship.toml
    ├── ghostty/config      # -> ~/.config/ghostty/config
    ├── claude/settings.json # -> ~/.claude/settings.json
    └── codex/config.toml   # -> ~/.codex/config.toml
```

## Install

```sh
./install.sh
```

The script does two things:

1. **Installs dependencies** — system packages (`ca-certificates`, `curl`, `git`, `nodejs`, `npm`, `zsh`, `tmux`, `flatpak`) first, then Starship, Claude Code, Codex, and Gear Lever (via Flatpak).
2. **Symlinks config files** — backs up any existing files to `~/.dotfiles-backup/` before creating symlinks.

## Conventions

- `bin/` entries are symlinked to `~/bin/` and are expected to be on `$PATH` (added by `.profile`).
- `home/` entries are symlinked directly into `~/`.
- `config/` entries map automatically by top-level name:
  - most entries go to `~/.config/{name}/...` or `~/.config/{file}`
  - `config/claude/` maps to `~/.claude/`
  - `config/codex/` maps to `~/.codex/`
- When adding a new config file under `config/`, you only need to update `install.sh` if it belongs outside `~/.config/` and is not one of the existing special cases.
- Do not commit secrets or credentials (`.credentials.json`, SSH keys, auth tokens).
