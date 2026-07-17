---
name: duckdb-knowledge-base
description: Build and query DuckDB knowledge bases with MCP tooling, parquet ingest, and schema conventions. Use when creating, querying, or managing DuckDB databases for knowledge-base workloads.
---

# DuckDB Knowledge Base

DuckDB v1.5.4 is installed at `/home/workstation/.local/bin/duckdb`. This skill covers knowledge-base patterns: per-project MCP integration, ingest conventions, parquet, and permission gating.

## Per-project MCP server

DuckDB MCP is configured per project (not globally) so each knowledge base owns its database path. Add to the project's `opencode.json`:

```jsonc
"mcp": {
  "duckdb": {
    "type": "local",
    "command": ["uvx", "mcp-server-motherduck", "--db-path", "<path>/knowledge.duckdb"],
    "enabled": true
  }
}
```

Gate DuckDB MCP tools in the project's permission block:

```jsonc
"permission": {
  "duckdb_*": "ask"
}
```

Restart opencode after adding MCP entries (config not hot-reloaded).

Verify the command works before wiring it into config:

```sh
uvx mcp-server-motherduck --help
```

## CLI quick reference

```sh
duckdb mydata.duckdb                                    # open interactive
duckdb mydata.duckdb "SELECT COUNT(*) FROM t;"          # one-shot query
duckdb mydata.duckdb ".tables"                          # list tables
duckdb mydata.duckdb <<'SQL'
CREATE OR REPLACE TABLE t AS SELECT * FROM read_csv_auto('file.csv');
SQL
duckdb mydata.duckdb <<'SQL'
COPY (SELECT * FROM t) TO 'out.csv' WITH (HEADER, DELIMITER ',');
SQL
```

## Ingest and schema conventions

- **Parquet preferred over CSV** for analytical tables: `CREATE TABLE t AS SELECT * FROM read_parquet('data/*.parquet');`
- **Partitioned data**: use `read_parquet('data/*/*.parquet', hive_partitioning=true)`.
- **Dates**: store as `DATE` type, not strings. Use `read_csv_auto` with `dateformat` hint when needed.
- **Indexes**: DuckDB does not use manual indexes; rely on its automatic zone maps and min-max indexes.
- **Views**: create views for common access patterns rather than duplicating data.
- **Attach**: use `ATTACH 'other.duckdb' AS other;` for cross-database queries.

## Knowledge base patterns

- One database file per domain (e.g., `papers.duckdb`, `logs.duckdb`, `system.duckdb`).
- Each database gets a `_meta` table tracking ingest timestamps, source files, and row counts.
- Use `read_parquet` with glob patterns for batch ingest.
- Export summaries back to parquet for portability.

## Permissions

- DuckDB MCP tools appear as `duckdb_query`, `duckdb_execute`, etc.
- Gate with `duckdb_*: ask` in the project's permission block; loosen to `allow` for read-only query tools if trusted.
- Never embed credentials in database files or SQL.

See also: `terminal-apps` reference (`duckdb.md`).
