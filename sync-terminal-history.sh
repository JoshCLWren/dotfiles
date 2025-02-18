#!/bin/bash

# Configuration
HISTORY_DIR="$HOME/.terminal_history"
HISTORY_REPO="$HISTORY_DIR/repo"
: "${TERMINAL_HISTORY_REMOTE:?Environment variable TERMINAL_HISTORY_REMOTE must be set}"
GIT_REMOTE="$TERMINAL_HISTORY_REMOTE"
BASH_HISTORY="$HOME/.bash_history"
ZSH_HISTORY="$HOME/.zsh_history"

# Create necessary directories
mkdir -p "$HISTORY_DIR"
mkdir -p "$HISTORY_REPO"

# Initialize git repository if it doesn't exist
if [ ! -d "$HISTORY_REPO/.git" ]; then
    cd "$HISTORY_REPO"
    git init
    git remote add origin "$GIT_REMOTE"
    echo "Git repository initialized"
fi

# Function to backup history files
backup_history() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    # Backup bash history if it exists
    if [ -f "$BASH_HISTORY" ]; then
        cp "$BASH_HISTORY" "$HISTORY_REPO/bash_history_$timestamp"
        echo "Backed up bash history"
    fi
    
    # Backup zsh history if it exists
    if [ -f "$ZSH_HISTORY" ]; then
        cp "$ZSH_HISTORY" "$HISTORY_REPO/zsh_history_$timestamp"
        echo "Backed up zsh history"
    fi
}

# Function to commit and push changes
sync_history() {
    cd "$HISTORY_REPO"
    
    # Check if there are any changes
    if git status --porcelain | grep -q '^'; then
        git add .
        git commit -m "History backup $(date)"
        git push origin master
        echo "Changes committed and pushed"
    else
        echo "No changes to sync"
    fi
}

# Function to restore history
restore_history() {
    cd "$HISTORY_REPO"
    git pull origin master
    
    # Get the most recent history files
    local latest_bash=$(ls -t bash_history_* 2>/dev/null | head -n1)
    local latest_zsh=$(ls -t zsh_history_* 2>/dev/null | head -n1)
    
    if [ -n "$latest_bash" ]; then
        cp "$latest_bash" "$BASH_HISTORY"
        echo "Restored bash history"
    fi
    
    if [ -n "$latest_zsh" ]; then
        cp "$latest_zsh" "$ZSH_HISTORY"
        echo "Restored zsh history"
    fi
}

# Main execution
case "$1" in
    "backup")
        backup_history
        sync_history
        ;;
    "restore")
        restore_history
        ;;
    *)
        echo "Usage: $0 {backup|restore}"
        exit 1
        ;;
esac
