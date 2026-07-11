#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.config-bak/$(date +%Y-%m-%d_%H%M%S)"

echo "=== Server_dot_files Deploy ==="
echo ""

# ── Backup existing configs ──
echo "Backing up current configs to $BACKUP_DIR ..."
mkdir -p "$BACKUP_DIR"

for f in .zshrc .zshenv .bash_aliases .bashrc .profile .tmux.conf .gitconfig .p10k.zsh; do
    if [ -f "$HOME/$f" ]; then
        cp "$HOME/$f" "$BACKUP_DIR/$f"
        echo "  backed up ~/$f"
    fi
done

if [ -d "$HOME/.config/nvim" ]; then
    cp -a "$HOME/.config/nvim" "$BACKUP_DIR/.config/nvim"
    echo "  backed up ~/.config/nvim"
fi

if [ -f "$HOME/.ssh/config" ]; then
    mkdir -p "$BACKUP_DIR/.ssh"
    cp "$HOME/.ssh/config" "$BACKUP_DIR/.ssh/config"
    echo "  backed up ~/.ssh/config"
fi

echo ""

# ── Deploy home files ──
echo "Deploying repo configs ..."
cp "$REPO_ROOT/.zshrc"       ~/.zshrc
cp "$REPO_ROOT/.zshenv"      ~/.zshenv
cp "$REPO_ROOT/.bash_aliases" ~/.bash_aliases
cp "$REPO_ROOT/.bashrc"      ~/.bashrc
cp "$REPO_ROOT/.profile"     ~/.profile
cp "$REPO_ROOT/.tmux.conf"   ~/.tmux.conf
cp "$REPO_ROOT/.gitconfig"   ~/.gitconfig
cp "$REPO_ROOT/.p10k.zsh"    ~/.p10k.zsh

if [ -d "$REPO_ROOT/bin" ]; then
    mkdir -p ~/bin
    cp -a "$REPO_ROOT/bin/." ~/bin/ 2>/dev/null || true
fi

mkdir -p ~/.ssh
cp "$REPO_ROOT/.ssh/config"  ~/.ssh/config

# ── Deploy .config directories ──
for dir in nvim yazi ghostty bat btop fastfetch micro harlequin opencode atuin nushell obsidian; do
    if [ -d "$REPO_ROOT/.config/$dir" ]; then
        mkdir -p "$HOME/.config/$dir"
        cp -a "$REPO_ROOT/.config/$dir/." "$HOME/.config/$dir/"
        echo "  deployed .config/$dir"
    fi
done

echo ""
echo "✓ Deploy complete. Backups in $BACKUP_DIR"
