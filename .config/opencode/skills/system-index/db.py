"""DuckDB schema and connection management for system-index."""
import duckdb
from dataclasses import dataclass
from datetime import datetime

SCHEMA_SQL = """
CREATE TABLE IF NOT EXISTS config_files (
    file_path    TEXT PRIMARY KEY,
    size_bytes   BIGINT,
    line_count   INTEGER,
    last_modified TIMESTAMP,
    indexed_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS config_lines (
    file_path    TEXT NOT NULL,
    line_number  INTEGER NOT NULL,
    content      TEXT NOT NULL,
    is_comment   BOOLEAN DEFAULT FALSE,
    file_mtime   TIMESTAMP NOT NULL,
    file_size    BIGINT NOT NULL,
    PRIMARY KEY (file_path, line_number)
);

CREATE TABLE IF NOT EXISTS packages (
    name         TEXT NOT NULL,
    version      TEXT,
    manager      TEXT NOT NULL,
    source       TEXT,
    PRIMARY KEY (name, manager)
);
"""


@dataclass
class ConfigFile:
    file_path: str
    size_bytes: int
    line_count: int
    last_modified: datetime
    indexed_at: datetime | None = None


@dataclass
class ConfigLine:
    file_path: str
    line_number: int
    content: str
    is_comment: bool


@dataclass
class Package:
    name: str
    version: str | None
    manager: str
    source: str | None


def init_db(db_path: str) -> duckdb.DuckDBPyConnection:
    """Create or open the system-index database with schema tables."""
    conn = duckdb.connect(db_path)
    conn.execute(SCHEMA_SQL)
    return conn
