# tldr

Versions: `tealdeer 1.6.1` (apt) and `tldr 3.5.0` (npm). The npm version is the primary client.

`tldr` provides simplified, example-driven man pages. It replaces reading full `man` pages with concise practical examples for commands you use daily.

## Quick Start

```bash
tldr ls          # examples for ls
tldr tar         # common tar patterns
tldr git log     # git log examples
```

## What It Replaces

| Instead of | Use | Why |
|-----------|-----|-----|
| `man ls` | `tldr ls` | 5 examples vs 200 lines of documentation |
| `man tar` | `tldr tar` | See compress/extract patterns instantly |


## Common Commands

| Command | Use |
| --- | --- |
| `tldr <cmd>` | Show examples for a command |
| `tldr --list` | List all available pages |
| `tldr --update` | Update the page cache |

## Quick Workflow

```bash
# Can't remember the tar flags?
tldr tar          # → extract: tar xzf archive.tar.gz
                  # → create:   tar czf archive.tar.gz dir/

# Find a git command you don't use often?
tldr git rebase   # → examples with common rebase patterns
```

If the apt `tldr` (tealdeer) cache doesn't load, the npm client handles the request instead.
