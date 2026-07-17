"""Live query tools for system-index MCP — wraps rg, journalctl, /proc."""
import os
import subprocess
import time
from fastmcp import FastMCP

MAX_LINES = 120
MAX_BYTES = 12_000
ARTIFACT_DIR = "/tmp/opencode/.artifacts/system-index"


def _cap(output: str, max_lines: int = MAX_LINES) -> str:
    """Cap output at max_lines and MAX_BYTES."""
    lines = output.splitlines()
    if len(lines) <= max_lines and len(output.encode()) <= MAX_BYTES:
        return output
    capped = "\n".join(lines[:max_lines])
    if len(capped.encode()) > MAX_BYTES:
        capped = capped[:MAX_BYTES]
    suffix = f"\n... (truncated, showing {max_lines} of {len(lines)} lines)"
    return capped + suffix


def _save_and_cap(output: str, tool_name: str, max_lines: int = MAX_LINES) -> str:
    """Save full output to artifact, return capped text."""
    os.makedirs(ARTIFACT_DIR, exist_ok=True)
    ts = int(time.time())
    artifact_path = os.path.join(ARTIFACT_DIR, f"{tool_name}-{ts}.txt")
    with open(artifact_path, "w") as f:
        f.write(output)
    capped = _cap(output, max_lines)
    total_lines = len(output.splitlines())
    if total_lines > max_lines:
        capped += f"\n[Full output ({total_lines} lines) saved to {artifact_path}]"
    return capped


def register(mcp: FastMCP):

    @mcp.tool()
    def log_search(
        pattern: str,
        source: str = "journald",
        since: str = "1 hour ago",
        max_lines: int = MAX_LINES,
    ) -> str:
        """Search system logs for a pattern.

        Args:
            pattern: Search pattern (ripgrep regex)
            source: 'journald' or a file path (e.g. '/var/log/syslog')
            since: Time range for journald (e.g. '1 hour ago', '30 minutes ago')
            max_lines: Maximum result lines (default 120)
        """
        try:
            if source == "journald":
                cmd = (
                    f"journalctl --since '{since}' --no-pager 2>/dev/null "
                    f"| rg -i '{pattern}'"
                )
            else:
                cmd = f"rg -in '{pattern}' '{source}' 2>/dev/null"
            result = subprocess.run(
                ["bash", "-c", cmd],
                capture_output=True, text=True, timeout=30,
            )
            output = result.stdout.strip()
            if not output:
                return f"No matches for '{pattern}' in {source}."
            return _save_and_cap(output, "log_search", max_lines)
        except subprocess.TimeoutExpired:
            return "Log search timed out after 30s."

    @mcp.tool()
    def proc_read(key: str) -> str:
        """Read a single /proc or /sys entry.

        Args:
            key: Entry name or path (e.g. 'cpuinfo', 'meminfo', 'version',
                 '/sys/class/drm/card0/device/vendor')
        """
        proc_map = {
            "cpuinfo": "/proc/cpuinfo",
            "meminfo": "/proc/meminfo",
            "version": "/proc/version",
            "modules": "/proc/modules",
            "mounts": "/proc/mounts",
            "partitions": "/proc/partitions",
            "uptime": "/proc/uptime",
            "loadavg": "/proc/loadavg",
        }
        path = proc_map.get(key, key)
        if not path.startswith("/"):
            path = f"/proc/{key}"

        try:
            with open(path, errors="replace") as f:
                content = f.read(MAX_BYTES)
            return content if content.strip() else f"{path} is empty."
        except PermissionError:
            return f"Permission denied: {path}"
        except FileNotFoundError:
            return f"Not found: {path}"

    @mcp.tool()
    def proc_search(pattern: str) -> str:
        """Search key /proc files for a pattern.

        Args:
            pattern: Search pattern (ripgrep regex)
        """
        proc_files = (
            "/proc/cpuinfo /proc/meminfo /proc/modules "
            "/proc/mounts /proc/partitions"
        )
        try:
            cmd = f"rg -i '{pattern}' {proc_files} 2>/dev/null"
            result = subprocess.run(
                ["bash", "-c", cmd],
                capture_output=True, text=True, timeout=15,
            )
            output = result.stdout.strip()
            if not output:
                return f"No matches for '{pattern}' in key /proc files."
            return _save_and_cap(output, "proc_search")
        except subprocess.TimeoutExpired:
            return "Search timed out after 15s."

    @mcp.tool()
    def file_grep(
        pattern: str, path: str, max_lines: int = MAX_LINES
    ) -> str:
        """Search any system file or directory with ripgrep.

        Args:
            pattern: Search pattern (ripgrep regex)
            path: File or directory path
            max_lines: Maximum result lines (default 120)
        """
        try:
            cmd = f"rg -in '{pattern}' '{path}' 2>/dev/null"
            result = subprocess.run(
                ["bash", "-c", cmd],
                capture_output=True, text=True, timeout=30,
            )
            output = result.stdout.strip()
            if not output:
                return f"No matches for '{pattern}' in '{path}'."
            return _save_and_cap(output, "file_grep", max_lines)
        except subprocess.TimeoutExpired:
            return "Search timed out after 30s."

    @mcp.tool()
    def file_head(path: str, lines: int = 50) -> str:
        """Read the first N lines of a file.

        Args:
            path: File path
            lines: Number of lines to read (default 50, max 200)
        """
        lines = min(lines, 200)
        try:
            with open(path, errors="replace") as f:
                content = []
                for i, raw in enumerate(f):
                    if i >= lines:
                        break
                    content.append(raw.rstrip("\n\r"))
            return "\n".join(content) if content else f"{path} is empty."
        except PermissionError:
            return f"Permission denied: {path}"
        except FileNotFoundError:
            return f"Not found: {path}"
        except IsADirectoryError:
            return f"'{path}' is a directory. Use file_grep to search directories."
