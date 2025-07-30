# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository for zsh shell configuration and development tools. The repository contains shell configuration files, git utilities, and a custom zsh git prompt implementation.

## Key Components

### Shell Configuration
- `zshrc.local`: Main zsh configuration with environment setup, PATH management, aliases, and custom functions
- `_zshrc.local`: Additional zsh configuration focused on PATH and basic setup
- `gitconfig.local`: Git configuration with VS Code as diff/merge tool

### Git Utilities
- `git-large-file-fix`: Functions for handling GitHub's large file rejections, including automated cleanup with BFG or git filter-branch
- `sync-terminal-history.sh`: Script to backup and sync terminal history across machines using git

### Zsh Git Prompt (Third-party)
- `zsh-git-prompt/`: Complete git prompt implementation with both Python and Haskell versions
- Provides informative git status in shell prompt (branch, ahead/behind, staged files, etc.)

## Development Commands

### Zsh Git Prompt (Haskell version)
```bash
cd zsh-git-prompt/
stack setup    # Install Haskell compiler
stack build && stack install    # Build and install locally
```

### Shell History Management
```bash
# Backup terminal history
./sync-terminal-history.sh backup

# Restore terminal history
./sync-terminal-history.sh restore
```

### Git Large File Utilities
- `git_fix_rejected_push [branch]`: Automatically find and remove large files from git history
- `git_detect_rejected_files "error_message"`: Parse GitHub error messages to identify problematic files
- `git_paste_fix`: Use clipboard content to detect and fix rejected files

## Key Aliases and Functions

### Git Shortcuts
- `status` → `git status`
- `commit` → `git commit`
- `add` → `git add .`
- `new` → `git checkout -b`
- `gl` → `git log --oneline --decorate --graph -10`
- `_rebase` → `git pull origin main --rebase`

### Development Tools
- `refresh` → `exec zsh` (reload shell)
- `z` → `vim ~/dotfiles/zshrc.local` (edit zsh config)
- `build` → `red; mikey; make tests` (project-specific build sequence)

### Kubernetes Utilities
- `k` → `kubectl`
- `kx` → Interactive pod shell selector with fzf
- `kxa` → API app container shell selector

## Environment Setup

The repository configures:
- Python development with pyenv and automatic virtual environment activation
- Node.js with fnm (Fast Node Manager)
- Go development environment
- Docker/Colima integration
- Google Cloud SDK integration
- Various development tools (fzf, jump, direnv)

## Architecture Notes

- The zsh configuration is split across multiple files for modularity
- Custom git utilities focus on GitHub integration and large file handling
- The git prompt implementation supports both Python and Haskell backends for performance
- Terminal history syncing enables cross-machine development workflow
- Automatic Python environment detection based on `.python-version` files