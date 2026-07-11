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
