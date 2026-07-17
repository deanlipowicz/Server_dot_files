"""DuckDB-backed config and package query tools for system-index MCP."""
import os
import duckdb
from fastmcp import FastMCP

MAX_LINES = 120
MAX_BYTES = 12_000
DB_PATH = os.path.expanduser("~/.local/share/opencode/system-index.db")


def _format_results(rows: list, max_lines: int = MAX_LINES) -> str:
    """Format query results as file:line: content, enforcing line and byte caps."""
    lines = [f"{r[0]}:{r[1]}: {r[2]}" for r in rows[:max_lines]]
    output = "\n".join(lines)
    if len(output.encode()) > MAX_BYTES:
        output = output[:MAX_BYTES].rsplit("\n", 1)[0]
    return output


def register(mcp: FastMCP, db_path: str = DB_PATH):
    global DB_PATH
    DB_PATH = db_path

    @mcp.tool()
    def config_search(
        pattern: str, path_glob: str | None = None, max_lines: int = MAX_LINES
    ) -> str:
        """Search indexed config files for lines matching pattern.

        Args:
            pattern: Text to search for (SQL LIKE, use % as wildcard)
            path_glob: Optional path filter (e.g. '/etc/apt/%')
            max_lines: Maximum results (default 120)
        """
        conn = duckdb.connect(DB_PATH, read_only=True)
        try:
            query = """
                SELECT file_path, line_number, content
                FROM config_lines
                WHERE is_comment = FALSE AND content ILIKE ?
            """
            params = [f"%{pattern}%"]
            if path_glob:
                query += " AND file_path LIKE ?"
                params.append(path_glob.replace("*", "%"))
            query += " ORDER BY file_path, line_number LIMIT ?"
            params.append(max_lines)

            rows = conn.execute(query, params).fetchall()
            if not rows:
                return f"No matches for '{pattern}' in config index."
            return _format_results(rows, max_lines=max_lines)
        finally:
            conn.close()

    @mcp.tool()
    def config_read(
        file_path: str, start_line: int = 1, end_line: int = 50
    ) -> str:
        """Read a range of lines from an indexed config file.

        Args:
            file_path: Path to config file (e.g. '/etc/fstab')
            start_line: First line number (1-indexed)
            end_line: Last line number (inclusive)
        """
        conn = duckdb.connect(DB_PATH, read_only=True)
        try:
            rows = conn.execute(
                """
                SELECT file_path, line_number, content
                FROM config_lines
                WHERE file_path = ? AND line_number BETWEEN ? AND ?
                ORDER BY line_number
                """,
                [file_path, start_line, end_line],
            ).fetchall()

            if not rows:
                exists = conn.execute(
                    "SELECT 1 FROM config_files WHERE file_path = ?", [file_path]
                ).fetchone()
                if not exists:
                    return f"File '{file_path}' not found in index. It may not be indexed or the index needs a refresh."
                return f"File '{file_path}' exists in index but has no lines in range {start_line}-{end_line}."
            return _format_results(rows, max_lines=MAX_LINES)
        finally:
            conn.close()

    @mcp.tool()
    def config_list_files(
        path_glob: str | None = None, pattern: str | None = None
    ) -> str:
        """List indexed config files with metadata.

        Args:
            path_glob: Optional path filter (e.g. '/etc/apt/%')
            pattern: Optional content search — list only files containing this text
        """
        conn = duckdb.connect(DB_PATH, read_only=True)
        try:
            if pattern:
                query = """
                    SELECT DISTINCT f.file_path, f.size_bytes, f.line_count
                    FROM config_lines l
                    JOIN config_files f ON l.file_path = f.file_path
                    WHERE l.content ILIKE ?
                """
                params = [f"%{pattern}%"]
                if path_glob:
                    query += " AND l.file_path LIKE ?"
                    params.append(path_glob.replace("*", "%"))
                query += " ORDER BY f.file_path"
            else:
                query = "SELECT file_path, size_bytes, line_count FROM config_files"
                params = []
                if path_glob:
                    query += " WHERE file_path LIKE ?"
                    params.append(path_glob.replace("*", "%"))
                query += " ORDER BY file_path"

            rows = conn.execute(query, params).fetchall()
            if not rows:
                return "No files found."
            lines = [f"{r[0]} ({r[2]} lines, {r[1]} bytes)" for r in rows]
            return "\n".join(lines[:MAX_LINES])
        finally:
            conn.close()

    @mcp.tool()
    def package_search(name: str, manager: str = "all") -> str:
        """Search installed packages by name.

        Args:
            name: Package name or partial name (SQL LIKE, use % for wildcard)
            manager: 'apt', 'pip', 'cargo', or 'all'
        """
        conn = duckdb.connect(DB_PATH, read_only=True)
        try:
            query = (
                "SELECT name, version, manager, source FROM packages "
                "WHERE name ILIKE ?"
            )
            params = [f"%{name}%"]
            if manager != "all":
                query += " AND manager = ?"
                params.append(manager)
            query += " ORDER BY manager, name LIMIT ?"
            params.append(MAX_LINES)

            rows = conn.execute(query, params).fetchall()
            if not rows:
                return f"No packages matching '{name}' found."
            lines = [f"{r[0]} {r[1]} ({r[2]})" for r in rows]
            return "\n".join(lines[:MAX_LINES])
        finally:
            conn.close()

    @mcp.tool()
    def package_list(manager: str = "all", pattern: str | None = None) -> str:
        """List installed packages, optionally filtered.

        Args:
            manager: 'apt', 'pip', 'cargo', or 'all'
            pattern: Optional name filter (SQL LIKE)
        """
        conn = duckdb.connect(DB_PATH, read_only=True)
        try:
            query = "SELECT name, version, manager FROM packages"
            params = []
            conditions = []
            if manager != "all":
                conditions.append("manager = ?")
                params.append(manager)
            if pattern:
                conditions.append("name ILIKE ?")
                params.append(f"%{pattern}%")
            if conditions:
                query += " WHERE " + " AND ".join(conditions)
            query += " ORDER BY manager, name LIMIT ?"
            params.append(MAX_LINES)

            rows = conn.execute(query, params).fetchall()
            if not rows:
                return "No packages found."
            lines = [f"{r[0]} {r[1]} ({r[2]})" for r in rows]
            return "\n".join(lines[:MAX_LINES])
        finally:
            conn.close()

    @mcp.tool()
    def index_status() -> str:
        """Show index metadata: age, file count, package counts."""
        conn = duckdb.connect(DB_PATH, read_only=True)
        try:
            built = conn.execute(
                "SELECT value FROM index_metadata WHERE key = 'built_at'"
            ).fetchone()
            file_count = conn.execute(
                "SELECT COUNT(*) FROM config_files"
            ).fetchone()[0]
            line_count = conn.execute(
                "SELECT COUNT(*) FROM config_lines"
            ).fetchone()[0]
            pkg_counts = conn.execute(
                "SELECT manager, COUNT(*) FROM packages GROUP BY manager"
            ).fetchall()

            parts = []
            if built:
                parts.append(f"Built: {built[0]}")
            else:
                parts.append("Index not yet built. Run index_refresh to create it.")
            parts.append(f"Files indexed: {file_count}")
            parts.append(f"Lines indexed: {line_count}")
            for mgr, count in pkg_counts:
                parts.append(f"Packages ({mgr}): {count}")
            return "\n".join(parts)
        finally:
            conn.close()

    @mcp.tool()
    def index_refresh(domains: str = "all") -> str:
        """Rebuild the system index.

        Args:
            domains: 'config', 'packages', or 'all' (comma-separated)
        """
        from build_index import refresh_index

        os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
        domain_list = [d.strip() for d in domains.split(",")]
        stats = refresh_index(DB_PATH, domain_list)
        parts = []
        if "config" in stats:
            c = stats["config"]
            parts.append(
                f"Config: {c['files_indexed']} files, {c['lines_indexed']} lines, "
                f"{c['skipped']} skipped"
            )
        if "packages" in stats:
            p = stats["packages"]
            parts.append(
                f"Packages: {p['apt']} apt, {p['pip']} pip, {p['cargo']} cargo"
            )
        return "\n".join(parts) if parts else "No domains refreshed."
