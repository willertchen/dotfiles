# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This is a [chezmoi](https://www.chezmoi.io/) dotfiles repository. It manages configuration files that get deployed to `$HOME` on macOS machines.

The source files here map to `$HOME` on the target machine. chezmoi uses filename prefixes to encode metadata:
- `dot_` → `.` (e.g. `dot_zshrc` → `~/.zshrc`)
- `private_` → file with mode 0600
- `executable_` → file with mode 0755
- `.tmpl` suffix → Go template, processed before deployment

## Key Commands

```bash
chezmoi add ~/.zshrc          # start tracking a new file
chezmoi edit ~/.zshrc         # edit a managed file (edits source, not target)
chezmoi diff                  # preview what would change in $HOME
chezmoi apply                 # apply source → $HOME
chezmoi status                # show which managed files differ from $HOME
chezmoi re-add                # sync changes made directly in $HOME back to source
```

## Environment

The target machine is macOS (Apple Silicon) with:
- Shell: zsh + zimfw + Powerlevel10k (p10k loaded via zimfw module `romkatv/powerlevel10k`)
- Terminal: cmux (Ghostty-based), config at `~/.config/ghostty/config`
- Node.js via fnm
- Homebrew at `/opt/homebrew`
- OrbStack (Docker/Linux VMs)

Note: Oh My Zsh is archived under `archives/oh-my-zsh/` and no longer active. The `ohmyzsh/ohmyzsh` git plugin is still loaded via zimfw for git aliases.

## Managed Files

Files currently tracked by chezmoi:

```
dot_zshrc                     → ~/.zshrc
dot_zprofile                  → ~/.zprofile
dot_zimrc                     → ~/.zimrc
dot_p10k.zsh                  → ~/.p10k.zsh
dot_gitconfig.tmpl            → ~/.gitconfig  (Go template)
dot_gitignore_global          → ~/.gitignore_global
dot_czrc                      → ~/.czrc
dot_config/ghostty/config     → ~/.config/ghostty/config
archives/                     → reference only, not deployed
```

Machine-specific overrides go in `~/.zshrc.local` (sourced at the bottom of `~/.zshrc`, not tracked by chezmoi).

## Templates

Use chezmoi templates (`.tmpl`) when a value differs per machine. The main variable to know:

```
{{ .chezmoi.homeDir }}   → /Users/willert
{{ .chezmoi.hostname }}  → machine hostname
{{ .chezmoi.os }}        → darwin
```

`dot_gitconfig.tmpl` uses `{{ .chezmoi.homeDir }}` for `core.excludesfile` instead of hardcoding `/Users/willert`.

## General Behavior

**Ask before any operation.** Before editing files, running commands, or making any changes, Claude must describe the intended action and wait for explicit user approval. Do not proceed autonomously.

Read-only / inspection commands that are always safe to run without asking:
- `git status`, `git diff`, `git log`, `git show`
- `chezmoi diff`, `chezmoi status`
- `ls`, `cat`, reading files

## Git Operations

Claude should **never** run `git add` or `git commit` autonomously. Always present the changes and let the user decide when and what to stage and commit.

## What NOT to commit

- `~/.ssh/id_rsa`, `~/.ssh/leju_github` — private keys
- `~/.zsh_history`
- `~/.oh-my-zsh/` — installed tool, not config
- Any `.env` files or files containing secrets
