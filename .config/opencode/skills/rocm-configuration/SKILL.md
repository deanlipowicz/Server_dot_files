---
name: rocm-configuration
description: Use when installing, upgrading, or troubleshooting ROCm runtime and PyTorch ROCm wheels on Ubuntu. Also use when PyTorch ROCm crashes with MIOpen ISA errors, HIP kernel file errors, extreme GPU slowness vs CPU, matching ROCm system version to PyTorch wheel indices, or auditing for redundant ROCm installations.
---

# ROCm Configuration

Install, match, and troubleshoot ROCm runtime and PyTorch ROCm wheels on Ubuntu with AMD dGPU/iGPU hardware. Covers installation patterns, version matching, MIOpen stability, JIT warmup, and performance tuning for Navi 33 (gfx1102) and related architectures.

## When to use

- Installing ROCm runtime on Ubuntu from AMD's official repo
- Matching PyTorch ROCm wheel version to system ROCm version
- Fixing `hipErrorInvalidKernelFile` (code 218) or `HSA_STATUS_ERROR_INVALID_ISA` (code 0x100f) crashes
- Diagnosing GPU slower than CPU for inference workloads
- Setting up GPU isolation (`HIP_VISIBLE_DEVICES`) for multi-GPU systems
- Creating ROCm-compatible wrapper scripts for PyTorch applications
- Auditing a system for duplicate or stale ROCm/torch installations
- Setting up a shared Python venv for multiple GPU tools (avoids 16 GB torch duplication)

Use `rocm-diagnostics` skill first for read-only GPU/ROCm state probes before making changes.

## Quick reference

| Symptom | Error | Fix |
|---|---|---|
| MIOpen crash between models | `HSA_STATUS_ERROR_INVALID_ISA` at `miopen_convolution` | `torch.backends.cudnn.enabled = False` |
| Invalid kernel file on first run | `hipErrorInvalidKernelFile` (code 218) | Wrong ROCm wheel version; match system ROCm |
| Extreme GPU slowness (10x+ CPU) | Layout/Ops taking 100s vs CPU 10s | First-run JIT; wait for warmup or pre-warm |
| `rocminfo` shows 0 agents | ROCm runtime not installed or permission issue | `apt install rocm-hip-runtime`; check `render` group |
| Wrong GPU selected | iGPU used instead of dGPU | `HIP_VISIBLE_DEVICES=N` per-invocation |

## Installation

### Minimum viable install (Ubuntu 24.04 noble)

```bash
# Add AMD official repo
wget -qO - https://repo.radeon.com/rocm/rocm.gpg.key | sudo apt-key add -
echo "deb [arch=amd64] https://repo.radeon.com/rocm/apt/latest noble main" | \
  sudo tee /etc/apt/sources.list.d/rocm.list
sudo apt update

# Install minimal runtime (~680 MB download, ~586 MB installed)
sudo apt install rocm-hip-runtime
```

Pulled packages: `rocm-core`, `rocm-language-runtime`, `rocminfo`, `hip-runtime-amd`, `hsa-rocr`, `comgr`, `rocm-device-libs`, `rocm-llvm`, and dependencies.

**No kernel changes, no reboot required** on existing amdgpu/amdkfd systems.

### Verify

```bash
rocminfo | grep -E '^(Agent |  Marketing Name:)'
# Expected: GPU agents listed (RX 7600 XT, 780M, etc.)
```

### Audit for redundancy

After installation, confirm there is only one system ROCm and one shared Python venv:

```bash
# System ROCm: should show exactly one versioned directory
ls -d /opt/rocm-* 2>/dev/null
# Expected: /opt/rocm-7.2.4 (just one, ~2.4 GB)

# /opt/rocm is the Debian alternatives symlink — NOT a duplicate
update-alternatives --display rocm | head -3

# Python venvs: check for stray torch installs
find ~/.local/share/uv -name "torch" -path "*/site-packages/*" -maxdepth 8 2>/dev/null

# Should find at most one: ~/.local/share/rocm-tools (the shared venv).
# Stale uv tool installs (marker-pdf etc.) with their own torch copies are redundant.
```

### Uninstall

```bash
sudo apt remove rocm-hip-runtime
sudo rm /etc/apt/sources.list.d/rocm.list
sudo apt update
```

## PyTorch ROCm wheel matching

**Critical rule:** The PyTorch ROCm wheel version MUST match the system ROCm version.

| system ROCm | Wheel index |
|---|---|
| 7.2.x | `https://download.pytorch.org/whl/rocm7.2` |
| 7.0.x | `https://download.pytorch.org/whl/rocm7.0` |
| 6.4.x | `https://download.pytorch.org/whl/rocm6.4` |
| 6.3.x | `https://download.pytorch.org/whl/rocm6.3` |

**Mismatch symptoms:** `hipErrorInvalidKernelFile` (code 218) on first convolution call. The compiled GPU kernels are ABI-incompatible with a different ROCm runtime version.

### Shared ROCm venv (recommended)

Create one shared venv for all GPU tools. Avoids duplicating torch (16 GB) per tool.

```bash
# 1. Create shared venv
uv venv ~/.local/share/rocm-tools

# 2. Install ROCm torch from exact wheel URL (--find-links alone resolves CUDA torch)
#    Locate the wheel: curl -sL https://download.pytorch.org/whl/torch/ | grep "rocm7.2.*cp312.*manylinux"
uv pip install --python ~/.local/share/rocm-tools/bin/python \
  "torch @ https://download-r2.pytorch.org/whl/rocm7.2/torch-2.13.0%2Brocm7.2-cp312-cp312-manylinux_2_28_x86_64.whl" \
  --find-links https://download.pytorch.org/whl/triton-rocm

# 3. Install GPU tools into the same venv (not uv tool install)
uv pip install --python ~/.local/share/rocm-tools/bin/python marker-pdf
uv pip install --python ~/.local/share/rocm-tools/bin/python "docling[tesserocr,rapidocr,easyocr,vlm]"

# 4. Symlink entry points into PATH
for bin in marker_single marker docling surya_ocr; do
  ln -sf ~/.local/share/rocm-tools/bin/$bin ~/.local/bin/
done
```

**Disk savings:** 1 shared venv (~16 GB with torch + 2 tools) vs N isolated venvs (~16 GB each). Each additional tool adds only its own deps (~2-3 GB).

**Docling note:** Uses `docling convert` subcommand (not bare `docling`). The wrapper calls `from docling.cli.main import app` which detects subcommands from sys.argv automatically.

**Why the direct URL:** `--find-links https://download.pytorch.org/whl/rocm7.2` does not find torch wheels (the index page only lists triton subdirectories). `--index-url` with PyPI fallback resolves CUDA torch from PyPI first. The exact wheel URL avoids both issues. Check for newer wheel versions at `https://download.pytorch.org/whl/torch/`.

### Validate

```python
import torch
print(torch.__version__)          # e.g. 2.13.0+rocm7.2
print(torch.version.hip)          # e.g. 7.2.53211
print(torch.cuda.is_available())  # True (ROCm presents as CUDA)
print(torch.cuda.device_count())  # >= 1
print(torch.cuda.get_device_name(0))  # "AMD Radeon RX 7600 XT"
```

## MIOpen kernel cache corruption

### Problem

Multi-model GPU pipelines (e.g. layout detection → bbox detection → OCR) crash at model transitions with:

```
HSA_STATUS_ERROR_INVALID_ISA: The instruction set architecture is invalid. code: 0x100f
MIOpen(HIP): Error [EvaluateInvokers] ... Error setting device 0: invalid kernel file
terminate called after throwing an instance of 'c10::AcceleratorError'
  what():  CUDA error: invalid kernel file
```

**Root cause:** MIOpen's kernel cache (find database) is written by Model A's conv2d configurations. When Model B uses different conv2d shapes, MIOpen reads stale or incompatible cache entries and fails to compile the correct ISA for the current device state.

**Affected GPUs:** Observed on Navi 33 (RX 7600 XT, gfx1102) and Phoenix iGPU (gfx1103) with ROCm 7.2.x. May affect other gfx11xx architectures.

### Fix

Disable PyTorch's MIOpen/cuDNN backend before any model imports:

```python
import torch
torch.backends.cudnn.enabled = False
# Now import marker/surya/etc.
```

PyTorch falls back to its native HIP conv2d implementation. **No measurable performance penalty** on Navi 33 for detection/OCR workloads.

**DO NOT** set `MIOPEN_DEBUG_DISABLE_FIND_DB=1` — this forces MIOpen to re-search algorithms on every operation, causing extreme slowness (300s/page vs 3s/page).

### Wrapper script pattern

Create a shebang wrapper that disables MIOpen before loading the application:

```python
#!/path/to/venv/bin/python
"""Application with MIOpen disabled for multi-model ROCm stability."""
import torch
torch.backends.cudnn.enabled = False
from application.cli import main
if __name__ == "__main__":
    main()
```

Place in `~/.local/bin/` and use as the Yazi opener or shell alias target.

**Installed wrappers:** `~/.local/bin/marker_single_gpu` (Marker PDF), `~/.local/bin/docling_single_gpu` (Docling). Both follow this pattern — MIOpen disabled, shebang pointing to shared venv python, imports the tool's CLI entry point.

## First-run JIT compilation

ROCm compiles GPU kernels on first use. The compiled code is cached in `/tmp` (persists until reboot).

**One-time cost:** ~75s for EfficientViT layout model on RX 7600 XT. Subsequent runs are fast.

**Pre-warm strategy:** Run a dummy 1-page conversion and discard the output:

```bash
HIP_VISIBLE_DEVICES=0 marker_single --page_range 0 /dev/null 2>/dev/null || true
# Or with the wrapper:
HIP_VISIBLE_DEVICES=0 marker_single_gpu /path/to/any.pdf --output_dir /tmp/warmup --page_range 0
rm -rf /tmp/warmup
```

**Detection:** If progress shows `~300s/it` for the first page then drops to `~3s/it`, you're seeing JIT compilation.

## GPU isolation

On dual-GPU systems (dGPU + iGPU), pin the workload to the discrete GPU:

```bash
HIP_VISIBLE_DEVICES=0 your_command
```

Rocmrinfo maps Agents to HIP devices as:
- Agent 2 → HIP device 0 (usually the dGPU)
- Agent 3 → HIP device 1 (usually the iGPU)
- Agent 1 is the host CPU (not a compute device)

**Do not export `HIP_VISIBLE_DEVICES` globally** — set per-invocation only.

For Yazi openers:
```toml
{ run = 'HIP_VISIBLE_DEVICES=0 my_gpu_command "$1"', desc = "GPU Task", for = "unix", block = true }
```

## Performance characteristics (Navi 33 / gfx1102)

Known performance profile from RX 7600 XT benchmarking:

| Operation type | GPU vs CPU (multicore) | Notes |
|---|---|---|
| ViT layout detection | 8-10x faster (after warmup) | EfficientViT conv2d benefits |
| OCR text recognition | 1.1-1.3x faster | I/O-bound, marginal GPU benefit |
| Table recognition | ~5x faster | Small model, fast on GPU |
| Image preprocessing | Equivalent | CPU-bound PIL operations |

**Batch size:** Larger batch sizes (36 for CUDA) reduce CPU↔GPU transfer overhead. Small tiles per batch cause transfer to dominate compute.

**Memory:** RX 7600 XT has 16 GB VRAM. Marker's full pipeline uses ~3 GB. Ample headroom.

## GPU device naming

ROCm may report GPU names differently across tools:

| rocminfo | torch.cuda.get_device_name() | Reality |
|---|---|---|
| `AMD Radeon RX 7600 XT` | `AMD Radeon RX 7600 XT` or `AMD Radeon Graphics` | dGPU |
| `AMD Radeon 780M Graphics` | `AMD Radeon 780M Graphics` or `AMD Radeon Graphics` | iGPU |

If `torch.cuda.get_device_name()` returns the generic name (`AMD Radeon Graphics`), verify the correct GPU is targeted by checking `torch_props.total_memory` (dGPU ≈ 17 GB, iGPU ≈ 16 GB shared) or `torch_props.is_integrated` (True for iGPU).

The missing `/opt/amdgpu/share/libdrm/amdgpu.ids` warning is cosmetic and does not affect functionality.

## Common pitfalls

1. **Wrong wheel index.** `--find-links "https://download.pytorch.org/whl/rocm7.0"` when system has ROCm 7.2 → kernel errors. Always match minor version.

2. **Using `uv tool install` for GPU tools.** Each tool gets its own isolated venv with a full torch copy (16 GB/tool). Use the shared venv pattern instead: `uv pip install --python ~/.local/share/rocm-tools/bin/python tool-name`.

3. **`timeout` command syntax.** Use `env` prefix or put env var before `timeout`: `HIP_VISIBLE_DEVICES=0 timeout 90 command`, NOT `timeout 90 HIP_VISIBLE_DEVICES=0 command`.

4. **Orphaned NVIDIA packages.** After swapping CUDA torch for ROCm torch, the nvidia-* packages remain as dead weight (2-3 GB). Remove with `uv pip uninstall --python ~/.local/share/rocm-tools/bin/python nvidia-*`.

5. **Setting `MIOPEN_DEBUG_DISABLE_FIND_DB=1`.** This disables the entire MIOpen find database, forcing algorithm search on every conv2d call. Use `torch.backends.cudnn.enabled = False` instead.

6. **Multiple opencode sessions.** Compiled ROCm kernels in `/tmp` are shared across processes. If one session crashes, subsequent sessions may still have valid cached kernels.

7. **Torchvision version mismatch.** When installing new GPU tools into the shared venv, dependants may pull a CUDA torchvision from PyPI that lacks ROCm kernels. Symptom: `RuntimeError: operator torchvision::nms does not exist`. Fix: install ROCm torchvision from exact wheel URL alongside ROCm torch.

## Cross-references

- `rocm-diagnostics` skill: read-only GPU/ROCm probes before making changes
- `ops-agent-docs/runbooks/rocm-diagnostics.md`: detailed runbook
- `ops-agent-docs/server-baseline.md`: host GPU inventory
- `source-building` skill: for building PyTorch from source against specific ROCm version
