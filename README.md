# Zsh Configuration Flake

My personal Zsh configuration managed with Nix flakes.

## Features

- Oh-My-Zsh with git, vi-mode, z, and direnv plugins
- Zsh syntax highlighting and history substring search
- Starship prompt
- Mise runtime manager
- Custom Git aliases and shell shortcuts

## Usage
```bash
nix run .
```

Or in a development shell:
```bash
nix develop
zsh-with-config
```

## Home Manager Integration

This flake exports a `lib.mkZshConfig` function for use with home-manager.
