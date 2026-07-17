"""Index builder for system-index — scans /etc and package manifests into DuckDB."""
import json
import subprocess
from datetime import datetime
from pathlib import Path

import duckdb

from db import init_db

# --- Configuration ---
EXCLUDED_DIRS = {"/etc/ssl"}
EXCLUDED_PATTERNS = ["*key*", "shadow*", "*.pem", "*.crt"]
BINARY_MIME_PREFIXES = ("application/", "image/", "audio/", "video/")
MAX_FILE_SIZE = 1_048_576  # 1MB

CONFIG_GLOBS = [
    "*.conf", "*.cfg", "*.ini", "*.json", "*.yaml", "*.yml",
    "*.toml", "*.list", "*.default", "*.env",
]

# Extra directories within /etc that should be indexed regardless of extension
ALWAYS_INCLUDE_PARENTS = {"/etc/default", "/etc/modprobe.d", "/etc/environment", "/etc/apt"}


# --- Helpers ---

def is_binary(path: Path) -> bool:
    """Check if file is binary via MIME type."""
    result = subprocess.run(
        ["file", "--mime-type", "-b", str(path)],
        capture_output=True, text=True, timeout=5,
    )
    return result.stdout.strip().startswith(BINARY_MIME_PREFIXES)


def should_index(path: Path) -> bool:
    """Return True if file should be included in the config index."""
    if not path.is_file():
        return False
    if path.stat().st_size > MAX_FILE_SIZE:
        return False
    parent = str(path.parent)
    if any(parent.startswith(d) for d in EXCLUDED_DIRS):
        return False
    if any(path.match(p) for p in EXCLUDED_PATTERNS):
        return False
    if is_binary(path):
        return False
    # Must match config glob or be in an always-include directory
    if any(path.match(g) for g in CONFIG_GLOBS):
        return True
    if parent in ALWAYS_INCLUDE_PARENTS or any(
        parent.startswith(d) for d in ALWAYS_INCLUDE_PARENTS
    ):
        return True
    return False


# --- Config Index ---

def build_config_index(conn: duckdb.DuckDBPyConnection, etc_path: str = "/etc") -> dict:
    """Scan /etc and populate config_files + config_lines tables.

    Returns:
        dict with keys: files_indexed, lines_indexed, skipped
    """
    conn.execute("DELETE FROM config_lines")
    conn.execute("DELETE FROM config_files")

    etc = Path(etc_path)
    stats = {"files_indexed": 0, "lines_indexed": 0, "skipped": 0}

    for path in etc.rglob("*"):
        if not should_index(path):
            stats["skipped"] += 1
            continue

        st = path.stat()
        rel = str(path)

        mtime = datetime.fromtimestamp(st.st_mtime)
        conn.execute(
            "INSERT OR REPLACE INTO config_files VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)",
            [rel, st.st_size, 0, mtime],
        )

        lines = []
        try:
            with open(path, errors="replace") as f:
                for i, raw in enumerate(f, 1):
                    line = raw.rstrip("\n\r")
                    if not line.strip():
                        continue  # skip blank lines
                    is_comment = line.strip().startswith("#")
                    lines.append((rel, i, line, is_comment, mtime, st.st_size))
        except (PermissionError, OSError):
            stats["skipped"] += 1
            continue

        if lines:
            conn.executemany(
                "INSERT INTO config_lines VALUES (?, ?, ?, ?, ?, ?)", lines
            )

        conn.execute(
            "UPDATE config_files SET line_count = ? WHERE file_path = ?",
            [len(lines), rel],
        )
        stats["files_indexed"] += 1
        stats["lines_indexed"] += len(lines)

    return stats


# --- Package Index ---

def build_package_index(conn: duckdb.DuckDBPyConnection) -> dict:
    """Query apt, pip, and cargo for installed packages.

    Returns:
        dict with keys: apt, pip, cargo (counts)
    """
    conn.execute("DELETE FROM packages")
    stats = {"apt": 0, "pip": 0, "cargo": 0}

    # --- apt (dpkg) ---
    try:
        result = subprocess.run(
            ["dpkg-query", "-W", "-f", "${Package}\t${Version}\t${Section}\n"],
            capture_output=True, text=True, timeout=30,
        )
        if result.returncode == 0:
            rows = []
            for line in result.stdout.strip().split("\n"):
                if not line.strip():
                    continue
                parts = line.split("\t")
                if len(parts) >= 2:
                    name, version = parts[0], parts[1]
                    source = parts[2] if len(parts) > 2 else None
                    rows.append((name, version, "apt", source))
            if rows:
                conn.executemany("INSERT INTO packages VALUES (?, ?, ?, ?)", rows)
            stats["apt"] = len(rows)
    except Exception:
        pass

    # --- pip (try uv first, fall back to pip) ---
    for cmd in [
        ["uv", "pip", "list", "--format", "json"],
        ["pip", "list", "--format", "json"],
    ]:
        if stats["pip"] > 0:
            break
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
            if result.returncode == 0 and result.stdout.strip():
                data = json.loads(result.stdout)
                rows = [(p["name"], p.get("version", ""), "pip", None) for p in data]
                if rows:
                    conn.executemany("INSERT INTO packages VALUES (?, ?, ?, ?)", rows)
                stats["pip"] = len(rows)
        except Exception:
            continue

    # --- cargo ---
    try:
        result = subprocess.run(
            ["cargo", "metadata", "--format-version", "1", "--no-deps"],
            capture_output=True, text=True, timeout=30,
        )
        if result.returncode == 0 and result.stdout.strip():
            meta = json.loads(result.stdout)
            packages = meta.get("packages", [])
            rows = [(p["name"], p["version"], "cargo", p.get("source")) for p in packages]
            if rows:
                conn.executemany("INSERT INTO packages VALUES (?, ?, ?, ?)", rows)
            stats["cargo"] = len(rows)
    except Exception:
        pass

    return stats


# --- Orchestrator ---

def refresh_index(db_path: str, domains: list[str] | None = None) -> dict:
    """Full index refresh.

    Args:
        db_path: Path to DuckDB database file.
        domains: List of domains to refresh. Default ['all'].
                 Valid: 'config', 'packages', 'all'.

    Returns:
        dict with 'config' and/or 'packages' keys containing stats.
    """
    if domains is None:
        domains = ["all"]
    conn = init_db(db_path)
    result = {}
    try:
        if "all" in domains or "config" in domains:
            result["config"] = build_config_index(conn)
        if "all" in domains or "packages" in domains:
            result["packages"] = build_package_index(conn)

        # Write metadata
        conn.execute(
            "CREATE TABLE IF NOT EXISTS index_metadata (key TEXT PRIMARY KEY, value TEXT)"
        )
        conn.execute(
            "INSERT OR REPLACE INTO index_metadata VALUES ('built_at', ?)",
            [datetime.now().isoformat()],
        )
    finally:
        conn.close()
    return result


# --- CLI entry point ---

if __name__ == "__main__":
    import sys

    db_path = sys.argv[1] if len(sys.argv) > 1 else "/home/workstation/.local/share/opencode/system-index.db"
    domains = sys.argv[2:] if len(sys.argv) > 2 else ["all"]
    stats = refresh_index(db_path, domains)
    print(f"Index refresh complete: {stats}")
