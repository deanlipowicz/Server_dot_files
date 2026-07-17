#!/usr/bin/env python3
"""System-index MCP server — indexed config queries + live system queries."""
import os

from fastmcp import FastMCP

DB_PATH = os.path.expanduser("~/.local/share/opencode/system-index.db")
os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)

mcp = FastMCP("system-index")

# Register tool groups
import tools_config
import tools_live

tools_config.register(mcp, DB_PATH)
tools_live.register(mcp)

if __name__ == "__main__":
    mcp.run()
