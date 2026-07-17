---
name: mcp-builder
description: Build and test MCP (Model Context Protocol) servers for opencode integration. Use when creating custom MCP tools, wrapping data sources, or building tool-augmented agent capabilities with Python FastMCP or TypeScript SDK.
---

# MCP Builder

Build and test MCP servers that integrate with opencode. Covers Python FastMCP and TypeScript SDK scaffolds, tool-description quality rules, and the local test loop.

## Python FastMCP scaffold

```sh
uv init my-mcp-server && cd my-mcp-server
uv add mcp
```

Minimal server (`server.py`):

```python
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("my-tool")

@mcp.tool()
def query_data(query: str) -> str:
    """Run a query against the local data store. Returns JSON array of results."""
    # implementation
    return "[]"

if __name__ == "__main__":
    mcp.run()
```

Wire into opencode:

```jsonc
"mcp": {
  "my-tool": {
    "type": "local",
    "command": ["uv", "run", "--directory", "/path/to/my-mcp-server", "server.py"],
    "enabled": true
  }
}
```

## TypeScript SDK scaffold

```sh
mkdir my-mcp-server && cd my-mcp-server
npm init -y && npm install @modelcontextprotocol/sdk zod
```

Minimal server (`index.ts`):

```typescript
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

const server = new McpServer({ name: "my-tool", version: "1.0.0" });

server.tool("query_data", "Run a query against the local data store.", { query: z.string() }, async ({ query }) => ({
  content: [{ type: "text", text: "[]" }],
}));

const transport = new StdioServerTransport();
await server.connect(transport);
```

## Tool-description quality rules

Tool descriptions are the primary interface the agent sees. If a human cannot say definitively which tool to use when given two descriptions, neither can the agent.

- Each tool must have a **distinct, unambiguous purpose**.
- The description should state **what the tool does** and **when to use it**.
- Minimize overlap between tools — if two tools could plausibly answer the same query, merge or differentiate them.
- Include parameter descriptions with types, constraints, and examples.
- Name tools with verb-noun patterns: `search_docs`, `get_record`, `list_tables`.

## Local test loop

1. Add the MCP server entry to a project's `opencode.json` (or `~/.config/opencode/opencode.jsonc` for testing).
2. Restart opencode (config is not hot-reloaded).
3. Exercise the tool: issue a natural-language request that should trigger it.
4. Inspect tool output — verify correctness, check for truncation, confirm error handling.
5. Iterate on tool descriptions and logic. After each server change, the transport resets on the next call; no opencode restart needed for server code changes.

## Debugging

- MCP servers communicate over stdio. Debug by running the server directly and sending JSON-RPC messages.
- Check opencode's MCP connection status (platform-dependent; typically `opencode mcp list` or inspect logs).
- Common failures: wrong Python/Node path in `command`, missing dependencies, server crashing on malformed input (validate and catch exceptions).

## Permission gating

- MCP tools from a server appear with the server name prefix: `my-tool_query_data` → gate with `my-tool_*: ask` in permissions.
- New MCP servers are trusted by neither the agent nor the user; default to `ask`.
- For read-only query servers, loosen to `allow` after the user confirms trust.

## Reference

- MCP specification: https://modelcontextprotocol.io
- FastMCP docs: https://github.com/jlowin/fastmcp
- TypeScript SDK: https://github.com/modelcontextprotocol/typescript-sdk
