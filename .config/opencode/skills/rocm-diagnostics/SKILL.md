---
name: rocm-diagnostics
description: Diagnose AMD GPU, ROCm, amdgpu kernel module, OpenCL, HIP, and compute-runtime issues on Ubuntu. Use when GPU visibility, ROCm visibility, driver loading, or compute-runtime failures occur.
---

# ROCm Diagnostics

Diagnose AMD GPU and ROCm issues on Ubuntu with read-only probes. Separate hardware visibility, kernel driver state, ROCm user-space packages, permissions/groups, and application runtime issues.

## Probe sequence (read-only)

Run these from the ops-agent workspace or any directory:

```sh
./scripts/gpu-probe     # PCI visibility, amdgpu module, bounded kernel messages, DRM sysfs cards
./scripts/rocm-probe    # ROCm/OpenCL user-space: rocminfo, amd-smi, rocm-smi, clinfo
```

Scripts are at `/home/workstation/ops-agent/scripts/gpu-probe` and `/home/workstation/ops-agent/scripts/rocm-probe`. Logs go to `ops-agent/logs/gpu-probe-*.log` and `ops-agent/logs/rocm-probe-*.log`.

## Manual bounded probes

```sh
lspci -nn | grep -Ei 'vga|3d|display|amd|ati'
lsmod | grep -E '^(amdgpu|amdkfd|kfd)'
modinfo amdgpu | grep -E '^(filename|version|srcversion|depends|vermagic|parm):' | head -80
dmesg --color=never 2>/dev/null | grep -Ei 'amdgpu|kfd|drm|gpu|firmware|error|fail|warn' | tail -120
rocminfo | grep -E '^(Agent |  Name:|  Marketing Name:|  Device Type:|  Chip ID:|  BDFID:)'
```

If kernel logs are unreadable without sudo, record that limitation and continue with PCI, module, sysfs, and ROCm probes.

## Expected dual-GPU evidence

- RX 7600 XT / Navi 33: PCI device `1002:7480`, commonly at `03:00.0`.
- Ryzen 8700G iGPU / Phoenix: PCI device `1002:15bf`, commonly at `0d:00.0`.
- ROCm should show two GPU agents when both are visible to the runtime.

## Visibility variables (record, do not set)

```text
HIP_VISIBLE_DEVICES
ROCR_VISIBLE_DEVICES
CUDA_VISIBLE_DEVICES
GPU_DEVICE_ORDINAL
HSA_OVERRIDE_GFX_VERSION
```

For one-off app testing, set visibility only in the command environment. Do not export globally unless there is a documented operational reason.

## Safety

- Do not use sudo for routine diagnostics.
- Do not reset GPUs, unload/reload modules, set clocks/fan speeds, or change power limits.
- Do not recommend driver changes without an explicit rollback note.
- Ask before changing kernel modules, groups, packages, udev rules, boot parameters, services, or ROCm installations.
- Document exact commands and version evidence.
- See also: `ops-agent-docs` runbook `rocm-diagnostics.md`, `server-baseline.md`.
- For installation, PyTorch wheel matching, MIOpen troubleshooting, and performance tuning: use the `rocm-configuration` skill.

## Redundant installation checks

```bash
# System ROCm: should be exactly one version
ls -d /opt/rocm-* 2>/dev/null
du -sh /opt/rocm-* 2>/dev/null

# Python venvs: each torch copy is 14-16 GB waste
find ~/.local/share/uv -name "torch" -path "*/site-packages/*" -maxdepth 8 2>/dev/null

# Apt packages: all should share the same version prefix
dpkg -l | grep -E 'rocm|amdgpu-dkms' | awk '{print $2, $3}'
```
