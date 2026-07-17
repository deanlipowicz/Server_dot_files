---
name: pi-harness-config
description: Inspect and maintain the Pi harness on this Ubuntu server. Pi is a supervised statistical-computing helper harness with bounded coding, learning, and note-writing launchers. Use when building, modifying, or diagnosing specialised Pi harness configurations.
---

# Pi Harness Configuration

Pi is a human-directed helper harness, not an autonomous agent. It provides bounded coding (`pi-code`), learning (`pi-learn`), and note-writing (`pi-note`) workflows. Configuration lives under `~/.pi/`.

Do not change research questions, estimands, modeling strategy, assumptions, variable definitions, or final interpretation. Those belong to the user.

## Discovery (read-only, bounded)

```sh
command -v pi || true
pi --version 2>/dev/null || true
find ~/.pi -maxdepth 3 -type f 2>/dev/null | sort | head -160
find ~/.config/pi ~/.cache/pi ~/.local/share/pi-node -maxdepth 3 -type f 2>/dev/null | sort | head -160
tmux list-sessions 2>/dev/null || true
```

Inspect scripts and environment references:
```sh
rg -n "PI_|pi-|tmux|node|npm|opencode|codex|OPENROUTER|API_KEY|TOKEN" ~/.pi ~/.config/pi ~/.local/bin ~/.local/share/pi-node 2>/dev/null | head -160
find ~/.pi -maxdepth 3 -type f -perm -111 2>/dev/null | sort
```

## Launcher matrix (pattern for building specialised harnesses)

| Launcher | Purpose | Tools | Mutation boundary |
|---|---|---|---|
| `pi-code` | Statistical coding | `read,bash,edit,write` | `plan-gate.ts`: plan required before edits/writes |
| `pi-learn` | Tutoring from resources | `read,bash` | Read-only by default |
| `pi-note` | OKF note conversion | `read,bash,edit,write` | `plan-gate.ts`: plan required before note creation |

Each launcher maps to a distinct tool/skill set. This pattern is reusable when building new specialised pi harness configurations: define the task domain, select the tool surface, and choose the mutation boundary (plan-gated or read-only).

## Supported languages (coding workflow)

DuckDB SQL, R, C++, Stan, HTML/CSS/JavaScript. Pi writes/inspects/explains source but does not assume it can run interpreters or build tools.

## Safety

- No sudo, destructive recursive file commands, or package manager mutations without approval.
- No raw source-data reads into conversation; no mutation under `data/raw/`.
- Pre-mutation checkpoints: snapshot to `.artifacts/checkpoints/` before changes.
- Back up exact files before approved edits: `cp -a file ~/ops-agent/backups/pi-harness/<stamp>/file.before`.

## Verification

```sh
bash -n ~/.pi/bin/pi-code && bash -n ~/.pi/bin/pi-learn && bash -n ~/.pi/bin/pi-note
~/.pi/bin/pi-code --help && ~/.pi/bin/pi-learn --help && ~/.pi/bin/pi-note --help
~/.pi/bin/pi-sync-check    # compatibility check after harness edits
```

Helper commands: `pi-budget-check`, `pi-context`, `pi-resume-notes`, `pi-env-audit`, `stanc-check`.

## Common failure modes

- `pi` only in local pi-node tree, not on PATH.
- Shell startup files missing Pi/Node path.
- Stale tmux sessions; scripts assume paths that have moved.
- Node/npm version mismatch from Pi install version.
- API keys missing from interactive environment (do not write keys to files to fix this).
- Logs too large — summarize with `rg`, Perl filters.

See also: `terminal-apps` reference (`pi.md`), `ops-agent-docs` runbook `pi-harness.md`, `server-baseline.md`.
