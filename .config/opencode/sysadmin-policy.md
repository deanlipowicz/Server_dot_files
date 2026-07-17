# System Administration Policy

This machine is managed via opencode. All system mutations require explicit approval.

## Boundaries

- No sudo, su, doas, pkexec, or privilege escalation without explicit user approval.
- No package installs, removals, or updates (`apt`, `apt-get`, `dpkg`, `snap`, `pip install --system`) without approval.
- No service restarts, enable/disable, or masking (`systemctl`, `service`) without approval.
- No filesystem mutations outside the workspace (`/etc`, `/usr/local`, `/opt`, `/boot`, `/var`) without approval.
- No kernel module loading/unloading, udev rule changes, or boot parameter edits without approval.

## Host state

- Check `ops-agent-docs` reference and `server-baseline.md` before proposing host changes.
- Inspect with read-only probes first: `lspci`, `lsmod`, `modinfo`, `dpkg -l`, `systemctl status`, `journalctl --since`.
- For ROCm/GPU: use the `rocm-diagnostics` skill for probe sequences.

## Secrets

- Never read, write, embed, or echo API keys, tokens, passwords, or SSH private keys into any file, configuration, prompt, or conversation.
- Use environment variable references (`{env:VAR_NAME}`) in configuration files.

## Change discipline

- Prefer reversible changes. Record exact commands and paths.
- Snapshot or back up before mutating system config files.
- After any approved system change, verify with a read-only probe.
- For source builds: use `source-building` skill; build as normal user, stage with `DESTDIR`, review before any install.
- Keep log output bounded. Summarize with `rg`, `sed -n`, `tail -n`, or `journalctl --since`.
