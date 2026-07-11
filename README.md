# Server_dot_files

Minimal dot files backup. This repo mirrors `$HOME` directly — no symlinks, no
bare repos, no template engine.

## Quick start

```bash
# Clone
git clone git@github.com:deanlipowicz/Server_dot_files.git ~/Server_dot_files

# Restore configs on a fresh machine (backs up existing configs first)
cd ~/Server_dot_files && ./deploy.sh

# Sync local changes back after editing configs
cd ~/Server_dot_files && ./sync.sh

# Unattended sync (for cron jobs)
cd ~/Server_dot_files && ./sync.sh --push
```

## What's tracked

**Home files:** `.zshrc`, `.zshenv`, `.bash_aliases`, `.bashrc`, `.profile`,
`.tmux.conf`, `.gitconfig`, `.p10k.zsh`, `~/bin/` scripts

**.config/:** nvim, yazi, ghostty, bat, btop, fastfetch, micro, harlequin,
opencode, atuin, nushell, obsidian

**Other:** `.ssh/config` (client config only — no keys)

**Excluded:** history files, caches, secrets, API keys are scrubbed during sync

---

## Tool Inventory

Everything installed on this system — whether configured directly in these dot
files or used by tools that are.

### Shell & Terminal

| Tool | Role | How it's installed |
|------|------|-------------------|
| **zsh** | Shell | apt (default) |
| Oh My Zsh | Zsh plugin framework | curl install |
| Powerlevel10k | Zsh theme | git clone |
| zsh-autosuggestions | Zsh plugin | git clone |
| zsh-syntax-highlighting | Zsh plugin | git clone |
| **tmux** | Terminal multiplexer | apt |
| **Ghostty** | Terminal emulator | binary release |

### File Management & Navigation

| Tool | Role | How it's installed |
|------|------|-------------------|
| **eza** | `ls` replacement (icons, git status) | apt |
| **bat** / batcat | `cat` replacement with syntax highlighting | apt |
| **fd** / fdfind | `find` replacement | apt |
| **ripgrep** | `grep` replacement | apt |
| **fzf** | Fuzzy finder | apt |
| **zoxide** | `cd` replacement | apt |
| **yazi** | Terminal file manager | cargo |
| **ncdu** | Disk usage analyzer | apt |
| **sd** | Search & replace | cargo |

### Version Control

| Tool | Role | How it's installed |
|------|------|-------------------|
| **git** | VCS | apt |
| **gh** | GitHub CLI | apt / .deb |
| **lazygit** | Git TUI | GitHub release |
| **delta** | Git diff viewer | cargo |
| **git-filter-repo** | Git history rewriting | pip |
| **pre-commit** | Git hook framework | pip |

### Editors

| Tool | Role | How it's installed |
|------|------|-------------------|
| **neovim** | Primary editor | apt |
| **micro** | Fallback terminal editor | binary/install.sh |
| **opencode** | AI coding assistant | curl install |

### Neovim — Plugins & Tooling

| Component | Role |
|-----------|------|
| LazyVim | Plugin framework & starter |
| nvim-lspconfig | LSP client config |
| nvim-treesitter | Syntax trees & highlighting |
| telescope.nvim | Fuzzy finder (files, grep, LSP) |
| harpoon | Quick file navigation |
| which-key | Keymap discovery popups |
| conform.nvim | Auto-formatting |
| nvim-lint | Linting integration |
| blink.cmp | Autocompletion engine |
| minuet-ai | AI inline completion |
| vimtex | LaTeX editing |
| noice.nvim | UI replacement (cmdline, messages) |
| nui.nvim | UI component library |
| snacks.nvim | Quick UI elements |
| gitsigns.nvim | Git decorations |
| toggleterm.nvim | Terminal inside Neovim |
| todo-comments.nvim | TODO/FIXME highlighting |
| indent-blankline.nvim | Indent guides |

### Language Runtimes

| Tool | Version | Source |
|------|---------|--------|
| **Python** | 3.12 | apt |
| **R** | 4.6.1 | CRAN (apt) |
| **Node.js** | (via bun) | bun |
| **Rust** | latest | rustup |
| **Lua** | 5.1, 5.4 | apt |
| **Perl** | 5.38 | apt |
| **C/C++** | gcc/g++ 13 | apt |
| **LaTeX** | LuaLaTeX | apt (texlive) |

### Package Managers

| Tool | For |
|------|-----|
| apt | System packages |
| cargo / cargo-update | Rust tools |
| bun | Node.js runtime & packages |
| pip | Python packages |
| uv | Python package manager |
| luarocks | Lua packages |
| rustup | Rust toolchains |

### Language Servers (LSP)

| Server | Language | How installed |
|--------|----------|--------------|
| pyright | Python | pip |
| lua-language-server | Lua | GitHub release |
| bash-language-server | Bash | npm / bun |
| typescript-language-server | TypeScript | npm / bun |
| vscode-css-language-server | CSS | npm / bun |
| vscode-eslint-language-server | JS/TS linting | npm / bun |
| vscode-html-language-server | HTML | npm / bun |
| vscode-json-language-server | JSON | npm / bun |
| vscode-markdown-language-server | Markdown | npm / bun |
| yaml-language-server | YAML | npm / bun |
| sql-language-server | SQL | npm / bun |
| stan-language-server | Stan | npm / bun |
| marksman | Markdown | GitHub release |
| texlab | LaTeX | cargo |
| clangd | C/C++ | apt |
| r-languageserver | R | R (install.packages) |

### Data & Databases

| Tool | Role | How installed |
|------|------|--------------|
| **duckdb** | Embedded analytical database | pip / binary |
| **harlequin** | TUI database IDE (duckdb, sqlite) | pip |
| **jq** | JSON processor | apt |
| **yq** | YAML processor | apt |
| **sqlite** | SQLite (harlequin adapter) | bundled with harlequin |

### System & Monitoring

| Tool | Role | How installed |
|------|------|--------------|
| **btop** | Resource monitor | apt |
| **fastfetch** | System info display | apt |
| **ncdu** | Disk usage analyzer | apt |
| rsync | File sync | apt |
| curl | HTTP client | apt |
| wget | Download tool | apt |
| screen | Terminal multiplexer | apt |
| sshfs | Remote filesystem mount | apt |

### AI & ML

| Tool | Role | How installed |
|------|------|--------------|
| **ollama** | Local LLM runner | curl install |
| **opencode** | AI coding agent | curl install |
| minuet-ai | AI inline completion in Neovim | lazy.nvim plugin |
| DeepSeek API | LLM backend for shell / opencode | API key (scrubbed in repo) |

### Security & Auth

| Tool | Role | How installed |
|------|------|--------------|
| **pass** | Password store (GPG-based) | apt |
| **ssh** | Remote access | apt |
| **sshfs** | Remote filesystem mount | apt |
| **keychain** | SSH agent manager | apt |
| Bitwarden CLI | Password manager | npm / bun |
| google-authenticator | 2FA | apt |
| GnuPG | Encryption suite | apt |

### Shell History & Docs

| Tool | Role | How installed |
|------|------|--------------|
| **atuin** | Shell history (encrypted, synced) | binary |
| **tealdeer** / tldr | Community-driven man pages | apt / bun |

### Custom Scripts (bin/)

| Script | Purpose |
|--------|---------|
| docker-compose | Docker Compose (standalone binary) |
| migrate-to-bun.sh | Migrate npm project to bun |
| rollback-bun-migration.sh | Undo bun migration |
| nanonets-ocr-drop-worker | OCR worker (systemd service) |
| tesseract-ocr-drop-worker | Tesseract OCR worker |
| open-notebook-start | Start Jupyter notebook server |
| open-notebook-stop | Stop Jupyter notebook |
| open-notebook-status | Check notebook status |
| open-notebook-idle-watch | Auto-stop idle notebook sessions |
| open-notebook-configure-* | Configure notebook kernels |

### Ops & Orchestration

| Tool | Role | How installed |
|------|------|--------------|
| **orchard** | R task orchestration engine | cargo |
| **quarto** | Scientific publishing system | binary |
| **stow** | Symlink-based dot file manager | pip |
| **systemd** | Service management | (OS) |
| **cron** | Periodic job scheduler | (OS) |
| **docker-compose** | Container orchestration | (in bin/) |

### Config Locations

| App | Config path |
|-----|------------|
| Zsh | `~/.zshrc` |
| Tmux | `~/.tmux.conf` |
| Git | `~/.gitconfig` |
| Powerlevel10k | `~/.p10k.zsh` |
| Ghostty | `~/.config/ghostty/config` |
| Neovim | `~/.config/nvim/` |
| Yazi | `~/.config/yazi/` |
| Bat | `~/.config/bat/config` |
| Btop | `~/.config/btop/btop.conf` |
| Fastfetch | `~/.config/fastfetch/presets/` |
| Micro | `~/.config/micro/settings.json` |
| Harlequin | `~/.config/harlequin/config.toml` |
| OpenCode | `~/.config/opencode/opencode.jsonc` |
| Atuin | `~/.config/atuin/config.toml` |
| Nushell | `~/.config/nushell/config.nu` |
| Obsidian | `~/.config/obsidian/` |
| SSH | `~/.ssh/config` |
