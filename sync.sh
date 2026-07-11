#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
PUSH=false

if [[ "${1:-}" == "--push" ]]; then
    PUSH=true
fi

echo "=== Sync: $HOME → Server_dot_files ==="
echo ""

# ── Home files ──
echo "  • .zshrc";        cp ~/.zshrc       "$REPO_ROOT/.zshrc"
echo "  • .zshenv";       cp ~/.zshenv      "$REPO_ROOT/.zshenv"
echo "  • .bash_aliases"; cp ~/.bash_aliases "$REPO_ROOT/.bash_aliases"
echo "  • .bashrc";       cp ~/.bashrc      "$REPO_ROOT/.bashrc"
echo "  • .profile";      cp ~/.profile     "$REPO_ROOT/.profile"
echo "  • .tmux.conf";    cp ~/.tmux.conf   "$REPO_ROOT/.tmux.conf"
echo "  • .gitconfig";    cp ~/.gitconfig   "$REPO_ROOT/.gitconfig"
echo "  • .p10k.zsh";     cp ~/.p10k.zsh    "$REPO_ROOT/.p10k.zsh"

echo "  • bin/";          mkdir -p "$REPO_ROOT/bin" && cp -a ~/bin/. "$REPO_ROOT/bin/" 2>/dev/null || true

mkdir -p "$REPO_ROOT/.ssh"
echo "  • .ssh/config";   cp ~/.ssh/config  "$REPO_ROOT/.ssh/config"

# ── .config directories ──
echo "  • Neovim";        rm -rf "$REPO_ROOT/.config/nvim" && cp -a ~/.config/nvim "$REPO_ROOT/.config/nvim"
echo "  • Yazi";          mkdir -p "$REPO_ROOT/.config/yazi" && cp -a ~/.config/yazi/. "$REPO_ROOT/.config/yazi/" 2>/dev/null || true
echo "  • Ghostty";       mkdir -p "$REPO_ROOT/.config/ghostty" && cp ~/.config/ghostty/config "$REPO_ROOT/.config/ghostty/config" 2>/dev/null || true
echo "  • Bat";           mkdir -p "$REPO_ROOT/.config/bat" && cp ~/.config/bat/config "$REPO_ROOT/.config/bat/config" 2>/dev/null || true
echo "  • Bat themes";    mkdir -p "$REPO_ROOT/.config/bat/themes" && cp -a ~/.config/bat/themes/. "$REPO_ROOT/.config/bat/themes/" 2>/dev/null || true
echo "  • Btop";          mkdir -p "$REPO_ROOT/.config/btop" && cp -a ~/.config/btop/. "$REPO_ROOT/.config/btop/" 2>/dev/null || true
echo "  • Fastfetch";     mkdir -p "$REPO_ROOT/.config/fastfetch" && cp -a ~/.config/fastfetch/. "$REPO_ROOT/.config/fastfetch/" 2>/dev/null || true
echo "  • Micro";         mkdir -p "$REPO_ROOT/.config/micro" && cp -a ~/.config/micro/. "$REPO_ROOT/.config/micro/" 2>/dev/null || true
echo "  • Harlequin";     mkdir -p "$REPO_ROOT/.config/harlequin" && cp ~/.config/harlequin/config.toml "$REPO_ROOT/.config/harlequin/config.toml" 2>/dev/null || true
echo "  • OpenCode";      mkdir -p "$REPO_ROOT/.config/opencode" && cp -a ~/.config/opencode/. "$REPO_ROOT/.config/opencode/" 2>/dev/null || true
echo "  • Atuin";         mkdir -p "$REPO_ROOT/.config/atuin" && cp -a ~/.config/atuin/. "$REPO_ROOT/.config/atuin/" 2>/dev/null || true
echo "  • Nushell";       mkdir -p "$REPO_ROOT/.config/nushell" && cp -a ~/.config/nushell/. "$REPO_ROOT/.config/nushell/" 2>/dev/null || true
echo "  • Obsidian";      mkdir -p "$REPO_ROOT/.config/obsidian" && cp -a ~/.config/obsidian/. "$REPO_ROOT/.config/obsidian/" 2>/dev/null || true

# ── Commit ──
cd "$REPO_ROOT"
git add -A

if git diff --cached --quiet; then
    echo ""
    echo "  Nothing changed — no commit needed."
    exit 0
fi

TIMESTAMP=$(date "+%Y-%m-%d %H:%M")
git commit -m "sync: $TIMESTAMP"
COMMIT_SHA=$(git rev-parse --short HEAD)
echo ""
echo "  ✓ Committed as $COMMIT_SHA"

# ── Push ──
if [ "$PUSH" = true ]; then
    git push
    echo "  ✓ Pushed to origin."
else
    echo ""
    echo "  Push to GitHub? (y/N): "
    read -r REPLY </dev/tty
    if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
        git push
        echo "  ✓ Pushed."
    else
        echo "  Skipped push. Run: git push"
    fi
fi
