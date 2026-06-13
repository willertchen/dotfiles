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
- Shell: zsh + Oh My Zsh + Powerlevel10k
- Node.js via fnm
- Homebrew at `/opt/homebrew`
- OrbStack (Docker/Linux VMs)

## Templates

Use chezmoi templates (`.tmpl`) when a value differs per machine. The main variable to know:

```
{{ .chezmoi.homeDir }}   → /Users/willert
{{ .chezmoi.hostname }}  → machine hostname
{{ .chezmoi.os }}        → darwin
```

Example: `dot_gitconfig.tmpl` can reference `{{ .chezmoi.homeDir }}` instead of hardcoding `/Users/willert`.

## Git Operations

Claude should **never** run `git add` or `git commit` autonomously. Always present the changes and let the user decide when and what to stage and commit.

Safe read-only git commands Claude may run freely:
- `git status`, `git diff`, `git log`, `git show`

## What NOT to commit

- `~/.ssh/id_rsa`, `~/.ssh/leju_github` — private keys
- `~/.zsh_history`
- `~/.oh-my-zsh/` — installed tool, not config
- Any `.env` files or files containing secrets
