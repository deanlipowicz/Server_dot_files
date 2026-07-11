# ──────────────────────────────────────────────
#  ZSH Configuration — Oh My Zsh + Powerlevel10k
# ──────────────────────────────────────────────

# -------- Instant Prompt (must be first) --------
# Powerlevel10k instant prompt: must be at the very top
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# -------- Path to Oh My Zsh --------
export ZSH="$HOME/.oh-my-zsh"

# -------- Theme: Powerlevel10k --------
ZSH_THEME="powerlevel10k/powerlevel10k"
# Use Nerd Font icons (JetBrainsMono Nerd Font installed locally)
POWERLEVEL9K_MODE="nerdfont-v3"

# -------- Plugin Configuration --------
# zsh-syntax-highlighting must be LAST in the plugins list
plugins=(
  git
  zsh-autocomplete
  zsh-autosuggestions
  web-search
  colored-man-pages
  copyfile
  copypath
  zsh-autopair
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# -------- Powerlevel10k Configuration --------
# To reconfigure: p10k configure
[[ ! -f "$HOME/.p10k.zsh" ]] || source "$HOME/.p10k.zsh"

# -------- PATH --------
# Append critical paths (no duplicates)
typeset -U path
path=(
  "$HOME/bin"
  "$HOME/.cargo/bin"
  "$HOME/.pi/bin"
  "$HOME/.local/bin"
  "$HOME/.atuin/bin"
  "$HOME/.opencode/bin"
  $path
)

# -------- Environment Variables --------
export EDITOR="nvim"
export VISUAL="nvim"
export CMDSTAN_HOME="$HOME/.cmdstan/cmdstan-2.39.0"
export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --follow --exclude .git 2>/dev/null || find . -type f'
export FZF_DEFAULT_OPTS="--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8,fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc,marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
export HIP_VISIBLE_DEVICES="0"
export HSA_OVERRIDE_GFX_VERSION="11.0.0"
export DEEPSEEK_API_KEY="{{DEEPSEEK_API_KEY}}"
export HIP_FORCE_DEV_KERNARG="1"

# -------- Options --------
setopt AUTO_CD                     # type dir name to cd into it
setopt EXTENDED_GLOB               # #, ~, ^ in globs

# -------- History Settings --------
HISTSIZE=50000
SAVEHIST=50000
HISTFILE="$HOME/.zsh_history"
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY

# -------- Atuin (magical shell history, replaces Ctrl+R) --------
if command -v atuin &>/dev/null; then
  source "$HOME/.atuin/bin/env"
  eval "$(atuin init zsh)"
fi

# -------- Completion --------
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' keep-prefix true
zstyle ':completion:*' recent-dirs-insert both

# -------- Apt: auto-sudo, and update upgrades everything --------
# `apt update`      → apt + cargo + atuin + rustup + uv + npm + gh
#                       + R libs + nvim plugins + yazi plugins + oh-my-zsh
#                       + zsh plugins + p10k + fwupd
# `apt install foo` → sudo apt install foo
# `sudo apt update` → normal apt update only (escape hatch)
# `apt update -y`   → same as `apt update` (extra flags ignored)
apt() {
  if [[ "$1" == "update" ]]; then
    # ── System packages ──
    command sudo apt update -y && command sudo apt upgrade -y

    # ── Cargo crates ──
    if command -v cargo-install-update &>/dev/null; then
      echo ""
      echo "── Updating Cargo packages ──"
      cargo install-update -a
    fi

    # ── Atuin shell history ──
    if command -v atuin-update &>/dev/null; then
      echo ""
      echo "── Updating Atuin ──"
      atuin-update 2>/dev/null || true
    fi

    # ── Rust toolchain ──
    if command -v rustup &>/dev/null; then
      echo ""
      echo "── Updating Rust toolchain ──"
      rustup update
    fi

    # ── uv tools (Python tools) ──
    if command -v uv &>/dev/null; then
      echo ""
      echo "── Updating uv tools ──"
      uv tool upgrade --all 2>/dev/null || uv tool upgrade --all
    fi

    # ── npm global packages ──
    if command -v npm &>/dev/null; then
      echo ""
      echo "── Updating npm global packages ──"
      npm update -g 2>/dev/null
    fi

    # ── GitHub CLI extensions ──
    if command -v gh &>/dev/null; then
      echo ""
      echo "── Updating GitHub CLI extensions ──"
      gh extension upgrade --all 2>/dev/null || true
    fi

    # ── R libraries ──
    if command -v R &>/dev/null; then
      echo ""
      echo "── Updating R libraries ──"
      R -e 'update.packages(ask=FALSE, repos="https://cloud.r-project.org")' 2>/dev/null
    fi

    # ── Neovim plugins (Lazy.nvim) ──
    if command -v nvim &>/dev/null; then
      echo ""
      echo "── Updating Neovim plugins ──"
      nvim --headless "+Lazy sync" +'quitall' 2>/dev/null
    fi

    # ── Yazi plugins ──
    if command -v ya &>/dev/null; then
      echo ""
      echo "── Updating Yazi plugins ──"
      ya pkg upgrade 2>/dev/null || true
    fi

    # ── Oh My Zsh ──
    if [[ -f "$ZSH/tools/upgrade.sh" ]]; then
      echo ""
      echo "── Updating Oh My Zsh ──"
      zsh "$ZSH/tools/upgrade.sh" 2>/dev/null || true
    fi

    # ── ZSH custom plugins (git pull) ──
    if [[ -d "$ZSH_CUSTOM/plugins" ]]; then
      echo ""
      echo "── Updating ZSH custom plugins ──"
      for plugin in "$ZSH_CUSTOM/plugins/"*(/); do
        if [[ -d "$plugin/.git" ]]; then
          git -C "$plugin" pull --ff-only 2>/dev/null || true
        fi
      done
    fi

    # ── Powerlevel10k ──
    local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if [[ -d "$p10k_dir/.git" ]]; then
      echo ""
      echo "── Updating Powerlevel10k ──"
      git -C "$p10k_dir" pull --ff-only 2>/dev/null || true
    fi

    # ── Firmware updates (fwupd) ──
    if command -v fwupdmgr &>/dev/null; then
      echo ""
      echo "── Checking firmware updates ──"
      fwupdmgr refresh 2>/dev/null || true
    fi

    echo ""
    echo "✓ All updates complete"
  else
    command sudo apt "$@"
  fi
}

# -------- Aliases --------
# Listing
alias ll='eza -l --icons --git'
alias la='eza -la --icons --git'
alias l='eza --icons'
alias ls='eza --icons'
alias tree='eza --tree --icons'

# Core utils
alias rg='/usr/bin/rg'
alias fd='fdfind'
alias cat='bat --paging=never'
alias bat='batcat'

# Navigation & tools
alias lg='lazygit'
alias tm='tmux new-session -A -s "$(basename "$(pwd)")" 2>/dev/null || tmux new-session -A -s main'
alias oc='opencode'

# Orchard R REPL (function shadows zsh's built-in `r`)
r() { orchard "$@"; }

# Config shortcuts
alias zshrc='$EDITOR ~/.zshrc'
alias zshconfig='$EDITOR ~/.zshrc'
alias ohmyzsh='$EDITOR ~/.oh-my-zsh'

# Workstation SSHFS mount
alias wsmount='sshfs workstation@workstation.tail13c816.ts.net:Documents ~/workstation-docs -o ControlPath=~/.ssh/workstation-socket -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3'
alias wsumount='fusermount -u ~/workstation-docs 2>/dev/null || umount ~/workstation-docs'

# Notification
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history | tail -n1 | sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Custom
alias ocr='systemctl --user start nanonets-ocr-drop.service'

# Suffix aliases — open files by typing their name
alias -s {md,txt,qmd,R,py,lua,json,toml,yaml,yml}=$EDITOR

# -----── Extract Any Archive --------
extract() {
  case "$1" in
    *.tar.gz|*.tgz) tar xzf "$1" ;;
    *.tar.xz)       tar xJf "$1" ;;
    *.tar.bz2)      tar xjf "$1" ;;
    *.zip)          unzip "$1" ;;
    *.rar)          unrar x "$1" ;;
    *.7z)           7z x "$1" ;;
    *)              echo "Unknown archive: $1" ;;
  esac
}

# -----── Magic Enter — show something useful on empty prompt --------
magic-enter() {
  if [[ -z "$BUFFER" ]]; then
    if git rev-parse --is-inside-work-tree 2>/dev/null; then
      git status -sb
    else
      eza --icons
    fi
    zle reset-prompt
  else
    zle accept-line
  fi
}
zle -N magic-enter
bindkey -M emacs "^M" magic-enter
bindkey -M viins "^M" magic-enter

# -------- Zoxide (smart cd) --------
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh --cmd j)"
  alias zi='zoxide query -i'   # interactive fzf picker
fi

# -------- FZF Key Bindings --------
if [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh
elif [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
  source /usr/share/fzf/key-bindings.zsh
fi

# -------- FZF Completion --------
if [[ -f /usr/share/doc/fzf/examples/completion.zsh ]]; then
  source /usr/share/doc/fzf/examples/completion.zsh
elif [[ -f /usr/share/fzf/completion.zsh ]]; then
  source /usr/share/fzf/completion.zsh
fi

# -----── tldr (simplified man pages) --------
# Cache the pages on first load if missing
if [[ ! -d "${XDG_CACHE_HOME:-$HOME/.cache}/tealdeer" ]]; then
  tldr --update &>/dev/null &
fi

# -----── Source cargo env --------
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# -----── Fastfetch (skip in tmux) --------
if [[ -z "$TMUX" ]] && command -v fastfetch &>/dev/null; then
  fastfetch --preset catppuccin-mocha 2>/dev/null
fi

# -----── SSH Agent (keychain) --------
if command -v keychain &>/dev/null; then
  eval "$(keychain --eval --agents ssh --quick id_ed25519 2>/dev/null)"
fi

# -----── GitHub CLI auth check (async — don't block startup) --------
if command -v gh &>/dev/null; then
  (gh auth status &>/dev/null || echo "  ! GitHub CLI not authenticated — run: gh auth login") &!
fi

# bun completions
[ -s "/home/workstation/.bun/_bun" ] && source "/home/workstation/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# === BUN MIGRATION START ===
# Ensure bun is in PATH (takes priority over any remaining Node/npm)
export PATH="$HOME/.bun/bin:$PATH"
# Aliases: npm, node, and npx now delegate to bun
alias npm='bun'
alias node='bun run'
alias npx='bunx'
# === BUN MIGRATION END ===
export PATH="$HOME/opt/quarto/bin:$PATH"
